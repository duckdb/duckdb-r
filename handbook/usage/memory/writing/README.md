# Writing

What writing into the engine costs:
a data frame through `dbWriteTable()` and `dbAppendTable()`,
a query result through `CREATE TABLE ... AS`, a temp table or
`COPY ... TO`,
and what an open transaction holds.
The budget it counts against, and where it spills, is
[`budget/`](/handbook/usage/memory/budget/README.md)'s;
the import surfaces are
[`data-import/`](/handbook/usage/data-import/README.md)'s.

* **A data frame is scanned in place, and the table is a second copy.**
  `dbWriteTable()` registers the frame as a view,
  runs `CREATE TABLE ... AS SELECT ... FROM` that view,
  and unregisters it
  ([`R/dbWriteTable__duckdb_connection_character_data.frame.R`](/R/dbWriteTable__duckdb_connection_character_data.frame.R));
  `dbAppendTable()` does the same through `INSERT INTO ... SELECT`
  ([`R/dbAppendTable__duckdb_connection.R`](/R/dbAppendTable__duckdb_connection.R)).
  Registration copies nothing but the columns it must re-encode —
  non-UTF-8 strings and `POSIXlt` (`encode_values()`,
  [`R/register.R`](/R/register.R)) —
  and the scan reads the R vectors directly;
  a deferred column, such as a compact sequence, is made real in R at
  bind time, so it costs its full size first
  ([`architecture/glue/threading/`](/handbook/architecture/glue/threading/README.md)
  owns why bind is where that happens).
  On the engine side the new table is buffer-pool memory:
  in an in-memory database it stays resident up to the limit and is
  offloaded to `temp_directory` beyond it —
  on the 1.5.5 release that offload fails instead, and the write with it,
  the spill regression
  [`budget/`](/handbook/usage/memory/budget/README.md) names;
  in a file database it is written through to the file as the
  statement runs, and only a working set stays in the pool.
  The peak is therefore the frame plus at most the limit —
  and with no limit set, the frame plus a whole engine copy.
  [#97](https://github.com/duckdb/duckdb-r/issues/97) reported twice
  the data for a large write;
  its reprex passes the limit through `dbConnect(config = )`,
  the form that does not reach a running instance
  ([#126](https://github.com/duckdb/duckdb-r/issues/126)),
  and with the limit set where it takes effect the same write stays
  within it
  ([`experiments/2026-09-14-memory-clients/`](/experiments/2026-09-14-memory-clients/README.md)).
  Against the other clients the route is as cheap as any:
  an 800 MB frame goes in for 279–320 MB over its own size under a
  300 MB limit — the pool filling to the limit, which is also what the
  engine generating the rows itself costs — where pandas, an Arrow
  table and polars in Python, a `Vec` in Rust and typed arrays in Node
  read 298–378,
  and `duckdb_register()` alone, with no table made, reads 1 MB
  ([`experiments/2026-09-19-memory-ingest/`](/experiments/2026-09-19-memory-ingest/README.md),
  the source of every cross-client number on this page).
  Data that arrives in pieces is appended in pieces for about a chunk
  more (fifty `dbAppendTable()` calls of a million rows: 426 MB over an
  idle process),
  and CSV over a pipe into `COPY ... FROM '/dev/stdin'` for the floor
  alone (315 MB), at three times the file reader's time.
  None of this grows with the data:
  at 12 GB on a 15.7 GiB machine, three quarters of its memory,
  the same routes read 355–582 MB over their baseline —
  373 over the frame for `dbWriteTable()`, 1 to register —
  and every one of them completes,
  where the same frame through pandas is killed building the frame.
* **Row-wise parameters cost one statement per row.**
  `dbBind()` or `params = ` with `n` rows executes the statement `n`
  times (`rapi_bind()`, [`src/statement.cpp`](/src/statement.cpp)),
  each its own auto-commit transaction unless `dbBegin()` wraps them:
  bounded in memory, and slow in proportion.
* **A query result written engine-side is budgeted.**
  `CREATE TABLE ... AS`, a temp table, duckplyr's `compute()`:
  the result lands in the buffer pool, counted and spillable,
  and none of the copies in flight that
  [`reading/`](/handbook/usage/memory/reading/README.md) describes
  ever arise.
  `COPY ... TO` and `compute_parquet()` stream the result to the file
  through per-thread buffers around the row group being written,
  and nothing crosses into R at all.
* **An open transaction holds nothing extra.**
  An uncommitted append is table blocks like any other:
  offloaded to `temp_directory` in an in-memory database,
  written through in a file database,
  and `COMMIT` then succeeds under the same limit.
  The one report of a `COMMIT` failing under a tight limit,
  [#1604](https://github.com/duckdb/duckdb-r/issues/1604),
  did not reproduce on four builds
  ([`experiments/2026-08-temp-storage-spill/`](/experiments/2026-08-temp-storage-spill/README.md)).
* **A registered Arrow object is Arrow's memory, and a lazy one is
  held whole.**
  `duckdb_register_arrow()` exports whatever it is given through
  `arrow::Scanner$create()` ([`R/register.R`](/R/register.R)),
  and the scanner reads ahead on Arrow's own thread pool,
  pausing only at a backpressure threshold above most datasets.
  An Arrow table already in memory costs the scan alone
  (354–429 MB over the table, under the 300 MB limit);
  a source that produces as it is read —
  `arrow::open_dataset()` handed over, which is what `arrow::to_duckdb()`
  does — is buffered by the scanner faster than a table write under a
  memory limit can drain it,
  and peaks above the data's size:
  1,036 MB for the 800 MB Parquet file, 1,435 MB with `threads = 1`,
  where `read_parquet()` in the engine reads the same file for 308 MB.
  The same pairing costs Python the same
  (799–854 MB for a dataset, a generator and an IPC stream),
  and the buffering has a ceiling the small dataset never reached:
  at 12 GB the scanner stops about 2 GB over an idle process,
  still four times the same stream taken a batch at a time;
  the engine's scan holds one batch per thread
  (`ArrowScanParallelStateNext()`,
  [`src/duckdb/src/function/table/arrow.cpp`](/src/duckdb/src/function/table/arrow.cpp)),
  and a consumer that keeps up — `count(*)` over the source — sees
  169–349 MB.
  An Arrow *stream* over an R connection cannot go this way at all:
  nanoarrow's reader refuses any thread but R's, the scanner pulls from
  Arrow's pool, and `threads = 1` does not change that
  ([`architecture/glue/threading/`](/handbook/architecture/glue/threading/README.md)).
  `dbAppendTableArrow()` is the route for a stream —
  DBI's default pulls a batch on R's thread and appends it as a data
  frame, 505 MB over an idle process for the same 800 MB —
  and for a file the engine can read, letting it read is a third of the
  cost.
  Once unregistered and dropped, the memory returns at Arrow's pace
  ([#1089](https://github.com/duckdb/duckdb-r/issues/1089):
  a second `gc()` was what it took).
