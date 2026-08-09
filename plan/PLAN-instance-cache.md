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

## Open, found while implementing

**Storage resolution now runs for calls that used to skip it.**
`duckdb()` resolves the extension and secret home before it reaches the
glue, and `driver_registry` used to return a cached driver *before* that
happened.
Without the registry every call resolves, so a second
`duckdb(dbdir, shared_home = TRUE)` on a live instance records a
session-wide choice — and `shared_home = TRUE` creates `~/.duckdb` — for
a call that changes nothing about the database.
`tests/testthat/test-storage-message-once.R` catches this: it was
written to assert that an ignored argument records no choice, and it now
fails.

The fix is not a reordering: on a reuse the config must *match* the live
instance's or the engine refuses it, so R cannot simply omit the storage
entries it would otherwise resolve.
Something has to tell R that an instance already exists before it
resolves anything — `DBInstanceCache::GetInstance()` returns `nullptr`
for an absent one and is the obvious probe, but it takes a config to
compare, which is the thing R has not built yet.
Settling this is the next step, and it decides whether the swap can be
one change or needs the storage resolution moved behind the glue.

## What the review found

A correctness pass over the implementation on this branch, with the
suite passing everything except the storage defect above.
The ranked findings, and what they do to the design.

**Blocking: the busy-spin hangs R, and nothing on this side can avoid
it.**
`GetInstanceInternal()` spins on `while (!weak_cache_entry.expired())`
waiting for another thread to finish a shutdown.
`~DatabaseInstance` releases the cache entry on its *last* line, so any
`DatabaseInstance` outliving its `DuckDB` handle leaves the entry alive
with a null `database` — the exact state the spin waits for.
In a single-threaded R process nothing ever releases it, and the loop
has no `R_CheckUserInterrupt()`, so the session wedges at 100% CPU and
Ctrl-C does not break out.
Reaching it takes no mistake: a `dbSendQuery()` result that has not been
cleared holds a `ClientContext`, which holds the `DatabaseInstance`, so
shutting the driver down and reopening the same file is enough.
This is the risk this document said to settle first, and it settles
against the swap: the package cannot keep a `DuckDB` handle alive for
every `ClientContext` it does not own.
An upstream fix — a bounded wait, or releasing the entry earlier in
`~DatabaseInstance` — is the precondition for any of the rest.

**The R side has to say what the engine cannot.**
The engine refuses a config mismatch with a message naming neither the
setting nor the way out, and it now fires where this package used to
reuse silently: `read_only`, `config`, and any two calls whose storage
home resolves differently.
The refusals [#2641](https://github.com/duckdb/duckdb-r/pull/2641) adds
have to land first, in front of the engine's.

**`allow_extensions` and `environment_scan` are worse than dropped.**
They live on the discarded wrapper, so a cache hit takes the first
instance's values while the *driver object* reports the second call's —
a driver that says the
[#1107](https://github.com/duckdb/duckdb-r/issues/1107) crash guard is
on against an engine that has it off.
Refusing them, as this document assumed, is not optional.

**`:memory:name` is cached.**
Only `""` and exactly `":memory:"` take `NEVER_CACHE`, so a named
in-memory database is shared against both `?duckdb` and the comment
above the branch — and then fails its own second call, because
`resolve_temp_directory()` hands each one a fresh `temp_directory` that
the config comparison rejects.

**Smaller, all real:** `dbConnect(drv, dbdir = <what the user spelled>)`
no longer matches `drv@dbdir`, which now holds the engine-canonical
path, so it silently invalidates the driver;
`RInstanceCache::wrappers` is never pruned and keeps a control block per
database opened, for the life of the process;
`duckdb_shutdown()` no longer releases the file to another process while
any instance reference survives, which `?duckdb` still promises it does;
and the `catch (std::exception &)` now spans code that can raise
`cpp11::unwind_exception`, which it would swallow.

*Not* found, and worth recording: no path spelling produces two
instances — `GetDBAbsolutePath()` is at least as strong as the deleted
`path_normalize()`, verified across relative, `..`, symlinked and
not-yet-existing paths — there is no reference cycle, `on_create` holds
exactly what belongs there, and the discarded `replacement_scans` are
never retained.
The approach is sound; the engine is not ready to carry it.

## The patch

[`patch/0039-Bound-the-instance-cache-shutdown-wait.patch`](/patch/0039-Bound-the-instance-cache-shutdown-wait.patch)
bounds the spin: it keeps waiting while an entry that is genuinely
shutting down expires, and raises once a deadline passes instead of
looping forever.
Twenty-three added lines, nothing upstream removed or reordered, so a
re-vendoring reapplies it without conflict.

Raising rather than falling through to `CreateInstance()` is the load-
bearing half.
The file lock does not fire within one process, so a create would
*succeed* and leave two instances writing one file — the exact
data-integrity bug the cache exists to prevent.
A clear error is the only safe answer.

Confirmed against a source build: the repro that wedged the session now
raises `Database "..." is still in use: an earlier instance has been
released but something is still holding it open` and returns control.

Verifying it took one detour worth recording. The engine is a unity
build -- `db_instance_cache.cpp` is `#include`d into `ub_src_main.cpp`,
and make's prerequisite is the unity file, not its members -- and
`Config/build/never-clean` keeps objects across installs. So editing a
vendored source marks nothing out of date: the first build linked an
object older than the edit and succeeded, and the repro still hung
against code that had never been compiled. Deleting the containing
`ub_*.o` by hand is what makes a vendored edit take effect.

The patch fixes the source build, which is what CRAN ships.
It does **not** fix the fast path
([`build/fast-paths/`](/handbook/build/fast-paths/README.md)), which
links a released `libduckdb` and cannot see a vendored change — so a
developer build with `DUCKDB_R_USE_SYSTEM_LIB=1` still hangs until the
fix is upstream and released.
That asymmetry is the reason to send it upstream rather than carry it.

## Staging

0. Get the busy-spin bounded. Carried as patch 0039 for the source
   build, and to be sent upstream — the fast path cannot see a vendored
   change, so only a released fix closes it everywhere.
1. Settle the linkage question. Done for Linux — the symbol resolves
   from the released `libduckdb` v1.5.5 and a probe links and runs
   against it — macOS unverified.
2. The glue swap, with the wrapper moved into `on_create`.
3. The R side: delete `path_normalize()` and `driver_registry`, keep
   #2641's refusals in front of the engine's.
4. Retire `rapi_canonicalize_path()` and close #2627.

Steps 2 and 3 are one change — the R side cannot keep a registry keyed
on a path the glue no longer computes.
