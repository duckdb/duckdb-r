# Spatial types

Geometry across the R boundary, through R vectors and through GeoArrow:
the core `GEOMETRY` type and its coordinate reference system (CRS), the `spatial` extension's own types,
and where R's spatial packages meet them.
The geometry functions are the [`spatial` extension's](https://duckdb.org/docs/current/core_extensions/spatial/overview) to document,
and every other type is [`types/`](/handbook/usage/types/README.md)'s.
The surface is measured route by route in [`experiments/2026-08-09-spatial-interop/`](/experiments/2026-08-09-spatial-interop/README.md),
through GeoArrow in [`experiments/2026-09-27-geoarrow/`](/experiments/2026-09-27-geoarrow/README.md),
and each type beside the others in [`experiments/2026-09-26-type-catalog/`](/experiments/2026-09-26-type-catalog/README.md).

## Reading

* **Geometry comes back as WKB by default.**
  `dbConnect(geometry = )` chooses: `"blob"`, the default set in [`R/dbConnect__duckdb_driver.R`](/R/dbConnect__duckdb_driver.R),
  returns raw vectors; `"wk"` returns `wk_wkb`, which `sf::st_as_sfc()` converts onward.
  [`GEOMETRY`](https://duckdb.org/docs/current/sql/data_types/geometry) is a core DuckDB type since 1.5,
  so reading one needs no extension,
  but the geometry functions are still `spatial`'s, and so is the CRS provider that resolves a name like `EPSG:4326`
  ([`extensions/`](/handbook/usage/extensions/README.md)).
* **The column's CRS reaches R either way.**
  It is an attribute on `wk_wkb`, and PROJJSON in the metadata of the `geoarrow.wkb` field an Arrow result carries,
  and `sf::st_crs()` reads the same CRS from both.
* **sf reads a result through GeoArrow in one call.**
  `sf::st_as_sf(dbGetQueryArrow(con, sql))` gives an `sf` whose geometries and CRS equal the source's,
  and `sf::st_as_sfc()` does the same for the `geoarrow_vctr` column of `as.data.frame()`.
  Both methods are the geoarrow package's, so it has to be loaded first:
  without it, `st_as_sf()` has no method for the stream.
  A `NULL` geometry reads as an empty one.
* **The routes behind `dbSendQuery(arrow = TRUE)` fail on a CRS.**
  `duckdb_fetch_arrow()`, `duckdb_fetch_record_batch()` and `arrow::to_arrow()`, which reads through them,
  fail with `INTERNAL Error: TransactionContext::ActiveTransaction called without active transaction` for a column with a CRS.
  `dbGetQueryArrow()` reads it,
  and so do those routes once the query casts the column to the bare type, as `geom::GEOMETRY`, which drops the CRS.

## Writing

* **Text writes GEOMETRY through `field.types`.**
  A `character` column of `sf::st_as_text()` output with `field.types = c(geom = "GEOMETRY")` lands a `GEOMETRY` column in one statement,
  because the `VARCHAR` cast parses WKT;
  spell the CRS into the type, as `"GEOMETRY('EPSG:4267')"`, to keep it, which needs `spatial` loaded.
  WKB has no such cast:
  `BLOB` to `GEOMETRY` is unimplemented, so the same call over `sf::st_as_binary()` output fails,
  and so do `dbAppendTable()` and a parameter bound to a `GEOMETRY` cast.
  `ST_GeomFromWKB()` does the conversion instead: per query, bound to `?`,
  or once through `ALTER TABLE … ALTER COLUMN … SET DATA TYPE GEOMETRY USING`, which drops the CRS because it names the bare type.
* **GeoArrow WKB writes GEOMETRY with its CRS.**
  Encode the geometry column as WKB,
  as `geoarrow::as_geoarrow_vctr(sf::st_geometry(x), schema = geoarrow::geoarrow_wkb(crs = sf::st_crs(x)))`
  or as a `wk::as_wkb()` column,
  and register `arrow::as_arrow_table(nanoarrow::as_nanoarrow_array_stream(df))` with `duckdb_register_arrow()`;
  `CREATE TABLE ... AS SELECT` from the view writes a `GEOMETRY` column with the CRS,
  which reads back into an `sf` equal to the one written.
  With `spatial` loaded, the type names the CRS by its identifier, as `GEOMETRY('EPSG:4267')`;
  without it, it keeps the PROJJSON it came as, and `sf::st_crs()` reads the same CRS from both.
* **The other GeoArrow encodings do not land as GEOMETRY.**
  What nanoarrow infers for an `sf` column, and what `arrow::as_arrow_table()` makes of one, is a native encoding,
  which lands as nested structs, as `STRUCT(x DOUBLE, y DOUBLE)[][][]` for a multipolygon.
  A native point converts in the query as `geometry::POINT_2D::GEOMETRY`;
  a native polygon casts neither through `POLYGON_2D` nor directly.
  `geoarrow_wkt()` lands as `VARCHAR`, which `::GEOMETRY` parses, and `ST_SetCRS()` gives the CRS back.
  geoarrow cannot write an `sfc` in the large or view layouts of WKB,
  and DuckDB lands those layouts, as its own export makes them, as `GEOMETRY`.
* **An `sf` or `sfc` column is not written, and may not say so.**
  A whole `sf` object handed to `dbWriteTable()` fails inside sf's own `dbWriteTable()` method,
  which writes EWKB hex into a column DuckDB parses as WKT ([#1670](https://github.com/duckdb/duckdb-r/issues/1670));
  a bare `sfc` column is worse: a `POINT` column writes *silently* as `DOUBLE[]`,
  and other geometry types abort with a message naming neither column nor type.
  Convert to text or to GeoArrow WKB first, and take one of the routes above;
  a `wk_wkb` column is no shortcut outside Arrow, because it writes as `BLOB` like any other list of raw vectors, dropping its class and its CRS.
  The duckspatial and duckdbfs packages wrap this.
  What to do about the write side is [`plan/PLAN-spatial-interop.md`](/plan/PLAN-spatial-interop.md)
  ([#117](https://github.com/duckdb/duckdb-r/issues/117)).
* **A `geoarrow_vctr` column writes its indices, silently.**
  The `geoarrow_vctr` that `as.data.frame()` gives for a geometry in an Arrow result
  is an integer vector of indices into the Arrow data it holds.
  `dbWriteTable()` of it, and `dbWriteTableArrow()`, which converts through such a data frame,
  write those integers as an `INTEGER` column, `1, 2, 3`, without an error.
  Convert it with `sf::st_as_sfc()` first, or keep it in Arrow.

## The `spatial` extension's types

* **The `spatial` extension's own types are aliases, and read as what they alias.**
  `POINT_2D`, `POINT_3D`, `POINT_4D`, `BOX_2D` and `BOX_2DF` are structs, and read as data frame columns;
  `LINESTRING_2D` and `LINESTRING_3D` are lists of point structs, and read as lists of data frames;
  `POLYGON_2D` and `POLYGON_3D` are lists of those rings, and read as lists of lists;
  `WKB_BLOB` is a `BLOB`, and reads as raw vectors.
  The same shapes write the plain struct or list, and `field.types` naming the alias casts back to it.
  WKT does not parse into them, but they cast to and from `GEOMETRY` in the query, as `'POINT (1 2)'::GEOMETRY::POINT_2D`.
  Arrow carries the storage without the alias.

## Limitations

* An `sf` object or `sfc` column is not written; a `POINT` column writes silently as `DOUBLE[]`.
* A `geoarrow_vctr` column writes its integer indices through `dbWriteTable()` and `dbWriteTableArrow()`.
* WKB in a `BLOB` column, or a `wk_wkb` column outside Arrow, has no cast to `GEOMETRY`.
* Of the GeoArrow encodings, only WKB lands as `GEOMETRY`.
* Naming a CRS in a type needs `spatial` loaded, and `ALTER ... SET DATA TYPE GEOMETRY` drops the CRS.
* The routes behind `dbSendQuery(arrow = TRUE)`, `arrow::to_arrow()` among them, fail on a column with a CRS.
* `sf::st_read()` of a table does not recognize a `GEOMETRY` column, and returns a data frame
  ([`experiments/2026-08-09-spatial-interop/`](/experiments/2026-08-09-spatial-interop/README.md)).
