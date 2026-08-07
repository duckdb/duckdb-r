# Types

The R ↔ DuckDB edges:
where a value does not survive the crossing unchanged,
and what to do about it.
The mapping itself is implemented in
[`src/types.cpp`](/src/types.cpp) (R vector → `LogicalType`)
and [`src/transform.cpp`](/src/transform.cpp) (the way back).

* **UTF-8 is required, strictly.**
  DuckDB checks string validity and rejects invalid UTF-8;
  this is deliberate engine behavior, not a bug
  ([#12](https://github.com/duckdb/duckdb-r/issues/12)).
  Convert first: `iconv(x, to = "UTF-8")` or `enc2utf8()`.
* **Geometry comes back as WKB by default.**
  `dbConnect(geometry = )` chooses: `"blob"`, the default set in
  [`R/dbConnect__duckdb_driver.R`](/R/dbConnect__duckdb_driver.R),
  returns raw vectors; `"wk"` returns `wk_wkb`, which
  `sf::st_as_sfc()` converts onward.
  There is no automatic conversion on the *write* side —
  write WKB blobs and use `ST_GeomFromWKB()` in DuckDB;
  the duckspatial and duckdbfs packages wrap this
  ([#1670](https://github.com/duckdb/duckdb-r/issues/1670)).
  Native `sf` support is roadmapped in
  [#117](https://github.com/duckdb/duckdb-r/issues/117).
* **An untyped `NULL` comes back as `NA_integer_`,**
  not logical `NA` — verified on a v1.5.5 vendored build.
  A logical `NA` crosses into DuckDB as one of two things.
  Typed contexts — a scanned logical column, a bound `NA`
  parameter — use a `BOOLEAN` NULL and round-trip as logical `NA`
  (`RApiTypes::SexpToValue()` in [`src/utils.cpp`](/src/utils.cpp),
  `typed_logical_null = true`).
  `expr_constant(NA)` instead deliberately produces an *untyped*
  NULL (`SQLNULL`,
  [#143](https://github.com/duckdb/duckdb-r/pull/143)):
  `SQLNULL` implicitly casts to anything,
  so a nested `NA` adopts its siblings' type —
  `greatest(NA, a)` with `a` `DOUBLE` binds `DOUBLE` —
  where a `BOOLEAN` constant could not
  (no implicit cast from `BOOLEAN` to numeric).
  The glitch is at top level:
  the engine exchanges an untyped `NULL` that survives to a result
  column to `INTEGER` (`ExpressionBinder::ExchangeNullType()` in
  [`src/duckdb/src/planner/expression_binder.cpp`](/src/duckdb/src/planner/expression_binder.cpp)),
  so a projected `expr_constant(NA)` and SQL `SELECT NULL`
  both return `NA_integer_`.
  Flipping that to logical `NA` is decided and pending
  ([#155](https://github.com/duckdb/duckdb-r/issues/155));
  the candidate fix is the engine-side exchange to `BOOLEAN`
  ([#156](https://github.com/duckdb/duckdb-r/pull/156)),
  held because it changes SQL-level results for every user
  and is therefore gated on the duckplyr revdep check
  ([`testing/revdep/`](/handbook/testing/revdep/README.md)).
  duckplyr does not wait for it:
  its translation emits a `___null()` macro,
  `CAST(NULL AS BOOLEAN)`, for a top-level bare `NA`,
  and keeps `expr_constant(NA)` for nested ones.
  A `SQLNULL` column itself never reaches the R conversion layer
  today; if the engine ever lets one through,
  `duckdb_r_typeof()` in [`src/transform.cpp`](/src/transform.cpp)
  has no case for it and errors.
* **MAP columns** round-trip since 1.5.4
  ([#200](https://github.com/duckdb/duckdb-r/issues/200)),
  but writing one back without `field.types` needs
  `dbConnect(map = "list_of")`; the default is `"data.frame"`,
  set in
  [`R/dbConnect__duckdb_driver.R`](/R/dbConnect__duckdb_driver.R).
  Columns with unit or other attribute classes arrive as their
  storage type — `units` becomes plain `DOUBLE`
  ([#590](https://github.com/duckdb/duckdb-r/issues/590)).
* **Arrow results are not R vectors at all** —
  they stay in the stream, and what consumes them is
  [`integrations/`](/handbook/usage/integrations/README.md)'s
  ([#642](https://github.com/duckdb/duckdb-r/issues/642)).
* **Timestamps** come back as `POSIXct` in the zone
  `dbConnect(timezone_out = )` names, `"UTC"` by default
  ([`R/dbConnect__duckdb_driver.R`](/R/dbConnect__duckdb_driver.R));
  adopting the session `TimeZone` for `TIMESTAMPTZ` is in flight
  ([#184](https://github.com/duckdb/duckdb-r/issues/184),
  [#2401](https://github.com/duckdb/duckdb-r/pull/2401)).

*To deepen: write the full mapping table from `src/types.cpp`,
verified on a vendored build.
This leaf is its home — a `?`-page for types would be generated from
here, not the other way round.*
