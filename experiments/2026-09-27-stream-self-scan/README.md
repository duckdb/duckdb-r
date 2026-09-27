# Scanning a stream on its own connection

*What it measures:* what a query does when it scans a streaming result on the connection that result came from.
The streams come from `dbGetQueryArrow()` and `to_arrow_stream()`, and the scans from `duckdb_register_arrow()` and `arrow::to_duckdb()`.
It records which scans answer, and whether an interrupt ends one that does not.
It compares the build before [#2775](https://github.com/duckdb/duckdb-r/pull/2775) and the Python client.
It also records where the scan waits and what works instead.

*When and on what:* 2026-09-27, Linux x86_64 with 4 cores, R 4.5.3.
duckdb 1.5.5.9028 is the branch of [#2803](https://github.com/duckdb/duckdb-r/pull/2803) on `main` at a1806e4bd.
duckdb 1.5.5.9026 is bf1600976, the commit before #2775.
Both are fast-path builds ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
What is measured here is engine code, not configuration.
The release `libduckdb` shares that code with the vendored engine, because `configure` insists on the same upstream commit.
The other packages are arrow 25.0.1, nanoarrow 0.9.0, DBI 1.3.0, dbplyr 2.6.0 and dplyr 1.2.1.
The Python client is duckdb 1.5.5 with pyarrow 25.0.1.
[`self-scan.R`](self-scan.R) is rendered to [`self-scan.md`](self-scan.md) by [`scripts/render-reprex.R`](/scripts/render-reprex.R).
`PRE_2775_LIB` names the library of the older build for it.
Each case runs in a fresh R session through callr and is killed after ten seconds without an answer.
The session info names the scratch library that held the newer build as `<fast-path build library>`.
[`run-python.sh`](run-python.sh) runs [`self-scan.py`](self-scan.py) and wrote [`python.txt`](python.txt).
[`backtraces.sh`](backtraces.sh) wrote [`backtraces.txt`](backtraces.txt).

*What it supports:* the Arrow section of [`usage/integrations/`](/handbook/usage/integrations/README.md).
It also supports the reference page of `to_arrow_stream()`.
It replaces the account of the wait in [`2026-09-26-to-arrow-stream/`](/experiments/2026-09-26-to-arrow-stream/README.md).
That account laid it at the glue's door.

## Every scan of a stream on its own connection waits

From [`self-scan.md`](self-scan.md):

* **A reader registered on its own connection.**
  A reader over a `dbGetQueryArrow()` stream of three million rows is registered with `duckdb_register_arrow()`.
  It is counted on the same connection.
  The count gives no answer within ten seconds.
  Neither does a result of ten rows, `SET threads = 1`, or a reader whose first batch has been read.
* **`to_arrow_stream()` handed back with `to_duckdb()`.**
  The reader waits the same way when `arrow::to_duckdb(con = )` hands it back to its own connection.
  So does a table from `to_duckdb()` taken through `to_arrow_stream()` and `to_duckdb()` again without `con`.
  Both calls without `con` use the one connection arrow keeps.
* **The build before #2775.**
  1.5.5.9026 gives no answer either.
* **An interrupt does not end the wait.**
  A session waiting on the scan is alive five seconds after a SIGINT, which is what Ctrl-C sends, and five seconds after a second one.
  The same interrupt ends an ordinary long query, `SELECT sum(i) FROM range(100000000000)`, within five seconds.

## The engine's lock, not the glue's check

The stream is dead before the scan reads it.
Registering a reader only records it for the replacement scan (`rapi_register_arrow()` in [`src/register.cpp`](/src/register.cpp)).
The query that scans it is the next statement on the connection.
Starting that query ends the stream's query (`ClientContext::CleanupInternal()`).
The engine keeps no mark on the stream for that.
It knows the stream is gone only by comparing it to the connection's active result, which needs the connection's lock.
`StreamQueryResult::IsOpen()` takes that lock before it compares (`src/duckdb/src/main/stream_query_result.cpp`).
The scanning query holds the lock until the scan returns.
So the scan waits for the read on arrow's pool, and the read waits for the lock.
The thread that holds the lock waits inside the scan, in arrow's `FutureImpl::Wait()`, and the interrupt above does not end that wait.

That is the engine's own stream, in both clients:

* **Python.**
  In [`python.txt`](python.txt), the same count times out on the connection the reader came from.
  It does so through `execute()` and through the relational API.
  It answers 3,000,000 through a cursor, which is a second connection, and over an Arrow table.
* **Where both wait.**
  From [`backtraces.txt`](backtraces.txt), trimmed to the frames that meet:

  ```
  Python, a thread of arrow's pool
  #4  duckdb::ClientContext::LockContext()
  #5  duckdb::StreamQueryResult::LockContext()
  #6  duckdb::StreamQueryResult::IsOpen()
  #7  duckdb::ResultArrowArrayStreamWrapper::MyStreamGetNext(ArrowArrayStream*, ArrowArray*)

  Python, the main thread
  #6  arrow::FutureImpl::Wait()
  #10 duckdb::ArrowArrayStreamWrapper::GetNextChunk()
  #19 duckdb::ClientContext::ExecuteTaskInternal(duckdb::ClientContextLock&, duckdb::BaseQueryResult&, bool)

  R before #2775, a thread of arrow's pool
  #6  duckdb::StreamQueryResult::IsOpen()
  #7  duckdb::ResultArrowArrayStreamWrapper::MyStreamGetNext(ArrowArrayStream*, ArrowArray*)
  #10 arrow::BackgroundGenerator<std::shared_ptr<arrow::RecordBatch> >::WorkerTask(...)

  R before #2775, R's thread
  #5  arrow::FutureImpl::Wait()
  #9  duckdb::ArrowArrayStreamWrapper::GetNextChunk()
  #18 duckdb::ClientContext::ExecuteTaskInternal(duckdb::ClientContextLock&, duckdb::BaseQueryResult&, bool)
  #24 rapi_execute (stmt=..., convert_opts=...) at statement.cpp:297
  ```

`ResultArrowArrayStreamWrapper` is the stream the engine hands out.
Since #2775 the glue wraps it, and its `RArrowArrayStreamWrapper::Invalidated()` asks `IsOpen()` before the engine does.
The stacks in [`2026-09-26-to-arrow-stream/`](/experiments/2026-09-26-to-arrow-stream/README.md) reach the wait from that check.

## What works instead

* **A second connection.**
  Registered on a second connection to the same database, the reader counts 3,000,000 rows.
* **Reading to the end first.**
  `arrow::as_arrow_table()` reads the stream to the end, and the table counts 3,000,000 rows on the stream's own connection.
* **A materialized result.**
  A reader from `dbSendQuery(arrow = TRUE)` and `duckdb_fetch_record_batch()` counts 3,000,000 rows on its own connection.
  The result is complete before the scan starts, so there is no stream to invalidate.

## Reads on R's thread fail instead

Both write methods are DBI's defaults, and both read the stream on R's thread between statements of their own.

* **`dbWriteTableArrow()` creates nothing.**
  It asks `dbExistsTable()` before it reads the schema.
  The schema request then fails with the invalidation error of [#2772](https://github.com/duckdb/duckdb-r/issues/2772), even for ten rows.
* **`dbAppendTableArrow()` leaves the first batch behind.**
  It reads a batch and appends it with `dbAppendTable()`, a statement, before it reads the next.
  Into an existing table from a stream of three million rows, the second read fails the same way, with 1,000,000 rows appended.
  A stream of ten rows is one batch, read to the end before the first append, and all ten arrive.

These reads happen outside any query, so `IsOpen()` finds the lock free and reports the invalidation.

## An aside: a bare stream

`duckdb_register_arrow()` refuses a nanoarrow stream itself, from either connection.
The error is `Invalid Error: std::exception`, from `rapi_prepare`.
Its schema callback reads `$schema` ([`R/register.R`](/R/register.R)), which is `NULL` for a nanoarrow stream.
That is why the cases wrap the stream in `arrow::as_record_batch_reader()`.

## Open problems

* **The engine could answer without the lock.**
  The statement that ends a stream's query could mark the stream itself, and `IsOpen()` could read that mark before it takes the lock.
  A scan on the stream's own connection would then fail with the invalidation error instead of waiting.
  That change is upstream's.
* **The glue could answer without the engine.**
  A statement from R reaches the engine through the glue's connection.
  The glue could count the statements it starts per connection, and a stream could keep the count it was created at.
  A read that finds the count moved would report the invalidation without asking `IsOpen()`.
  Registration must not count, because it runs no statement.
  Neither this nor the engine change is built here.
