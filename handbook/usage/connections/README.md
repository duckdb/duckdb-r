# Connections

`dbConnect()` semantics:
database instances and their caching,
when `config` and `read_only` take effect,
and `duckdb_shutdown()`.
`?duckdb` (the roxygen in [`R/Driver.R`](/R/Driver.R))
is the shipped reference for this topic
and carries the full text of these rules.

The load-bearing facts:

* `duckdb()` returns a driver that owns a *database instance*;
  `dbConnect()` opens connections to it,
  and many connections share one instance.
* For a file-based `dbdir` the instance is **cached**,
  keyed by the normalized path —
  DuckDB allows only one read-write handle per database file,
  so reuse is what lets repeated
  `dbConnect(duckdb(dbdir = "my.db"))` calls work at all.
  An in-memory database is never cached.
* `config`, `read_only`, `home`, and `shared_home`
  bind when the instance is *created*;
  a call that reuses a cached instance ignores them silently
  ([#83](https://github.com/duckdb/duckdb-r/issues/83),
  [#171](https://github.com/duckdb/duckdb-r/issues/171)).
  To apply new values to a file database,
  release the instance with `duckdb_shutdown()` first.
  Warning in exactly the surprise cases is planned
  ([#126](https://github.com/duckdb/duckdb-r/issues/126)).
* `dbDisconnect()` closes one connection only;
  its `shutdown` argument is unused.
  Instances are shut down when the driver is garbage-collected
  or the session ends.
* In a multi-statement string,
  everything before the final statement executes at prepare time,
  and `?` placeholders bind only in the last statement
  ([#179](https://github.com/duckdb/duckdb-r/issues/179)).
  DBI's `immediate = TRUE` is no way around this and no way to opt out:
  the driver has no unprepared path — every route reaches
  [`src/statement.cpp`](/src/statement.cpp)'s prepare, which is where the
  earlier statements run — and the argument lands in `...` unread,
  which it will stop doing
  ([#2498](https://github.com/duckdb/duckdb-r/issues/2498)).

*To deepen: absorb the instance and caching section of `?duckdb`;
drain [#172](https://github.com/duckdb/duckdb-r/issues/172),
[#455](https://github.com/duckdb/duckdb-r/issues/455).*
