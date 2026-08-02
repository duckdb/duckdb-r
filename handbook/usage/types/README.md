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
* **No automatic sf / geometry conversion.**
  Write geometry as WKB blobs and convert with
  `ST_GeomFromWKB()` on the DuckDB side (and `ST_AsWKB()` back);
  the duckspatial and duckdbfs packages wrap this
  ([#1670](https://github.com/duckdb/duckdb-r/issues/1670)).
  Native support is roadmapped in
  [#117](https://github.com/duckdb/duckdb-r/issues/117).
* **`NULL` arrives as logical `NA`** in untyped contexts;
  making the relational API return typed `NA`s instead is decided
  and pending ([#155](https://github.com/duckdb/duckdb-r/issues/155)).
* **MAP columns** round-trip since 1.5.4
  ([#200](https://github.com/duckdb/duckdb-r/issues/200));
  columns with unit or other attribute classes arrive as their
  storage type — `units` becomes plain `DOUBLE`
  ([#590](https://github.com/duckdb/duckdb-r/issues/590)).
* **Other frames without a copy:**
  `dbGetQueryArrow()` returns a `nanoarrow_array_stream` that
  polars, arrow, and data.table consume directly —
  `polars::as_polars_df()` and friends —
  with no R data frame in between
  ([#642](https://github.com/duckdb/duckdb-r/issues/642)).
* **Timestamps:** columns come back as UTC `POSIXct`;
  adopting the session `TimeZone` for `TIMESTAMPTZ` is in flight
  ([#184](https://github.com/duckdb/duckdb-r/issues/184),
  [#2401](https://github.com/duckdb/duckdb-r/pull/2401)).

*To deepen: write the full mapping table from `src/types.cpp`,
verified on a vendored build,
and stage it here until a types reference page exists.*
