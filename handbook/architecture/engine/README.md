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
jemalloc is excluded from the generated source list;
enabling it deliberately is open
([#2365](https://github.com/duckdb/duckdb-r/issues/2365)).
Compiler warnings from the vendored tree are noise the shipped
build does not silence
([#1829](https://github.com/duckdb/duckdb-r/issues/1829));
the no-suppression policy is
[`glue/`](/handbook/architecture/glue/README.md)'s.
