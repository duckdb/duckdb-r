# The engine's budget

What `memory_limit` bounds and what escapes it,
how to see the engine's side,
where spill goes,
and what external storage buys.
What a result costs on its way into R is
[`reading/`](/handbook/usage/memory/reading/README.md)'s;
what a write costs is
[`writing/`](/handbook/usage/memory/writing/README.md)'s.

## The limit, and what escapes it

The engine allocates through its buffer manager,
bounded by `memory_limit` —
by default 80% of the memory available at startup
(`DBConfig::SetDefaultMaxMemory()`,
vendored `src/duckdb/src/main/config.cpp`).
R vectors come from R's allocator, which no engine setting bounds:
a fetched result is R memory however small the limit,
and the two sides are cumulative — neither sees the other
([#1065](https://github.com/duckdb/duckdb-r/issues/1065)).

Set the limit where it takes effect:
on the driver, `duckdb(config = list(memory_limit = "2GB"))`,
or on a live connection with `SET memory_limit`.
Passed to `dbConnect(config = )` it applies only in the cases
[`connections/`](/handbook/usage/connections/README.md) lists,
and is silently kept out of a running instance otherwise
([#126](https://github.com/duckdb/duckdb-r/issues/126)) —
the shape of more than one "the limit is not respected" report.

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
  bounded instead by its own size cap,
  which [`reading/`](/handbook/usage/memory/reading/README.md) states.

The engine's own ledger, `SELECT * FROM duckdb_memory()`,
shows the counted side per tag and what of it has spilled;
the untracked copies above never appear in it,
and R's `gc()` never sees the engine at all —
so a session's true footprint is the process, not either report.

## Spill

The engine offloads to `temp_directory` when its budget runs out —
on by default, as in the CLI.
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
The 1.5.5 release points both idioms at a directory nothing creates,
so its first spill fails with an I/O error
([#2562](https://github.com/duckdb/duckdb-r/pull/2562) is the fix,
on `main`);
the ADBC route is unaffected, since it never passes through the
package's setting
([`experiments/2026-09-14-memory-clients/`](/experiments/2026-09-14-memory-clients/README.md)).
Spill covers table data and query state alike,
an uncommitted write included
([`writing/`](/handbook/usage/memory/writing/README.md));
what it never covers is a result copy on its way to R.
A `COMMIT` failing under a tight limit was reported once, on 1.3.2
([#1604](https://github.com/duckdb/duckdb-r/issues/1604)),
and not reproduced since — not even on 1.3.2 itself, per
[`experiments/2026-08-temp-storage-spill/`](/experiments/2026-08-temp-storage-spill/README.md),
which measured the spill behavior of both connection idioms
across four builds.

## What external storage buys

Disk helps exactly as far as the engine side reaches:
in the picture on [`memory/`](/handbook/usage/memory/README.md),
everything that borders disk is pageable or spillable,
and nothing below the pool ever moves back up —
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
  spillable, which no result copy is,
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
* **Spill saves the engine's work, not the copies in flight.**
  `temp_directory` lets tables and query state outgrow `memory_limit`
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
