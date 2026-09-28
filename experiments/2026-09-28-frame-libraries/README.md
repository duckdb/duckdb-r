# A query result in Polars, data.table and collapse

*What it measures:* the one call that takes a query result into each frame library that
[#642](https://github.com/duckdb/duckdb-r/issues/642) asks for: Polars, data.table and collapse.
Also whether the columns there are the memory the result arrived in or a copy of it.
For Polars that is the data address of each Arrow buffer of each batch, before the conversion and after it.
For data.table and collapse it is the address of each column vector.

*When and on what:* 2026-09-28, Linux x86_64 with 4 cores and 16 GB, R 4.5.3.
The packages are DBI 1.3.0, nanoarrow 0.9.0, data.table 1.18.6.1, collapse 2.1.8 and lobstr 1.2.2.
polars is 1.9000.9000.9000, the development version that r-universe builds from pola-rs/r-polars at 0ada39de32.
It carries the prebuilt Rust library of polars 2.0.0-rc.2.
The release is published on R-multiverse, which the environment this ran in could not reach, so it is not measured.
duckdb 1.5.5.9029 is 7fd4c2c8fd, the top of the stack of pull requests this record was written on.
It is a fast-path build linking the release `libduckdb` of DuckDB 1.5.5 ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
The Arrow export measured is the engine's, which the release shares with the vendored engine.
[`frames.R`](frames.R) is rendered to [`frames.md`](frames.md) by [`scripts/render-reprex.R`](/scripts/render-reprex.R).
The session info names the scratch library that held the build, polars, collapse and lobstr as `<scratch library>`.

*What it supports:* the frame library entry in [`usage/integrations/`](/handbook/usage/integrations/README.md).

## Findings

From [`frames.md`](frames.md), on a result of 2.5 million rows with two integer columns, a double and a string:

* **Polars takes the stream's buffers as they are.**
  `polars::as_polars_df(dbGetQueryArrow(con, sql))` reads the stream through Polars' own Arrow import.
  In its source, `as_polars_df()` falls back to `as_polars_series()`, which has a `nanoarrow_array_stream` method, and unnests the struct.
  It keeps one chunk per batch, three here.
  The data buffers of `i`, an integer, and `d`, a double, keep their addresses in every batch.
  The `string` column the stream sends becomes Polars' `string_view`.
  Its characters keep their address, and the views are new, 16 bytes per row.
  Under `arrow_output_version = '1.4'` and `produce_arrow_string_view = true` the stream sends views, and those keep their address too.
  The batches are collected before they go to Polars so that their addresses can be read.
  Polars' own export hands back what it holds, so an address that matches on both sides was copied by neither.
* **`data.table::setDT()` keeps every column.**
  `setDT(dbGetQuery(con, sql))` returns a `data.table`, and each column keeps the address it had in the data frame.
  `as.data.table()` copies all four.
* **collapse takes the data frame as it is.**
  `fsummarise(fgroup_by(df, g), ...)` summarises the data frame that `dbGetQuery()` returned.
  `qDT()` returns a `data.table` whose columns keep the data frame's addresses.

## Replicating

Put a build of this package, polars, collapse and lobstr first in the library path.
Then, from this directory, run `Rscript ../../scripts/render-reprex.R frames.R frames`.
It needs no network and takes about ten seconds.
polars installs from `https://rpolars.r-universe.dev`.
Under `NOT_CRAN=true`, `R CMD INSTALL` of its source package downloads the prebuilt Rust library instead of compiling it.
Compiling it needs Rust 1.97, newer than the 1.94.1 installed here.
