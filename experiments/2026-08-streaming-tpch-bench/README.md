# TPC-H fetch benchmark: materialized vs streaming transfer into R

How long it takes to move a TPC-H query result from the engine into R,
and what the move costs in memory, per fetch strategy.
Gathered for
[`plan/PLAN-streaming-thread.md`](/plan/PLAN-streaming-thread.md),
which reads the numbers as
"how much of the wall clock is conversion, and therefore how much a
producer thread could hide";
supports [`usage/memory/`](/handbook/usage/memory/README.md)
once its streaming entries land.

The harness is [`bench.R`](bench.R): one file, DBI + duckdb only.

* Data: the `tpch` extension (`CALL dbgen(sf = ...)`) when it can be
  installed, otherwise a deterministic synthetic `lineitem` with the
  same schema and column widths — the harness runs offline.
* Isolation: every scenario × query cell runs in a fresh R subprocess;
  peak RSS is `VmHWM` reset per cell (Linux),
  R allocation is the `gc()` max-used delta.
* Scenarios:
  `materialize` (`dbGetQuery()`),
  `materialize_chunked` (`dbSendQuery()` + `dbFetch(n)` loop),
  `stream_all` / `stream_chunked`
  (`dbSendQuery(stream = TRUE)`, [#2292](https://github.com/duckdb/duckdb-r/pull/2292) builds only),
  `arrow_drain` (`dbSendQueryArrow()` chunks, never converted —
  production cost as seen from R),
  `engine_only` (`CREATE TEMP TABLE AS`, no R conversion at all),
  `spill_then_stream` (temp table, then chunked stream from it).
  Unsupported cells are skipped and say so.
* Queries: `q1` (TPC-H Q1 — engine-bound control, 4-row result),
  `all` (`SELECT * FROM lineitem` — wide, mixed types, bare scan),
  `sorted` (the same behind an `ORDER BY` — engine and conversion
  balanced),
  `strings` (the VARCHAR columns — string-allocation bound).

Run it:

```sh
Rscript bench.R --sf=0.2 --reps=3 --out=results.csv
# against a specific build:
DUCKDB_LIB=/path/to/lib Rscript bench.R --sf=0.2
# knobs: --buffer=64MB (streaming_buffer_size), --memlimit=500MB,
#        --chunk=10000, --db=/path/to/reuse.duckdb,
#        --scenarios=..., --queries=...
```

## The runs

Run 2026-08-08 in an Ubuntu 24.04 container (x86_64, 4 cores),
R 4.5.3, `sf = 0.2` — 1,199,969 `lineitem` rows via the `tpch`
extension's `dbgen` — 3 reps, medians reported, default settings
unless said otherwise.
Two builds:

* `results-duckdb-1.5.5-cran-sf0.2.csv` —
  duckdb 1.5.5, the CRAN release current on the run date,
  installed as a Posit Package Manager binary;
  no `stream` support, so those cells are absent.
* `results-pr2292-b83a73c-sf0.2.csv` —
  [#2292](https://github.com/duckdb/duckdb-r/pull/2292)
  at `b83a73c`, built from source (1.5.5.9010).
* `results-pr2292-b83a73c-sf0.2-buffer64mb.csv` —
  the same build, stream scenarios only,
  with `SET streaming_buffer_size = '64MB'`
  instead of the ~1 MB default.

Numbers move ±10–15 % between reps on this shared container;
read them as shape, not as truth to two decimals.

## What the numbers say

* **Conversion dominates the wall clock for wide fetches.**
  On the PR build, producing `SELECT * FROM lineitem` into a temp
  table (`engine_only`) takes 0.23 s where `dbGetQuery()` takes
  2.21 s — the R conversion is ~90 % of the time;
  the string projection is the same story (0.18 s vs 2.00 s).
  The `ORDER BY` variant is the balanced case the plan needs:
  on the CRAN build the engine share is 48 % (1.26 s of 2.63 s),
  on the PR build's faster sort ~18 % (0.48 s of 2.60 s).
  This brackets what a producer thread can hide
  (its ceiling is the engine share) and says the complementary
  lever — cheaper conversion — matters at least as much.
* **Streaming delivers the memory win it was built for**
  ([#1997](https://github.com/duckdb/duckdb-r/issues/1997)):
  `stream_chunked` peaks at 106 MB RSS against `materialize`'s
  471 MB for the full-width query (91 vs 287 MB for strings),
  and is *faster* at the same time
  (1.36 s vs 2.21 s; 1.40 s vs 2.00 s) —
  discarding batches beats building one 480 MB data frame.
* **Full-fetch streaming costs nothing.**
  `stream_all` — same big data frame, streamed underneath —
  matches `materialize` within noise
  (2.03 vs 2.21 s on `all`; the sort pays ~12 %, 2.91 vs 2.60 s).
* **Small results are indifferent:** every `q1` cell lands at
  0.04–0.09 s on both builds; no strategy penalizes them.
* **Today's chunked API only pretends:**
  on both builds `materialize_chunked` holds the full-result peak
  (483 MB CRAN, 471 MB PR) *and* runs slower than `materialize`
  (3.07 vs 2.21 s CRAN) — the #1997 report, quantified.
* **The two-phase spill idiom is competitive:**
  `spill_then_stream` beats direct materialization on time
  (1.80 vs 2.21 s on `all`, 1.46 vs 2.00 s on strings)
  while keeping R at batch-sized memory —
  the engine-side copy is the price (311 MB peak, spillable
  under `memory_limit`, which R's copies never are).
* **`streaming_buffer_size` is a real but bounded knob:**
  64 MB instead of ~1 MB cuts the sorted stream from 2.28 to
  1.73 s (deeper production runs per fetch, more worker overlap)
  but adds its size to RSS (106 → 161 MB on `all`) and does
  nothing for scan-shaped queries — batching production better is
  not the same as overlapping it with conversion.
* **Caveat:** `arrow_drain` is not a pure production probe
  everywhere — on the CRAN build the sorted variant runs slower
  through the Arrow stream (3.78 s) than a full materialize
  (2.63 s); prefer `engine_only` as the production estimate.

Prior art: duckdblabs/db-benchmark
(Tom Ebergen's continuation of the h2oai benchmark)
compares solutions on group-by/join and is the reference for such
claims, but it does not isolate the R transfer boundary and its
multi-solution harness is heavy to run piecemeal;
DuckDB's in-tree `benchmark/tpch/` runner measures the engine without
ever crossing into R.
This harness sits between the two on purpose:
engine constant, boundary varied, one script.

To refresh: run the command above per build of interest and commit the
CSV named after the build.
