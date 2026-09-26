# The engine

The DuckDB engine embedded in `src/duckdb/`:
which commit is embedded, how that version reaches R,
and how this build differs from a stock one.
The engine itself — SQL dialect, storage, execution, tuning —
is documented at [duckdb.org/docs](https://duckdb.org/docs/)
and not repeated here;
how the copy is kept current is
[`operations/vendoring/`](/handbook/operations/vendoring/README.md).

**Identity.**
Two identifiers travel with the copy,
both defined in the vendored `pragma_version.cpp`:
`DUCKDB_VERSION` (the release string) and `DUCKDB_SOURCE_ID`
(the abbreviated upstream commit).
`PRAGMA version` returns both;
the source id is what the fast path's commit-match guard checks
([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
At vendor time `rconfigure.py` writes the version into
[`R/version.R`](/R/version.R),
which is what `dbGetInfo()` reports without opening a database.
The source id is ten characters, and it is ten because the vendor
scripts pin `core.abbrev` in the upstream clone they work from:
upstream derives it from `git describe`, whose default abbreviation
grows with the number of objects in the repository it runs in,
so without the pin the same upstream commit vendored from two clones
produced two different trees.
Ten is DuckDB's own length in the built library,
which is what the commit-match guard compares against.
Branches carry eleven-character ids from before the pin;
they are rewritten by the next vendor commit that touches them.
The *package* version is a different number, owned by
[`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md).

**How this build differs from stock.**
The authoritative flag lists are the committed
[`src/Makevars`](/src/Makevars) and
[`src/Makevars.win`](/src/Makevars.win),
both generated from [`src/Makevars.in`](/src/Makevars.in),
which is where a flag change goes.
The load-bearing ones:

* `-DDUCKDB_DISABLE_PRINT` — the engine cannot write to the console
  behind R's back.
* `-DDUCKDB_EXTENSION_AUTOLOAD_DEFAULT` and the linked extension set —
  what they mean for a reader loading an extension is
  [`usage/extensions/`](/handbook/usage/extensions/README.md)'s.
* `-DDUCKDB_PLATFORM_RTOOLS=1` — Windows only;
  the `_mingw` platform string extension downloads key on.
* `-DDUCKDB_RSTRTMGR` — Windows restart-manager support,
  set by `configure.win` and off on R < 4.2, which ships no `librstrtmgr.a`.
* `-DBROTLI_ENCODER_CLEANUP_ON_OOM` — an R package must not `exit()`.
* `-DDUCKDB_ENABLE_JEMALLOC` — 64-bit glibc Linux only,
  and the one flag `configure` decides rather than `rconfigure.py`.

**The allocator.**
DuckDB allocates through `Allocator::DefaultAllocate`:
`malloc` in `allocator_standard.cpp`, jemalloc in `allocator_jemalloc.cpp`,
and a build compiles exactly one of the two.
Upstream builds jemalloc on 64-bit glibc Linux and nowhere else —
its `CMakeLists.txt` gates the target on exactly that,
and the wrapper stops with an `#error` everywhere else —
so macOS, Windows, 32-bit and musl keep the standard allocator
([#2365](https://github.com/duckdb/duckdb-r/issues/2365)).
This package makes the same choice, and makes it in `configure`,
because `src/Makevars` is generated once on the vendoring machine
while the platform that decides is the one doing the compiling.
`configure` probes with the compiler R will use and writes
`src/Makevars.jemalloc`, which adds the define, the include path
and `$(SOURCES_JEMALLOC)` —
a source list of its own, because `src/include/sources.mk` is shared with Windows.
`DUCKDB_R_DISABLE_JEMALLOC=1` keeps the standard allocator regardless
([`build/configuration/`](/handbook/build/configuration/README.md)).
Upstream's amalgamation lists the wrapper and not the allocator,
so `rconfigure.py` copies `third_party/jemalloc/` itself —
minus `jemalloc_cpp.cpp`, which overrides global `new` and `delete`:
that is DuckDB's `OVERRIDE_NEW_DELETE`,
and not something an R package may do to the process it is loaded into.
What the swap buys is thread-local caches and per-arena purging
under parallel execution.
With the standard allocator `Allocator::SupportsFlush()` is glibc-only,
`ThreadIdle()` does nothing,
and `allocator_background_threads` and the flush thresholds are inert settings.

Compiler warnings from the vendored tree are noise the shipped
build does not silence
([#1829](https://github.com/duckdb/duckdb-r/issues/1829));
the no-suppression policy is
[`glue/conventions/`](/handbook/architecture/glue/conventions/README.md)'s.
