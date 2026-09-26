# DuckDB ↔ R-spatial interop

*What it measures:* which route carries a geometry across the R boundary
and what arrives on the other side —
37 rows in all: 10 asking whether a spatial name is core in 1.5,
8 reading a `GEOMETRY` column into R,
19 writing an R geometry into one —
plus what each route does to the CRS.

*When and on what:* 2026-08-09, duckdb 1.5.5.9013
(DuckDB 1.5.5, vendored build, `spatial` loaded from the extension store),
sf 1.1-2, wk 0.9.5, geoarrow 0.4.3, arrow 25.0.0, nanoarrow 0.9.0,
Linux.
The geometries are the first three counties of `sf`'s `nc.shp`
(`MULTIPOLYGON`, EPSG:4267).

*What it supports:*
[`usage/types/`](/handbook/usage/types/README.md), and
[`plan/PLAN-spatial-interop.md`](/plan/PLAN-spatial-interop.md),
which proposes what to do about the write side.

Run [`probe.R`](probe.R); the recorded run is [`probe.md`](probe.md),
rendered with `reprex::reprex(si = TRUE)`.

## What the run compresses to

**The engine moved under this issue.**
`GEOMETRY` is a core type in DuckDB 1.5, not an extension alias,
and so are `ST_AsWKB()`, `ST_GeomFromWKB()`, `ST_AsText()`,
`ST_SetCRS()`, and the `VARCHAR` → `GEOMETRY` cast that reads WKT.
The `spatial` extension is still what supplies the geometry *functions* —
`ST_Read()`, `ST_Point()`, `ST_Area()`, `ST_Transform()`,
even `ST_GeomFromText()` —
and, less obviously, the CRS provider:
naming a CRS in DDL (`GEOMETRY('EPSG:4326')`) fails with
"unrecognized coordinate system" until `spatial` is loaded,
while `ST_SetCRS()` takes the same string without it.

**Reading works, in three shapes, and the CRS survives all of them.**
`geometry = "blob"` yields raw WKB, `geometry = "wk"` yields `wk_wkb`
carrying the column's CRS identifier as an attribute,
and `dbGetQueryArrow()` yields a `geoarrow.wkb` field whose extension
metadata carries the CRS as PROJJSON —
DuckDB 1.5 registers that Arrow extension type in both directions,
which is what
[duckdb_spatial#153](https://github.com/duckdb/duckdb_spatial/issues/153)
was waiting for.
`sf::st_as_sfc()` reconstructs the source CRS from either representation.

**Two read-side gaps are in sf, not here.**
`sf::st_read(con, <table>)` still warns
"Could not find a simple features geometry column" and returns a
`data.frame`: it recognizes neither a `GEOMETRY` column nor the
`wk_wkb` vector this package hands it.
The `st_read(con, query = )` workaround from the issue thread still
works, and still loses the CRS —
`ST_AsWKB()` returns a `BLOB`, and a `BLOB` has no CRS to carry.

**The write side is where the story is.**
No route from an `sf` or `sfc` object reaches a `GEOMETRY` column,
and the failures are worse than a refusal:

* An `sf` object handed to `dbWriteTable()` or `sf::st_write()`
  fails with "Failed to parse geometry: Unknown geometry type at
  offset 0" — sf's own `dbDataType()` method declares the column
  `geometry` and writes EWKB hex into it, which DuckDB now tries to
  parse as WKT.
  The 2024 report's "Unknown type: '0106…'" has become a parse error;
  it is still a failure.
* A bare `sfc` column is not refused at all.
  A `POINT` column writes **silently** as `DOUBLE[]` —
  the type detector walks into the `sfg` list and finds numbers —
  so the geometry is gone and nothing says so.
  `LINESTRING` and `MULTIPOLYGON` reach the transform and abort with
  `Invalid Error: std::exception`, naming neither column nor type.
  `duckdb_register()` is the same both ways: it types an `sf` object's
  column as `DOUBLE[2][][][]` and fails on fetch.
* A `wk_wkb` column writes as `BLOB`, dropping its class and CRS
  without a warning.
* `BLOB` → `GEOMETRY` has no cast, so `field.types = c(geom =
  "GEOMETRY")` over WKB fails, and so does `dbAppendTable()` of WKB
  into an existing `GEOMETRY` column.

**Three routes do work today,** none of them obvious:

* **WKT, in one step.**
  `dbWriteTable(con, tbl, df, field.types = c(geom = "GEOMETRY"))`
  with a `character` column of `st_as_text()` output lands a
  `GEOMETRY` column, because the `VARCHAR` cast parses WKT —
  and `field.types = c(geom = "GEOMETRY('EPSG:4267')")` lands the CRS
  with it, once `spatial` is loaded.
  `dbAppendTable()` of WKT works for the same reason.
  This is shorter than the `ALTER TABLE … USING ST_GeomFromWKB()`
  route the handbook has been giving, which needs two statements and
  drops the CRS: `SET DATA TYPE GEOMETRY` names the bare type, so a
  CRS applied in the `USING` clause has nowhere to live.
  A projection — `SELECT ST_SetCRS(geom, 'EPSG:4267')` — keeps it.
* **WKB through a parameter.** `ST_GeomFromWKB(?)` bound to a raw
  vector yields `GEOMETRY`, which is the per-query form of the same
  thing.
* **Arrow, which is the only route that carries geometry and CRS
  together.**
  A `wk_wkb` column becomes a `geoarrow.wkb` field with PROJJSON
  metadata, and DuckDB reads it as `GEOMETRY('EPSG:4267')`;
  the round trip back to `sf` is geometry-equal and CRS-equal to the
  original.
  It is also the narrowest path in the record:
  `duckdb_register_arrow()` accepts an `arrow` object but not a
  `nanoarrow` array stream (that one aborts with `std::exception`),
  and `arrow`'s own conversions do not preserve the extension type —
  `as_arrow_table()` turns a `wk_wkb` column into a plain `BLOB` and an
  `sf` object into `geoarrow.multipolygon`, an encoding DuckDB does not
  register, which arrives as `STRUCT(x DOUBLE, y DOUBLE)[][][]`.
  Only `arrow::as_record_batch_reader()` wrapped around a
  `nanoarrow` stream keeps `geoarrow.wkb` intact,
  and only with the geoarrow package loaded to register it.
