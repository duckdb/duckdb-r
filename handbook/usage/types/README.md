# Types

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](/handbook/meta/handbook/);
the last section holds this leaf's parameters.*

Scope: the R ↔ DuckDB edges: UTF-8 strictness, geometry via WKB,
`Inf`/`NaN`, `NULL` vs `NA`.

Today:

* no single owner yet;
  the natural home is a `?duckdb_types` reference page, not yet written

To write this leaf:

* gather: the mapping from `src/types.cpp` and the R coercion code;
  UTF-8 strictness is deliberate engine behavior — say so
* drain: #12, #155, #184, #200, #590, #642, #1670
* stage the facts here until a `?duckdb_types` reference page exists,
  then invert to a pointer
