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
