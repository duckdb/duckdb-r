# `arrow::to_arrow()` on the DBI Arrow interface

*What it measures:* whether `arrow::to_arrow()` can be rebuilt on `dbGetQueryArrow()` and `arrow::as_record_batch_reader()`
and still return the class, schema and data it returns today.
It also records what streaming changes about how long the reader stays valid, and how much memory each construction peaks at.
The comparison is the legacy route that `to_arrow()` takes now, `dbSendQuery(arrow = TRUE)` with `duckdb_fetch_record_batch()`.

*When and on what:* 2026-09-26, Linux x86_64 with 4 cores and 16 GB, R 4.5.3.
duckdb 1.5.5.9026 is `main` at 937144d6f, in the fast-path build of [`build/fast-paths/`](/handbook/build/fast-paths/README.md).
The other packages are arrow 25.0.1, nanoarrow 0.9.0, DBI 1.3.0, dbplyr 2.6.0 and dplyr 1.2.1.
The constructions are in [`to-arrow-stream.R`](to-arrow-stream.R).
[`equivalence.R`](equivalence.R) is rendered to [`equivalence.md`](equivalence.md).
[`lifetime.R`](lifetime.R) is rendered to [`lifetime.md`](lifetime.md).
Both are rendered by `reprex::reprex(input = , wd = ".", venue = "gh", si = TRUE)`.
Their session info names the scratch library that held the fast-path build as `<fast-path build library>`.
[`memory.R`](memory.R) runs one process per case and wrote [`memory.csv`](memory.csv).
[`hang-backtrace.sh`](hang-backtrace.sh) printed the stacks quoted below.

*What it supports:* the `to_arrow()` paragraph in [`usage/integrations/`](/handbook/usage/integrations/README.md).
It is also context for [#2788](https://github.com/duckdb/duckdb-r/pull/2788), which deprecates the `arrow = TRUE` route.
That deprecation stays soft because `to_arrow()` still takes the route.

## Three constructions

`to_arrow()` in arrow 25.0.1 passes an Arrow object through and refuses anything but a dbplyr table on a duckdb connection.
It sends the rendered query with `arrow = TRUE` and reads it with `duckdb_fetch_record_batch()`.
It wraps that reader in arrow's internal `MakeSafeRecordBatchReader()` and applies the table's groups, which makes an `arrow_dplyr_query`.
The engine has materialized the whole result by the time `dbSendQuery()` returns.

* **`to_arrow_stream()`, the candidate.**
  It keeps that contract, with `DBI::dbGetQueryArrow()` and `arrow::as_record_batch_reader()` in place of the duckdb calls and the wrapper.
  It uses exported API only.
  DBI's default `dbGetQueryArrow()` sends the query, fetches the stream with `dbFetchArrow()` and clears the DBI result before it returns.
  The stream owns the engine's query result from then on, and arrow owns the stream.
* **`to_arrow_literal()`, the literal swap.**
  The same two calls, with `MakeSafeRecordBatchReader()` kept around the reader so that every read runs on R's thread.
* **`to_arrow_pulled()`, reads on R's thread from exported API.**
  `as_record_batch_reader()` over an R function that takes the next batch from the stream and moves it into arrow.
  Arrow's function reader runs the function on R's thread and passes an error on.

## The same data in the same shape

From [`equivalence.md`](equivalence.md), the candidate against `to_arrow()`:

* **Class.**
  A `RecordBatchReader` for a plain table, and an `arrow_dplyr_query` grouped by `g` for a grouped one.
* **Schema and data.**
  `Table$Equals()` finds them equal after `as_arrow_table()`, metadata included, in every case.
  The cases are a three-million-row table (three batches) and a `filter()`, `mutate()`, `summarise()` and `arrange()` pipeline.
  They include a table with a row of `NULL`s and a column of each of seventeen types, `LIST`, `STRUCT`, `MAP` and `DECIMAL` among them.
  Empty results of both tables are the last two.
* **Downstream.**
  `collect()` gives identical data frames, and both routes fail alike on the `INTERVAL` column, which arrow cannot convert to R.
  A further arrow pipeline of `filter()`, `mutate()`, `group_by()`, `summarise()` and `arrange()` collects identically.
  So do the carried groups.
* **Sources that call R.**
  Arrow's engine pulls the candidate's stream from its own threads.
  A query over a registered data frame with factor and list columns collects identically that way.
  So does an arrow dataset handed to duckdb with `to_duckdb()` and back.
* **Passthrough and refusal.**
  An arrow `Table` and an `arrow_dplyr_query` come back identical, and a `dbplyr::lazy_frame()` gets `to_arrow()`'s message.

## What streaming changes

From [`lifetime.md`](lifetime.md):

* **A statement on the same connection invalidates an unread reader.**
  `to_arrow()`'s reader reads all three million rows after a `SELECT 42`.
  The candidate's raises the error of [#2772](https://github.com/duckdb/duckdb-r/issues/2772), before its first batch or after it.
  The message starts `Invalid Input Error: The query result was invalidated by another statement on its connection`.
  Read to the end first, and the next statement is harmless.
* **So does a second reader.**
  An arrow `inner_join()` of two readers from one connection gives 428,572 rows through `to_arrow()`.
  Through the candidate it gives the invalidation error.
* **A second connection is independent.**
  The same join with the second reader on a second connection gives 428,572 rows.
  A stream open on the first connection reads its remaining two million rows after the second inserts ten into the table it scans.
  The second connection counts 3,000,010 rows, and the stream reads the snapshot it started on.
* **A query that fails after its first batch fails at the read.**
  `to_arrow()` fails inside `to_arrow()`, while it materializes.
  The candidate and the pulled reader raise the engine's error from `as_arrow_table()` and from arrow's engine.
  The literal swap returns two million of three million rows and no error, through `as_arrow_table()` and `summarise()` alike.
  In arrow's `r/src/recordbatchreader.cpp`, `SafeRecordBatchReader::ReadNext()` passes a lambda to `SafeCallIntoRVoid()`.
  The lambda returns the wrapped reader's `Status`, and the `std::function<void(void)>` it becomes discards it.
  So an error reads as the end of the stream.
* **The DBI result and the connection may go first.**
  The candidate's reader reads all three million rows after `dbDisconnect(shutdown = TRUE)`.
  The stream holds the engine's query result, and with it the connection's context.
* **Handing the reader back to duckdb.**
  `to_duckdb()` registers it on arrow's own connection by default, where duckdb pulls it from a thread of arrow's pool.
  `to_arrow()`'s reader, the literal swap's and the pulled one are refused there with
  `NotImplemented: Call to R ... from a non-R thread from an unsupported context`.
  The candidate's gives three million rows.
* **Handing it back to its own connection hangs.**
  The other three are refused the same way.
  The candidate's stream waits for the connection the scanning query holds, until the subprocess is killed at 20 seconds.
  The stacks from [`hang-backtrace.sh`](hang-backtrace.sh), trimmed to the frames that meet:

  ```
  Thread 2 (arrow's pool)
  #4  duckdb::ClientContext::LockContext()
  #6  duckdb::StreamQueryResult::IsOpen()
  #7  duckdb::RArrowArrayStreamWrapper::Invalidated () at arrow_export.cpp:119
  #8  duckdb::RArrowArrayStreamWrapper::GetNext () at arrow_export.cpp:146
  #11 arrow::BackgroundGenerator<std::shared_ptr<arrow::RecordBatch> >::WorkerTask(...)

  Thread 1 (R)
  #5  arrow::FutureImpl::Wait()
  #9  duckdb::ArrowArrayStreamWrapper::GetNextChunk()
  #18 duckdb::ClientContext::ExecuteTaskInternal(duckdb::ClientContextLock&, ...)
  #24 rapi_execute () at statement.cpp:296
  ```

## Memory

The figures are peak resident memory over the process's baseline of 223 MB, from [`memory.csv`](memory.csv).
The query is `SELECT range AS i, range * 0.5 AS x FROM range(n)`, 800 MB of data at fifty million rows and 320 MB at twenty million.
The first figure of each pair is for 800 MB, the second for 320 MB.

* **Consumed by arrow's engine**, `summarise(n = n(), s = sum(x))` and then `collect()`:
  * `to_arrow()`: 1,218 and 520 MB.
  * The candidate: 68 and 67 MB.
  * The literal swap: 68 and 83 MB.
  * The pulled reader: 1,195 and 497 MB.
* **Into an arrow `Table`** with `as_arrow_table()`:
  * `to_arrow()`: 2,309 and 918 MB.
  * The candidate, the literal swap and the pulled reader: 1,161 to 1,162 and 468 MB.
* **Into a data frame** with `collect()`:
  * `to_arrow()`: 2,882 and 1,144 MB.
  * The candidate, the literal swap and the pulled reader: 1,719 to 1,721 and 686 to 689 MB.

At fifty million rows, the call to `to_arrow()` itself took 2.65 to 2.92 seconds, and to each of the others 0.02 to 0.04 seconds.
End to end, the candidate was faster in each of these single runs.
It took 2.72 against 3.49 seconds through arrow's engine, 2.91 against 4.29 into a `Table`, and 4.94 against 6.30 into a data frame.

## What the numbers say

* **The candidate's reader holds the result once, not twice.**
  Where the consumer keeps everything, `to_arrow()` costs the engine's copy on top, about 1,150 MB at 800 MB of data.
  Where the consumer keeps nothing, the candidate and the literal swap stay at 67 to 83 MB whatever the size of the result.
  `to_arrow()` costs the whole result and more there.
* **The pulled reader streams on paper only.**
  Each batch reaches arrow as an R `RecordBatch` object, whose reference to the batch lives until R's collector finalizes it.
  R's collector does not see arrow's memory.
  [`usage/memory/reading/`](/handbook/usage/memory/reading/README.md) describes the same effect for dropped batches.
* **The literal swap is unsafe as it stands.**
  It is the only construction measured that loses rows silently, and the loss comes from arrow's wrapper, not from the engine.
* **The candidate is the one that both streams and reports errors, on released arrow.**
  What it gives up is the wrapper's guarantee that reads run on R's thread.
  Arrow's engine and duckdb's arrow scan pull it from their own threads.
  None of the scans measured here failed that way, R-backed sources included.
  The hang on the reader's own connection is such a pull, though, blocked on the connection's lock.

## What the change to arrow would be

`to_arrow()` would swap its two duckdb calls and drop the wrapper:

```r
stream <- DBI::dbGetQueryArrow(dbplyr::remote_con(.data), dbplyr::remote_query(.data))
out <- as_record_batch_reader(stream)
```

That needs DBI 1.2.0 for `dbGetQueryArrow()`.
It also needs a duckdb that reports an invalidated stream as an error ([#2775](https://github.com/duckdb/duckdb-r/pull/2775)).
No release carries that on the date above.
Before it, a statement between `to_arrow()` and the read ends the stream early and silently.
That is [#2772](https://github.com/duckdb/duckdb-r/issues/2772).

Keeping reads on R's thread instead needs `SafeRecordBatchReader::ReadNext()` to return the wrapped reader's status.
Something along these lines, not built here:

```cpp
arrow::Status ReadNext(std::shared_ptr<arrow::RecordBatch>* batch_out) override {
  arrow::Status status;
  RETURN_NOT_OK(SafeCallIntoRVoid(
      [&] { status = this->parent_->ReadNext(batch_out); },
      "SafeRecordBatchReader::ReadNext()"));
  return status;
}
```

With it, the literal swap keeps the candidate's memory, measured above.
It refuses both `to_duckdb()` round trips, as it and `to_arrow()` do today, rather than completing one and hanging on the other.
The fix stands on its own, because any reader the wrapper holds loses its errors today.

## Open problems

* **The own-connection hang is the glue's to report.**
  `RArrowArrayStreamWrapper::Invalidated()` asks `StreamQueryResult::IsOpen()`, which waits for the client context lock.
  The query scanning the stream holds that lock until the scan returns.
  The fetch after the check would need the same lock, so the stream cannot be read there at all.
  What is open is refusing with an error rather than waiting.
* **Reads from arrow's threads were checked against R-backed sources only.**
  They were not checked against every R callback the engine can reach, the progress display among them
  ([`architecture/glue/threading/`](/handbook/architecture/glue/threading/README.md)).
