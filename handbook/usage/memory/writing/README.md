# Writing

What writing into the engine costs:
a data frame through `dbWriteTable()` and `dbAppendTable()`,
a query result through `CREATE TABLE ... AS`, a temp table or
`COPY ... TO`,
and what an open transaction holds.
The budget it counts against, and where it spills, is
[`budget/`](/handbook/usage/memory/budget/README.md)'s;
the import surfaces are
[`data-import/`](/handbook/usage/data-import/README.md)'s.

* **A data frame is scanned in place, and the table is a second copy.**
  `dbWriteTable()` registers the frame as a view,
  runs `CREATE TABLE ... AS SELECT ... FROM` that view,
  and unregisters it
  ([`R/dbWriteTable__duckdb_connection_character_data.frame.R`](/R/dbWriteTable__duckdb_connection_character_data.frame.R));
  `dbAppendTable()` does the same through `INSERT INTO ... SELECT`
  ([`R/dbAppendTable__duckdb_connection.R`](/R/dbAppendTable__duckdb_connection.R)).
  Registration copies nothing but the columns it must re-encode —
  non-UTF-8 strings and `POSIXlt` (`encode_values()`,
  [`R/register.R`](/R/register.R)) —
  and the scan reads the R vectors directly;
  a deferred column, such as a compact sequence, is made real in R at
  bind time, so it costs its full size first
  ([`architecture/glue/threading/`](/handbook/architecture/glue/threading/README.md)
  owns why bind is where that happens).
  On the engine side the new table is buffer-pool memory:
  in an in-memory database it stays resident up to the limit and is
  offloaded to `temp_directory` beyond it;
  in a file database it is written through to the file as the
  statement runs, and only a working set stays in the pool.
  The peak is therefore the frame plus at most the limit —
  and with no limit set, the frame plus a whole engine copy.
  [#97](https://github.com/duckdb/duckdb-r/issues/97) reported twice
  the data for a large write;
  its reprex passes the limit through `dbConnect(config = )`,
  the form that does not reach a running instance
  ([#126](https://github.com/duckdb/duckdb-r/issues/126)),
  and with the limit set where it takes effect the same write stays
  within it — measured, with every other number on this page, in
  [`experiments/2026-09-14-memory-clients/`](/experiments/2026-09-14-memory-clients/README.md).
* **Row-wise parameters cost one statement per row.**
  `dbBind()` or `params = ` with `n` rows executes the statement `n`
  times (`rapi_bind()`, [`src/statement.cpp`](/src/statement.cpp)),
  each its own auto-commit transaction unless `dbBegin()` wraps them:
  bounded in memory, and slow in proportion.
* **A query result written engine-side is budgeted.**
  `CREATE TABLE ... AS`, a temp table, duckplyr's `compute()`:
  the result lands in the buffer pool, counted and spillable,
  and none of the copies in flight that
  [`reading/`](/handbook/usage/memory/reading/README.md) describes
  ever arise.
  `COPY ... TO` and `compute_parquet()` stream the result to the file
  through per-thread buffers around the row group being written,
  and nothing crosses into R at all.
* **An open transaction holds nothing extra.**
  An uncommitted append is table blocks like any other:
  offloaded to `temp_directory` in an in-memory database,
  written through in a file database,
  and `COMMIT` then succeeds under the same limit.
  The one report of a `COMMIT` failing under a tight limit,
  [#1604](https://github.com/duckdb/duckdb-r/issues/1604),
  did not reproduce on four builds
  ([`experiments/2026-08-temp-storage-spill/`](/experiments/2026-08-temp-storage-spill/README.md)).
* **A registered Arrow object** is scanned batch by batch through
  its own reader;
  its memory is Arrow's, and returns at Arrow's pace once the object
  is unregistered and dropped
  ([#1089](https://github.com/duckdb/duckdb-r/issues/1089):
  a second `gc()` was what it took).
