# Every DuckDB type through Arrow, in and out of R

*What it measures:* for every DuckDB type, the Arrow type the engine exports it as,
under each setting that changes that, and what nanoarrow and arrow make of it in R;
for every Arrow type, the DuckDB type and value it lands as when registered;
for every R class, the Arrow type each package infers for it and the DuckDB type that lands, beside what `dbWriteTable()` gives;
and which R functions carry Arrow's types across, in each direction.

*When and on what:* 2026-09-27, duckdb 1.5.5.9028 (DuckDB 1.5.5, linked through the fast path) at the commit that adds this directory,
Linux, with `json`, `inet`, `spatial` and `icu` from the extension store,
nanoarrow 0.9.0, arrow 25.0.1, geoarrow 0.4.4, wk 0.9.5, bit64 4.8.6, dbplyr 2.6.0.
The list of DuckDB types is the one [`2026-09-26-type-catalog/`](/experiments/2026-09-26-type-catalog/README.md) proves complete against the engine,
copied into [`types.R`](types.R).
The list of Arrow types is every type nanoarrow has a constructor for, plus the canonical extension types and geoarrow's.

*What it supports:* [`usage/arrow-types/`](/handbook/usage/arrow-types/README.md),
and the open work in [`plan/PLAN-type-documentation.md`](/plan/PLAN-type-documentation.md).

## Method

Each script is rendered with `reprex::reprex(si = TRUE)` from this directory, which `out.R` needs for `types.R`:

* [`out.R`](out.R) → [`out.md`](out.md): each DuckDB type out through `dbGetQueryArrow()`,
  its Arrow type with the default export and with `arrow_lossless_conversion`,
  then the R value from nanoarrow's `as.data.frame()` and from arrow's `as.data.frame()` of `as_arrow_table()`;
  the other export settings, each with the types it changes;
  values chosen to show where precision goes;
  and the zone label each reader gives a timestamp, with R's zone and DuckDB's `TimeZone` set apart.
* [`in.R`](in.R) → [`in.md`](in.md): each Arrow type, built in R and registered through `duckdb_register_arrow()`,
  with the DuckDB type and value it lands as;
  a failure names the step that failed, building the array, arrow importing it, or DuckDB scanning it.
  Then each R class, through nanoarrow's and arrow's inference, beside `dbWriteTable()` on the same column.
* [`routes.R`](routes.R) → [`routes.md`](routes.md): every R function that writes Arrow data, given columns of Arrow types no R class writes,
  and every function that reads a result as Arrow, under both export settings.

Nanoarrow builds most Arrow arrays from R values.
The interval types and `list_view` it cannot, so `in.R` builds the first two intervals from raw bytes,
and takes `interval_month_day_nano`, `list_view` and `arrow.opaque` from DuckDB's own export on a connection of their own.
A stream is registered on another connection than the one that produced it, and every call registers a view of its own name:
the reasons are in the scripts.

## Findings

What each type does is the leaf's; what the run found beyond that:

* **Every read route is the engine's export.**
  The seven functions that return Arrow give the same schema, and each follows `arrow_lossless_conversion`;
  R converts nothing until a reader does.
* **The two readers disagree, and neither covers the export.**
  nanoarrow reads `int64` and `uint32` as `numeric` and a dictionary as `character`;
  arrow reads them as `integer` when every value fits and a dictionary as `factor`.
  Neither converts `interval_month_day_nano`; arrow also refuses `sparse_union`, the view layouts,
  and every extension type it did not register itself, which includes all of `arrow_lossless_conversion`'s.
  nanoarrow refuses `list_view` and the extension types whose storage is `fixed_size_binary`.
* **The default export loses a value it cannot represent, without an error.**
  `HUGEINT` and `UHUGEINT` export as `decimal128(38, 0)`, which holds 38 digits;
  the largest `UHUGEINT` arrives in R as `-1`.
* **Only the routes that let DuckDB scan the Arrow data keep its types.**
  `duckdb_register_arrow()` and `arrow::to_duckdb()` land every column as its Arrow type maps.
  `dbWriteTableArrow()`, `dbCreateTableArrow()` and `dbBindArrow()` go through an R data frame,
  so `uint32` and `decimal128` land as `DOUBLE`, a dictionary as `VARCHAR`, `time64` fails to append,
  and `interval_month_day_nano` fails to convert.
  `duckdb_register_arrow()` refuses a nanoarrow stream with `Invalid Error: std::exception`.
* **The engine misreads Arrow's `interval_day_time`.**
  Two 32-bit fields, days and milliseconds, are read as one 64-bit count of milliseconds:
  2 days and 3000 ms land as `3579139:24:48.002`.
  The vendored `src/duckdb/src/function/table/arrow_conversion.cpp` routes `ArrowDateTimeType::DAYS` to the millisecond conversion.
* **The view layouts need `arrow_output_version` 1.4.**
  Set with the default 1.0, `produce_arrow_string_view` and `arrow_output_list_view` change nothing;
  1.4 also turns binary data into `binary_view` on its own, and 1.5 narrows `DECIMAL` to `decimal32` and `decimal64`.
* **dbplyr cannot open a table holding a type R cannot hold.**
  `dplyr::tbl()` reads the fields through a query R has to convert, and fails on `TIME_NS`;
  `arrow::to_arrow()` takes such a `tbl()`, and `arrow::to_duckdb()` returns one,
  so `to_duckdb()` fails the same way for Arrow data that lands as `TIME_NS`.
  The table in `routes.R` holds only types R can hold for that reason.

Found in passing, and not about types:
one parameter used both inside `typeof()` and in a cast,
as in `PREPARE p AS SELECT typeof($1), $1::VARCHAR` followed by `EXECUTE p('ok')`,
raises `INTERNAL Error: Invalid PhysicalType for GetTypeIdSize` and invalidates the database.
`routes.R` binds the type and the value in separate queries for that reason.

Replicate with the vendored build or the fast path ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)),
from this directory, `reprex::reprex(input = "out.R", si = TRUE)` and likewise for the other two;
`INSTALL` needs network access to `extensions.duckdb.org`.
