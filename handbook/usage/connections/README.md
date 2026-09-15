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
* **Each of those losses is now an error**
  ([#2560](https://github.com/duckdb/duckdb-r/issues/2560)),
  and taking the arguments out of `dbConnect()` altogether remains
  [#126](https://github.com/duckdb/duckdb-r/issues/126).
  A setting is refused when it *differs* from the instance's, not
  merely when it is passed: `dbConnect()` forwards the driver's own
  values, so repeating one is no collision.
  A `dbdir` that would displace the driver's is refused only when the
  driver owns a file — `dbConnect(duckdb(), "my.db")` displaces a
  throwaway in-memory database and is the documented idiom.
  The way through, either way, is `duckdb_shutdown()`.
* **Why an error and not a warning.**
  The trade is a script that used to run and now stops, against a
  setting the caller believed had applied.
  The second is the worse failure and the harder one to notice —
  a database opened writable when `read_only = TRUE` was asked for
  reads as success until something writes — and
  [tidy design](https://design.tidyverse.org/) settles which way that
  goes.
  The cost is bounded by comparing values rather than counting
  arguments: the calls that break are the ones that were already not
  doing what they said.
* **Two callers get the warning instead**
  — `datacaged` and `Rduckhts`, named in
  `INSTANCE_SETTINGS_WARN_ONLY` in [`R/Driver.R`](/R/Driver.R).
  A reverse-dependency run over 353 packages found exactly those two
  stopping where 1.5.5 ran, each on a `read_only` handed to a database
  it had opened earlier.
  The list is meant to be deleted rather than extended:
  an entry goes when that package stops passing settings to a reused
  instance, and a third package found later is a reason to reconsider
  erroring at all, not to add a line.
  Two things it does not do.
  It does not help a user's own script, or any package not named,
  doing exactly what those two do.
  And it makes the behaviour depend on the caller, so the same line
  errors from a script and warns from inside `datacaged` —
  worth remembering when a report does not reproduce.
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
drain [#455](https://github.com/duckdb/duckdb-r/issues/455).*
