# Data import

Getting data in (and out):
CSV and Parquet through `duckdb_read_csv()` or the engine's own
readers, many files at once,
and an R data frame through registration or the environment scan.

* **`duckdb_read_csv()`** (`?duckdb_read_csv`,
  [`R/csv.R`](/R/csv.R)) sniffs the header and column types with
  `utils::read.csv` on a prefix of the file,
  then loads via the engine.
  The sniff is the limit:
  quirky files confuse it, and options like a `filename` column
  cannot be expressed
  ([#1733](https://github.com/duckdb/duckdb-r/issues/1733)).
  A rewrite on DuckDB's native `read_csv` is the decided fix
  ([#1511](https://github.com/duckdb/duckdb-r/issues/1511));
  the wider ingestion-API design is
  [#118](https://github.com/duckdb/duckdb-r/issues/118).
* **The engine's readers** need no R wrapper:
  `read_csv`, `read_parquet`, and globs work in SQL,
  and `tbl_function(con, "read_csv('*.csv', filename = true)")`
  exposes them to dplyr —
  that, not the wrapper, is the supported way to a `filename`
  column or many-file reads today.
  Since DuckDB 1.3 `filename` is a *virtual* column:
  selecting it by name works with no option set at all,
  and `filename = true` only promotes it into `SELECT *`.
  A wrapper that forwards nothing therefore withholds less than it
  looks like — what it withholds is the column in `SELECT *`.
* **An R data frame reaches the engine by registration,**
  `duckdb_register()`, which makes a view over the data frame without
  copying it; `duckdb(environment_scan = TRUE)` does the same for a
  data frame found by name in the calling environment, and a table of
  that name in the database wins over it.
  Both bind with the connection's conversion options —
  `bigint`, `map`, `posixct` — so one data frame reaching the engine
  two ways arrives as one set of types.
  Which types those are is
  [`types/`](/handbook/usage/types/README.md)'s.
* **Out:** `COPY ... TO 'file.parquet'` in SQL;
  writing from dplyr pipelines is duckplyr's `compute_parquet()`.
* **R data frames** need no import at all:
  `duckdb_register()` scans a frame in place, zero-copy,
  and `dbWriteTable()` copies it into a table.

*To deepen: state the sniffing rules and their defaults from
`R/csv.R`; fold the [#1511](https://github.com/duckdb/duckdb-r/issues/1511)
outcome in when it lands.*
