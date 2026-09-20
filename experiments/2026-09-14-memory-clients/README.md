# Result memory across DuckDB clients, and the R findings re-run in containers

*What it measures:* the peak resident memory of one process fetching
the same 800 MB result — fifty million rows of two `DOUBLE` columns —
through each route a client offers,
materialized or streamed, discarded or converted,
and once more sorted under a 200 MB `memory_limit`;
plus the findings the memory leaves rest on,
each re-run in a fresh container on the dev build and on the CRAN
release.

*When and on what:* 2026-09-14, in Docker on Linux x86_64
(4 cores, 15.7 GiB visible to each container),
one container per run, images as pulled that day:

* `ghcr.io/cynkra/docker-images/rig-ubuntu-duckdb-dev` — Ubuntu 22.04,
  R 4.6.1, duckdb 1.5.5.9022 (`main` of the day; this branch changes
  no code, so it stands for the branch as well) — the *dev* image;
* `ghcr.io/cynkra/docker-images/p3m-noble-duckdb` — Ubuntu 24.04,
  R 4.6.1, duckdb 1.5.5 from CRAN — the *CRAN* image;
* `python:3.12-slim` — Python 3.12.14, duckdb 1.5.5, pyarrow 25.0.1,
  pandas 3.0.5;
* `node:22-slim` — `@duckdb/node-api` 1.5.5-r.5, engine 1.5.5;
* `golang:1.25` — Go 1.25.14, go-duckdb v2.4.3, whose bundled engine
  is 1.4.1, one release behind the others;
* `rust:slim` — the `duckdb` crate 1.10505.0, engine 1.5.5, compiled
  from the bundled sources.

Julia is absent: its package registry hosts were refused by the
network policy of the session that ran this,
and the script written for it ([`julia/clients.jl`](julia/clients.jl))
has therefore never run.

*What it supports:*
[`usage/memory/reading/`](/handbook/usage/memory/reading/README.md),
[`usage/memory/writing/`](/handbook/usage/memory/writing/README.md)
and [`usage/memory/budget/`](/handbook/usage/memory/budget/README.md).

## Method

Every process reads its own `VmHWM` from `/proc/self/status` at the end,
so a peak is the whole process — engine, client library and language
runtime together, of which the runtime and an idle engine are roughly
100 MB in every client here — and prints one CSV line:
`lang,image,scenario,rows,peak_mb,seconds`.
[`run.sh`](run.sh) runs one scenario per container
(`./run.sh run <lang> <image-label> <scenario...>`) after
`./run.sh prepare <lang>` has installed that language's client into a
cache directory beside the repository;
it honours `HTTPS_PROXY` and mounts `CA_BUNDLE` for every tool when set.
The per-language scripts are [`r/clients.R`](r/clients.R),
[`python/clients.py`](python/clients.py), [`go/main.go`](go/main.go),
[`rust/src/main.rs`](rust/src/main.rs) and
[`node/clients.mjs`](node/clients.mjs);
[`r/findings.R`](r/findings.R) holds the R findings, one per process,
printing `image,finding,metric,value` lines.
The recorded runs are [`results/clients.csv`](results/clients.csv),
[`results/findings-dev.csv`](results/findings-dev.csv),
[`results/findings-cran.csv`](results/findings-cran.csv) and
[`results/versions.csv`](results/versions.csv).

Two container details matter for reading the numbers:
a process starts with the working directory `/tmp`, because an
in-memory database's default spill directory is `.tmp` under the
working directory in every client but R, and a read-only one turns the
first spill into an error; and nothing but the R package sets a spill
directory of its own.

## The R findings, on both builds

Each metric is the dev image's value, then the CRAN image's where it
differs; a peak is in MB over the process's own baseline unless it says
otherwise.

* **Execution is eager.** After `dbSendQuery()` returns, the result
  object already holds all 100,000 rows of a 100,000-row query;
  `dbFetch(n = 5)` then returns five of them.
* **The default route holds two copies.** `dbGetQuery()` of the
  800 MB result peaks 1,542 (1,545) MB over baseline: the engine's
  collection and the R vectors together.
* **Chunking the default route changes nothing.** `dbSendQuery()` with
  a `dbFetch(n = 1e6)` loop peaks at 1,655 MB, exactly the whole
  `dbGetQuery()`'s 1,655 (1,645 and 1,645 on CRAN).
* **The legacy arrow route is the widest.** `dbSendQuery(arrow = TRUE)`
  with `duckdb_fetch_arrow()` peaks at 1,741 MB on both.
* **The engine's ledger does not see a held result.** With a
  materialized result of a 5,000,000-row table held,
  `duckdb_memory()` lists the table alone, 107 MB, on both.
* **A relation materializes on touch and holds the result twice.**
  For a 76 MB relation: 3 (7) MB after `rel_to_altrep()`,
  158 (162) MB after touching both columns,
  273 (277) MB after copying the columns out as plain vectors,
  168 (172) MB after dropping the ALTREP frame and collecting.
* **An ADBC batch is one engine chunk, and a second statement
  materializes an open stream.** The first batch holds 2,048 rows;
  running `SELECT 1` on the connection while a 480 MB stream was open
  raised RSS by 495 (497) MB, and the stream then read all
  30,000,000 rows.
* **A drain loop is bounded only when batches are released.**
  Draining the 800 MB result in 100,000-row batches under a 200 MB
  limit peaked at 828 (555) MB when batches were merely dropped,
  145 (142) MB with `nanoarrow_pointer_release()` on each,
  224 (206) MB with a `gc()` every 5,000,000 rows;
  the stream opened at 123 (102) MB in every case.
* **The Arrow stream carries a sort larger than the limit — on the
  dev build.** The sorted 800 MB result under a 200 MB limit opened
  at 354 MB and drained at 369 MB on the dev image;
  on the CRAN image the sort failed at its first spill with
  `IO Error: Failed to create directory ".../duckdb/temp"`,
  the 1.5.5 spill-directory regression
  ([#2562](https://github.com/duckdb/duckdb-r/pull/2562) fixed it on
  `main`), while ADBC on the same CRAN build streamed the same sort at
  363 MB, its spill directory being the engine's own default.
* **A write is bounded by the limit, and a transaction holds nothing
  extra.** Writing a 480 MB frame under a 200 MB limit:
  into an in-memory database the table sat at 200 MB in the pool with
  384 MB offloaded and the process peaked 204 MB over baseline;
  into a file database it was written through, 186 MB retained,
  a 402 MB file, a 203 MB peak.
  Inside `dbBegin()`, the ledger's `TRANSACTION` tag stayed at 0 MB,
  391 MB was offloaded (in-memory) or the data written through (file),
  `dbCommit()` succeeded, and the peaks were 203 and 208 MB.
  On the CRAN image the in-memory write failed on the same spill
  regression — and, inside a transaction, aborted that transaction —
  while the file database wrote through as on the dev image.
* **`dbConnect(config = )` does not reach a running instance.**
  `memory_limit = "200MB"` reads back as 190.7 MiB when passed to
  `duckdb(config = )` or to `dbConnect()` together with a new `dbdir`,
  and as the 12.5 GiB default when passed to `dbConnect()` on the
  driver's own `dbdir`, `:memory:` or a file alike — on both builds.
* **The record-batch reader does not leak.** Eight cycles of fetch,
  read and drop of a 160 MB result left RSS over baseline at
  11, 126, 114, 114, −14, 115, 103, 172 MB on the dev image and
  33, 34, 136, 125, 7, 8, 7, 140 MB on CRAN: allocator retention
  wandering, not 160 MB per cycle.
* **The default limit is 80% of what the engine sees.**
  12.5 GiB in a container that shows 15.7 GiB.

## The same result through every client

Peak resident memory in MB for the 800 MB result, whole process;
the last column is the peak over the data's own size.
Rows that stream are marked ▸.

| client (engine) | route | peak MB | × data |
|---|---|---|---|
| R dev 1.5.5.9022 | `dbGetQuery()` | 1,655 | 2.1 |
| R dev | `dbSendQuery()` + `dbFetch(n = 1e6)` loop | 1,655 | 2.1 |
| R dev | `dbSendQuery(arrow = TRUE)` + `duckdb_fetch_arrow()` | 1,741 | 2.2 |
| R dev | ▸ `dbSendQueryArrow()` + `dbFetchArrowChunk()`, batches dropped | 916 | 1.1 |
| R dev | ▸ the same, each batch released | 159 | 0.2 |
| R dev | ▸ the same, each batch converted with `as.data.frame()` | 228 | 0.3 |
| R dev | ▸ the same, sorted, under a 200 MB limit | 376 | 0.5 |
| R dev | ▸ ADBC stream, batches released | 150 | 0.2 |
| R dev | ▸ ADBC stream, sorted, under a 200 MB limit | 366 | 0.5 |
| R CRAN 1.5.5 | `dbGetQuery()` | 1,645 | 2.1 |
| R CRAN | `dbSendQuery()` + `dbFetch(n = 1e6)` loop | 1,645 | 2.1 |
| R CRAN | `dbSendQuery(arrow = TRUE)` + `duckdb_fetch_arrow()` | 1,741 | 2.2 |
| R CRAN | ▸ Arrow stream, batches dropped | 897 | 1.1 |
| R CRAN | ▸ Arrow stream, each batch released | 140 | 0.2 |
| R CRAN | ▸ Arrow stream, each batch converted | 194 | 0.2 |
| R CRAN | ▸ Arrow stream, sorted, under a 200 MB limit | *spill error* | — |
| R CRAN | ▸ ADBC stream, batches released | 146 | 0.2 |
| R CRAN | ▸ ADBC stream, sorted, under a 200 MB limit | 363 | 0.5 |
| Python 1.5.5 | `.df()` (pandas) | 1,807 | 2.3 |
| Python | `.fetch_arrow_table()` | 900 | 1.1 |
| Python | `.fetchnumpy()` | 1,229 | 1.5 |
| Python | ▸ `.fetchmany(1e6)` loop | 321 | 0.4 |
| Python | ▸ `.fetch_record_batch(1e6)` reader | 196 | 0.2 |
| Python | ▸ `.fetch_df_chunk()` loop | 281 | 0.4 |
| Python | ▸ record-batch reader, sorted, under a 200 MB limit | 362 | 0.5 |
| Node 1.5.5 | `runAndReadAll()` + `getColumns()` | 3,681 | 4.6 |
| Node | `runAndReadAll()`, chunks kept, no conversion | 1,867 | 2.3 |
| Node | `run()` + `fetchChunk()` loop | 1,329 | 1.7 |
| Node | ▸ `stream()` + `fetchChunk()` loop | 400 | 0.5 |
| Node | ▸ `stream()`, sorted, under a 200 MB limit | 412 | 0.5 |
| Go 1.4.1 | `database/sql` rows into slices | 3,223 | 4.0 |
| Go | `database/sql` rows, discarded | 821 | 1.0 |
| Go | the same, sorted, under a 200 MB limit | 1,070 | 1.3 |
| Rust 1.5.5 | `query_arrow()` collected | 1,646 | 2.1 |
| Rust | `query_map()` collected into a `Vec` | 1,569 | 2.0 |
| Rust | `query_arrow()` iterated, discarded | 805 | 1.0 |
| Rust | `query()` rows iterated, discarded | 805 | 1.0 |
| Rust | `query_arrow()`, sorted, under a 200 MB limit | 1,135 | 1.4 |

## What the numbers say

* **Two copies is the materialized norm, not an R peculiarity.**
  R's `dbGetQuery()`, pandas' `.df()` and Rust's collected results
  all peak at twice the data and a little more:
  the engine's copy and the language's copy coexist during
  conversion everywhere.
  Go's slices and Node's JavaScript arrays cost four times the data,
  their containers growing by doubling or boxing every value.
* **What is peculiar to this package is a chunked API that buys
  nothing.** `dbFetch(n = )` over `dbSendQuery()` peaks exactly like
  the whole fetch, where Python's `fetchmany()` loop stays at 321 MB:
  the #1997 report, once more.
* **Streaming is the default in Python and on request in Node;
  Go and Rust hold the engine copy.**
  A discard loop costs 196 to 400 MB where the client streams
  (Python, Node's `stream()`, R's Arrow stream and ADBC once batches
  are released), and the full data where it does not
  (Go's rows and Rust's iterators at 805 to 821 MB,
  Node's `run()` at 1,329 MB).
  R's released Arrow stream and ADBC, at 140 to 159 MB, are the lowest
  peaks measured in any client.
* **The held copy is untracked in every client.**
  Under a 200 MB limit, a sorted result streams at 362 to 412 MB
  in Python, Node and R, and costs 1,070 to 1,135 MB in Go and Rust:
  the limit governed the sort, and the result collection it then held
  escaped it — the engine's own default for a materialized result,
  which every client inherits.
* **Releasing batches is what makes an R drain loop bounded.**
  Batches merely dropped left the loop at 897 to 916 MB, the whole
  result waiting for a collector that never saw it;
  released batches held it at 140 to 159 MB.
  Node's `stream()` shows the same collector effect more mildly,
  at 400 MB.
* **The 1.5.5 release cannot spill an in-memory database through the
  R package.** Its sorted stream and its in-memory write under a limit
  both fail at the first spill; the dev build handles both, and so does
  ADBC on the release itself.

To refresh: pull the images, run `./run.sh prepare <lang>` for each
language (the Rust one compiles the engine, in the order of an hour),
then `./run.sh run <lang> <image-label> <scenario...>` per scenario as
listed in the scripts, and replace the CSVs.

## At the worker's RAM

The same fetch shapes with fifteen times the result:
750 million rows, 12 GB, on the 15.7 GiB worker —
three quarters of its memory, so a route that holds the result twice
cannot complete.
One container at a time, each capped by a cgroup at 14.5 GB with no
swap, so a run that outgrows the cap is killed inside its container
(recorded as *OOM*, with the seconds it took to die) rather than by the
host;
`run.sh` takes the size as `ROWS` and the cap as `MEMORY`,
Node's heap ceiling raised to 14 GB for the occasion.
The dev build only, since the CRAN build read the same at 800 MB;
the sorted-under-a-limit variants left out,
because the engine would have to spill the 12 GB and the session's
disk allowance is 15 GB.
Recorded in
[`results/clients-near-ram.csv`](results/clients-near-ram.csv),
same columns.

| client (engine) | route | peak MB | s |
|---|---|---|---|
| R dev 1.5.5.9023 | `dbGetQuery()` | *OOM* | 69 |
| R dev | `dbSendQuery()` + `dbFetch(n = 1e6)` loop | *OOM* | 50 |
| R dev | `dbSendQuery(arrow = TRUE)` + `duckdb_fetch_arrow()` | *OOM* | 48 |
| R dev | ▸ `dbSendQueryArrow()` + `dbFetchArrowChunk()`, batches dropped | 8,031 | 34 |
| R dev | ▸ the same, each batch released | 166 | 11 |
| R dev | ▸ the same, each batch converted with `as.data.frame()` | 229 | 21 |
| R dev | ▸ ADBC stream, batches released | 154 | 70 |
| Python 1.5.5 | `.df()` (pandas) | *OOM* | 70 |
| Python | `.fetch_arrow_table()` | 11,743 | 45 |
| Python | `.fetchnumpy()` | *OOM* | 38 |
| Python | ▸ `.fetchmany(1e6)` loop | 320 | 227 |
| Python | ▸ `.fetch_record_batch(1e6)` reader | 255 | 14 |
| Python | ▸ `.fetch_df_chunk()` loop | 292 | 17 |
| Node 1.5.5 | `runAndReadAll()` + `getColumns()` | *OOM* | 8,559 |
| Node | `runAndReadAll()`, chunks kept, no conversion | *OOM* | 59 |
| Node | `run()` + `fetchChunk()` loop | 12,114 | 60 |
| Node | ▸ `stream()` + `fetchChunk()` loop | 444 | 42 |
| Go 1.5.5 | `database/sql` rows into slices | *OOM* | 85 |
| Go | `database/sql` rows, discarded | 11,746 | 162 |
| Rust 1.5.5 | `query_arrow()` collected | *OOM* | 43 |
| Rust | `query_map()` collected into a `Vec` | *OOM* | 51 |
| Rust | `query_arrow()` iterated, discarded | 11,726 | 28 |
| Rust | `query()` rows iterated, discarded | 11,727 | 41 |

* **What held the result twice is killed, in every client.**
  `dbGetQuery()`, the `dbFetch(n = )` loop and the legacy arrow route
  in R; pandas and NumPy in Python; Node's arrays and its kept chunks;
  Go's slices; Rust's collected table and `Vec`.
  The 2× of the small run is not a cost at this size but a wall.
* **What streams carries 12 GB through a few hundred megabytes,
  and the number is the small run's.**
  R's released Arrow stream at 166 (159 at 800 MB), the converted one
  at 229 (228), ADBC at 154 (150);
  Python's three streaming forms at 255–320 (196–321);
  Node's `stream()` at 444 (400).
  The peak of a streaming route is a property of the batch,
  not of the result.
* **A held engine copy survives only because one copy still fits.**
  Go's and Rust's iterators and Node's `run()` read 11.7–12.1 GB —
  the engine's materialized result, walked once —
  and Python's Arrow table 11.7 GB;
  a result with less room than its own size would end where the
  collected forms did.
  These are the routes the small run marked as holding one copy,
  and at this size one copy is the whole machine.
* **Dropping batches is not releasing them.**
  The stream whose batches are merely dropped climbs to 8 GB before
  R's collector happens to run, in a 34-second run —
  the collector sees none of Arrow's memory and chose its moment on
  R-heap pressure alone.
  Released as consumed, the same stream peaks at 166.
* **Node's failure is slow.**
  `getColumns()` over 750 million rows did not die in a minute like
  the others but after two hours and twenty-three minutes of the
  collector thrashing under its 14 GB heap ceiling —
  what a user would see as a hang.
* **Batch size buys time, not memory.**
  ADBC's 2048-row batches take 70 seconds where the 1e6-row Arrow
  chunks take 11, at the same peak;
  Python's `fetchmany()` takes 227 seconds building a tuple per row.
