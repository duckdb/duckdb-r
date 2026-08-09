# Hand the driver cache to the engine

Replace `driver_registry` and `path_normalize()` with
`DBInstanceCache`, the instance cache DuckDB already keeps and this
package bypasses.
What the cache does today is
[`usage/connections/`](/handbook/usage/connections/README.md)'s;
this is the design for moving it.

## Why

Two facts, both measured in
[`2026-08-09-path-canonicalization/`](/experiments/2026-08-09-path-canonicalization/README.md).

**The registry is a correctness guard, not an optimization.**
DuckDB's file lock is per-process, and `rapi_startup()` builds a
`DuckDB` directly, so two read-write instances on one file in one R
session both open and then diverge — each sees what was committed
before it opened and nothing the other writes afterwards.
`driver_registry` is the only thing preventing that, which makes a key
that fails to unify two spellings of one path a data-integrity bug.

**The engine already keys on the identity we are trying to compute.**
`DBInstanceCache::GetOrCreateInstance()` canonicalizes with
`FileSystem::CanonicalizePath()` and passes an extension-prefixed
`dbdir` (`md:`, `ducklake:`) through untouched — the two behaviours
[#2627](https://github.com/duckdb/duckdb-r/pull/2627) and
[#2641](https://github.com/duckdb/duckdb-r/pull/2641) each add to the R
side by hand.
It also refuses the second instance the registry exists to prevent, in
C++, where the engine can see it.

Adopting it retires `path_normalize()`, `driver_registry` and
`rapi_canonicalize_path()`, and makes
[#455](https://github.com/duckdb/duckdb-r/issues/455) structural rather
than fixed: no R-side resolution is left to refuse a network path.

## The shape

`rapi_startup()` stops calling `make_uniq<DuckDB>(dbdirchar, &config)`
and calls `GetOrCreateInstance()` on one process-wide cache, doing its
per-instance setup in that call's `on_create` callback.
The R layer stops normalizing and stops registering: `duckdb()` hands
`dbdir` over as the caller spelled it.

## The decisions this rests on

* **The wrapper becomes one per instance, not one per call.**
  `DBConfig::operator==` compares `options` only
  ([`config.cpp:700`](/src/duckdb/src/main/config.cpp)), so the
  `ReplacementDataDBWrapper` back-pointer this package puts in
  `config.replacement_scans` does not break cache equality — and that is
  the hazard, not the relief.
  A cache hit returns an instance whose replacement scans still point at
  the **first** caller's `DBWrapper`, so a second `DBWrapper` would be a
  wrapper nothing routes to.
  The wrapper has to be created inside `on_create` and shared with the
  instance, and `DBWrapper::db` becomes a `shared_ptr<DuckDB>` — the
  rewrite the `// FIXME: Rewrite properly with shared pointers` in
  [`src/database.cpp`](/src/database.cpp) already names.
* **Catalog work moves into `on_create`.**
  Forcing `arrow_scan` to `INITIALIZE_ON_SCHEDULE` and registering
  `DataFrameScanFunction` run unconditionally today.
  Against a shared instance the second call would re-register into a
  catalog that already has them.
  `on_create` is the callback `GetOrCreateInstance()` takes for exactly
  this, and it runs once per instance.
* **`allow_extensions` and `environment_scan` are not in `DBConfig`.**
  They live on the wrapper, so the cache cannot see a conflict in them
  and will hand back an instance built with the other value.
  They are refused on a reused instance, the way
  [#2641](https://github.com/duckdb/duckdb-r/pull/2641) refuses
  `read_only` and `config`.
* **The R-side refusal runs before the engine's.**
  The cache raises `Can't open a connection to same database file with a
  different configuration than existing connections`, which names
  neither the setting nor the way out.
  #2641's checks stay in front of it and keep saying which setting and
  what to do; the engine's is the backstop for what R cannot see.
* **`duckdb_shutdown()` stops guaranteeing a shutdown.**
  The cache holds a `weak_ptr`; the instance dies when the last
  `shared_ptr` goes.
  A driver released while another still holds the instance no longer
  destroys it — closer to what the function should have meant, and a
  documented behaviour change either way.

## The risks to settle first

* **`DBInstanceCache` is not `DUCKDB_API`-exported**
  ([`db_instance_cache.hpp:31`](/src/duckdb/src/include/duckdb/main/db_instance_cache.hpp)),
  unlike `FileSystem::CanonicalizePath`.
  A vendored build links it; the fast path links a released
  `libduckdb` and may not
  ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
  The C API alternative, `duckdb_get_or_create_from_cache()`, is stable
  but yields an opaque `duckdb_database` where the glue needs `DuckDB &`
  for catalog work and replacement scans.
  Settling this is the first step, and an exported cache — or a C API
  that yields the instance — is the upstream request either way.
* **`GetInstanceInternal()` busy-spins** while an entry that is shutting
  down expires (`while (!weak_cache_entry.expired()) {}`).
  That spin would run inside R, uninterruptible.
  How reachable it is from this package's lifecycle needs establishing
  before the swap, not after.

## Staging

1. Settle the linkage question: build against a released `libduckdb` on
   Linux and macOS and see whether the symbol resolves.
2. The glue swap, with the wrapper moved into `on_create`.
3. The R side: delete `path_normalize()` and `driver_registry`, keep
   #2641's refusals in front of the engine's.
4. Retire `rapi_canonicalize_path()` and close #2627.

Steps 2 and 3 are one change — the R side cannot keep a registry keyed
on a path the glue no longer computes.
