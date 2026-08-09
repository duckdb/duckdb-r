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
  R is the lenient side: it carries the bytes and prints them,
  so `validUTF8()`, not the console, is what agrees with the engine.
  Repairing means naming the encoding the bytes are actually in —
  `iconv(x, from = "latin1", to = "UTF-8")` —
  and `iconv()` yields `NA` for what it cannot convert
  unless `sub =` says otherwise,
  so a repair that fails shows up as missing data.
  `enc2utf8()` re-encodes only what R has marked, and a string read
  from a file whose encoding the reader was not told is marked
  `"unknown"`: it passes through untouched, still invalid.
  Which is why the cheapest place to fix this is the reader.
* **Geometry comes back as WKB by default.**
  `dbConnect(geometry = )` chooses: `"blob"`, the default set in
  [`R/dbConnect__duckdb_driver.R`](/R/dbConnect__duckdb_driver.R),
  returns raw vectors; `"wk"` returns `wk_wkb`, which
  `sf::st_as_sfc()` converts onward.
  There is no automatic conversion on the *write* side,
  and an `sf` object handed to `dbWriteTable()` fails rather than
  finding one ([#1670](https://github.com/duckdb/duckdb-r/issues/1670)).
  The route is WKB in a `BLOB` column —
  `sf::st_as_binary()` produces the raw vectors, and a list of them
  writes as `BLOB` — with `ST_GeomFromWKB()` reading it back,
  either per query or once, through
  `ALTER TABLE … ALTER COLUMN … SET DATA TYPE GEOMETRY USING`.
  The duckspatial and duckdbfs packages wrap this.
  Native `sf` support is roadmapped in
  [#117](https://github.com/duckdb/duckdb-r/issues/117).
* **An untyped `NULL` comes back as `NA_integer_`,**
  matching the engine's own `SELECT NULL`;
  mapping it to logical `NA` instead was declined
  ([#155](https://github.com/duckdb/duckdb-r/issues/155)).
  A typed `NULL` — a scanned logical column, a bound `NA`
  parameter — round-trips as logical `NA`,
  and the `expr_constant(NA)` corner is
  [`relational/`](/handbook/usage/relational/README.md)'s.
* **MAP columns** round-trip since 1.5.4
  ([#200](https://github.com/duckdb/duckdb-r/issues/200)),
  but writing one back without `field.types` needs
  `dbConnect(map = "list_of")`; the default is `"data.frame"`,
  set in
  [`R/dbConnect__duckdb_driver.R`](/R/dbConnect__duckdb_driver.R).
* **Attribute classes do not cross, in either direction.**
  A `units` column becomes plain `DOUBLE` going in — through
  `dbWriteTable()`, through `duckdb_register()`, as a bound parameter —
  and comes back plain `numeric`:
  the value survives, the class does not, and nothing warns
  ([#590](https://github.com/duckdb/duckdb-r/issues/590)).
  Re-applying it on the way out (`units::set_units()`) is the caller's.
  The same holds for a column that reaches the engine through Arrow:
  `arrow` carries `[m^2]` in its schema as an extension type,
  and DuckDB reads the storage underneath it.
  This used to be a hard stop rather than a quiet loss —
  before DuckDB 1.2.1 the same column raised
  `rapi_prepare: Unknown column type for prepare: INVALID`
  ([duckdb/duckdb#16321](https://github.com/duckdb/duckdb/pull/16321)) —
  so code written against that era may still be avoiding a route that
  now works.
* **Arrow results are not R vectors at all** —
  they stay in the stream, and what consumes them is
  [`integrations/`](/handbook/usage/integrations/README.md)'s
  ([#642](https://github.com/duckdb/duckdb-r/issues/642)).
* **Timestamps** come back as `POSIXct`;
  which zone labels them — `timezone_out` for plain `TIMESTAMP`,
  the session `TimeZone` for `TIMESTAMPTZ` —
  and when an instant can change is
  [`timestamps/`](/handbook/usage/timestamps/README.md)'s.
* **Not every column lifts into the relational path** (duckplyr's):
  `rel_from_df()` refuses rather than converts —
  which columns, and what duckplyr does about a refusal, is
  [`relational/`](/handbook/usage/relational/README.md)'s.

*To deepen: write the full mapping table from `src/types.cpp`,
verified on a vendored build.
This leaf is its home — a `?`-page for types would be generated from
here, not the other way round.*
