# Data import

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](../../meta/handbook/);
the last section holds this leaf's parameters.*

Scope: `duckdb_read_csv()` versus the SQL readers, globs,
and Parquet ingestion.

Today:

* `?duckdb_read_csv` — the function reference
* a CSV concept page (`.Rd`) is the natural next home, not yet written

To write this leaf:

* own: `duckdb_read_csv()` versus SQL `read_csv`, globs,
  Parquet in and out
* drain: #118, #1511, #1733
* stage the facts here until a CSV reference page exists,
  then invert to a pointer
