# Geometry between DuckDB and sf through GeoArrow

*What it measures:* each way to read a `GEOMETRY` column into sf through Arrow, with a CRS and without one;
each GeoArrow encoding an sf geometry column can be written in, and the DuckDB type it lands as;
what the CRS becomes at every step, with the `spatial` extension loaded and without it;
and the routes that lose the geometry on the way.

*When and on what:* 2026-09-27, duckdb 1.5.5.9028 (DuckDB 1.5.5, linked through the fast path), built from
[#2808](https://github.com/duckdb/duckdb-r/pull/2808), Linux, with `spatial` from the extension store,
sf 1.1-3, geoarrow 0.4.4, nanoarrow 0.9.0, arrow 25.0.1, wk 0.9.5, dbplyr 2.6.0.
The geometries are the first three counties of sf's `nc.shp`, `MULTIPOLYGON` in EPSG:4267.

*What it supports:* [`usage/arrow-types/`](/handbook/usage/arrow-types/README.md),
and the open work in [`plan/PLAN-spatial-interop.md`](/plan/PLAN-spatial-interop.md).

## Method

[`geoarrow.R`](geoarrow.R) → [`geoarrow.md`](geoarrow.md), rendered with `reprex::reprex(si = TRUE)`.
A result counts as the same when every geometry equals its original under `sf::st_equals()` and the CRS compares equal under `sf::st_crs()`.
The Arrow data is registered as an arrow `Table`, which DuckDB can scan more than once, except where the script measures a reader.

## Findings

* **sf reads a GEOMETRY result through Arrow in one call.**
  `sf::st_as_sf(dbGetQueryArrow(con, sql))` gives an sf whose geometries and CRS equal the source's,
  and so do `sf::st_as_sf()` of `arrow::as_arrow_table()` and `sf::st_as_sfc()` of the `geoarrow_vctr` column.
  Those methods are geoarrow's: until geoarrow is loaded, `st_as_sf()` has none for a nanoarrow stream.
  A `NULL` geometry reads as an empty one.
  The large and view layouts of the export read the same.
* **The routes behind `dbSendQuery(arrow = TRUE)` fail on a CRS.**
  `duckdb_fetch_record_batch()`, and `arrow::to_arrow()`, which reads through it, fail with
  `INTERNAL Error: TransactionContext::ActiveTransaction called without active transaction` for a column with a CRS,
  and read the same column without one.
  That route exports the schema after the materialized query's transaction has ended,
  and exporting a CRS converts it through the client context
  (`CoordinateReferenceSystem::TryConvert()` in the vendored `src/duckdb/src/common/arrow/arrow_type_extension.cpp`),
  which the error says needs an active transaction.
  Casting the column to the bare type in the query, `geom::GEOMETRY`, drops the CRS, and the route reads it.
* **Only WKB lands as GEOMETRY.**
  A column encoded as `geoarrow_wkb()`, through `geoarrow::as_geoarrow_vctr(x, schema = )`, or a `wk::as_wkb()` column,
  lands as `GEOMETRY` with its CRS, and reads back into an equal sf.
  What nanoarrow infers for an sf column, and what `arrow::as_arrow_table()` makes of one, is the native `geoarrow.multipolygon`,
  which lands as `STRUCT(x DOUBLE, y DOUBLE)[][][]`;
  `geoarrow_wkt()` lands as `VARCHAR`.
  geoarrow cannot write an sfc as `geoarrow_large_wkb()` or `geoarrow_wkb_view()`,
  but those layouts, as DuckDB exports them, land as `GEOMETRY` too.
* **The native and WKT encodings convert in SQL only in part.**
  A native point casts through `POINT_2D`, as `geometry::POINT_2D::GEOMETRY`;
  a native polygon has no cast to `GEOMETRY`, through `POLYGON_2D` or directly.
  WKT casts with `::GEOMETRY`, and `ST_SetCRS()` puts the CRS back.
* **The CRS lands with the spatial extension or without it.**
  With `spatial` loaded, the type names it by its identifier, `GEOMETRY('EPSG:4267')`;
  without, it keeps the PROJJSON it came as.
  Both read back as the same CRS.
* **A registered reader is scanned once.**
  `duckdb_register_arrow()` of a `RecordBatchReader` returns its rows to the first query and none to the next;
  a `Table` returns them every time.
* **The routes through an R data frame write indices, not geometries.**
  A `geoarrow_vctr` is an integer vector of indices into the Arrow data it holds.
  `dbWriteTable()` of a data frame read with `as.data.frame(dbGetQueryArrow())`, and `dbWriteTableArrow()`,
  write those integers as an `INTEGER` column, `1, 2, 3`, without an error.

Replicate with the vendored build or the fast path ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)),
from this directory, `reprex::reprex(input = "geoarrow.R", si = TRUE)`;
`INSTALL` needs network access to `extensions.duckdb.org`.
