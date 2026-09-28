# Arrow types

Every DuckDB type as it crosses to R through Arrow and back:
the Arrow type the engine exports it as, what the two R readers make of that,
which Arrow type writes it again, and which R functions keep Arrow's types on the way in.
The routes through R vectors are [`types/`](/handbook/usage/types/README.md)'s,
and how a stream behaves, when it drains and what invalidates it, is [`integrations/`](/handbook/usage/integrations/README.md)'s.
Every entry on this page was measured on DuckDB 1.5.5, nanoarrow 0.9.0 and arrow 25.0.1
in [`experiments/2026-09-27-arrow-types/`](/experiments/2026-09-27-arrow-types/README.md),
and geometry also with geoarrow 0.4.4 and sf 1.1-3 in [`experiments/2026-09-27-geoarrow/`](/experiments/2026-09-27-geoarrow/README.md).

## The routes

**Reading.**
Every function that returns Arrow hands out the engine's own export, under the connection's settings:
`dbGetQueryArrow()`, `dbFetchArrow()` and `dbFetchArrowChunk()` after `dbSendQueryArrow()`, `dbReadTableArrow()`,
`duckdb_fetch_arrow()` and `duckdb_fetch_record_batch()` after `dbSendQuery(arrow = TRUE)`, and `arrow::to_arrow()`.
No R vector exists until a reader converts the stream,
and the two readers differ, so each entry below names both:
nanoarrow's `as.data.frame()`, and arrow's `as.data.frame()` of `arrow::as_arrow_table()`.

**The export settings** are DuckDB's, set with `SET`, and each changes the Arrow type of some columns:

* `arrow_lossless_conversion = true` exports each type that has no exact Arrow counterpart as an extension type that names it,
  so that DuckDB, or another Arrow consumer that knows the name, gets the type back.
  Where nanoarrow falls back to the storage of one, the entries below say so.
* `arrow_large_buffer_size = true` gives strings, binary data and lists 64-bit offsets,
  as `large_string`, `large_binary` and `large_list`, which both readers convert as they convert the others.
* `arrow_output_version`, `'1.0'` by default, gates the newer layouts.
  From `'1.4'`, binary data exports as `binary_view`,
  and `produce_arrow_string_view = true` and `arrow_output_list_view = true` take effect, as `string_view` and `list_view`;
  with an older version those two change nothing.
  From `'1.5'`, a `DECIMAL` up to width 9 exports as `decimal32` and up to width 18 as `decimal64`.
  nanoarrow converts `string_view` and `binary_view`.

**Writing.**
Only the routes that let DuckDB scan the Arrow data keep its types:
`duckdb_register_arrow()`, and `arrow::to_duckdb()`, which calls it.
`duckdb_register_arrow()` takes whatever `arrow::Scanner$create()` scans ([`R/register.R`](/R/register.R)).
Nothing is copied: the result is a view, and `CREATE TABLE ... AS SELECT * FROM` it writes a table.
A registered arrow `Table` is scanned by every query, and a `RecordBatchReader` by the first only, a limitation (below).
Every other route converts through an R data frame, so a column lands as the type its R vector writes ([`types/`](/handbook/usage/types/README.md)).
`dbWriteTableArrow()`, `dbCreateTableArrow()` and `dbAppendTableArrow()` are DBI's defaults, which do that batch by batch.
`dbBindArrow()` converts the same way, then binds by position.

## Reading

### Numbers

* **`BOOLEAN`** exports as `bool` and reads as `logical`;
  with `arrow_lossless_conversion`, as `arrow.bool8`, which nanoarrow reads as the `integer` of its storage.
* **`TINYINT`, `SMALLINT`, `INTEGER`, `UTINYINT`, `USMALLINT`** export as `int8`, `int16`, `int32`, `uint8` and `uint16`,
  and read as `integer`.
* **`UINTEGER`** exports as `uint32`.
  nanoarrow reads it as `numeric`; arrow reads it as `integer` when every value fits, and as `numeric` otherwise.
* **`BIGINT`** exports as `int64`.
  nanoarrow reads it as `numeric`, exact up to 2^53.
  arrow reads it as `integer` when every value fits and as `bit64::integer64` otherwise, exactly,
  or as `integer64` always under `options(arrow.int64_downcast = FALSE)`.
* **`UBIGINT`** exports as `uint64`, and both read it as `numeric`, exact up to 2^53.
* **`HUGEINT`, `UHUGEINT`** export as `decimal128(38, 0)`, and both read them as `numeric`; their rounding is a limitation (below).
  With `arrow_lossless_conversion` they export as `arrow.opaque`, which carries every value.
  Their text reads them exactly ([`types/`](/handbook/usage/types/README.md)).
* **`BIGNUM`** exports as `arrow.opaque` under either setting;
  nanoarrow reads its storage bytes as a `blob`.
* **`DECIMAL(width, scale)`** exports as `decimal128(width, scale)`, or narrower from output version 1.5,
  and both read it as `numeric`; its rounding is a limitation (below).
* **`FLOAT`, `DOUBLE`** export as `float` and `double`, and read as `numeric`.

### Text and binary

* **`VARCHAR`** exports as `string` and reads as `character`.
* **`BLOB`** exports as `binary`; nanoarrow reads it as a `blob::blob`, and arrow as an `arrow_binary` list of raw vectors.
* **`BIT`** exports as `binary`, the bytes DuckDB stores for the bit string, and reads as a `blob` or `arrow_binary` of those bytes.
  With `arrow_lossless_conversion` it exports as `arrow.opaque`, which nanoarrow reads as the same bytes.
  Its text reads it as `0` and `1` ([`types/`](/handbook/usage/types/README.md)).
* **`UUID`** exports as `string`, lowercase and hyphenated, and reads as `character`.
  With `arrow_lossless_conversion` it exports as `arrow.uuid`.

### Dates and times

* **`DATE`** exports as `date32` and reads as `Date`.
* **`TIME`** exports as `time64('us')` and reads as `hms`.
* **`TIME_NS`** exports as `time64('ns')` and reads as `hms`.
* **`TIMETZ`** exports as the `time64('us')` of its local time and reads as `hms`.
  With `arrow_lossless_conversion` it exports as `arrow.opaque`, which keeps the offset.
* **`TIMESTAMP_S`, `TIMESTAMP_MS`, `TIMESTAMP`, `TIMESTAMP_NS`** export as `timestamp` in their own unit, without a zone,
  and read as `POSIXct`.
  The two readers label the same instant differently:
  nanoarrow gives it the zone `UTC`, so it prints the stored clock,
  and arrow gives it none, so it prints in R's session zone, a different clock outside UTC.
* **`TIMESTAMPTZ`** exports as `timestamp('us', zone)`, where the zone is DuckDB's `TimeZone` setting
  ([`timestamps/`](/handbook/usage/timestamps/README.md)), and both readers read it as a `POSIXct` labelled with that zone.
* **`INTERVAL`** exports as `interval_month_day_nano`.

### Enums and nested types

* **`ENUM`** exports as a dictionary of its values; nanoarrow reads it as `character`, and arrow as `factor`.
* **`ARRAY`** exports as a `fixed_size_list` and reads as a list of vectors (`vctrs::list_of()` or `arrow_fixed_size_list`),
  without the `array = "matrix"` that `dbGetQuery()` needs.
* **`LIST`** exports as `list` and reads as a list of vectors (`vctrs::list_of()` or `arrow_list`).
* **`MAP`** exports as `map` and reads as a list of key and value data frames.
* **`STRUCT`** exports as `struct` and reads as a data frame column, a tibble in arrow's case.
* **`UNION`** exports as a `sparse_union`.
  nanoarrow reads it as a data frame with a column per member, `NA` where the value is another member's.

### Everything else

* **`NULL`**, untyped, exports as `int32` and reads as `NA_integer_`, as it does through `dbGetQuery()`.
* **`JSON`** exports as `string` and reads as `character`;
  with `arrow_lossless_conversion` it exports as `arrow.json`, which nanoarrow reads as `character`.
* **`INET`** exports as a struct whose `address` is a `decimal128(38, 0)`, read as a double as through `dbGetQuery()`;
  with `arrow_lossless_conversion` that field becomes `arrow.opaque`.

## Writing

### Arrow types

Each Arrow type lands as one DuckDB type when DuckDB scans it:

* **`bool`, `int8` to `int64`, `uint8` to `uint64`, `float`, `double`** land as `BOOLEAN`, the integer type of the same width and sign,
  `FLOAT` and `DOUBLE`.
* **`decimal32`, `decimal64`, `decimal128`** land as `DECIMAL` of the same width and scale.
* **`string`, `large_string`, `string_view`** land as `VARCHAR`,
  and **`binary`, `large_binary`, `binary_view`, `fixed_size_binary`** as `BLOB`.
* **`date32`, `date64`** land as `DATE`.
* **`time32` and `time64('us')`** land as `TIME`, and **`time64('ns')`** as `TIME_NS`.
* **`timestamp`** without a zone lands as `TIMESTAMP_S`, `TIMESTAMP_MS`, `TIMESTAMP` or `TIMESTAMP_NS` by its unit,
  and with a zone as `TIMESTAMPTZ`, the same instant.
* **`duration`** lands as `INTERVAL` in any unit.
* **`interval_months`** and **`interval_month_day_nano`** land as `INTERVAL`, each part kept.
* **`list`, `large_list`, `list_view`** land as `LIST`, and **`fixed_size_list`** as `ARRAY`.
* **`struct`** lands as `STRUCT`, **`map`** as `MAP`, and **`sparse_union`** as `UNION`.
  Arrow requires the keys of a map to be non-nullable, and nanoarrow's `na_map()` builds nullable ones unless the key type says otherwise.
* **A dictionary** lands as `VARCHAR`.
* **`na`** lands as a column of type `NULL`.
* **The extension types** land as the DuckDB type they name:
  `arrow.uuid` as `UUID`, `arrow.json` as `JSON`, `arrow.bool8` as `BOOLEAN`, and `arrow.opaque` as the DuckDB type in its metadata.
  What the GeoArrow types land as is under Geometry and Limitations.

### R classes, through Arrow

An R vector reaches DuckDB through Arrow as the Arrow type its package infers,
which differs from what `dbWriteTable()` gives for some classes.
Where nothing is said below, nanoarrow and arrow infer the type `dbWriteTable()` writes.

* **`factor`** infers a dictionary and lands as `VARCHAR`, where `dbWriteTable()` writes `ENUM`.
  arrow lands an `ordered` one as `VARCHAR` too.
* **`POSIXct`** infers a `timestamp` with its zone, or R's session zone where it has none, and lands as `TIMESTAMPTZ`,
  where `dbWriteTable()` writes a plain `TIMESTAMP`.
* **`difftime`** infers a `duration` and lands as `INTERVAL` in hours and below, so 2 days land as `48:00:00`,
  where `dbWriteTable()` keeps the days.
* **`hms`** infers `time32` and lands as `TIME`, where `dbWriteTable()` writes `INTERVAL` unless the connection has `time = "hms"`;
  its truncation is a limitation (below).
* **A plain list of vectors** lands as `LIST` through arrow.
* **A matrix column** lands as `ARRAY` through nanoarrow.

## Geometry

`GEOMETRY` and the `spatial` extension's own types through Arrow, and where the geoarrow and sf packages meet them:

* **`GEOMETRY` exports as `geoarrow.wkb`, with the column's CRS in the field's metadata,**
  as PROJJSON once `spatial` is loaded, and as the identifier without it.
  It stays `geoarrow.wkb` under every export setting, `arrow_lossless_conversion` included;
  `arrow_large_buffer_size` makes its storage `large_binary`, and an `arrow_output_version` from `'1.4'` makes it `binary_view`.
  With the geoarrow package loaded, both readers convert it to a `geoarrow_vctr` in each of those layouts, arrow the view one included.
* **sf reads a result through GeoArrow in one call.**
  With geoarrow loaded, `sf::st_as_sf(dbGetQueryArrow(con, sql))` gives an `sf` whose geometries and CRS equal the source's,
  in the large and view layouts too,
  and so do `sf::st_as_sf()` of the result's `arrow::as_arrow_table()`, and `sf::st_as_sfc()` of the `geoarrow_vctr` column of `as.data.frame()`.
* **The `spatial` extension's own types cross as their storage.**
  `POINT_2D` and the other point and box types export as a `struct`, `LINESTRING_2D` and `LINESTRING_3D` as a `list` of point structs,
  `POLYGON_2D` and `POLYGON_3D` as a list of those lists, and `WKB_BLOB` as `binary`, with `arrow_lossless_conversion` too,
  and each reader converts them as it converts those Arrow types.
* **GeoArrow WKB writes `GEOMETRY` with its CRS.**
  Encode the geometry column as WKB,
  as `geoarrow::as_geoarrow_vctr(sf::st_geometry(x), schema = geoarrow::geoarrow_wkb(crs = sf::st_crs(x)))`,
  or as a `wk::as_wkb()` column, which nanoarrow infers as `geoarrow.wkb` once geoarrow is loaded.
  Register `arrow::as_arrow_table(nanoarrow::as_nanoarrow_array_stream(df))` with `duckdb_register_arrow()`,
  and a `CREATE TABLE ... AS SELECT` from the view writes a `GEOMETRY` column with the CRS,
  which reads back into an `sf` equal to the one written.
  With `spatial` loaded, the type names the CRS by its identifier, as `GEOMETRY('EPSG:4267')`;
  without it, it keeps the PROJJSON it came as, and `sf::st_crs()` reads the same CRS from both.
  WKB without a CRS lands as plain `GEOMETRY`, and so do the large and view layouts DuckDB's own export makes.
* **A `geoarrow_vctr` column holds indices.**
  The `geoarrow_vctr` that `as.data.frame()` gives for a geometry in an Arrow result
  is an integer vector of indices into the Arrow data it holds, and writing it back is a limitation (below).

## Limitations

* A column the reader cannot convert fails the whole data frame, not that column alone.
  Neither reader converts `INTERVAL`, so a result holding one fails in R whole; read it through `dbGetQuery()`, or as text.
  Neither converts the lossless extension types either, except where nanoarrow falls back to the storage;
  arrow converts no `BIGNUM`, no `UNION` and no view layout but a geometry's, and nanoarrow no `list_view`.
* `duckdb_register_arrow()` needs the arrow package and refuses a nanoarrow stream with `Invalid Error: std::exception`;
  `arrow::as_record_batch_reader()` turns one into what it takes.
  A registered reader is scanned once: a `RecordBatchReader` is a stream the first query drains,
  so a second query of the view sees no rows ([`experiments/2026-09-27-geoarrow/`](/experiments/2026-09-27-geoarrow/README.md)).
* `arrow::to_duckdb()` fails on Arrow data that lands as a type R cannot hold, and `to_arrow()` on a table holding one
  ([`integrations/`](/handbook/usage/integrations/README.md)).
* The DBI Arrow write methods land `uint32` and `decimal128` as `DOUBLE`, `timestamp('ns')` as `TIMESTAMP`, and a dictionary as `VARCHAR`;
  `time64` fails unless the connection has `time = "hms"`, because the `hms` it converts to otherwise writes `INTERVAL`,
  which does not cast to the `TIME` column `dbCreateTableArrow()` made;
  and `interval_month_day_nano` fails, because nanoarrow has no R vector for it.
  `dbBindArrow()` refuses a stream whose fields have names, with "`params` must not be named", so the names must be empty.
* Both readers read `HUGEINT`, `UHUGEINT` and `DECIMAL` rounded to a double, and `UBIGINT` rounded past 2^53;
  nanoarrow rounds a `BIGINT` past 2^53 too, with a warning.
* The default export writes a `UHUGEINT` of 2^127 or more as a negative number, without an error,
  because it does not fit the signed 128 bits of `decimal128(38, 0)`: the largest `UHUGEINT` reads as `-1`.
  `arrow_lossless_conversion` carries it as a type neither R reader converts.
* A `DATE` of `infinity` reads as a date millions of years away,
  `TIME_NS` as an `hms` whose double of seconds keeps the nanoseconds only as far as a double does,
  `TIMETZ` without its offset under the default export,
  and `TIMESTAMP_NS` as a `POSIXct` whose double loses the nanoseconds.
* `VARIANT` has no Arrow export: the stream fails as soon as its schema is read.
* DuckDB refuses `half_float`, `decimal256` and `dense_union`, reads `interval_day_time` wrong,
  truncates a `duration` below a microsecond, and never lands a dictionary as `ENUM`.
  Of an `interval_day_time`, it reads the two 32-bit fields, days and milliseconds, as one 64-bit count of milliseconds,
  so 2 days and 3000 ms land as `3579139:24:48.002`.
* Through Arrow, `hms` writes `TIME` truncated to milliseconds or seconds: nanoarrow infers milliseconds, and arrow whole seconds.
  An array built as `time64('us')`, as `nanoarrow::as_nanoarrow_array(x, schema = nanoarrow::na_time64("us"))`, keeps the microseconds.
* nanoarrow refuses an `ordered` factor, and a plain list of vectors, for which it needs a `vctrs::list_of()`;
  arrow flattens a matrix column into one row per cell.
* Without geoarrow loaded, nanoarrow reads a geometry's WKB as a `blob`, arrow as an `arrow_binary`,
  and `sf::st_as_sf()` has no method for an Arrow result; with it, a `NULL` geometry reads as an empty one.
* The routes behind `dbSendQuery(arrow = TRUE)` fail on a `GEOMETRY` column with a CRS.
  `duckdb_fetch_arrow()`, `duckdb_fetch_record_batch()` and `arrow::to_arrow()`, which reads through them,
  fail with `INTERNAL Error: TransactionContext::ActiveTransaction called without active transaction`,
  because they export the schema once the query's transaction has ended, and exporting a CRS needs an active one
  ([`plan/PLAN-spatial-interop.md`](/plan/PLAN-spatial-interop.md)).
  `dbGetQueryArrow()` reads it,
  and so do those routes once the query casts the column to the bare type, as `geom::GEOMETRY`, which drops the CRS.
* The `spatial` extension's own types lose their alias through Arrow, in both directions,
  and registered back land as the plain `STRUCT`, `LIST` or `BLOB`
  ([`experiments/2026-09-26-type-catalog/`](/experiments/2026-09-26-type-catalog/README.md)).
* arrow carries a `wk_wkb` column as its own R extension type, which lands as `BLOB`,
  and geoarrow cannot write an `sfc` in the large or view layouts of WKB.
* Of the GeoArrow encodings, only WKB lands as `GEOMETRY`.
  A native encoding, which is what nanoarrow infers for an `sf` column and what `arrow::as_arrow_table()` makes of one,
  lands as its struct storage, as `STRUCT(x DOUBLE, y DOUBLE)[][][]` for a multipolygon.
  A native point converts in the query as `geometry::POINT_2D::GEOMETRY`,
  and a native polygon casts neither through `POLYGON_2D` nor directly.
  `geoarrow_wkt()` lands as `VARCHAR`, which `::GEOMETRY` parses, and `ST_SetCRS()` gives the CRS back.
* A `geoarrow_vctr` column writes its integer indices through `dbWriteTable()` and `dbWriteTableArrow()`,
  which converts through such a data frame, as an `INTEGER` column, `1, 2, 3`, without an error.
  Convert it with `sf::st_as_sfc()` first, or keep it in Arrow.

*To deepen: measure run-end encoded arrays, which neither R package builds
([`plan/PLAN-type-documentation.md`](/plan/PLAN-type-documentation.md)).*
