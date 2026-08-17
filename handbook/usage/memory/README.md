# Memory

What a query costs in memory on both sides of the R boundary:
what the engine holds while it reads and executes,
where each copy of a result lives on its way into R
and when each is freed,
what `memory_limit` bounds,
and how external storage — a database file, spill, temp tables —
extends what a session can process.
The routes themselves — DBI, Arrow, ADBC, relational — are
[`integrations/`](/handbook/usage/integrations/README.md)'s;
this page is what each of them allocates, and for how long.

## Two allocators, one sum

The engine allocates through its buffer manager,
bounded by `memory_limit` —
by default 80% of the memory available at startup
(`DBConfig::SetDefaultMaxMemory()`,
vendored `src/duckdb/src/main/config.cpp`).
R vectors come from R's allocator, which no engine setting bounds:
a fetched result is R memory however small the limit,
and the two sides are cumulative — neither sees the other
([#1065](https://github.com/duckdb/duckdb-r/issues/1065)).

Two engine allocations escape the limit as well,
as properties of today's system, not choices a caller can revisit:

* **A materialized result is untracked heap.**
  The engine can collect a result through the buffer manager —
  counted, evictable, spillable
  (`QueryResultMemoryType::BUFFER_MANAGED`,
  vendored
  `src/duckdb/src/execution/operator/helper/physical_result_collector.cpp`) —
  but this package requests the default in-memory kind,
  allocated from the plain allocator and invisible to `memory_limit`.
  Switching, and freeing the collection progressively as it converts,
  is planned
  ([`plan/PLAN-streaming-thread.md`](/plan/PLAN-streaming-thread.md)).
* **A streaming result's buffer is untracked too** —
  bounded instead by its own size cap
  ([below](#a-results-copies-path-by-path)).

Engine-side overshoot on *writes* has been reported as well,
tracked in [#97](https://github.com/duckdb/duckdb-r/issues/97).

The whole geography, with disk on the far side:

```text
 database file ◄──► ┌─────────────────────────────┐
 temp_directory ◄─► │ buffer pool — table blocks, │  counted against
 Parquet / CSV ───► │ query state, temp tables    │  memory_limit
                    └──────────────┬──────────────┘
                                   │ execute
                    ┌──────────────▼──────────────┐
                    │ result collection (whole) / │  untracked
                    │ stream buffer (bounded)     │  engine heap
                    └──────────────┬──────────────┘
                                   │ convert — whole or batch
                    ┌──────────────▼──────────────┐
                    │ R vectors                   │  no limit, no spill,
                    └─────────────────────────────┘  freed by R's collector
```

Disk and the buffer pool exchange data in both directions;
below the pool, data moves only downward — toward R, never back.

## What the engine holds while a query runs

By the source the query reads:

* **A database file:**
  table blocks page into the buffer pool as the scan needs them
  and evict under `memory_limit`;
  a clean block is dropped and re-read on its next touch.
* **An in-memory database:**
  the table data *is* buffer-pool memory, counted against the limit.
  Under pressure such blocks cannot be dropped —
  there is no file to re-read them from —
  so they are offloaded to `temp_directory`,
  and where spill is unavailable, pressure is an out-of-memory error
  (the eviction paths in
  vendored `src/duckdb/src/storage/standard_buffer_manager.cpp`).
* **A Parquet or CSV file:**
  scanned, never loaded whole —
  the readers hold buffers around what each thread is decoding,
  freed as the scan advances;
  what accumulates is what the query keeps, not the file.
  The engine's execution internals are duckdb.org's to document
  ([`architecture/engine/`](/handbook/architecture/engine/README.md)).
* **A registered data frame or Arrow table:**
  scanned in place from R's own memory, zero-copy
  ([`data-import/`](/handbook/usage/data-import/README.md));
  registration keeps the object alive until it is unregistered.
* **Query state** — join hash tables, sort runs, window buffers —
  is counted against the limit and spills ([below](#spill)).

## A result's copies, path by path

A result can exist in up to three shapes at once:
the engine's own collection, Arrow arrays, and R vectors.
Peak memory is whatever coexists,
so the paths differ by which copies they hold and when each is freed.

* **`dbSendQuery()` + `dbFetch()`, and so `dbGetQuery()`.**
  Everything runs up front — at `dbSendQuery()`,
  or at `dbBind()` for a parameterized statement —
  and nothing at fetch time.
  The engine executes and materializes the whole result (untracked,
  above), and the glue converts it into full-length R vectors
  in one pass (`rapi_execute_impl()`,
  [`src/statement.cpp`](/src/statement.cpp)),
  so the peak holds both copies;
  the engine's is freed as that call returns.
  The R copy is stored whole in the result object
  ([`R/Result.R`](/R/Result.R)),
  and `dbFetch(n = )` merely slices it
  ([`R/dbFetch__duckdb_result.R`](/R/dbFetch__duckdb_result.R)):
  chunked fetching bounds nothing,
  holding the full-result peak and running slower than one fetch
  ([#1997](https://github.com/duckdb/duckdb-r/issues/1997),
  quantified in
  [`experiments/2026-08-streaming-tpch-bench/`](/experiments/2026-08-streaming-tpch-bench/README.md)).
  A multi-row `dbBind()` executes once per row and `rbind()`s the
  per-row frames — one more full copy while it concatenates.
  `dbClearResult()` frees the prepared statement;
  the R copy goes to the garbage collector with the result object.
  The open fix is a streaming mode with chunk-wise conversion,
  `dbSendQuery(stream = TRUE)`:
  [#2584](https://github.com/duckdb/duckdb-r/pull/2584),
  [#2586](https://github.com/duckdb/duckdb-r/pull/2586) and
  [#2587](https://github.com/duckdb/duckdb-r/pull/2587),
  with [`plan/PLAN-streaming-thread.md`](/plan/PLAN-streaming-thread.md)
  carrying what comes after.
* **`dbSendQuery(arrow = TRUE)` + `dbFetch()` or
  `duckdb_fetch_arrow()`.**
  The legacy arrow route materializes exactly like the default route —
  streaming execution is `dbSendQueryArrow()`'s alone —
  and then keeps the engine copy alive in the result object
  for the result's whole lifetime, re-scanning it on each fetch.
  A fetch converts the entire result into arrow record batches and a
  Table (`rapi_execute_arrow()`,
  [`src/statement.cpp`](/src/statement.cpp)),
  and `dbFetch()` stacks `as.data.frame()` on top:
  up to three copies coexist —
  the shape of the
  [#1065](https://github.com/duckdb/duckdb-r/issues/1065) report.
  `duckdb_fetch_record_batch()` additionally leaks its stream wrapper
  (the `FIXME` at `rapi_record_batch()`, same file).
  The route is slated for retirement in favor of the DBI Arrow API
  ([#2587](https://github.com/duckdb/duckdb-r/pull/2587)
  refuses to combine it with `stream = TRUE` and names the migration).
* **`dbSendQueryArrow()` + `dbFetchArrow()` /
  `dbFetchArrowChunk()`.**
  The one route that streams today.
  Execution starts at `dbSendQueryArrow()` and pauses at a bounded
  buffer:
  the engine produces at most `streaming_buffer_size` ahead of the
  consumer — 1,000,000 bytes by default, a plain `SET`
  (vendored `src/duckdb/src/include/duckdb/main/client_config.hpp`) —
  then parks.
  It waits rather than spills,
  holding pipeline state and the transaction open,
  with the buffer itself outside `memory_limit` accounting.
  `dbFetchArrowChunk()` holds one batch at a time;
  `dbFetchArrow()` hands the whole stream to nanoarrow,
  so what materializes from it is the consumer's choice.
  The stream pins the connection —
  any other statement invalidates it —
  `dbClearResult()` frees it eagerly,
  and a multi-row bind falls back to one materialized result per row
  (`rapi_bind()`, [`src/statement.cpp`](/src/statement.cpp)).
  The surfaces, and that a stream drains once, are
  [`integrations/`](/handbook/usage/integrations/README.md)'s.
* **ADBC.**
  The engine's own ADBC driver, compiled into this package's library
  (`duckdb_adbc()`, [`R/Driver.R`](/R/Driver.R);
  vendored `src/duckdb/src/common/adbc/adbc.cpp`),
  executes with a streaming result and hands it across as an Arrow
  stream: batch-sized engine memory,
  with conversion owned by whatever consumes the stream.
  One caveat with no DBI-side equivalent:
  running another statement on the same ADBC connection
  *materializes* every open stream into memory
  (`MaterializeStreams()`, same file) instead of invalidating it,
  so an abandoned stream can become a full result copy
  as a side effect of the next query.
* **The relational API (duckplyr).**
  `rel_to_altrep()` defers everything:
  an unexecuted relation costs no result memory at all.
  The first touch of any column materializes the whole result
  engine-side, within the `n_rows`/`n_cells` budget
  (`AltrepRelationWrapper`,
  [`src/reltoaltrep.cpp`](/src/reltoaltrep.cpp);
  the C++ half is
  [`architecture/glue/altrep/`](/handbook/architecture/glue/altrep/README.md)'s).
  Each column converts to a full R vector on its own first touch and
  is cached; untouched columns stay engine-only.
  The engine collection is never released:
  it lives alongside the converted vectors for as long as the data
  frame does, so a fully touched frame holds the result twice until
  the collector takes it —
  [#1027](https://github.com/duckdb/duckdb-r/pull/1027) is the open
  fix, freeing the collection once the last column has converted.

## Spill

The engine offloads to `temp_directory` when a query outgrows
memory — on by default, as in the CLI.
For an in-memory database the package points it at a fresh
per-instance directory below the session temporary directory;
the engine creates it at first spill and removes it at shutdown,
and instances must not share one
(spill file names are deterministic,
and shutdown cleanup removes what it finds).
A file database is left to the engine's own default, `<dbdir>.tmp`
beside the file (vendored `src/duckdb/src/main/config.cpp`);
the options that override either are
[`storage/`](/handbook/usage/storage/README.md)'s.
Spill covers query state, not a transaction's own uncommitted
writes — those blocks stay pinned, so a very large single append
can still fail at `COMMIT` under a tight limit
(engine-side; reported once on 1.3.2 and not reproduced since,
[#1604](https://github.com/duckdb/duckdb-r/issues/1604) —
not even on 1.3.2 itself, per
[`experiments/2026-08-temp-storage-spill/`](/experiments/2026-08-temp-storage-spill/README.md),
which measured the spill behavior of both connection idioms
across four builds).

## What external storage buys

Disk helps exactly as far as the engine side reaches:
in the picture above, everything that borders disk is pageable or
spillable, and nothing below the result line ever moves back up —
an R vector cannot be sent to disk.
Processing data larger than memory therefore means keeping the large
side engine-side, on or against external storage,
and letting only reductions or batches cross into R.

* **A file database bounds the dataset by disk, not by RAM.**
  With `dbConnect(duckdb(), dbdir = )` the tables live in the file
  and the buffer pool holds only the working set,
  so data far beyond `memory_limit` is queryable from the start.
  An in-memory database is the weaker configuration for size:
  every table is resident,
  and only memory pressure moves blocks out to `temp_directory` —
  external storage as overflow, not as home.
* **A temp table is the spillable form of a result.**
  Where a large result must cross into R piecewise,
  materialize it engine-side first —
  `CREATE TEMP TABLE ... AS`, fetch from the table in slices,
  drop it.
  The temp table is engine data, counted against `memory_limit` and
  spillable, which no result copy above is,
  and the idiom measured competitive with direct materialization
  ([`experiments/2026-08-streaming-tpch-bench/`](/experiments/2026-08-streaming-tpch-bench/README.md)).
* **A Parquet file is a result that never touches R.**
  `COPY (...) TO 'file.parquet'` in SQL,
  or duckplyr's `compute_parquet()`,
  writes a result straight to external storage,
  streamed, with no R copy at any point;
  scanning it back is a streamed read again.
  The surfaces are
  [`data-import/`](/handbook/usage/data-import/README.md)'s.
* **Spill saves queries, not results.**
  `temp_directory` lets query state outgrow `memory_limit`
  ([above](#spill));
  it never catches a result collection or an R copy,
  which is why the untracked copies in the fetch paths stay the
  bottleneck until the planned work above lands.
* **Best of all is not to fetch:**
  leave larger-than-memory data in DuckDB,
  query it lazily via dbplyr or duckplyr,
  and `collect()` only the reduction;
  [#72](https://github.com/duckdb/duckdb-r/issues/72) is the long
  history behind that advice.

*To deepen: give the write path
([#97](https://github.com/duckdb/duckdb-r/issues/97))
the measured account the fetch paths have.*
