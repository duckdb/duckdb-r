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
duckdb 2.0.0.9000 built from source at 73ead8b of the `v2.0-cyanoptera` series, engine `v2.0.0`, httpfs from DuckDB's extension repository.
Each local query ran at `threads = 1` and at `threads = 4` on a table of 10,000,000 rows (and one of 2,500,000 for the join).

* [`run.R`](run.R), rendered by [`scripts/render-reprex.R`](/scripts/render-reprex.R) into [`run.md`](run.md):
  per run the row count, the wall time, the number of calls, and per R call a trace sampled every quarter second.
  Every call is in [`calls.csv`](calls.csv), consecutive calls with the same percentage in the same R call collapsed into one row with their count.
  [`throttle_server.py`](throttle_server.py) is the throttled server.
* [`finish.sh`](finish.sh) runs [`finish.R`](finish.R) under gdb with a breakpoint on `RProgressBarDisplay::Finish()`,
  and writes [`finish.txt`](finish.txt).

The session info names the scratch library that held the build as `<branch build library>`.

*What it supports:* [`usage/interactive/`](/handbook/usage/interactive/README.md).

## What every query is told

* **Every query opens with a 100.**
  The glue prepares each statement with `ClientContext::Prepare()`, which runs a `PREPARE` as a query of its own,
  and that query's display finishes before the statement runs ([`finish.txt`](finish.txt)).
  The query's own calls follow, from 0, and its own `Finish()` is the last call.
* **The calls come from the R thread, whenever it runs or polls an engine task**, whether or not the value moved.
  Single-threaded that was 12 to 35 calls a second (103 calls in a scan of 8.7 s, 155 in a join of 4.6 s);
  at four threads a query of under a second gets 5 to 40.
* **A materialized result is told everything inside the call that runs it.**
  `dbSendQuery()` runs the query to its end before it returns, so its `dbFetch(n = )` reads get no calls,
  and its trace is `dbGetQuery()`'s.

## a. Large local queries

The percentage is the pipelines' source progress, each pipeline weighted by its source's estimated row count,
so it moves with execution, not only with fetches, and its speed follows the weights rather than the clock.

* **Scan with a filter** (`hash(i::VARCHAR || 'salt') % 100 = 0`, 99,688 rows out):
  single-threaded it climbs evenly from 0 to 66.7% over 8.7 s, then jumps to 100 with `Finish()`.
  At four threads it reads 17.6, 47.9, then 100 in 0.9 s.
  The scan never fills more than two thirds of the sum: `EXPLAIN` estimates the filtered scan at about 2 rows,
  so the scan's share is small against what does not report before the end.
* **`GROUP BY`** (2,454,520 groups): single-threaded the scan drives 0 to 72.9% over 8.1 s,
  the next update reads 91.3, and the groups' output fills the rest by 10.3 s.
* **`ORDER BY`** (2,500,000 rows): single-threaded the scan drives 0 to 19.9% over 2.9 s, about 70% of the query's time.
  Then 0.30 s pass with no call while the sort finishes its runs, the bar reappears at 40.0,
  and the sorted output moves it to 80.0 before `Finish()`.
* **Join** (10,000,000 probe rows against 2,500,000 build rows, 100,812 out):
  single-threaded it climbs from 0 to 34% while the build side is scanned and then faster to 77% on the probe side,
  then a last update just below 100 and `Finish()`, 4.6 s in all.
  At four threads the join takes 0.2 s and gets 6 calls.
* **Streamed**, the same calls arrive spread over the reads that run the engine.
  A result that fits the streaming buffer is computed by the first read, which gets every call;
  a larger one (the `GROUP BY`'s and the `ORDER BY`'s output) keeps reporting on the reads that refill the buffer.
  `Finish()` comes with the read that ends the query, never with the first chunk:
  read 3 of the `GROUP BY`, read 2 of the `ORDER BY`, read 50 of the 976 KiB stream in [`finish.txt`](finish.txt).
  Reads after it, and reads the buffer already holds, get no call.

## b. A remote part and a local part

The remote file holds 4,000,000 rows in row groups of 100,000, 68 MB, served at 2 MB/s per response.

* **The remote scan alone** (`count(*)` and `sum()` of one column):
  single-threaded it climbs evenly to 100 over 4.9 s, row group by row group.
  At four threads, where httpfs fetches several ranges at once, it sits at 15.1% for 0.9 s, jumps to 55 and then 75.3,
  sits there for another 0.9 s, and ends with `Finish()` at 3.1 s.
* **A heavy expression on the remote rows**, in the remote scan's own pipeline:
  the bar is the remote source's, 0 to 33.3% evenly in 3.3 s single-threaded, then `Finish()`.
* **The remote file as a join's build side, a local table of 10,000,000 rows as its probe side.**
  The remote columns alone take 7.4 s single-threaded.
  In the join, those first 7.4 s move the bar from 0 to about 16%;
  the local probe moves it from 16 to 57% over the next 8.1 s, then one update reads 99.99 and `Finish()` follows, 15.7 s in all.
  At four threads the remote part moves it in steps (2.9, 8.6, 16) over 3 s, and the local part takes it to 57 and 100 in 0.4 s.
* **A remote aggregate followed by a local sort of its 2,754,617 groups:**
  single-threaded the remote part drives 0 to 42% over 7.2 s, the sort and its output take the rest in 2.3 s.

The split follows the estimated rows of each part's sources, not their duration:
a slow network stretches its share of the bar in time without widening it,
and a local part with more rows than the remote one owns more of the bar than its seconds would suggest.

## c. The streaming buffer

A stream of a cheap scan, 5,000,000 rows read in chunks of 100,000, at four threads:

* at 976 KiB every one of the 50 reads runs the engine and gets about 3 calls, and `Finish()` comes with read 50;
* at the default 10 MiB one read in three or four runs the engine, the others get no call, and `Finish()` comes with read 47;
* at 1 GiB the first read computes the whole result in 0.2 s and gets every call, `Finish()` included, and the 50 reads after it get none.
