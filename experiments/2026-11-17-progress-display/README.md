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
since both pass it 100.
Asked on [#3012](https://github.com/duckdb/duckdb-r/pull/3012), after [#2967](https://github.com/duckdb/duckdb-r/issues/2967).

*When and on what:* 2026-11-17, Linux x86_64 on an Intel Xeon at 2.10 GHz with 4 cores, R 4.5.3, nanoarrow 0.9.0,
duckdb 2.0.0.9000 built from source at 73ead8b of the `v2.0-cyanoptera` series, engine `v2.0.0`,
httpfs `77392a7207` from DuckDB's extension repository.
Each local query ran at `threads = 1` and at `threads = 4` on a table of 10,000,000 rows (and one of 2,500,000 for the join),
both built single-threaded under a fixed seed.

* [`run.R`](run.R), rendered by [`scripts/render-reprex.R`](/scripts/render-reprex.R) into [`run.md`](run.md):
  per run the row count, the wall time, the number of calls, and per R call a trace sampled every quarter second.
  It also writes every call to a CSV file, which is not kept here; its header says where it goes.
  [`throttle_server.py`](throttle_server.py) is the throttled server.
* [`finish.sh`](finish.sh) runs [`finish.R`](finish.R) under gdb with a breakpoint on `RProgressBarDisplay::Finish()`,
  and writes [`finish.txt`](finish.txt): per scenario, the reads that got any call and the phase every `Finish()` came in.
  Its streams read chunks of 100,000 rows, and gdb's breakpoint makes their calls more frequent than in `run.md`.

The session info names the scratch library that held the build as `<branch build library>`.

*What it supports:* [`usage/interactive/`](/handbook/usage/interactive/README.md).

## What every query is told

* **A statement through `dbGetQuery()`, `dbExecute()` or `dbGetQueryArrow()` opens with a 100.**
  The glue prepares the last statement of the string with `ClientContext::Prepare()`, which runs a `PREPARE` as a query of its own,
  and that query's display finishes before the statement runs ([`finish.txt`](finish.txt)).
  The statement's own calls follow, from 0, and its own `Finish()` is its last call.
  The statements before the last in a multi-statement string run through `Connection::Query()` without a `PREPARE`,
  each with its own display and `Finish()`:
  `SELECT 1; SELECT count(*) ...; SELECT 2` passes four 100s from `Finish()`.
* **The calls come from the R thread, whenever it runs or polls an engine task**, whether or not the value moved.
  Single-threaded that was 10 to 35 calls a second (103 calls in the 10.2 s `dbGetQuery()` scan, 155 in the 4.6 s join);
  at four threads a query of under a second gets 6 to 39.
* **A materialized result is told everything inside the call that runs it.**
  `dbSendQuery()` runs the query to its end before it returns, so its `dbFetch(n = )` reads get no calls,
  and its trace is `dbGetQuery()`'s.

## a. Large local queries

The percentage is the pipelines' source progress, each pipeline weighted by its source's estimated row count,
so it moves with execution, not only with fetches, and its speed follows the weights rather than the clock.
Single-threaded, through `dbGetQuery()`:

* **Scan with a filter** (`hash(i::VARCHAR || 'salt') % 100 = 0`, 99,688 rows out):
  climbs evenly from 0 to 66.7% over 10.1 s, then jumps to 100 with `Finish()`.
  At four threads it reads 15.2, 41.4, 64.9, then 100 in 0.95 s.
  The scan never fills more than two thirds of the sum: `EXPLAIN` in [`run.md`](run.md) estimates the filtered scan at about 2 rows,
  so the scan's share is small against what does not report before the end.
* **`GROUP BY`** (2,454,520 groups): the scan drives 0 to 73.9% over 9.0 s,
  the next update reads 91.3, and the groups' output fills the rest by 11.1 s.
* **`ORDER BY`** (2,500,000 rows): the scan drives 0 to 19.9% over 3.2 s, about 70% of the query's time.
  Then 0.28 s pass with no call while the sort finishes its runs, the bar reappears at 40.0,
  and the sorted output moves it to 80.0 before `Finish()` at 4.3 s.
* **Join** (10,000,000 probe rows against 2,500,000 build rows, 99,800 out):
  climbs from 0 to 34% in 2.9 s while the build side is scanned and then faster to 77% on the probe side,
  then an update just below 100 and `Finish()`, 4.6 s in all.
  At four threads the join takes 0.2 s and gets 7 calls.
* **Streamed**, the same calls arrive spread over the reads that run the engine.
  A result that fits the streaming buffer is computed by the first read, which gets every call;
  a larger one (the `GROUP BY`'s and the `ORDER BY`'s output) keeps reporting on the reads that refill the buffer.
  `Finish()` comes with the read that ends the query, which is the first read when the result fits the buffer.
  In [`finish.txt`](finish.txt), with chunks of 100,000 rows, that was read 22 of 26 for the `GROUP BY`,
  read 20 of 26 for the `ORDER BY`, and read 1 of 51 for a scan under a 1 GiB buffer.
  In [`run.md`](run.md), with chunks of 1,000,000 rows, the callback's 100 came with read 3 of the `GROUP BY` and read 2 of the `ORDER BY`.
  Reads after it, and reads the buffer already holds, get no call.
  No `Finish()` arrived mid-stream in any run,
  although the poll before a fetch (`src/arrow_export.cpp`) could in principle see a ready chunk and finish the display early.

## b. A remote part and a local part

The remote file holds 4,000,000 rows in row groups of 100,000, 68 MB, served at 2 MB/s per response.

* **The remote scan alone** (`count(*)` and `sum()` of one column):
  single-threaded it climbs evenly to 97.8% over 4.8 s, row group by row group, and finishes at 5.0 s.
  At four threads, where httpfs fetches several ranges at once, it stands at 12.5% for about 0.6 s, jumps to 52.7 and 80.3,
  stands at 92.5 for about 0.5 s, and ends with `Finish()` at 3.1 s.
* **A heavy expression on the remote rows**, in the remote scan's own pipeline:
  the bar is the remote source's, 0 to 32.6% evenly in 3.2 s single-threaded, one update at 66.7, then `Finish()` at 3.5 s.
* **The remote file as a join's build side, a local table of 10,000,000 rows as its probe side.**
  The remote columns alone take 7.4 s single-threaded and 3.1 s at four threads.
  In the join, single-threaded, the first 7.4 s move the bar from 0 to about 16%;
  the local probe moves it from 16 to 57% over the next 8.3 s, then `Finish()` at 15.9 s.
  At four threads the remote part moves it in steps (3.3, 9.4, 9.8, 16.0) over 2.6 s,
  and the local part takes it to 54 and 100 in 0.35 s.
* **A remote aggregate followed by a local sort of its 2,754,617 groups:**
  single-threaded the remote part drives 0 to 44% over 7.4 s, and the sort and its output take the rest in 2.4 s.

The split follows the estimated rows of each part's sources, not their duration:
a slow network stretches its share of the bar in time without widening it,
and a local part with more rows than the remote one owns more of the bar than its seconds would suggest.

## c. The streaming buffer

A stream of a cheap scan, 5,000,000 rows read in chunks of 100,000, at four threads:

* at 976 KiB every one of the 50 reads runs the engine and gets about 3 calls, and `Finish()` comes with read 50;
* at the default 10 MiB 15 of the 50 reads run the engine, the others get no call, and `Finish()` comes with read 47;
* at 1 GiB the first read computes the whole result in 0.2 s and gets every call, `Finish()` included, and the 50 reads after it get none.

The reads with calls are counted in [`finish.txt`](finish.txt), the `Finish()` reads are in both it and [`run.md`](run.md).
