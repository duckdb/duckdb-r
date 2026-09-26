# Reading

What a query costs on its way into R:
what the engine holds while it reads each kind of source,
where each copy of a result lives per route and when it is freed,
and which routes carry a result larger than memory.
The budget all of it counts against, and where it spills, is
[`budget/`](/handbook/usage/memory/budget/README.md)'s;
the routes themselves are
[`integrations/`](/handbook/usage/integrations/README.md)'s.

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
  is counted against the limit and spills.

## A result's copies, path by path

A result can exist in up to three shapes at once:
the engine's own collection, Arrow arrays, and R vectors.
Peak memory is whatever coexists,
so the paths differ by which copies they hold and when each is freed.

* **`dbSendQuery()` + `dbFetch()`, and so `dbGetQuery()`.**
  Everything runs up front — at `dbSendQuery()`,
  or at `dbBind()` for a parameterized statement —
  and nothing at fetch time.
  The engine executes and materializes the whole result
  (untracked; [`budget/`](/handbook/usage/memory/budget/README.md)),
  and the glue converts it into full-length R vectors
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
  [`src/arrow_export.cpp`](/src/arrow_export.cpp)),
  and `dbFetch()` stacks `as.data.frame()` on top:
  up to three copies coexist —
  the shape of the
  [#1065](https://github.com/duckdb/duckdb-r/issues/1065) report.
  `duckdb_fetch_record_batch()` instead hands the engine copy to an
  arrow `RecordBatchReader` (`rapi_record_batch()`, same file),
  which reads it batch by batch and frees it when the reader is
  collected.
  The route is slated for retirement in favor of the DBI Arrow API
  ([#2587](https://github.com/duckdb/duckdb-r/pull/2587)
  refuses to combine it with `stream = TRUE` and names the migration).
* **`dbSendQueryArrow()` + `dbFetchArrow()` /
  `dbFetchArrowChunk()`.**
  The one DBI route that streams today.
  Execution starts at `dbSendQueryArrow()` and pauses at a bounded
  buffer:
  the engine produces at most `streaming_buffer_size` ahead of the
  consumer — 1,000,000 bytes by default, a plain `SET`
  (vendored `src/duckdb/src/include/duckdb/main/client_config.hpp`),
  which an order-preserving plan splits between a read queue and the
  batches still being assembled
  (vendored `src/duckdb/src/main/buffered_data/batched_buffered_data.cpp`) —
  then parks.
  It waits rather than spills,
  holding pipeline state and the transaction open,
  with the buffer itself outside `memory_limit` accounting.
  A batch is `chunk_size` rows — 1,000,000 by default on both fetch
  methods — assembled engine-side from the engine's own chunks,
  so a batch costs rows times row width, in Arrow memory,
  before anything reaches R.
  `dbFetchArrowChunk()` hands over one such batch at a time;
  `dbFetchArrow()` hands over the whole stream,
  and what materializes from it is the consumer's choice.
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
  executes with a streaming result behind the same engine buffer
  and hands it across as an Arrow stream
  whose every batch is one engine chunk —
  `STANDARD_VECTOR_SIZE` rows, 2048
  (vendored `src/duckdb/src/include/duckdb/common/vector_size.hpp`).
  Conversion is owned by whatever consumes the stream;
  `read_adbc()` followed by `as.data.frame()` is a full R copy.
  One caveat with no DBI-side equivalent:
  running another statement on the same ADBC connection
  *materializes* every open stream in full, untracked, into memory
  (`MaterializeStreams()`, same file) instead of invalidating it,
  and the stream stays readable afterwards —
  so drain or release a stream before the connection does anything
  else, or its whole result is the price of the next statement.
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
  Until then, a frame that must live on is cheaper as a plain copy:
  copying every column out with an ordinary subset and dropping the
  ALTREP frame releases both of its copies,
  at the price of a third one while the copy is made
  (measured in the experiment named below).

## More than fits

Both streaming routes — `dbSendQueryArrow()` and ADBC — carry a
result larger than memory, on three conditions:

* **The engine side must fit or spill.**
  A sort or a join ahead of the stream completes before the first
  batch, within `memory_limit` if spill is available and the limit is
  set where it takes effect
  ([`budget/`](/handbook/usage/memory/budget/README.md)).
* **The consumer must not accumulate.**
  Converting the whole stream at once is a full R copy;
  a loop over batches is what keeps R at batch size.
* **Each batch must be released before the next,
  and `nanoarrow_pointer_release()` is what releases it.**
  A batch is a `nanoarrow_array` whose buffers the engine allocated
  with `malloc`, outside R's heap
  (`rapi_fetch_arrow_array()`, [`src/arrow_export.cpp`](/src/arrow_export.cpp),
  fills a struct that `nanoarrow::nanoarrow_allocate_array()` owns);
  what frees them is the struct's release callback,
  the engine's `ArrowAppender::ReleaseArray`.
  `nanoarrow::nanoarrow_pointer_release()` runs that callback at once,
  whatever else refers to the batch, and is the route with the most
  control: the object is an invalid pointer afterwards, and the result
  it came from is untouched.
  Dropping the batch leaves the callback to the finalizer nanoarrow
  registered on the pointer, which runs only in a collection,
  and R's collector runs on R-heap pressure these buffers never
  create — so a loop that merely drops each batch climbs toward the
  full result until a collection happens to run
  (8 GB of a 12 GB result, measured).
  `gc()` is the fallback that forces one:
  a single call frees a dropped batch, since the finalizer calls the
  release directly, but only if nothing refers to the batch any more,
  and at the cost of a full collection each time.
  The one thing neither route reaches is a character column converted
  from the batch: nanoarrow converts strings lazily, moving that column
  out of the batch into an owner of its own, so the column keeps its
  buffers until it is materialized or dropped, while numeric columns
  are copied and let the batch go.
  Every one of these is measured in
  [`experiments/2026-09-14-memory-clients/`](/experiments/2026-09-14-memory-clients/README.md#releasing-a-batch),
  beside every other number this page rests on.

The materializing routes carry no such result:
`dbGetQuery()`, `dbFetch()` in any chunking, the legacy arrow route
and a touched relation each hold the whole result on at least one
side of the boundary.
Measured at three quarters of a machine's memory —
12 GB of a 15.7 GiB worker, in the same experiment —
the released Arrow stream peaks at 166 MB, the converted one at 229
and ADBC at 154, the small result's numbers,
while `dbGetQuery()`, the `dbFetch(n = )` loop and the legacy arrow
route are each killed at the memory cap within a minute.

## Against the other clients

The same result through the Python, Node, Go and Rust clients —
each bundling the engine release the CRAN package ships,
Go one release behind — measured in
[`experiments/2026-09-14-memory-clients/`](/experiments/2026-09-14-memory-clients/README.md):

* **Python streams by default.**
  `execute()` opens a streaming result, so `fetchmany()`,
  a record-batch reader and `fetch_df_chunk()` all stay at batch size
  (255–320 MB for a 12 GB result);
  a whole pandas frame peaks a little above twice the data,
  a whole Arrow table barely above the data itself.
* **Node streams on request.**
  `stream()` stays near batch size; `run()` holds the engine copy,
  and columns as JavaScript arrays cost several times the data —
  at 12 GB, two hours of collector thrashing before the kill.
* **Go and Rust iterate over a held engine copy.**
  `database/sql` rows and the `duckdb` crate's iterators both walk a
  materialized result: the data once while iterating,
  twice when collected in Rust,
  and more in Go's growing slices.
  Under a limit the held copy is untracked there too — the same
  property as this package's materialized route, not an R one —
  and at 12 GB on a 16 GB machine it is why they survive at 11.7 GB
  where every collected form is killed,
  and why a result without room for one copy would end them too.
* **Where this package differs** is the chunked API of its default
  route: `dbFetch(n = )` keeps the full peak where Python's
  `fetchmany()` does not.
  Its Arrow stream, released batch by batch, and ADBC sit with the
  lowest peaks of any client measured.
