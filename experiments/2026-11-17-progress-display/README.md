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
Each local query ran at `threads = 1` and at `threads = 4` on a table of 40,000,000 rows (and one of 10,000,000 for the join);
the tables and the remote file are built single-threaded under a fixed seed.

* [`run.R`](run.R), rendered by [`scripts/render-reprex.R`](/scripts/render-reprex.R) into [`run.md`](run.md):
  per run the row count, the wall time, the number of calls, and per R call a trace sampled every quarter second.
  It also writes every call to a CSV file, which is not kept here; its header says where it goes.
  [`throttle_server.py`](throttle_server.py) is the throttled server.
* [`finish.sh`](finish.sh) runs [`finish.R`](finish.R) under gdb with a breakpoint on `RProgressBarDisplay::Finish()`, then once without gdb,
  and writes [`finish.txt`](finish.txt): per scenario, the calls, the reads that got any, and under gdb the phase every `Finish()` came in.
  Its streams read chunks of 100,000 rows of a table of 10,000,000.

The session info names the scratch library that held the build as `<branch build library>`.

*What it supports:* [`usage/interactive/`](/handbook/usage/interactive/README.md).

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
  395 in the 2.7 s scan, 493 in the 4.2 s `GROUP BY`.
  With four threads, R's thread polls in a loop while the workers run, and each poll calls the callback:
  535,180 calls in the 2.7 s scan, though as few as a few hundred in runs where R's thread ran tasks itself.
* **What the callback costs sets how many calls it gets.**
  An earlier rendering of this record used a callback that copied its four-million-element vectors on every call, 33 ms a call:
  its single-threaded queries ran ten times longer, and its 1 GiB stream got 7 calls where `finish.R`'s cheap callback gets thousands,
  with and without gdb ([`finish.txt`](finish.txt)).
  The callback in [`run.R`](run.R) now keeps its vectors in its own closure, which costs microseconds.
* **A materialized result is told everything inside the call that runs it.**
  `dbSendQuery()` runs the query to its end before it returns, so its `dbFetch(n = )` reads get no calls,
  and its trace is `dbGetQuery()`'s.

## a. Large local queries

The percentage is the pipelines' source progress, each pipeline weighted by its source's estimated row count,
so it moves with execution, not only with fetches, and its speed follows the weights rather than the clock.
Single-threaded, through `dbGetQuery()`:

* **Scan with a filter** (`hash(i::VARCHAR || 'salt') % 100 = 0`, 398,634 rows out):
  climbs evenly from 0 to 50.0% over 2.7 s, then jumps to 100 with `Finish()`; at four threads the same, in 2.7 s too.
  The scan never fills more than half of the sum: `EXPLAIN` in [`run.md`](run.md) estimates the filtered scan at about 1 row,
  so the scan's share is small against what does not report before the end.
* **`GROUP BY`** (9,817,025 groups): the scan drives 0 to 78.4% over 3.7 s,
  the next update reads 92.8, and the groups' output fills the rest, `Finish()` at 3.9 s.
* **`ORDER BY`** (10,000,000 rows): the scan drives 0 to 16.7% over 0.8 s.
  Then 1.02 s, 44% of the query's time, pass with no call while the sort finishes its runs;
  the bar reappears at 33.3, and the sorted output moves it on until `Finish()` at 2.2 s.
* **Join** (40,000,000 probe rows against 10,000,000 build rows, 399,630 out):
  0.5 s in all, climbing through 33.8 and 66.9 to 71.9% before `Finish()`.
* **Streamed**, the same calls arrive spread over the reads that run the engine.
  A result that fits the streaming buffer is computed by the first read, which gets every call;
  a larger one (the `GROUP BY`'s and the `ORDER BY`'s output) keeps reporting on the reads that refill the buffer.
  `Finish()` comes with the read that ends the query, which is the first read when the result fits the buffer.
  In [`finish.txt`](finish.txt), with chunks of 100,000 rows, that was read 22 of 26 for a `GROUP BY`,
  read 20 of 26 for an `ORDER BY`, and read 1 of 51 for a scan under a 1 GiB buffer.
  In [`run.md`](run.md), with chunks of 1,000,000 rows, the callback's 100 came with read 10 of the `GROUP BY` and of the `ORDER BY`,
  their last reads with rows.
  Reads after it, and reads the buffer already holds, get no call.
  No `Finish()` arrived mid-stream in any run.

## b. A remote part and a local part

The remote file holds 4,000,000 rows in row groups of 100,000, 68 MB, served at 2 MB/s per response.

* **The remote scan alone** (`count(*)` and `sum()` of one column):
  single-threaded it climbs in steps of 10% about every half second to 98.0%, row groups at a time, and finishes at 4.2 s.
  At four threads, where httpfs fetches several ranges at once, it stands at 17.6% for at least 0.75 s, jumps through 50.2 and 57.7 to 87.8,
  stands at 97.5 for about 0.5 s, and ends with `Finish()` at 3.0 s.
* **A heavy expression on the remote rows**, in the remote scan's own pipeline:
  the bar is the remote source's, 0 to 30.9% in 2.3 s single-threaded, one update at 66.7, then `Finish()` at 2.4 s.
* **The remote file as a join's build side, a local table of 40,000,000 rows as its probe side.**
  The remote columns alone take 6.7 s single-threaded and 3.1 s at four threads.
  In the join, single-threaded, the first 6.9 s move the bar from 0 to 6.9%;
  the local probe moves it from 6.9 to 75.8% in the next 1.9 s, then `Finish()` at 8.9 s.
  At four threads the remote part moves it in steps (1.0, 3.8, 6.6, 6.7) over 3.1 s,
  and the local part takes it through 23.1 and 64.9 to 100 in 0.5 s.
* **A remote aggregate followed by a local sort of its 2,754,617 groups:**
  single-threaded the remote part drives 0 to 44.2% over 6.9 s, and the sort and its output take the rest in 0.5 s.

The split follows the estimated rows of each part's sources, not their duration:
a slow network stretches its share of the bar in time without widening it,
and a local part with more rows than the remote one owns more of the bar than its seconds would suggest.

## c. The streaming buffer

A stream of a cheap scan, 5,000,000 rows read in chunks of 100,000, at four threads, 51 reads with the one that returns `NULL`:

* at 976 KiB 50 of the 51 reads run the engine, and `Finish()` comes with read 50;
* at the default 10 MiB 14 of the 51 reads run the engine in [`run.md`](run.md) and 15 in [`finish.txt`](finish.txt),
  the others get no call, and `Finish()` comes with read 44 and read 47;
* at 1 GiB the first read computes the whole result in 0.14 s and gets every call, `Finish()` included, and the 50 reads after it get none.
