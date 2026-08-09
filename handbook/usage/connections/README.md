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
  keyed by the canonical path, in `driver_registry`.
  An in-memory database is never cached.
* **That cache is a correctness guard, not an optimization.**
  The engine does not refuse a second read-write instance on a file
  another instance in the same process already holds — its lock is
  per-process, and `rapi_startup()` builds a `DuckDB` directly.
  Two such instances open happily and then diverge: each sees what was
  committed before it opened and nothing the other writes afterwards.
  So `driver_registry` is what keeps one R session to one writer per
  database, and a key that fails to unify two spellings of one file is
  a data-integrity bug rather than a missed reuse
  ([`2026-08-09-path-canonicalization/`](/experiments/2026-08-09-path-canonicalization/README.md)).
* **The engine has its own instance cache, and this package does not
  use it.**
  `DBInstanceCache::GetOrCreateInstance()` keys on the same
  canonicalization this package now asks for, refuses the second
  instance the registry exists to prevent, and is reachable from the
  stable C API as `duckdb_get_or_create_from_cache()` —
  which is what `duckdb_open()` itself goes through.
  `rapi_startup()` bypasses it.
  Adopting it would retire both `path_normalize()` and
  `driver_registry`, and would change one documented behaviour: the
  engine raises `Can't open a connection to same database file with a
  different configuration` where this package silently reuses the
  first instance's settings — the loud failure
  [#2560](https://github.com/duckdb/duckdb-r/issues/2560) asks for.
* **The key is the engine's path, not R's.**
  `path_normalize()` asks DuckDB, through `rapi_canonicalize_path()`,
  rather than calling `normalizePath()`:
  the identity that decides whether two calls collide on a lock is
  the engine's, so it is the engine that should state it.
  DuckDB canonicalizes the longest existing prefix and appends the
  rest, which means a database that does not exist yet resolves
  without anything being created,
  and gets the same key it will keep once it does.
  Two spellings of one database — relative, symlinked, differently
  separated — therefore share an instance rather than colliding.
  Only `~` stays R's to expand: DuckDB has its own idea of the home
  directory, and on Windows it is not R's.
  A path that resolves no further is used as it stands.
  Refusing it is what made `duckdb()` reject network drives whose
  directories the user may traverse but not list
  ([#455](https://github.com/duckdb/duckdb-r/issues/455));
  what the two canonicalizers each resolve, and what that costs, is
  [`2026-08-09-path-canonicalization/`](/experiments/2026-08-09-path-canonicalization/README.md)'s.
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
drain [#172](https://github.com/duckdb/duckdb-r/issues/172).*
