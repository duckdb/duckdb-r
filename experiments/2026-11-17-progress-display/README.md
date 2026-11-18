# What the progress display is told, and when

*What it measures:* every call the engine makes to the function set as `duckdb.progress_display`,
with the time since the R call that issued the query and the percentage it passes,
split by the R call it arrives in.
For large local queries (a scan with a filter, a `GROUP BY`, an `ORDER BY`, a join),
each read whole with `dbGetQuery()`, streamed with `dbGetQueryArrow()` and `$get_next()`,
and through `dbSendQuery()` and `dbFetch(n = )`.
For queries with a slow remote part, a Parquet file read through httpfs from a local server throttled to 2 MB/s per response,
and a slow local part.
For one stream under three values of `max_streaming_buffer_size`.
And which of the calls are the display's `Finish()` rather than an `Update()`, which the callback cannot tell apart,
since both pass it 100, and whether every call the engine makes reaches the R function.
Asked on [#3012](https://github.com/duckdb/duckdb-r/pull/3012), after [#2967](https://github.com/duckdb/duckdb-r/issues/2967).

*When and on what:* 2026-11-17, Linux x86_64 on an Intel Xeon at 2.10 GHz with 4 cores, R 4.5.3, nanoarrow 0.9.0,
duckdb 2.0.0.9000 built from source at 73ead8b of the `v2.0-cyanoptera` series, engine `v2.0.0`,
httpfs `77392a7207` from DuckDB's extension repository.
Each local query ran at `threads = 1` and at `threads = 4` on a table of 40,000,000 rows (and one of 10,000,000 for the join);
the tables and the remote file are built single-threaded under a fixed seed.

* [`run.R`](run.R), rendered by [`scripts/render-reprex.R`](/scripts/render-reprex.R) into [`run.md`](run.md):
  per run the row count, the wall time and the number of calls,
  and per R call a trace sampled every quarter second, the longest silence, the highest value below 100 and the largest rise.
  Every value quoted below is in `run.md`, `finish.txt` or `arrow-thread.txt`.
  `run.R` also writes every call to a CSV file, which is not kept here; its header says where it goes.
  [`throttle_server.py`](throttle_server.py) is the throttled server.
* [`finish.sh`](finish.sh) runs [`finish.R`](finish.R) under gdb
  with breakpoints on `RProgressBarDisplay::Update()` and `RProgressBarDisplay::Finish()`, then once without gdb.
  It writes [`finish.txt`](finish.txt): per scenario, the R callback's calls and the reads that got any,
  and under gdb the `Update()` calls, how many of them came from a thread other than R's, and the phase every `Finish()` came in.
  Its streams read chunks of 100,000 rows of a table of 10,000,000.
  It ran on the same branch after merging `v2.0-cyanoptera` at 1748e8f, whose changes leave the progress display alone.
* [`arrow-thread.sh`](arrow-thread.sh) runs [`arrow-thread.R`](arrow-thread.R) once per route,
  each reading a stream of 10,000,000 rows under a 16 KiB buffer,
  through `$get_next()`, `as_arrow_table()`, `write_parquet()`, `write_dataset()` or `collect()`,
  the last four on arrow's record batch reader,
  under gdb with breakpoints on `RProgressBarDisplay::Update()`, `RProgressBarDisplay::Finish()` and `RArrowArrayStreamWrapper::GetNext()`
  and `DLIB` naming the build library.
  [`arrow-thread.txt`](arrow-thread.txt) holds, per route, the R callback's calls, the breakpoint counts per event and thread,
  and their sequence with consecutive runs collapsed; arrow was 26.0.1.

The session info names the scratch library that held the build as `<branch build library>`.
Values printed as 100 in "highest below 100" are just below it, and the trace rounds them to 100.0 too.

*What it supports:* [`usage/interactive/`](/handbook/usage/interactive/README.md).

## Conclusions

* **#2967 looked like a bug because the bar was expected to move on the later reads of a stream and did not.**
  The cause is the engine's streaming buffer: a read the buffer serves runs no engine work, so the engine sends no call.
  Under a buffer too small for the result, every read that runs the engine reports ([c](#c-the-streaming-buffer)),
  which a test in [`tests/testthat/test-progress_display.R`](/tests/testthat/test-progress_display.R) holds to.
* **What the bar shows and when is the engine's behavior, and out of this package's scope.**
  The engine weighs the percentage by estimated rows, not time, and decides when to update and when to finish
  ([a](#a-large-local-queries), [b](#b-a-remote-part-and-a-local-part)).
* **The package relays every call made on R's thread; calls from arrow's thread pool are dropped
  ([#3034](https://github.com/duckdb/duckdb-r/issues/3034)).**
  In the glue, `RProgressBarDisplay::Update()` ([`src/connection.cpp`](/src/connection.cpp)) calls the R function on every call,
  and `Finish()` calls `Update(100)`; it returns early only when no function is set or when called off R's thread,
  and an error the function raises is ignored.
  `get_progress_display()` ([`R/progress_display.R`](/R/progress_display.R)) hands a user's function over unwrapped;
  only the default display throttles.
  Under gdb with breakpoints on `Update()` and `Finish()`, every one of 1,972 `Update()` calls across eleven scenarios,
  at one and at four threads, materialized and streamed, came on R's thread and reached the R function,
  one callback per call ([`finish.txt`](finish.txt)).
  No scenario here reads a stream off R's thread.
  One that does is [#3034](https://github.com/duckdb/duckdb-r/issues/3034):
  a stream handed to `arrow::as_record_batch_reader()` and read by arrow's thread pool,
  as `write_dataset()` or `collect()` on the reader do,
  runs the engine on an arrow thread, and the check drops all of those calls, `Finish()` included:
  14,184 and 14,159 `Update()` calls on arrow's thread, and the R callback got only the one call it had before the first read
  ([`arrow-thread.txt`](arrow-thread.txt)).
  `$get_next()`, `as_arrow_table()` and `write_parquet()` read on R's thread and deliver every call.
* **A stream's display can finish before the stream ends, which is the engine's behavior, recorded here and not fixed.**
  `Executor::IdleState()` reports a ready state while the result collector is blocked
  ([`src/duckdb/src/parallel/executor.cpp`](/src/duckdb/src/parallel/executor.cpp)),
  and `ClientContext::UpdateProgressInternal()` passes any observable state as final,
  under the engine's own note that this is not correct for streaming results
  ([`src/duckdb/src/main/client_context_execution.cpp`](/src/duckdb/src/main/client_context_execution.cpp)).
  In [`finish.txt`](finish.txt) the four-thread scan under a 976 KiB buffer finished its display with read 9 of 51
  and brought no `Finish()` at its end, under gdb, whose breakpoints change the timing.
  In R the default display is then cleared early and painted again by later updates,
  and no final `Finish()` clears it, so its line stays unless a later update reaches 100.
  It depends on timing: the same stream at one thread, and every stream in `run.md`, finished with its last read.
  The probe for #3034, also under gdb, saw it on every route ([`arrow-thread.txt`](arrow-thread.txt)):
  each stream got its `Finish()` before its updates passed 0.5, after 0.150187 through `$get_next()`,
  0.08192 through `as_arrow_table()` and 0.43008 through `write_parquet()`, and none at its end;
  there the last update of the routes on R's thread passed 100, which clears the line.

## What every query is told

* **A statement that a DBI call prepares opens with a 100.**
  `dbGetQuery()`, `dbExecute()`, `dbSendQuery()`, `dbSendStatement()` and `dbGetQueryArrow()` prepare the last statement of the string
  with `ClientContext::Prepare()`, which runs a `PREPARE` as a query of its own,
  and that query's display finishes before the statement runs ([`finish.txt`](finish.txt)).
  The statement's own calls follow, from 0, and its own `Finish()` is its last call.
  The statements before the last in a multi-statement string run through `Connection::Query()` without a `PREPARE`,
  each with its own display and `Finish()`:
  `SELECT 1; SELECT count(*) ...; SELECT 2` passes four 100s from `Finish()`, one for each statement and one for the last one's `PREPARE`.
* **The calls come from the R thread, whenever it runs or polls an engine task**, whether or not the value moved.
  Single-threaded, R's thread runs every task, and the calls come between task slices:
  395 in the 2.77 s scan, 493 in the 4.06 s `GROUP BY`.
  With four threads, R's thread can poll in a loop while the workers run, and each poll calls the callback:
  548,317 calls in the four-thread scan, but 302 in the four-thread `count(*)` of the same filter.
* **R's thread calls again as soon as the callback returns**, so what the callback costs sets how many calls it gets.
  `run.R`'s callback, which stores three numbers, got 21,004 calls in the 1 GiB stream's first read;
  `finish.R`'s, which writes a line to standard output, got 8,448 in its whole 1 GiB stream scenario,
  and 239 under gdb, whose breakpoints make every call slower ([`finish.txt`](finish.txt)).
* **A materialized result is told everything inside the call that runs it.**
  `dbSendQuery()` runs the query to its end before it returns, so its `dbFetch(n = )` reads get no calls,
  and its trace is `dbGetQuery()`'s.

## a. Large local queries

The percentage is the pipelines' source progress, each pipeline weighted by its source's estimated row count,
so it moves with execution, not only with fetches, and its speed follows the weights rather than the clock.
Single-threaded, through `dbGetQuery()`:

* **Scan with a filter** (`hash(i::VARCHAR || 'salt') % 100 = 0`, 398,634 rows out):
  climbs evenly from 0 to 50 over 2.76 s, then jumps to 100 with `Finish()`.
  The scan never fills more than half of the sum: `EXPLAIN` in [`run.md`](run.md) estimates the filtered scan at about 1 row,
  so the scan's share is small against what does not report before the end.
  Its `count(*)` alone stops at 66.67 the same way.
  Returning its rows, the scan took as long at four threads as at one (2.75 s and 2.77 s),
  while its `count(*)` took 0.68 s at four threads against 2.79 s at one:
  the scan that returns rows did not spread over the workers, and R's thread polled throughout, hence its 548,317 calls.
* **`GROUP BY`** (9,817,025 groups): the scan drives the bar evenly to 75.3 at 3.50 s,
  the largest rise follows, 78.38 to 92.79 at 3.65 s, and `Finish()` comes at 3.77 s.
* **`ORDER BY`** (10,000,000 rows): the scan drives 0 to 15.6 by 0.75 s.
  Then 1.11 s, from 0.82 to 1.92 s and nearly half of the query's 2.47 s, pass with no call while the sort finishes its runs;
  the bar reappears at 33.33, the sorted output takes it to 66.67, and `Finish()` follows at 2.35 s.
* **Join** (40,000,000 probe rows against 10,000,000 build rows, 399,630 out):
  0.47 s in all, 590 calls, reading 37.6 at 0.25 s and rising from 71.9 to just below 100 at the end.
* **Streamed**, the same calls arrive spread over the reads that run the engine.
  A result that fits the streaming buffer is computed by the first read, which gets every call;
  a larger one (the `GROUP BY`'s and the `ORDER BY`'s output) keeps reporting on the reads that refill the buffer.
  `Finish()` comes with the read that ends the query, which is the first read when the result fits the buffer.
  In [`finish.txt`](finish.txt), with chunks of 100,000 rows, that was read 22 of 26 for a `GROUP BY`,
  read 20 of 26 for an `ORDER BY`, and read 1 of 51 for a scan under a 1 GiB buffer.
  In [`run.md`](run.md), with chunks of 1,000,000 rows, the callback's 100 came with read 10 of the `GROUP BY` and of the `ORDER BY`,
  their last reads with rows; the `ORDER BY` reads from 65.5 to 100 in that read.
  Reads after it, and reads the buffer already holds, get no call.
  One `Finish()` came mid-stream, at read 9 of 51 of the four-thread 976 KiB scan in [`finish.txt`](finish.txt),
  under gdb, whose breakpoints change the timing;
  the [conclusions](#conclusions) give its cause.

## b. A remote part and a local part

The remote file holds 4,000,000 rows in row groups of 100,000, 68 MB, served at 2 MB/s per response.

* **The remote scan alone** (`count(*)` and `sum()` of one column):
  single-threaded it climbs in steps of about 10 every half second, row groups at a time, and finishes at 4.20 s.
  At four threads, where httpfs fetches several ranges at once, it stands at 15.1 from 0.56 s to at least 1.31 s,
  jumps through 47.7 and 55.2 to 87.8 and 97.5, and ends with `Finish()` at 2.35 s.
* **A heavy expression on the remote rows**, in the remote scan's own pipeline:
  the bar is the remote source's, 0 to 31.8 by 2.31 s single-threaded, one update at 66.67, then `Finish()` at 2.35 s.
* **The remote file as a join's build side, a local table of 40,000,000 rows as its probe side.**
  The remote columns alone take 6.72 s single-threaded and 3.00 s at four threads.
  In the join, single-threaded, the bar reads 6.9 at 6.90 s, after the remote part;
  the local probe takes it to 75.7 by 9.06 s, and `Finish()` follows at once.
  At four threads the remote part moves it in steps (1.0, 2.0, 3.3, 5.5, 6.0) up to 3.07 s,
  and the local part takes it through 16.2 and 52.7 to 100 by 3.72 s.
* **A remote aggregate followed by a local sort of its 2,754,617 groups:**
  single-threaded the bar reads 41.0 at 6.83 s, after the remote part, then 0.21 s pass with no call,
  and the sort and its output take it from 72.1 at 7.14 s to `Finish()` at 7.22 s.

The split follows the estimated rows of each part's sources, not their duration:
a slow network stretches its share of the bar in time without widening it,
and a local part with more rows than the remote one owns more of the bar than its seconds would suggest.

## c. The streaming buffer

A stream of a cheap scan, 5,000,000 rows read in chunks of 100,000, at four threads, 51 reads with the one that returns `NULL`:

* at 976 KiB 50 of the 51 reads run the engine, and `Finish()` comes with read 50,
  except in the four-thread run of [`finish.txt`](finish.txt) under gdb, whose breakpoints change the timing, where it came with read 9;
* at the default 10 MiB 14 of the 51 reads run the engine in [`run.md`](run.md) and 15 in [`finish.txt`](finish.txt),
  the others get no call, and `Finish()` comes with read 44 and read 47;
* at 1 GiB the first read computes the whole result in 0.12 s and gets every call, `Finish()` included, and the 50 reads after it get none.
