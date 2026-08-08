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
* `dbdir`, `config`, `read_only`, `home`, and `shared_home`
  all describe the *instance*, so they bind when it is created —
  and `dbConnect()` accepts every one of them anyway,
  in two ways, neither of them what a caller wants
  ([#83](https://github.com/duckdb/duckdb-r/issues/83),
  [#171](https://github.com/duckdb/duckdb-r/issues/171)).
  `dbdir` wins: it overrides the path the driver was built with,
  silently, and opens the connection on a driver of its own,
  leaving the object passed in holding its own database.
  The rest lose: merged over the driver's, they land only where that
  call is the one creating the instance — which is why the same
  `config` argument takes effect beside a `dbdir` naming another
  file, and is dropped without it.
  Naming all of them once, in `duckdb()`, is what avoids both.
  To apply new values to a file database,
  release the instance with `duckdb_shutdown()` first;
  a setting the engine also accepts after startup, `memory_limit`
  and `threads` among them, can be `SET` on the connection instead.
  The silence is provisional in two steps:
  failing loudly where these arguments collide is
  [#2560](https://github.com/duckdb/duckdb-r/issues/2560),
  and taking them out of `dbConnect()` altogether is
  [#126](https://github.com/duckdb/duckdb-r/issues/126).
* `dbDisconnect()` closes one connection only;
  its `shutdown` argument is unused.
  Instances are shut down when the driver is garbage-collected
  or the session ends.

*To deepen: absorb the instance and caching section of `?duckdb`;
drain [#172](https://github.com/duckdb/duckdb-r/issues/172),
[#455](https://github.com/duckdb/duckdb-r/issues/455).*
