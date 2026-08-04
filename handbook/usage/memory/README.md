# Memory

What DuckDB's `memory_limit` bounds and what it does not,
where larger-than-memory work spills,
and how to keep results from materializing in R.

* **`memory_limit` bounds the engine, not R.**
  A fetched result is R memory:
  `dbGetQuery()` and a full `dbFetch()` materialize every row
  as R vectors, outside any engine limit
  ([#1065](https://github.com/duckdb/duckdb-r/issues/1065)).
  Writes have shown engine-side overshoot too, tracked in
  [#97](https://github.com/duckdb/duckdb-r/issues/97).
* **Stream instead of materializing:**
  `dbSendQueryArrow()` and `dbFetchArrowChunk()` consume a result
  batch by batch;
  see [`integrations/`](/handbook/usage/integrations/README.md).
  `dbSendQuery()` today executes and buffers eagerly —
  a known boundary
  ([#1997](https://github.com/duckdb/duckdb-r/issues/1997)).
* **Spill:** the engine offloads to `temp_directory` when a query
  outgrows memory.
  For an in-memory database the package points it at a session
  temporary directory so spill works out of the box;
  a file database is left to the engine's own default, `<dbdir>.tmp`
  beside the file (`src/duckdb/src/main/config.cpp`);
  the options that override either are
  [`storage/`](/handbook/usage/storage/README.md)'s.
  Spill covers query state, not a transaction's own uncommitted
  writes — those blocks stay pinned, so a very large single append
  can still fail at `COMMIT` under a tight limit
  (engine-side; reported once on 1.3.2 and not reproduced since,
  [#1604](https://github.com/duckdb/duckdb-r/issues/1604)).
* Larger-than-memory data is best left in DuckDB —
  query it lazily via dbplyr and `collect()` only the reduction;
  [#72](https://github.com/duckdb/duckdb-r/issues/72) is the long
  history behind that advice.

*To deepen: verify and state the engine's default `memory_limit`
as shipped, on a vendored build.*
