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
  `dbdir` wins: it overrides the path the driver was built with
  and opens the connection on a driver of its own,
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
* **Each of those losses is now a warning**
  ([#2560](https://github.com/duckdb/duckdb-r/issues/2560)),
  and taking the arguments out of `dbConnect()` altogether remains
  [#126](https://github.com/duckdb/duckdb-r/issues/126).
  A setting is reported when it *differs* from the instance's, not
  merely when it is passed: `dbConnect()` forwards the driver's own
  values, so repeating one is no collision.
  A `dbdir` that displaces the driver's is reported only when the
  driver owns a file — `dbConnect(duckdb(), "my.db")` displaces a
  throwaway in-memory database and stays silent, because that is the
  documented idiom.
* **A `dbdir` an extension answers is not normalized.**
  `md:` (MotherDuck), `ducklake:` and their kind name a replacement
  open, not a file, so they pass through untouched; normalizing one
  turned it into a local file name the engine then failed to open.
  The test for a prefix is the engine's own: two or more
  alphanumeric characters before the first colon, which leaves `C:\db`
  a Windows path, and `://` after them marks a URL scheme rather than
  a prefix, which leaves `s3://` to be normalized like any other path.
* `dbDisconnect()` closes one connection only;
  its `shutdown` argument is unused.
  Instances are shut down when the driver is garbage-collected
  or the session ends.

*To deepen: absorb the instance and caching section of `?duckdb`;
drain [#172](https://github.com/duckdb/duckdb-r/issues/172),
[#455](https://github.com/duckdb/duckdb-r/issues/455).*
