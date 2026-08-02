# Connections

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](/handbook/meta/handbook/);
the last section holds this leaf's parameters.*

Scope: `dbConnect()` semantics: instance caching, `config` and `read_only`,
`dbdir` precedence, `duckdb_shutdown()`.

Today:

* `?duckdb` — the driver reference
* a connection-semantics concept page (`.Rd`) is the natural next home,
  not yet written

To write this leaf:

* gather: the `dbConnect()` / `duckdb()` roxygen in `R/Driver.R`
  and `R/dbConnect__duckdb_driver.R`;
  instance caching, `config` / `read_only` binding, `dbdir` precedence
* drain: #83, #126, #171, #172, #179, #455
* stage the facts here until a `?duckdb_connections` reference page
  exists, then invert to a pointer
