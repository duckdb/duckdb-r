# Result memory across DuckDB clients, and the R findings re-run in containers

*What it measures:* the peak resident memory of one process fetching
the same 800 MB result — fifty million rows of two `DOUBLE` columns —
through each route a client offers,
materialized or streamed, discarded or converted,
and once more sorted under a 200 MB `memory_limit`;
plus the findings the memory leaves rest on,
each re-run in a fresh container on the dev build and on the CRAN release.

*When and on what:* 2026-09-14, in Docker on Linux x86_64
(4 cores, 16 GB), one container per run, images as pulled that day:
`ghcr.io/cynkra/docker-images/rig-ubuntu-duckdb-dev` (duckdb 1.5.5.9022,
R 4.6.1), `ghcr.io/cynkra/docker-images/p3m-noble-duckdb` (duckdb 1.5.5,
R 4.6.1), `python:3.12-slim` (duckdb 1.5.5, pyarrow 25.0.1, pandas 3.0.5),
`node:22-slim` (`@duckdb/node-api` 1.5.5-r.5), `golang:1.25`
(go-duckdb v2), `rust:slim` (the `duckdb` crate, bundled engine).
Julia is absent: the package registry hosts were refused by the
network policy of the session that ran this.

*What it supports:*
[`usage/memory/reading/`](/handbook/usage/memory/reading/README.md)
and [`usage/memory/writing/`](/handbook/usage/memory/writing/README.md).

## Method

Every process reads its own `VmHWM` from `/proc/self/status` at the end,
so a peak is the whole process — engine, client library and language
runtime together — and prints one CSV line:
`lang,image,scenario,rows,peak_mb,seconds`.
[`run.sh`](run.sh) runs one scenario per container
(`./run.sh run <lang> <image-label> <scenario...>`) after
`./run.sh prepare <lang>` has installed that language's client into a
cache directory beside the repository;
it honours `HTTPS_PROXY` and mounts `CA_BUNDLE` for every tool when set.
The per-language scripts are [`r/clients.R`](r/clients.R),
[`python/clients.py`](python/clients.py), [`go/main.go`](go/main.go),
[`rust/src/main.rs`](rust/src/main.rs), [`node/clients.mjs`](node/clients.mjs);
[`r/findings.R`](r/findings.R) holds the R findings, one per process,
printing `image,finding,metric,value` lines.
The recorded runs are [`results/clients.csv`](results/clients.csv),
[`results/findings-dev.csv`](results/findings-dev.csv) and
[`results/findings-cran.csv`](results/findings-cran.csv).

Two container details matter for reading the numbers:
a process starts with the working directory `/tmp`, because an in-memory
database's default spill directory is `.tmp` under the working directory
in every client but R, and a read-only one turns the first spill into an
error; and nothing but the R package sets a spill directory of its own.

## What the numbers say

*The runs are in progress; this section is written once they finish.*
