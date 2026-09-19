# Bringing data into DuckDB: what each route costs, across clients

*What it measures:* the peak resident memory of one process bringing
the same 800 MB dataset — fifty million rows of two `DOUBLE` columns —
into a DuckDB table through every route a client offers:
a frame the process already holds, handed over by the client's own call
or through Arrow;
data produced piece by piece and never held whole — chunked appends,
appenders fed row by row or chunk by chunk, a generator behind an Arrow
reader or a table function;
a second process feeding a pipe, as CSV or as an Arrow IPC stream;
a Parquet round-trip through a file;
and, as the floor, the engine generating the rows itself
or reading them from a file it wrote earlier.

*When and on what:* 2026-09-19, in Docker on Linux x86_64
(4 cores, 15.7 GiB visible to each container),
one container per run, images as pulled that day:
`ghcr.io/cynkra/docker-images/rig-ubuntu-duckdb-dev` (Ubuntu 22.04,
R 4.6.1, duckdb 1.5.5.9023 — the *dev* image), 
`ghcr.io/cynkra/docker-images/p3m-noble-duckdb` (Ubuntu 24.04, R 4.6.1,
duckdb 1.5.5 from CRAN — the *CRAN* image),
`python:3.12-slim` (duckdb 1.5.5, pyarrow 25.0.1, pandas 3.0.6,
polars 1.44.2), `node:22-slim` (`@duckdb/node-api` 1.5.5-r.5),
`golang:1.25` (duckdb-go v2, engine 1.5.5, built with its Arrow route),
`rust:slim` (the `duckdb` crate 1.10505.0, engine 1.5.5, compiled from
the bundled sources).
Julia is absent for the reason
[`2026-09-14-memory-clients/`](/experiments/2026-09-14-memory-clients/README.md)
gives.

*What it supports:*
[`usage/memory/writing/`](/handbook/usage/memory/writing/README.md).

## Method

Every run targets a fresh **file database** under
`SET memory_limit = '300MB'`, so the table is written through to disk
and the engine's working set is bounded the same way in every client;
a few runs repeat the main routes into an in-memory database.
Each process resets the kernel's peak-RSS counter
(writing `5` to `/proc/self/clear_refs`) at the moment the measured
step begins — after the source frame exists, for the frame routes —
records its resident size as the baseline,
and reads `VmHWM` at the end;
the CSV column `over_base_mb` is therefore the ingest step's own peak,
not the source's construction, which the earlier high-water mark would
otherwise hide.
Every process verifies the row count in the table before it reports.
The line format is
`lang,image,scenario,target,rows,base_mb,peak_mb,over_base_mb,seconds`,
recorded in [`results/ingest.csv`](results/ingest.csv).

[`run.sh`](run.sh) runs one scenario per container
(`./run.sh run <lang> <image-label> <file|memory> <scenario...>`)
after `./run.sh prepare <lang>` has installed that language's client
into a cache directory beside the repository;
the Python preparation also writes the shared source files,
`src.parquet` (372 MB) and `src.csv` (1,033 MB), with the engine.
The per-language scripts are [`r/ingest.R`](r/ingest.R),
[`python/ingest.py`](python/ingest.py), [`node/ingest.mjs`](node/ingest.mjs),
[`go/main.go`](go/main.go) and [`rust/src/main.rs`](rust/src/main.rs);
each language's `ingest.sh` wraps a scenario with its producer where
the route needs one — an `awk` loop printing fifty million CSV lines
for the CSV pipe, and [`r/producer_arrow.R`](r/producer_arrow.R) or
[`python/producer_arrow.py`](python/producer_arrow.py) writing an Arrow
IPC stream for the Arrow pipe.

The scenario names, shared across languages where the route exists:

* `engine_generate` — the floor: the engine generates the rows,
  no client data at all.
* `file_read_parquet`, `file_read_csv` — the engine reads a file it
  wrote earlier; `file_duckdb_read_csv` is the R package's own CSV
  wrapper on the same file.
* `frame_*` — the process holds the data as a native frame first
  (a data frame, pandas, an Arrow table, polars, typed arrays, slices,
  vectors), and the route hands it over:
  `frame_dbWriteTable`, `frame_dbAppendTable`, `frame_pandas_register`,
  `frame_pandas_append`, `frame_arrow_register`, `frame_polars_register`,
  `frame_nanoarrow_register`, `frame_arrays_appender_chunks`,
  `frame_slices_appender`, `frame_vec_appender`, `frame_arrow_vtab`;
  `frame_register_only` and `frame_pandas_register_only` register the
  frame and scan it with an aggregate, creating no table;
  `frame_nanoparquet_roundtrip` and `frame_parquet_roundtrip` write the
  frame to Parquet and let the engine read it back.
* `chunks_*` — fifty frames of a million rows, generated and appended
  one at a time, never held whole.
* `stream_*` — data produced as the engine pulls it:
  `stream_appender_rows` and `stream_appender_chunks` feed an appender,
  `stream_append_record_batches` an appender with Arrow batches,
  `stream_arrow_reader_generator` a generator behind an Arrow reader,
  `stream_arrow_view` a lazy Arrow record reader registered as a view,
  `stream_table_function` a table function the engine calls chunk by
  chunk;
  `stream_stdin_csv` and `stream_stdin_arrow` read a pipe fed by a
  second process, as CSV through `COPY ... FROM '/dev/stdin'`
  and as an Arrow IPC stream registered as a source;
  `stream_stdin_arrow_dbAppendTableArrow` takes the same stream through
  DBI's `dbAppendTableArrow()`, a batch at a time.
* `dataset_*` — the client's Arrow library reads the Parquet file
  through its dataset scanner, and the engine ingests the stream:
  `dataset_arrow_scanner` in Python, `dataset_arrow_to_duckdb` in R
  (what `arrow::to_duckdb()` does).
* `stream_reader_only_*` and `stream_scanner_only_*` involve no engine:
  the Python process consumes its own generator through the plain
  reader or through the dataset scanner,
  with a consumer that pauses 20 ms per batch (`_slow`) or 150 ms
  (`_slower`).
* The suffixes are the variants the findings explain:
  `_syspool` (Arrow on the system allocator), `_noorder`
  (`preserve_insertion_order = false`), `_1thread` (`threads = 1`),
  `_count` (`count(*)` over the source instead of a table),
  `_chunks` (one batch registered and inserted at a time),
  `_gogc20` (Go's collector at `GOGC=20`).

## The numbers

Peak resident memory in MB over the baseline taken at the start of the
measured step, and the step's wall time in seconds,
for fifty million rows of two `DOUBLE` columns — 800 MB as a frame,
in a file database under a 300 MB `memory_limit` unless the row says
*memory*.
For the `frame_*` routes the baseline already holds the frame
(800–910 MB, depending on the frame library),
so their number is the cost of handing it over;
for every other route the baseline is an idle process,
and the marker ▸ says the client never holds the data whole.
The engine's own floor — `engine_generate` — is the buffer pool
filling to the limit while the table is written through,
and reads as 289–300 in every client.

| client (engine) | route | over base MB | s |
|---|---|---|---|
| R dev 1.5.5.9023 | `engine_generate` | 289 | 6.7 |
| R dev | `file_read_parquet` | 308 | 4.1 |
| R dev | `file_read_csv` | 451 | 6.6 |
| R dev | `file_duckdb_read_csv` | 477 | 6.9 |
| R dev | `frame_dbWriteTable` | 304 | 10.9 |
| R dev | `frame_dbAppendTable` | 279 | 8.2 |
| R dev | `frame_register_only` | 1 | 0.2 |
| R dev | `frame_arrow_register` | 429 | 5.5 |
| R dev | `frame_nanoarrow_register` | 354 | 9.3 |
| R dev | `frame_nanoparquet_roundtrip` | 364 | 9.2 |
| R dev | ▸ `chunks_dbAppendTable` | 426 | 11.5 |
| R dev | ▸ `stream_stdin_csv` | 315 | 21.0 |
| R dev | ▸ `stream_stdin_arrow`, also with `threads = 1` | *fails* | — |
| R dev | ▸ `stream_stdin_arrow_dbAppendTableArrow` | 505 | 14.7 |
| R dev | ▸ `dataset_arrow_to_duckdb` | 1,036 | 3.9 |
| R dev | ▸ the same, `threads = 1` | 1,435 | 6.9 |
| R dev | ▸ the same, `count(*)` instead of a table | 349 | 0.7 |
| R dev, *memory* | `frame_dbWriteTable` | 320 | 4.0 |
| R dev, *memory* | `frame_nanoarrow_register` | 374 | 6.2 |
| R dev, *memory* | ▸ `chunks_dbAppendTable` | 374 | 8.5 |
| R CRAN 1.5.5 | `frame_dbWriteTable` | 320 | 7.0 |
| R CRAN | `frame_nanoarrow_register` | 392 | 8.8 |
| R CRAN | ▸ `chunks_dbAppendTable` | 426 | 12.2 |
| R CRAN | ▸ `stream_stdin_csv` | 328 | 20.8 |
| Python 1.5.5 | `engine_generate` | 299 | 6.1 |
| Python | `file_read_parquet` | 340 | 2.0 |
| Python | `file_read_csv` | 522 | 3.3 |
| Python | `frame_pandas_register` | 356 | 3.0 |
| Python | `frame_pandas_register_only` | 3 | 0.1 |
| Python | `frame_pandas_append` | 361 | 5.6 |
| Python | `frame_arrow_register` | 310 | 7.4 |
| Python | `frame_polars_register` | 378 | 7.9 |
| Python | `frame_parquet_roundtrip` | 407 | 9.1 |
| Python | ▸ `chunks_pandas_append` | 421 | 12.8 |
| Python | ▸ `stream_stdin_csv` | 334 | 20.6 |
| Python | ▸ `stream_arrow_reader_generator` | 820 | 5.8 |
| Python | ▸ the same, system allocator for Arrow | 680 | 3.6 |
| Python | ▸ the same, `preserve_insertion_order = false` | 608 | 2.7 |
| Python | ▸ the same, `threads = 1` | 854 | 6.7 |
| Python | ▸ the same, `count(*)` instead of a table | 169 | 1.4 |
| Python | ▸ `stream_arrow_reader_generator_chunks` | 455 | 7.6 |
| Python | ▸ `stream_stdin_arrow` | 814 | 6.9 |
| Python | ▸ the same, system allocator for Arrow | 849 | 3.1 |
| Python | ▸ `dataset_arrow_scanner` | 799 | 3.1 |
| Python | ▸ the same, `threads = 1` | 1,246 | 6.1 |
| Python | ▸ the same, `count(*)` instead of a table | 283 | 0.3 |
| Python, no engine | ▸ `stream_reader_only_slow` | 30 | 1.6 |
| Python, no engine | ▸ `stream_scanner_only_slow` | 146 | 1.3 |
| Python, no engine | ▸ `stream_reader_only_slower` | 30 | 8.2 |
| Python, no engine | ▸ `stream_scanner_only_slower` | 535 | 7.7 |
| Python, *memory* | `frame_pandas_register` | 383 | 3.4 |
| Python, *memory* | `frame_arrow_register` | 310 | 4.0 |
| Python, *memory* | ▸ `stream_arrow_reader_generator` | 758 | 3.7 |
| Node 1.5.5 | `engine_generate` | 299 | 6.1 |
| Node | `file_read_parquet` | 337 | 3.7 |
| Node | `file_read_csv` | 450 | 6.3 |
| Node | `frame_arrays_appender_chunks` | 354 | 12.0 |
| Node | ▸ `stream_appender_rows` | 316 | 20.5 |
| Node | ▸ `stream_appender_chunks` | 331 | 14.3 |
| Node | ▸ `stream_table_function` | 334 | 9.4 |
| Node | ▸ `stream_stdin_csv` | 330 | 20.8 |
| Go 1.5.5 | `engine_generate` | 300 | 5.6 |
| Go | `file_read_parquet` | 348 | 3.2 |
| Go | `file_read_csv` | 432 | 5.5 |
| Go | `frame_slices_appender` | 1,126 | 13.6 |
| Go | the same, `GOGC=20` | 494 | 12.9 |
| Go | ▸ `stream_appender_rows` | 351 | 13.3 |
| Go | ▸ the same, `GOGC=20` | 345 | 13.3 |
| Go | ▸ `stream_arrow_view` | 500 | 2.3 |
| Go | ▸ `stream_stdin_csv` | 333 | 19.0 |
| Rust 1.5.5 | `engine_generate` | 295 | 4.6 |
| Rust | `file_read_parquet` | 319 | 2.1 |
| Rust | `file_read_csv` | 430 | 2.8 |
| Rust | `frame_vec_appender` | 310 | 10.8 |
| Rust | `frame_arrow_vtab` | 298 | 4.2 |
| Rust | ▸ `stream_appender_rows` | 310 | 10.5 |
| Rust | ▸ `stream_append_record_batches` | 326 | 5.2 |
| Rust | ▸ `stream_stdin_csv` | 324 | 21.1 |

The two R rows that fail do so with
`arrow_scan: get_next failed(): IOError: Can't read from R connection on a non-R thread`,
raised by nanoarrow's connection reader
(`read_con_input_stream()` in its `src/ipc.c`,
which compares the calling thread with the one the package loaded on) —
and `SET threads = 1` does not change who calls,
for the reason the findings give.
An earlier version of the R producer failed on its own side with
`IOError: lseek failed`,
because arrow's `FileOutputStream` on `/dev/stdout` is asked where it is
by the stream writer's alignment and a pipe cannot say;
the producer now writes through an R connection wrapped for arrow.

## What the numbers say

* **The floor is the pool, and handing a frame over costs nothing beyond it.**
  Every client's `engine_generate` reads 289–300:
  the buffer pool filling to the 300 MB limit while the table is written
  through.
  A frame the process already holds is scanned in place by every client
  that offers it — R's `dbWriteTable()` and `dbAppendTable()` at 279–320
  over the frame, pandas, an Arrow table and polars at 310–378,
  Rust's `Vec` through the appender at 310, its Arrow table through the
  virtual table at 298, Node's typed arrays through chunk appends at 354 —
  and registering alone, with no table made, costs 1–3.
  The CRAN 1.5.5 build reads the same as the development build,
  and the in-memory database the same as the file one:
  a table beyond the limit is offloaded to `temp_directory`
  as it would be written through to a file.
* **Producing as the engine pulls stays within a hundred of the floor.**
  Appenders fed row by row (Node 316, Go 351, Rust 310),
  chunk by chunk (Node 331, Rust's record batches 326),
  a table function the engine calls (Node 334),
  and CSV over a pipe into `COPY ... FROM '/dev/stdin'`
  (315–334 in every client, at three to four times the time of the
  file reader) all hold one piece at a time.
  Fifty frame appends of a million rows (R 426, Python 421 and 455)
  add the frame library's own chunk in flight and the statement per
  chunk.
  Go's `frame_slices_appender` is the one outlier at 1,126:
  `AppendRow` boxes every value into an `any`,
  and Go's collector lets the heap double before it runs
  (`GOGC`'s default of 100);
  `GOGC=20` brings the same code to 494,
  and the appender fed from a generator never allocates that garbage
  in the first place (351, 345).
* **A lazy Arrow source registered as a table costs the whole dataset,
  or more — Arrow's doing, not the engine's.**
  Python's generator behind a `RecordBatchReader` (820; 758 in memory),
  an IPC stream over a pipe (814), pyarrow's dataset over the Parquet
  file (799), and R's `arrow::open_dataset()` handed to
  `duckdb_register_arrow()` — what `arrow::to_duckdb()` does — (1,036)
  all peak at the data's size or above,
  where the engine reading the same Parquet file directly costs
  308–348.
  The engine's scan holds one batch per thread
  (`ArrowScanParallelStateNext()`,
  [`src/duckdb/src/function/table/arrow.cpp`](/src/duckdb/src/function/table/arrow.cpp)),
  and neither the allocator (680, 849), nor the insertion-order sink
  (608), nor a single engine thread (854, 1,246, 1,435 — worse, because
  the consumer is slower) is where the memory goes.
  What both clients do is wrap the source in Arrow's dataset `Scanner`
  before exporting it —
  [`R/register.R`](/R/register.R)'s `export_fun` calls
  `arrow::Scanner$create()`,
  and the Python module calls `pyarrow.dataset.Scanner.from_batches()` —
  and the scanner reads ahead on Arrow's own thread pool,
  pausing only at its backpressure threshold,
  which is above this dataset's size.
  The rows with `count(*)` in place of the table (169, 283, 349) are the
  same scan with a consumer that keeps up:
  the readahead never accumulates.
  The rows without the engine show the scanner alone:
  a consumer a little slower than the producer sees 146 through the
  scanner against 30 through the plain reader,
  and one as slow as a table write under the limit
  sees 535 against 30 —
  which, over the engine's floor of 300, is the 814–854 of the table
  rows.
  So the cost belongs to the pairing of a lazy source with a slow sink,
  and a table write under a memory limit is the slow sink.
  The readahead is bounded, though the bound is above this dataset:
  at fifteen times the data it stops at about 2 GB
  ([below](#at-the-workers-ram)).
* **The remedy is to take the stream in pieces on the client's side.**
  Python inserting one registered batch at a time (455)
  and R's `dbAppendTableArrow()` (505) —
  DBI's default, which pulls a batch on R's thread and appends it as a
  data frame — halve the cost,
  and the second is the only way the Arrow pipe reaches R's engine at all:
  the scanner pulls from Arrow's pool,
  and nanoarrow's connection reader refuses any thread but R's,
  `threads = 1` or not.
  For a file the engine can read, letting it read is a third of the cost
  and faster.
* **Round trips through Parquet are sound and not cheaper.**
  R's nanoparquet (364) and pandas (407) write the frame and let the
  engine read it back for about what handing the frame over costs,
  plus the file.
* **Go's Arrow view reads as 500** with the record reader implemented
  on the Go allocator and consumed through duckdb-go's own stream —
  no scanner in between, and the collector's pacing again.

## At the worker's RAM

The same routes with fifteen times the data:
750 million rows, 12 GB as a frame, on the 15.7 GiB worker —
three quarters of its memory, and more than any route that holds the
data twice can have.
One container at a time, each capped by a cgroup at 14.5 GB with no
swap, so a run that outgrows the cap is killed inside its container
(recorded as *OOM*) rather than by the host;
the dev build only, since the CRAN build read the same at 800 MB;
`memory_limit` at 300 MB as before.
Left out at this size:
the file sources and the Parquet round trips,
because the session's disk allowance of 15 GB cannot hold a 12 GB
table beside a 12 GB source;
R's `frame_arrow_register`, whose conversion copies the frame;
and the probe variants.
Recorded in
[`results/ingest-near-ram.csv`](results/ingest-near-ram.csv),
same columns.

| client (engine) | route | over base MB | s |
|---|---|---|---|
| R dev 1.5.5.9023 | `engine_generate` | 355 | 107 |
| R dev | `frame_dbWriteTable` | 373 | 102 |
| R dev | `frame_register_only` | 1 | 1 |
| R dev | `frame_nanoarrow_register` | 426 | 104 |
| R dev | ▸ `chunks_dbAppendTable` | 463 | 186 |
| R dev | ▸ `stream_stdin_csv` | 431 | 378 |
| R dev | ▸ `stream_stdin_arrow_dbAppendTableArrow` | 582 | 236 |
| Python 1.5.5 | `engine_generate` | 363 | 87 |
| Python | `frame_pandas_register` | *OOM building the frame* | 64 |
| Python | `frame_pandas_register_only` | *OOM building the frame* | 36 |
| Python | `frame_arrow_register` | 372 | 98 |
| Python | ▸ `chunks_pandas_append` | 468 | 165 |
| Python | ▸ `stream_arrow_reader_generator` | 2,114 | 49 |
| Python | ▸ `stream_arrow_reader_generator_chunks` | 516 | 157 |
| Python | ▸ `stream_stdin_arrow` | 2,033 | 50 |
| Python | ▸ `stream_stdin_csv` | 402 | 372 |
| Node 1.5.5 | `engine_generate` | 361 | 95 |
| Node | `frame_arrays_appender_chunks` | 531 | 165 |
| Node | ▸ `stream_appender_rows` | 350 | 272 |
| Node | ▸ `stream_appender_chunks` | 515 | 187 |
| Node | ▸ `stream_table_function` | 386 | 127 |
| Node | ▸ `stream_stdin_csv` | 388 | 370 |
| Go 1.5.5 | `engine_generate` | 364 | 69 |
| Go | `frame_slices_appender` | *OOM* | 95 |
| Go | the same, `GOGC=20` | 2,877 | 174 |
| Go | ▸ `stream_appender_rows` | 412 | 171 |
| Go | ▸ `stream_arrow_view` | 552 | 33 |
| Go | ▸ `stream_stdin_csv` | 410 | 351 |
| Rust 1.5.5 | `engine_generate` | 358 | 69 |
| Rust | `frame_vec_appender` | 348 | 168 |
| Rust | `frame_arrow_vtab` | 359 | 73 |
| Rust | ▸ `stream_appender_rows` | 348 | 159 |
| Rust | ▸ `stream_append_record_batches` | 363 | 80 |
| Rust | ▸ `stream_stdin_csv` | 441 | 346 |

* **What stayed near the floor stays near it.**
  The floor reads 355–364 (sixty above the small run's, growing with
  the row count rather than with the data held),
  and the frame routes sit on it as before:
  373 over the 12 GB frame in R, 372 for the Arrow table in Python,
  348 and 359 in Rust, 531 in Node,
  1 MB to register.
  The piecewise routes read 348–582, and CSV over a pipe 388–441 at
  six minutes, the producer's pace.
  The two rows killed at the cap are the two that would hold the data
  twice.
* **pandas dies building the frame, before the engine is involved.**
  Its constructor consolidates the two float columns into one block,
  a copy,
  so the frame alone wants 24 GB at this size;
  the Arrow table built from the same NumPy arrays is zero-copy
  and goes through for 372.
* **A lazy Arrow source is buffered up to a threshold, not without limit.**
  At 800 MB the scanner held the whole dataset (820 and 814);
  at 12 GB the generator and the IPC pipe both stop at about 2.1 GB
  over an idle process — some 1.7 GB of readahead above the floor,
  the backpressure threshold the small dataset never reached.
  So the pairing of a lazy source with a table write costs a bounded
  two gigabytes rather than the data,
  still four times the same stream taken a batch at a time (516).
* **Go's collector headroom is a fraction of the live heap.**
  `frame_slices_appender` is killed at the cap:
  `AppendRow` boxes every value, and the collector lets the garbage
  grow by `GOGC` percent of the 12 GB that is live before it runs.
  At `GOGC=20` that is 2.4 GB of headroom,
  and the run reads 2,877 over the slices —
  the 494 of the small run scaled with the live heap,
  as pacing predicts.
  The appender fed from a generator, with no live frame to scale on,
  stays at 412.
