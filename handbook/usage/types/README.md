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
* **`NULL` arrives as logical `NA`** in untyped contexts;
  making the relational API return typed `NA`s instead is decided
  and pending ([#155](https://github.com/duckdb/duckdb-r/issues/155)).
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
