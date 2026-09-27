# Arrow types

Every DuckDB type as it crosses to R through Arrow and back:
the Arrow type the engine exports it as, what the two R readers make of that,
which Arrow type writes it again, and which R functions keep Arrow's types on the way in.
The routes through R vectors are [`types/`](/handbook/usage/types/README.md)'s,
and how a stream behaves, when it drains and what invalidates it, is [`integrations/`](/handbook/usage/integrations/README.md)'s.
Every entry below was measured on DuckDB 1.5.5, nanoarrow 0.9.0 and arrow 25.0.1
in [`experiments/2026-09-27-arrow-types/`](/experiments/2026-09-27-arrow-types/README.md).

## The routes

**Reading.**
Every function that returns Arrow hands out the engine's own export, under the connection's settings:
`dbGetQueryArrow()`, `dbFetchArrow()` and `dbFetchArrowChunk()` after `dbSendQueryArrow()`, `dbReadTableArrow()`,
`duckdb_fetch_arrow()` and `duckdb_fetch_record_batch()` after `dbSendQuery(arrow = TRUE)`, and `arrow::to_arrow()`.
No R vector exists until a reader converts the stream ([#642](https://github.com/duckdb/duckdb-r/issues/642)),
and the two readers differ, so each entry below names both:
nanoarrow's `as.data.frame()`, and arrow's `as.data.frame()` of `arrow::as_arrow_table()`.
A column the reader cannot convert fails the whole data frame, not that column alone.

**The export settings** are DuckDB's, set with `SET`, and each changes the Arrow type of some columns:

* `arrow_lossless_conversion = true` exports each type that has no exact Arrow counterpart as an extension type that names it,
  so that DuckDB, or another Arrow consumer that knows the name, gets the type back.
  Neither R reader converts those, except where nanoarrow falls back to the storage;
  the entries below say which.
* `arrow_large_buffer_size = true` gives strings, binary data and lists 64-bit offsets,
  as `large_string`, `large_binary` and `large_list`, which both readers convert as they convert the others.
* `arrow_output_version`, `'1.0'` by default, gates the newer layouts.
  From `'1.4'`, binary data exports as `binary_view`,
  and `produce_arrow_string_view = true` and `arrow_output_list_view = true` take effect, as `string_view` and `list_view`;
  with an older version those two change nothing.
  From `'1.5'`, a `DECIMAL` up to width 9 exports as `decimal32` and up to width 18 as `decimal64`.
  arrow converts none of the view layouts; nanoarrow converts `string_view` and `binary_view`, and not `list_view`.

**Writing.**
Only the routes that let DuckDB scan the Arrow data keep its types:
`duckdb_register_arrow()`, and `arrow::to_duckdb()`, which calls it.
`duckdb_register_arrow()` takes whatever `arrow::Scanner$create()` scans ([`R/register.R`](/R/register.R)), so it needs the arrow package,
and refuses a nanoarrow stream with `Invalid Error: std::exception`;
`arrow::as_record_batch_reader()` turns one into what it takes.
Nothing is copied: the result is a view, and `CREATE TABLE ... AS SELECT * FROM` it writes a table.
Every other route converts through an R data frame, so a column lands as the type its R vector writes ([`types/`](/handbook/usage/types/README.md)).
`dbWriteTableArrow()`, `dbCreateTableArrow()` and `dbAppendTableArrow()` are DBI's defaults, which do that batch by batch:
`uint32` and `decimal128` land as `DOUBLE`, `timestamp('ns')` as `TIMESTAMP`, and a dictionary as `VARCHAR`;
`time64` fails, because the `hms` it converts to writes `INTERVAL`, which does not cast to the `TIME` column `dbCreateTableArrow()` made;
and `interval_month_day_nano` fails, because nanoarrow has no R vector for it.
`dbBindArrow()` converts the same way, then binds by position,
and a stream whose fields have names is refused with "`params` must not be named", so the names must be empty.

## Reading

### Numbers

* **`BOOLEAN`** exports as `bool` and reads as `logical`;
  with `arrow_lossless_conversion`, as `arrow.bool8`, which nanoarrow reads as the `integer` of its storage and arrow refuses.
* **`TINYINT`, `SMALLINT`, `INTEGER`, `UTINYINT`, `USMALLINT`** export as `int8`, `int16`, `int32`, `uint8` and `uint16`,
  and read as `integer`.
* **`UINTEGER`** exports as `uint32`.
  nanoarrow reads it as `numeric`; arrow reads it as `integer` when every value fits, and as `numeric` otherwise.
* **`BIGINT`** exports as `int64`.
  nanoarrow reads it as `numeric`, with a warning where a value past 2^53 is rounded.
  arrow reads it as `integer` when every value fits and as `bit64::integer64` otherwise, exactly,
  or as `integer64` always under `options(arrow.int64_downcast = FALSE)`.
* **`UBIGINT`** exports as `uint64`, and both read it as `numeric`, rounded past 2^53.
* **`HUGEINT`, `UHUGEINT`** export as `decimal128(38, 0)`, and both read them as `numeric`, rounded to a double.
  A value of more than 38 digits does not fit that type and arrives wrong, without an error:
  the largest `UHUGEINT` reads as `-1`.
  With `arrow_lossless_conversion` they export as `arrow.opaque`, which carries every value and neither reader converts.
  Their text reads them exactly ([`types/`](/handbook/usage/types/README.md)).
* **`BIGNUM`** exports as `arrow.opaque` under either setting;
  nanoarrow reads its storage bytes as a `blob`, and arrow refuses it.
* **`DECIMAL(width, scale)`** exports as `decimal128(width, scale)`, or narrower from output version 1.5,
  and both read it as `numeric`, rounded to a double.
* **`FLOAT`, `DOUBLE`** export as `float` and `double`, and read as `numeric`.

### Text and binary

* **`VARCHAR`** exports as `string` and reads as `character`.
* **`BLOB`** exports as `binary`; nanoarrow reads it as a `blob::blob`, and arrow as an `arrow_binary` list of raw vectors.
* **`BIT`** exports as `binary`, the bytes DuckDB stores for the bit string, and reads as a `blob` or `arrow_binary` of those bytes.
  With `arrow_lossless_conversion` it exports as `arrow.opaque`, which nanoarrow reads as the same bytes and arrow refuses.
  Its text reads it as `0` and `1` ([`types/`](/handbook/usage/types/README.md)).
* **`UUID`** exports as `string`, lowercase and hyphenated, and reads as `character`.
  With `arrow_lossless_conversion` it exports as `arrow.uuid`, which neither reader converts.

### Dates and times

* **`DATE`** exports as `date32` and reads as `Date`; `infinity` reads as a date millions of years away.
* **`TIME`** exports as `time64('us')` and reads as `hms`.
* **`TIME_NS`** exports as `time64('ns')` and reads as `hms`, whose double of seconds keeps the nanoseconds only as far as a double does.
* **`TIMETZ`** exports as the `time64('us')` of its local time, with the offset dropped, and reads as `hms`.
  With `arrow_lossless_conversion` it exports as `arrow.opaque`, which keeps the offset and neither reader converts.
* **`TIMESTAMP_S`, `TIMESTAMP_MS`, `TIMESTAMP`, `TIMESTAMP_NS`** export as `timestamp` in their own unit, without a zone,
  and read as `POSIXct`, whose double loses the nanoseconds.
  The two readers label the same instant differently:
  nanoarrow gives it the zone `UTC`, so it prints the stored clock,
  and arrow gives it none, so it prints in R's session zone, a different clock outside UTC.
* **`TIMESTAMPTZ`** exports as `timestamp('us', zone)`, where the zone is DuckDB's `TimeZone` setting
  ([`timestamps/`](/handbook/usage/timestamps/README.md)), and both readers read it as a `POSIXct` labelled with that zone.
* **`INTERVAL`** exports as `interval_month_day_nano`, and neither reader converts it,
  so a result holding one fails in R whole; read it through `dbGetQuery()`, or as text.

### Enums and nested types

* **`ENUM`** exports as a dictionary of its values; nanoarrow reads it as `character`, and arrow as `factor`.
* **`ARRAY`** exports as a `fixed_size_list` and reads as a list of vectors (`vctrs::list_of()` or `arrow_fixed_size_list`),
  without the `array = "matrix"` that `dbGetQuery()` needs.
* **`LIST`** exports as `list` and reads as a list of vectors (`vctrs::list_of()` or `arrow_list`).
* **`MAP`** exports as `map` and reads as a list of key and value data frames.
* **`STRUCT`** exports as `struct` and reads as a data frame column, a tibble in arrow's case.
* **`UNION`** exports as a `sparse_union`.
  nanoarrow reads it as a data frame with a column per member, `NA` where the value is another member's;
  arrow refuses it.
* **`VARIANT`** is refused by the engine's export: the stream fails as soon as its schema is read.

### Everything else

* **`NULL`**, untyped, exports as `int32` and reads as `NA_integer_`, as it does through `dbGetQuery()`.
* **`JSON`** exports as `string` and reads as `character`;
  with `arrow_lossless_conversion` it exports as `arrow.json`, which nanoarrow reads as `character` and arrow refuses.
* **`INET`** exports as a struct whose `address` is a `decimal128(38, 0)`, read as a double as through `dbGetQuery()`;
  with `arrow_lossless_conversion` that field becomes `arrow.opaque`, which neither reader converts.
* **`GEOMETRY`**, and the `spatial` extension's own types, cross Arrow as [`spatial/`](/handbook/usage/spatial/README.md) says, CRS included.
  What the readers make of `GEOMETRY` depends on the geoarrow package:
  once it is loaded, both convert it to a `geoarrow_vctr`;
  until then, nanoarrow reads its WKB as a `blob` and arrow as an `arrow_binary`.

## Writing

### Arrow types

Each Arrow type lands as one DuckDB type when DuckDB scans it:

* **`bool`, `int8` to `int64`, `uint8` to `uint64`, `float`, `double`** land as `BOOLEAN`, the integer type of the same width and sign,
  `FLOAT` and `DOUBLE`; `half_float` is refused.
* **`decimal32`, `decimal64`, `decimal128`** land as `DECIMAL` of the same width and scale; `decimal256` is refused.
* **`string`, `large_string`, `string_view`** land as `VARCHAR`,
  and **`binary`, `large_binary`, `binary_view`, `fixed_size_binary`** as `BLOB`.
* **`date32`, `date64`** land as `DATE`.
* **`time32` and `time64('us')`** land as `TIME`, and **`time64('ns')`** as `TIME_NS`.
* **`timestamp`** without a zone lands as `TIMESTAMP_S`, `TIMESTAMP_MS`, `TIMESTAMP` or `TIMESTAMP_NS` by its unit,
  and with a zone as `TIMESTAMPTZ`, the same instant.
* **`duration`** lands as `INTERVAL` in any unit, below a microsecond truncated.
* **`interval_months`** and **`interval_month_day_nano`** land as `INTERVAL`, each part kept.
  **`interval_day_time`** lands wrong: DuckDB reads its two 32-bit fields, days and milliseconds, as one 64-bit count of milliseconds,
  so 2 days and 3000 ms land as `3579139:24:48.002`.
* **`list`, `large_list`, `list_view`** land as `LIST`, and **`fixed_size_list`** as `ARRAY`.
* **`struct`** lands as `STRUCT`, **`map`** as `MAP`, and **`sparse_union`** as `UNION`; `dense_union` is refused.
  Arrow requires the keys of a map to be non-nullable, and nanoarrow's `na_map()` builds nullable ones unless the key type says otherwise.
* **A dictionary** lands as `VARCHAR`, never as `ENUM`.
* **`na`** lands as a column of type `NULL`.
* **The extension types** land as the DuckDB type they name:
  `arrow.uuid` as `UUID`, `arrow.json` as `JSON`, `arrow.bool8` as `BOOLEAN`, `arrow.opaque` as the DuckDB type in its metadata,
  and `geoarrow.wkb` as `GEOMETRY` with its CRS.
  geoarrow's native encodings, such as `geoarrow.point`, land as their struct storage, not as `GEOMETRY`.

### R classes, through Arrow

An R vector reaches DuckDB through Arrow as the Arrow type its package infers,
which differs from what `dbWriteTable()` gives for some classes.
Where nothing is said below, nanoarrow and arrow infer the type `dbWriteTable()` writes.

* **`factor`** infers a dictionary and lands as `VARCHAR`, where `dbWriteTable()` writes `ENUM`.
  nanoarrow refuses an `ordered` factor, and arrow lands it as `VARCHAR`.
* **`POSIXct`** infers a `timestamp` with its zone, or R's session zone where it has none, and lands as `TIMESTAMPTZ`,
  where `dbWriteTable()` writes a plain `TIMESTAMP`.
* **`difftime`** infers a `duration` and lands as `INTERVAL` in hours and below, so 2 days land as `48:00:00`,
  where `dbWriteTable()` keeps the days.
* **`hms`** infers `time32` and lands as `TIME`, the one R route to that type,
  but truncated: nanoarrow infers milliseconds, and arrow whole seconds.
  An array built as `time64('us')`, as `nanoarrow::as_nanoarrow_array(x, schema = nanoarrow::na_time64("us"))`, keeps the microseconds.
* **A plain list of vectors** is refused by nanoarrow, which needs a `vctrs::list_of()`, and lands as `LIST` through arrow.
* **A matrix column** lands as `ARRAY` through nanoarrow; arrow flattens it into one row per cell.
* **`wk_wkb`** lands as `GEOMETRY` through nanoarrow once geoarrow is loaded,
  and as `BLOB` through arrow, which carries it as its own R extension type ([`spatial/`](/handbook/usage/spatial/README.md)).

*To deepen: derive the user-facing reference page from this leaf ([#2566](https://github.com/duckdb/duckdb-r/issues/2566)),
and measure run-end encoded arrays, which neither R package builds
([`plan/PLAN-type-documentation.md`](/plan/PLAN-type-documentation.md)).*
