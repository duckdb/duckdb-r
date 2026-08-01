# The engine

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.*

Scope: the DuckDB engine embedded in `src/duckdb/`:
what it is, which commit is embedded,
and how this package's build of it differs from a stock build.

Today:

* [duckdb.org/docs](https://duckdb.org/docs/) —
  the engine's own documentation, which this tree does not duplicate
* [duckdb/duckdb](https://github.com/duckdb/duckdb) —
  the upstream sources and internals
* [`R/version.R`](../../../R/version.R) —
  the embedded engine version, generated at vendor time
* how the embedded copy is maintained is
  [`operations/vendoring/`](../../operations/vendoring/), not here
