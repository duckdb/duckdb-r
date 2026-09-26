# Spatial types

Geometry across the R boundary:
the core `GEOMETRY` type and its coordinate reference system (CRS), the `spatial` extension's own types,
and where R's spatial packages meet them.
The geometry functions are the [`spatial` extension's](https://duckdb.org/docs/current/core_extensions/spatial/overview) to document,
and every other type is [`types/`](/handbook/usage/types/README.md)'s.
The surface is measured route by route in [`experiments/2026-08-09-spatial-interop/`](/experiments/2026-08-09-spatial-interop/README.md),
and each type beside the others in [`experiments/2026-09-26-type-catalog/`](/experiments/2026-09-26-type-catalog/README.md).

* **Geometry comes back as WKB by default.**
  `dbConnect(geometry = )` chooses: `"blob"`, the default set in [`R/dbConnect__duckdb_driver.R`](/R/dbConnect__duckdb_driver.R),
  returns raw vectors; `"wk"` returns `wk_wkb`, which `sf::st_as_sfc()` converts onward.
  [`GEOMETRY`](https://duckdb.org/docs/current/sql/data_types/geometry) is a core DuckDB type since 1.5,
  so reading one needs no extension,
  but the geometry functions are still `spatial`'s, and so is the CRS provider that resolves a name like `EPSG:4326`
  ([`extensions/`](/handbook/usage/extensions/README.md)).
* **The column's CRS reaches R either way.**
  It is an attribute on `wk_wkb`, and PROJJSON in the metadata of the `geoarrow.wkb` field an Arrow result carries:
  the engine registers that Arrow extension type in both directions, so geometry and CRS also round-trip through Arrow.
* **Writing a geometry means writing WKT, not WKB.**
  A `character` column of `sf::st_as_text()` output with `field.types = c(geom = "GEOMETRY")` lands a `GEOMETRY` column in one statement,
  because the `VARCHAR` cast parses WKT;
  spell the CRS into the type, as `"GEOMETRY('EPSG:4267')"`, to keep it, which needs `spatial` loaded.
  WKB has no such cast:
  `BLOB` to `GEOMETRY` is unimplemented, so the same call over `sf::st_as_binary()` output fails,
  and so do `dbAppendTable()` and a parameter bound to a `GEOMETRY` cast.
  `ST_GeomFromWKB()` does the conversion instead: per query, bound to `?`,
  or once through `ALTER TABLE … ALTER COLUMN … SET DATA TYPE GEOMETRY USING`, which drops the CRS because it names the bare type.
* **An `sf` or `sfc` column is not written, and may not say so.**
  A whole `sf` object handed to `dbWriteTable()` fails inside sf's own `dbDataType()` method,
  which writes EWKB hex into a column DuckDB parses as WKT ([#1670](https://github.com/duckdb/duckdb-r/issues/1670));
  a bare `sfc` column is worse: a `POINT` column writes *silently* as `DOUBLE[]`,
  and other geometry types abort with a message naming neither column nor type.
  Convert to text or to WKB first, and take one of the routes above;
  a `wk_wkb` column is no shortcut, because it writes as `BLOB` like any other list of raw vectors, dropping its class and its CRS.
  The duckspatial and duckdbfs packages wrap this.
  What to do about the write side is [`plan/PLAN-spatial-interop.md`](/plan/PLAN-spatial-interop.md)
  ([#117](https://github.com/duckdb/duckdb-r/issues/117)).
* **The `spatial` extension's own types are aliases, and read as what they alias.**
  `POINT_2D`, `POINT_3D`, `POINT_4D`, `BOX_2D` and `BOX_2DF` are structs, and read as data frame columns;
  `LINESTRING_2D` and `LINESTRING_3D` are lists of point structs, and read as lists of data frames;
  `POLYGON_2D` and `POLYGON_3D` are lists of those rings, and read as lists of lists;
  `WKB_BLOB` is a `BLOB`, and reads as raw vectors.
  The same shapes write the plain struct or list, and `field.types` naming the alias casts back to it.
  WKT does not parse into them, but they cast to and from `GEOMETRY` in the query, as `'POINT (1 2)'::GEOMETRY::POINT_2D`.
  Arrow carries the storage without the alias.
