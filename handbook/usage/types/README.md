# Types

Every DuckDB type as it crosses to R and back:
what a value of the type becomes when read, which R value writes it again, and what to do where neither works.
The mapping is implemented in [`src/types.cpp`](/src/types.cpp) (R vector to `LogicalType`) and [`src/transform.cpp`](/src/transform.cpp) (the way back).
The list of types is DuckDB's own [documentation](https://duckdb.org/docs/current/sql/data_types/overview) for the release vendored here,
and every entry on this page was measured on DuckDB 1.5.5, in [`experiments/2026-09-26-type-catalog/`](/experiments/2026-09-26-type-catalog/README.md),
[`experiments/2026-09-27-review-limits/`](/experiments/2026-09-27-review-limits/README.md)
or, for geometry route by route, [`experiments/2026-08-09-spatial-interop/`](/experiments/2026-08-09-spatial-interop/README.md).
Which zone labels a timestamp is [`timestamps/`](/handbook/usage/timestamps/README.md)'s,
and the geometry functions are the [`spatial` extension's](https://duckdb.org/docs/current/core_extensions/spatial/overview) to document.

The reference pages `?duckdb_types` and `?duckdb_types_arrow` are this leaf and [`arrow-types/`](/handbook/usage/arrow-types/README.md),
rendered into roxygen under `R/` by [`scripts/types-rd.R`](/scripts/types-rd.R), which leaves this paragraph out.
Edit the leaves, re-run the script and then roxygen; its `--check`, which CI runs, fails while a page is stale.

## The routes

**Reading.**
`dbGetQuery()` converts each column by its type, and seven `dbConnect()` arguments change the shape,
set in [`R/dbConnect__duckdb_driver.R`](/R/dbConnect__duckdb_driver.R).
Their defaults are `bigint = "numeric"`, `array = "none"`, `map = "data.frame"`, `geometry = "blob"`,
`time = "difftime"`, `blob = "list"` and `interval = "difftime"`.
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
* **`BIGINT`** (`INT8`, `LONG`) reads as `numeric`, exact up to 2^53,
  or with `bigint = "integer64"` as `bit64::integer64`, exact but for the minimum.
  An `integer64` column or parameter writes `BIGINT` whatever `bigint` says,
  pinned by [`tests/testthat/test-integer64.R`](/tests/testthat/test-integer64.R).
* **`UBIGINT`** reads as `numeric`, or with `bigint = "integer64"` as `integer64`, which holds the values below 2^63.
  Below 2^63, the `integer64` it reads as writes it back through `field.types`, and its text writes any value.
* **`HUGEINT`, `UHUGEINT`** read as `numeric`, and `bigint` does not change that; their rounding is a limitation (below).
  Their text is exact both ways.
* **`BIGNUM`** (`VARINT`) reads and writes through its text, and through Arrow.
* **`DECIMAL(width, scale)`** (`NUMERIC`) reads as `numeric` at every width; its rounding is a limitation (below).
  Its text is exact both ways, and Arrow writes it exactly.
* **`FLOAT`** (`REAL`) and **`DOUBLE`** read as `numeric`, and `numeric` writes `DOUBLE`.
  `NaN` reads and writes as `NaN`, never as `NA`, and `NA` is `NULL` in both directions.

## Text and binary

The [text](https://duckdb.org/docs/current/sql/data_types/text), [blob](https://duckdb.org/docs/current/sql/data_types/blob)
and [bitstring](https://duckdb.org/docs/current/sql/data_types/bitstring) types, and `UUID`:

* **`VARCHAR`** (`CHAR`, `BPCHAR`, `TEXT`, `STRING`) reads as `character`, and `character` writes it;
  non-UTF-8 text is a limitation (below).
* **`BLOB`** (`BYTEA`, `BINARY`, `VARBINARY`) reads as a list of raw vectors, or with `blob = "blob"` as `blob::blob`,
  pinned by [`tests/testthat/test-blob.R`](/tests/testthat/test-blob.R).
  A `blob::blob` or a list of raw vectors writes it.
* **`BIT`** (`BITSTRING`) reads and writes through its text.
* **`UUID`** reads as `character`, lowercase and hyphenated.
  `character` writes `VARCHAR`, and `field.types` makes it a `UUID`.

## Dates and times

The [date](https://duckdb.org/docs/current/sql/data_types/date), [time](https://duckdb.org/docs/current/sql/data_types/time),
[timestamp](https://duckdb.org/docs/current/sql/data_types/timestamp) and [interval](https://duckdb.org/docs/current/sql/data_types/interval) types:

* **`DATE`** reads as `Date`, and a `Date` writes it, stored as double or as integer.
* **`TIME`** reads as `difftime` in seconds, or with `time = "hms"` as `hms::hms`,
  pinned by [`tests/testthat/test-timestamp.R`](/tests/testthat/test-timestamp.R).
  With `time = "hms"`, an `hms` column, data frame field or parameter writes it,
  and a `difftime` that is not an `hms` keeps writing `INTERVAL`; `dbQuoteLiteral()` quotes an `hms` as a `TIME` there.
  Its text writes it through `field.types`, and so does Arrow.
* **`TIME_NS`** reads as `TIME` does, in seconds to the nanosecond,
  pinned by [`tests/testthat/test-timestamp.R`](/tests/testthat/test-timestamp.R).
  Its text writes it through `field.types`, and so does Arrow.
* **`TIMETZ`** (`TIME WITH TIME ZONE`) reads as `TIME` does, as its local time,
  pinned by [`tests/testthat/test-timestamp.R`](/tests/testthat/test-timestamp.R).
  Its text writes it.
* **`TIMESTAMP_S`, `TIMESTAMP_MS`, `TIMESTAMP`** (`DATETIME`) read as `POSIXct`.
  `POSIXct` writes `TIMESTAMP`, the instant in UTC, and `field.types` names the other precisions.
* **`TIMESTAMP_NS`** reads as `POSIXct`.
  `POSIXct` writes it to the microsecond through `field.types`, and Arrow writes it directly.
* **`TIMESTAMPTZ`** (`TIMESTAMP WITH TIME ZONE`) reads as `POSIXct`.
  `POSIXct` writes the plain `TIMESTAMP` of the same instant; `field.types` makes it `TIMESTAMPTZ`,
  and Arrow writes it directly.
* **`INTERVAL`** reads as `difftime` in seconds whatever `time` says, counting a month as 30 days and a day as 24 hours,
  a limitation (below).
  With `interval = "Period"` it reads as a `lubridate::Period` that keeps the months, the days and the time apart,
  the time as whole hours and minutes and the seconds left over, which a double holds to the microsecond.
  lubridate's `%m+%` adds its months and days to a date or a `POSIXct` as DuckDB adds an `INTERVAL`'s;
  its time is a limitation (below).
  Under that option a `Period` column, data frame field or parameter writes it part for part, `NA` in any part as `NULL`,
  and `dbQuoteLiteral()` quotes a `Period` as that `INTERVAL`;
  under the default, a `Period` of seconds alone writes a `DOUBLE` of them.
  A `difftime` in any unit, or an `hms` under the default `time`, writes `INTERVAL`.

## Enums and nested types

The [enum](https://duckdb.org/docs/current/sql/data_types/enum) type,
and the [nested](https://duckdb.org/docs/current/sql/data_types/overview) ones:

* **`ENUM`** reads as `factor`, with every value of the type as a level.
  A `factor` or `ordered` column writes `ENUM` of its levels; a `factor` parameter binds as `VARCHAR`.
* **`ARRAY`** (`INTEGER[3]`) reads with `array = "matrix"`, as a matrix with a row per value.
  A `NULL` array reads as a row of `NA`, the same as an array of `NULL`s.
  A `BLOB` or `GEOMETRY` array is a list matrix without a class of its own,
  and under `blob = "blob"` or `geometry = "wk"` each cell is a `blob` or a `wk_wkb` of length one.
  A matrix column writes it.
* **`LIST`** (`INTEGER[]`) reads as a list of vectors, `NULL` for a `NULL` row, and a list column whose elements share a type writes it.
* **`MAP`** reads as a list of `data.frame(key, value)`, which writes a list of structs unless `field.types` names the map.
  With `map = "list_of"`, the `vctrs::list_of()` it reads as writes back as `MAP` without `field.types`
  ([#200](https://github.com/duckdb/duckdb-r/issues/200)).
  Its text casts to `MAP` in the query and as a parameter.
* **`STRUCT`** (`ROW`) reads as a data frame column, where a `NULL` struct is a row of `NA`, the same as a struct of `NULL`s.
  A data frame column writes it, and a data frame parameter binds a struct per row.
* **`UNION`** reads in the query through `union_tag()`, `union_extract()` or a cast to `VARCHAR`, and an Arrow result carries it.
  A column of a member's type writes it through `field.types`, which picks that member; text picks the `VARCHAR` member.
* **`VARIANT`** reads as a list, each value converted by its own type.
  A column of the value's type writes it through `field.types`; the list it reads as writes as a `LIST` inside the variant.

## Geometry

The [`GEOMETRY`](https://duckdb.org/docs/current/sql/data_types/geometry) type, its coordinate reference system (CRS),
and the `spatial` extension's own types:

* **`GEOMETRY`** reads as WKB.
  With `geometry = "blob"`, the default, it reads as a list of raw vectors whatever `blob` says;
  with `geometry = "wk"`, as `wk_wkb`, carrying the column's CRS as an attribute, which `sf::st_as_sfc()` converts onward, CRS included.
  The type is core since DuckDB 1.5, so reading one needs no extension;
  the geometry functions are the `spatial` extension's ([`extensions/`](/handbook/usage/extensions/README.md)).
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
  `WKB_BLOB` is a `BLOB`, and reads as one.
  The same shapes write the plain struct or list, and `field.types` naming the alias casts back to it.
  They cast to and from `GEOMETRY` in the query, as `'POINT (1 2)'::GEOMETRY::POINT_2D`.

## Everything else

* **An untyped `NULL` comes back as `NA_integer_`,**
  matching the engine's own `SELECT NULL`;
  mapping it to logical `NA` instead was declined ([#155](https://github.com/duckdb/duckdb-r/issues/155)).
  A typed `NULL`, as a scanned logical column or a bound `NA` parameter, round-trips as logical `NA`.
  What `expr_constant(NA)` builds in the relational API is [`relational/`](/handbook/usage/relational/README.md)'s.
* **`JSON`**, the [`json` extension's](https://duckdb.org/docs/current/data/json/json_type) alias of `VARCHAR`, reads as `character`.
  Its text writes it through `field.types`.
* **`INET`**, the [`inet` extension's](https://duckdb.org/docs/current/core_extensions/inet) address type,
  reads as a data frame column whose `address` is a `HUGEINT` read as a double, exact for IPv4.
  Its text reads and writes it exactly.

## Limitations

* `BIT`, `BIGNUM` and `UNION` have no R vector,
  so `dbGetQuery()` and `dbExecute()` refuse a column of one, or of anything nesting one, by name and before the statement runs,
  and `dplyr::tbl()` cannot open a table holding one ([`integrations/`](/handbook/usage/integrations/README.md)).
* `dbColumnInfo()` names the class a column reads as under the default options, whatever the connection sets:
  `numeric` for a `BIGINT` read as `integer64`, `difftime` for a `TIME` read as an `hms` or an `INTERVAL` read as a `Period`,
  `raw` for a `BLOB` read as a `blob`, and `data.frame` for a `MAP` read as a `list_of`.
* `dbCreateTable()` takes its column types from `dbDataType()`,
  which says `TIME` for `difftime` and `hms`, `DOUBLE` for `integer64`, `VARCHAR` for `factor`, and the element type for a matrix,
  where the write routes give `INTERVAL`, `BIGINT`, `ENUM` and `ARRAY`,
  so a `difftime` column fails to append to the table it created
  ([`plan/PLAN-type-documentation.md`](/plan/PLAN-type-documentation.md)).
  Under `time = "hms"` the two agree on time,
  since a connection's `dbDataType()` then says `INTERVAL` for a `difftime` that is not an `hms`.
  `dbWriteTable()` types a `list_of` map through `dbDataType()` as well, where a map value writes as a list cell does,
  so a map of `difftime` or `hms` values fails to write, typed `TIME` and written `INTERVAL`;
  under `time = "hms"` a `difftime` value is typed `INTERVAL` and writes, and an `hms` one still fails.
  For a data frame column, `dbDataType()` gives its field's type when it has one field and fails when it has several,
  and `dbCreateTable()` and `sqlCreateTable()` with it, where `dbWriteTable()` writes a `STRUCT`.
* Attribute classes do not cross, in either direction, through Arrow too:
  a `units` column writes plain `DOUBLE` and reads back plain `numeric`, and nothing warns
  ([#590](https://github.com/duckdb/duckdb-r/issues/590)).
* `rel_from_df()`, which duckplyr builds on, refuses some columns rather than converting them
  ([`relational/`](/handbook/usage/relational/README.md)).
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
  `enc2utf8()` re-encodes only what R has marked, and a string read from a file whose encoding the reader was not told is marked `"unknown"`:
  it passes through untouched, still invalid.
  Which is why the cheapest place to fix this is the reader.
* A raw vector column is refused with a message naming neither the column nor its class
  ([`plan/PLAN-type-documentation.md`](/plan/PLAN-type-documentation.md)).
* `TIME_NS` reads as a double of seconds, which holds a nanosecond up to 24:00:00 only to within 1/128 of one,
  so `round(as.numeric(x) * 1e9)` recovers it, and an `hms` prints it to the microsecond.
* `TIMESTAMP_NS` reads truncated to the microsecond, with a warning the first time in a session and never again,
  `TIMETZ` without its offset, pinned by [`tests/testthat/test-timestamp.R`](/tests/testthat/test-timestamp.R),
  and `infinity` and `-infinity` as a finite date millions of years away or a finite instant, not as `Inf`.
  Read as a `difftime`, an `INTERVAL` counts a month as 30 days and a day as 24 hours,
  so which part was months or days is lost, unless `interval = "Period"`.
  Under it, an `ARRAY` of `INTERVAL` is refused before the statement runs,
  and a `Period` whose parts do not fit is refused naming its column or parameter.
  A `Period` built in R has its seconds rounded to the microsecond on write,
  and a double of seconds past 2^33 of them, some 272 years, does not hold each microsecond.
* lubridate adds a `Period`'s hours, minutes and seconds as clock time, where DuckDB adds an `INTERVAL`'s microseconds as elapsed time,
  so across a daylight saving change `%m+%` lands an hour off, or on `NA` inside the skipped hour
  ([`experiments/2026-09-28-interval-mappings/`](/experiments/2026-09-28-interval-mappings/README.md)).
* A `Period` with a year, month, day, hour or minute is refused without `interval = "Period"`, naming its column or parameter,
  and so is one in a list cell or a map value under either `interval`, which writes a `DOUBLE` of the seconds there.
* `INTERVAL` has no clock mapping, and `interval = "Period"` is the exact one:
  one clock duration has one precision, so a month does not combine with a day and a month part has no exact form;
  its days would be 86400 seconds, where DuckDB adds a calendar day to a `TIMESTAMPTZ` across a daylight saving change;
  clock's constructors take 32-bit counts, and its arithmetic wraps past 64 bits without an error;
  and `rel_to_altrep()` could build a duration lazily only through clock's undocumented fields.
  Converting a `Period` to a clock duration is for clock and lubridate to offer, which neither does today,
  and not for the package to bridge ([`experiments/2026-09-28-interval-mappings/`](/experiments/2026-09-28-interval-mappings/README.md)).
* A `POSIXct` writes with its zone label dropped, and a `difftime` or `hms` without its unit.
* `NaN`, `Inf` and `-Inf` in a `Date`, `difftime` or `POSIXct` stored as double write as far-off negative values, not as `NULL` or infinity:
  on x86_64, the `DATE` 5877642-06-23 (BC), an `INTERVAL` of -106751991 days, and a `TIMESTAMP` no cast to `VARCHAR` accepts,
  because only `NA` is taken for missing ([`src/types.cpp`](/src/types.cpp)).
* A `POSIXct` stored as integer writes, binds and creates `INTEGER`, not `TIMESTAMP`, and reads back as `integer`.
* `TIMETZ`, `GEOMETRY` and `VARIANT` do not write back as themselves from the value R reads,
  and `TIME` does only under `time = "hms"`, the one R route to it outside Arrow.
  Under the default `time`, `difftime` and `hms` write `INTERVAL`, which does not cast to `TIME`,
  so `field.types`, `dbAppendTable()` and a parameter all fail with that cast error.
  Under `time = "hms"`, an `hms` writes `TIME` rounded to the microsecond, one in a list cell still writes `INTERVAL`,
  an `hms` no longer appends to an `INTERVAL` column, because `TIME` does not cast to `INTERVAL`,
  and a value outside 00:00:00 to 24:00:00, `NaN` and the infinities included, is refused naming its column or parameter.
* No R class writes `TIME_NS`, because DuckDB casts neither `TIME` nor `INTERVAL` to it:
  a `TIME_NS` read back does not append to its column, not even as an `hms` under `time = "hms"`,
  and `field.types` naming it fails on an `hms` or a `difftime` the same way.
* An `ordered` factor writes an unordered `ENUM`.
* An `ARRAY` column under the default `array = "none"` is refused with a hint to `array = "matrix"`, and only once the statement has run,
  so an `INSERT ... RETURNING` of one has inserted its rows by the time it fails.
  An array holding nested values is refused, pinned by [`tests/testthat/test-array.R`](/tests/testthat/test-array.R),
  and so is a matrix parameter.
* `MAP` does not write from its text through `field.types` or `dbAppendTable()`,
  which wrap a `MAP` column in `map_from_entries()`, and that takes a list of structs, not text;
  the list it reads as does not bind as a `MAP` parameter.
* `VARIANT` fails on a value whose type R cannot hold.
* A `GEOMETRY` column read under the default `geometry = "blob"` loses its CRS,
  and naming a CRS in a type, as `EPSG:4326`, needs `spatial` loaded, which resolves the name
  ([`extensions/`](/handbook/usage/extensions/README.md)).
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
* An `INET` address reads rounded for IPv6.

*To deepen: measure what `rel_to_df()` and `rel_to_altrep()` make of each type,
which neither record covers ([`plan/PLAN-type-documentation.md`](/plan/PLAN-type-documentation.md)).*
