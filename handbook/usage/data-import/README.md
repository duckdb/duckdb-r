# Data import

Getting CSV and Parquet data in (and out):
`duckdb_read_csv()` versus the engine's own readers,
and reading many files at once.

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
* **Out:** `COPY ... TO 'file.parquet'` in SQL;
  writing from dplyr pipelines is duckplyr's `compute_parquet()`.
* **R data frames** need no import at all:
  `duckdb_register()` scans a frame in place, zero-copy,
  and `dbWriteTable()` copies it into a table.

*To deepen: state the sniffing rules and their defaults from
`R/csv.R`; fold the [#1511](https://github.com/duckdb/duckdb-r/issues/1511)
outcome in when it lands.*
