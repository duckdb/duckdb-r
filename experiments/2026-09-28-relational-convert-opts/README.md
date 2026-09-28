# What a relation's routes to R make of the conversion options

*What it measures:* which routes between a relation and R follow the connection's conversion options:
`rel_to_altrep()`, `as.data.frame()` of a relation, and `rel_sql()`, beside `dbGetQuery()` of the same query,
and `rel_from_df()` beside `duckdb_register()` of the same data frame,
on a connection with `bigint`, `array`, `map`, `geometry`, `time` and `blob` all set away from their defaults.

*When and on what:* 2026-09-28, Linux x86_64, R 4.5.3, DBI 1.3.0, bit64 4.8.6, vctrs 0.7.3, wk 0.9.5, hms 1.1.4, blob 1.3.0.
duckdb 1.5.5.9029 with the commits that add `time`, `blob` and `interval` and the fixes that follow them,
a fast-path build linking the release `libduckdb` of DuckDB 1.5.5 ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
[`convert-opts.R`](convert-opts.R) is rendered to [`convert-opts.md`](convert-opts.md)
by [`scripts/render-reprex.R`](/scripts/render-reprex.R),
and the session info names the scratch library that held the build as `<fast-path build library>`.

*What it supports:* the limitation in [`usage/relational/`](/handbook/usage/relational/README.md).

## Findings

From [`convert-opts.md`](convert-opts.md):

* **`as.data.frame()` of a relation and `rel_sql()` convert with the default options.**
  `dbGetQuery()` and `rel_to_altrep()` read the five columns as `integer64`, `vctrs_list_of`, `wk_wkb`, `hms` and `blob`,
  and the other two as `numeric`, `list`, `list`, `difftime` and `list`.
  Both reach `result_to_df()` in [`src/relational.cpp`](/src/relational.cpp), which converts with a default `ConvertOpts()`
  rather than the one the relation carries.
* **So an `ARRAY` column is refused there under `array = "matrix"`.**
  `dbGetQuery()` reads it as a one-row matrix,
  and `as.data.frame()` of the relation refuses it with the hint to set the `array` the connection already has.
* **`rel_from_df()` writes with the default options too.**
  With `time = "hms"` and `map = "list_of"`, `duckdb_register()` types an `hms` column as `TIME`
  and a column of named lists as map entries, a list of `STRUCT(key, value)`,
  while `rel_from_df()` types them as `INTERVAL` and as nested lists:
  [`src/relational.cpp`](/src/relational.cpp) hands the scan none of the options.
