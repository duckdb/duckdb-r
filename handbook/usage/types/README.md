# Types

Every DuckDB type as it crosses to R and back:
what a value of the type becomes when read, which R value writes it again, and what to do where neither works.
The mapping is implemented in [`src/types.cpp`](/src/types.cpp) (R vector to `LogicalType`) and [`src/transform.cpp`](/src/transform.cpp) (the way back).
The list of types is DuckDB's own [documentation](https://duckdb.org/docs/current/sql/data_types/overview) for the release vendored here,
and every entry on this page was measured on DuckDB 1.5.5, in [`experiments/2026-09-26-type-catalog/`](/experiments/2026-09-26-type-catalog/README.md),
[`experiments/2026-09-27-review-limits/`](/experiments/2026-09-27-review-limits/README.md),
[`experiments/2026-09-28-type-rereview/`](/experiments/2026-09-28-type-rereview/README.md)
or, for geometry route by route, [`experiments/2026-08-09-spatial-interop/`](/experiments/2026-08-09-spatial-interop/README.md).
Which zone labels a timestamp is [`timestamps/`](/handbook/usage/timestamps/README.md)'s.

The reference pages `?duckdb_types` and `?duckdb_types_arrow` are this leaf and [`arrow-types/`](/handbook/usage/arrow-types/README.md),
rendered into roxygen under `R/` by [`scripts/types-rd.R`](/scripts/types-rd.R), which leaves this paragraph out.
Edit the leaves, re-run the script and then roxygen; its `--check`, which CI runs, fails while a page is stale.

## The routes

**Reading.**
`dbGetQuery()` converts each column by its type, and four `dbConnect()` arguments change the shape,
with defaults `bigint = "numeric"`, `array = "none"`, `map = "data.frame"` and `geometry = "blob"`,
set in [`R/dbConnect__duckdb_driver.R`](/R/dbConnect__duckdb_driver.R).
`dbGetQueryArrow()` hands out the engine's own Arrow export instead,
and what each type becomes there, and in the R readers that convert the stream, is [`arrow-types/`](/handbook/usage/arrow-types/README.md)'s.
A cast to `VARCHAR` in the query reads any type as text.

**Writing.**
`dbWriteTable()` and `duckdb_register()` take a column's type from its R class,
and `field.types` casts that column to the type it names, from any value that casts.
`dbAppendTable()` casts to the type of the existing column, and a parameter (`params =`) binds by its R class, cast by the query.
A `character` column holding a value's text form writes every scalar type through `field.types`, because DuckDB parses the text it prints.
Arrow, registered with `duckdb_register_arrow()`, writes the types no R class does.

## Numbers

The [numeric](https://duckdb.org/docs/current/sql/data_types/numeric) and [boolean](https://duckdb.org/docs/current/sql/data_types/boolean) types:

* **`BOOLEAN`** (`BOOL`, `LOGICAL`) reads as `logical`, and `logical` writes it.
* **`TINYINT`, `SMALLINT`, `UTINYINT`, `USMALLINT`** read as `integer`, exactly.
  `integer` writes `INTEGER`, and `field.types` names the narrower type.
* **`INTEGER`** (`INT4`, `INT`, `SIGNED`) reads as `integer`, exactly but for the minimum, and `integer` writes it.
* **`UINTEGER`** reads as `numeric`, exactly; `numeric` writes `DOUBLE`, and `field.types` names `UINTEGER`.
* **`BIGINT`** (`INT8`, `LONG`) reads as `numeric`, exact up to 2^53, and its rounding past that is a limitation (below).
  With `bigint = "integer64"` it reads as `bit64::integer64`, exact but for the minimum.
  An `integer64` column or parameter writes `BIGINT` whatever `bigint` says,
  pinned by [`tests/testthat/test-integer64.R`](/tests/testthat/test-integer64.R).
* **`UBIGINT`** reads as `numeric`, exact up to 2^53, and its rounding past that is a limitation (below).
  With `bigint = "integer64"` it reads as `integer64`, which holds the values below 2^63.
  Below 2^63, the `integer64` it reads as writes it back through `field.types`, and its text writes any value.
* **`HUGEINT`, `UHUGEINT`** read as `numeric`, and `bigint` does not change that; their rounding is a limitation (below).
  Their text is exact both ways.
* **`BIGNUM`** (`VARINT`) reads and writes through its text, and Arrow writes it ([`arrow-types/`](/handbook/usage/arrow-types/README.md)).
* **`DECIMAL(width, scale)`** (`NUMERIC`) reads as `numeric` at every width; its rounding is a limitation (below).
  Its text is exact both ways, and Arrow writes it exactly.
* **`FLOAT`** (`REAL`) and **`DOUBLE`** read as `numeric`, and `numeric` writes `DOUBLE`.
  `NaN` reads and writes as `NaN`, never as `NA`, and `NA` is `NULL` in both directions.

## Text and binary

The [text](https://duckdb.org/docs/current/sql/data_types/text), [blob](https://duckdb.org/docs/current/sql/data_types/blob)
and [bitstring](https://duckdb.org/docs/current/sql/data_types/bitstring) types, and `UUID`:

* **`VARCHAR`** (`CHAR`, `BPCHAR`, `TEXT`, `STRING`) reads as `character`, and `character` writes it;
  non-UTF-8 text is a limitation (below).
* **`BLOB`** (`BYTEA`, `BINARY`, `VARBINARY`) reads as a list of raw vectors.
  A `blob::blob` or a list of raw vectors writes it.
* **`BIT`** (`BITSTRING`) reads and writes through its text.
* **`UUID`** reads as `character`, lowercase and hyphenated.
  `character` writes `VARCHAR`, and `field.types` makes it a `UUID`.

## Dates and times

The [date](https://duckdb.org/docs/current/sql/data_types/date), [time](https://duckdb.org/docs/current/sql/data_types/time),
[timestamp](https://duckdb.org/docs/current/sql/data_types/timestamp) and [interval](https://duckdb.org/docs/current/sql/data_types/interval) types:

* **`DATE`** reads as `Date`, and a `Date` writes it, stored as double or as integer.
* **`TIME`** reads as `difftime` in seconds.
  Its text writes it through `field.types`, and so does Arrow ([`arrow-types/`](/handbook/usage/arrow-types/README.md)).
* **`TIME_NS`** reads through Arrow, and to the microsecond through a cast to `TIME` in the query.
  Its text writes it, and so does Arrow.
* **`TIMETZ`** (`TIME WITH TIME ZONE`) reads as the `difftime` of its local time,
  pinned by [`tests/testthat/test-timestamp.R`](/tests/testthat/test-timestamp.R).
  The offset it drops is a limitation (below).
  Its text writes it.
* **`TIMESTAMP_S`, `TIMESTAMP_MS`, `TIMESTAMP`** (`DATETIME`) read as `POSIXct`.
  `POSIXct` writes `TIMESTAMP`, the instant in UTC, and `field.types` names the other precisions.
* **`TIMESTAMP_NS`** reads as `POSIXct`.
  `POSIXct` writes it to the microsecond through `field.types`, and Arrow writes it directly.
* **`TIMESTAMPTZ`** (`TIMESTAMP WITH TIME ZONE`) reads as `POSIXct`.
  `POSIXct` writes the plain `TIMESTAMP` of the same instant; `field.types` makes it `TIMESTAMPTZ`,
  and Arrow writes it directly.
* **`INTERVAL`** reads as `difftime` in seconds, counting a month as 30 days and a day as 24 hours.
  A `difftime` in any unit, or an `hms`, writes `INTERVAL`.

## Enums and nested types

The [enum](https://duckdb.org/docs/current/sql/data_types/enum) type,
and the [nested](https://duckdb.org/docs/current/sql/data_types/overview) ones:

* **`ENUM`** reads as `factor`, with every value of the type as a level.
  A `factor` or `ordered` column writes `ENUM` of its levels; a `factor` parameter binds as `VARCHAR`.
* **`ARRAY`** (`INTEGER[3]`) reads with `array = "matrix"`, as a matrix with a row per value.
  A matrix column writes it.
* **`LIST`** (`INTEGER[]`) reads as a list of vectors, `NULL` for a `NULL` row, and a list column whose elements share a type writes it.
* **`MAP`** reads as a list of `data.frame(key, value)`, which writes a list of structs unless `field.types` names the map.
  With `map = "list_of"`, the `vctrs::list_of()` it reads as writes back as `MAP` without `field.types`
  ([#200](https://github.com/duckdb/duckdb-r/issues/200)),
  and a list column of named lists writes a list of structs, an entry per name,
  valued by the first element of the name's value, or by `NULL` where that value is `NULL` or empty,
  pinned by [`tests/testthat/test-map.R`](/tests/testthat/test-map.R).
  Its text casts to `MAP` in the query and as a parameter.
* **`STRUCT`** (`ROW`) reads as a data frame column.
  A data frame column writes it, and a data frame parameter binds a struct per row.
* **`UNION`** reads in the query through `union_tag()`, `union_extract()` or a cast to `VARCHAR`, and an Arrow result carries it.
  A column of a member's type writes it through `field.types`, which picks that member; text picks the `VARCHAR` member.
* **`VARIANT`** reads as a list, each value converted by its own type.
  A column of the value's type writes it through `field.types`.

## Geometry

The [`GEOMETRY`](https://duckdb.org/docs/current/sql/data_types/geometry) type, its coordinate reference system (CRS),
and the `spatial` extension's own types:

* **`GEOMETRY`** reads as WKB.
  With `geometry = "blob"`, the default, it reads as a list of raw vectors;
  with `geometry = "wk"`, as `wk_wkb`, carrying the column's CRS as an attribute, which `sf::st_as_sfc()` converts onward, CRS included.
  The type is core since DuckDB 1.5, so reading one needs no extension;
  the geometry functions are the [`spatial` extension's](https://duckdb.org/docs/current/core_extensions/spatial/overview)
  ([`extensions/`](/handbook/usage/extensions/README.md)).
  Arrow carries the column as GeoArrow WKB with its CRS, in both directions ([`arrow-types/`](/handbook/usage/arrow-types/README.md)).
* **WKT writes `GEOMETRY`.**
  A `character` column of WKT, as `sf::st_as_text()` makes it, writes a `GEOMETRY` column with `field.types = c(geom = "GEOMETRY")`
  and appends to one with `dbAppendTable()`, because the cast from `VARCHAR` parses WKT.
  Naming the CRS in the type, as `"GEOMETRY('EPSG:4267')"`, gives the column its CRS.
  Writing WKB as raw vectors, an `sf` object or an `sfc` column is a limitation (below).
* **The `spatial` extension's own types are aliases, and read as what they alias.**
  `POINT_2D`, `POINT_3D`, `POINT_4D`, `BOX_2D` and `BOX_2DF` are structs, and read as data frame columns;
  `LINESTRING_2D` and `LINESTRING_3D` are lists of point structs, and read as lists of data frames;
  `POLYGON_2D` and `POLYGON_3D` are lists of those rings, and read as lists of lists;
  `WKB_BLOB` is a `BLOB`, and reads as raw vectors.
  The same shapes write the plain struct or list, and `field.types` naming the alias casts back to it.
  They cast to `GEOMETRY` in the query,
  and the point, linestring, polygon and WKB types cast from it, as `'POINT (1 2)'::GEOMETRY::POINT_2D`.

## Everything else

* **An untyped `NULL` comes back as `NA_integer_`,**
  matching the engine's own `SELECT NULL`;
  mapping it to logical `NA` instead was declined ([#155](https://github.com/duckdb/duckdb-r/issues/155)).
  A typed `NULL`, as a scanned logical column or a bound `NA` parameter, round-trips as logical `NA`.
  What `expr_constant(NA)` builds in the relational API is [`relational/`](/handbook/usage/relational/README.md)'s.
* **`JSON`**, the [`json` extension's](https://duckdb.org/docs/current/data/json/json_type) alias of `VARCHAR`, reads as `character`.
  Its text writes it through `field.types`.
* **`INET`**, the [`inet` extension's](https://duckdb.org/docs/current/core_extensions/inet) address type,
  reads as a data frame column whose `address` is a `HUGEINT` read as a double, exact for IPv4;
  an IPv6 address is a limitation (below).
  Its text reads and writes it exactly.

## Limitations

* `BIT`, `BIGNUM`, `TIME_NS` and `UNION` have no R vector,
  so `dbGetQuery()` and `dbExecute()` refuse a column of one, or of anything nesting one, by name and before the statement runs.
  What that does to `dplyr::tbl()` is [`integrations/`](/handbook/usage/integrations/README.md)'s.
* `dbCreateTable()` takes its column types from `dbDataType()`,
  which says `TIME` for `difftime` and `hms`, `DOUBLE` for `integer64`, `VARCHAR` for `factor`, and the element type for a matrix,
  where the write routes give `INTERVAL`, `BIGINT`, `ENUM` and `ARRAY`,
  so a `difftime` column fails to append to the table it created
  ([`plan/PLAN-type-documentation.md`](/plan/PLAN-type-documentation.md)).
  For a data frame column, `dbDataType()` gives its field's type when it has one field and fails when it has several,
  and `dbCreateTable()` and `sqlCreateTable()` with it, where `dbWriteTable()` writes a `STRUCT`.
* Attribute classes do not cross, in either direction, through Arrow too:
  a `units` column writes plain `DOUBLE` and reads back plain `numeric`, and nothing warns
  ([#590](https://github.com/duckdb/duckdb-r/issues/590)).
* `rel_from_df()`, which duckplyr builds on, refuses some columns rather than converting them,
  and `rel_to_altrep()` reads an `ARRAY` column with the wrong shape ([`relational/`](/handbook/usage/relational/README.md)).
* The `INTEGER` minimum, -2147483648, is R's `NA_integer_` and reads as `NA`,
  and under `bigint = "integer64"` so does the `BIGINT` minimum, which is `integer64`'s `NA`.
* `HUGEINT`, `UHUGEINT` and `DECIMAL` past a double's 15 to 17 significant digits,
  and `BIGINT` and `UBIGINT` past 2^53, read as rounded doubles;
  under `bigint = "integer64"`, a `UBIGINT` of 2^63 reads as `NA`, and one past it wraps to a negative number.
* A string holding a NUL byte is refused on the way out, pinned by [`tests/testthat/test-null_byte.R`](/tests/testthat/test-null_byte.R).
* UTF-8 is required, strictly.
  DuckDB checks string validity and rejects invalid UTF-8;
  this is deliberate engine behavior, not a bug ([#12](https://github.com/duckdb/duckdb-r/issues/12)).
  R is the lenient side: it carries the bytes and prints them,
  so `validUTF8()`, not the console, is what agrees with the engine.
  Repairing means naming the encoding the bytes are actually in, as `iconv(x, from = "latin1", to = "UTF-8")`,
  and `iconv()` yields `NA` for what it cannot convert unless `sub =` says otherwise,
  so a repair that fails shows up as missing data.
  `enc2utf8()` re-encodes only what R has marked,
  and a string read from a file whose encoding the reader was not told is marked `"unknown"`:
  it passes through untouched, still invalid.
  Which is why the cheapest place to fix this is the reader.
* A raw vector column is refused with a message naming neither the column nor its class
  ([`plan/PLAN-type-documentation.md`](/plan/PLAN-type-documentation.md)).
* `TIMESTAMP_NS` reads truncated to the microsecond, with a warning the first time in a session and never again,
  `TIMETZ` without its offset, pinned by [`tests/testthat/test-timestamp.R`](/tests/testthat/test-timestamp.R),
  and `infinity` and `-infinity` as a finite date millions of years away or a finite instant, not as `Inf`.
  Which part of an `INTERVAL` was months or days is lost.
* A `POSIXct` writes with its zone label dropped, and a `difftime` or `hms` without its unit.
* `NaN`, `Inf` and `-Inf` in a `Date`, `difftime` or `POSIXct` stored as double write as far-off negative values, not as `NULL` or infinity:
  on x86_64, the `DATE` 5877642-06-23 (BC), an `INTERVAL` of -106751991 days, and a `TIMESTAMP` no cast to `VARCHAR` accepts,
  because only `NA` is taken for missing ([`src/types.cpp`](/src/types.cpp)).
* A `POSIXct` stored as integer writes, binds and creates `INTEGER`, not `TIMESTAMP`, and reads back as `integer`.
* `TIME`, `TIMETZ`, `GEOMETRY` and `VARIANT` do not write back as themselves from the value R reads.
  `difftime` and `hms` write `INTERVAL`, which does not cast to `TIME`,
  so `field.types`, `dbAppendTable()` and a parameter all fail with that cast error.
  The list a `VARIANT` reads as writes as a `LIST` inside the variant.
* An `ordered` factor writes an unordered `ENUM`.
* An `ARRAY` column under the default `array = "none"` is refused with a hint to `array = "matrix"`, and only once the statement has run,
  so an `INSERT ... RETURNING` of one has inserted its rows by the time it fails.
  An array holding nested values is refused, pinned by [`tests/testthat/test-array.R`](/tests/testthat/test-array.R),
  and so is a matrix parameter.
* A `NULL` array read with `array = "matrix"` and a `NULL` struct both read as a row of `NA`,
  and cannot be told from an array or a struct of `NULL`s.
* A matrix that also carries a class (`Date`, `POSIXct`, `difftime`, `hms` or `factor`) is refused as a column and as a parameter,
  and an array of more than two dimensions as a column, unless either holds one value per row,
  pinned by [`tests/testthat/test-array.R`](/tests/testthat/test-array.R).
  As a parameter, that array binds a row per value and loses its shape, and in a list cell either kind flattens to its values.
  `dbDataType()`, and so `dbCreateTable()`, types a classed matrix as its class's scalar type.
* `MAP` does not write from its text through `field.types` or `dbAppendTable()`,
  which wrap a `MAP` column in `map_from_entries()`, and that takes a list of structs, not text;
  the list it reads as does not bind as a `MAP` parameter.
* `VARIANT` fails on a value whose type R cannot hold.
* A `GEOMETRY` column read under the default `geometry = "blob"` loses its CRS.
  A CRS named in a type needs `spatial` loaded, which resolves the name ([`extensions/`](/handbook/usage/extensions/README.md)),
  unless the core knows it: `GEOMETRY('OGC:CRS84')` binds without `spatial`, and `GEOMETRY('EPSG:4267')` does not.
  The core knows the systems [`default_coordinate_systems.cpp`](/src/duckdb/src/catalog/default/default_coordinate_systems.cpp) lists.
* WKB does not write `GEOMETRY`, because `BLOB` has no cast to it:
  `field.types = c(geom = "GEOMETRY")`, `dbAppendTable()` and a parameter bound to a `GEOMETRY` cast
  all fail on `sf::st_as_binary()` output,
  and a `wk_wkb` column writes `BLOB`, without its class or CRS.
  Convert in SQL with `ST_GeomFromWKB()`, in the query or around a bound `?`,
  and keep a CRS with `ST_SetCRS()` in a `CREATE TABLE ... AS SELECT`;
  `ALTER TABLE ... SET DATA TYPE GEOMETRY USING` names the bare type, so the column has no CRS.
* `sf` does not write.
  `dbWriteTable()` of an `sf` object fails in sf's own method,
  which writes EWKB hex into a column DuckDB parses as WKT ([#1670](https://github.com/duckdb/duckdb-r/issues/1670));
  an `sfc` column of points writes silently as `DOUBLE[]`,
  and of any other geometry type aborts with a message naming neither column nor type;
  and `duckdb_register()` of an `sf` object types its geometry as nested `DOUBLE` arrays, in a view that fails when read.
  Write WKT, or GeoArrow WKB through Arrow; the duckspatial and duckdbfs packages wrap this
  ([`plan/PLAN-spatial-interop.md`](/plan/PLAN-spatial-interop.md), [#117](https://github.com/duckdb/duckdb-r/issues/117)).
* `sf::st_read()` of a table does not recognize a `GEOMETRY` column, and returns a data frame.
* WKT does not parse into the `spatial` extension's own types.
* `GEOMETRY` does not cast to `BOX_2D` or `BOX_2DF`, failing with "Unimplemented type for cast";
  `ST_Extent()` gives a geometry's `BOX_2D`.
* An IPv6 `INET` address reads as the double of the `HUGEINT` the engine stores, which is the address minus 2^127:
  `'::1'::INET` reads as `-1.7e38`, and its text as `::1`.

*To deepen: measure what `rel_to_df()` and `rel_to_altrep()` make of each type,
which no record covers beyond an `ARRAY` column ([`plan/PLAN-type-documentation.md`](/plan/PLAN-type-documentation.md)).*
