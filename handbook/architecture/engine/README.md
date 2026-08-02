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
Two identifiers travel with the copy, both defined in the vendored
`pragma_version.cpp`:
`DUCKDB_VERSION` (the release string) and `DUCKDB_SOURCE_ID`
(the abbreviated upstream commit).
`PRAGMA version` returns both;
the source id is what the fast path's commit-match guard checks
([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
At vendor time `rconfigure.py` writes the version into
[`R/version.R`](/R/version.R) (generated — correct the generator),
which is what `dbGetInfo()` reports without opening a database.
The *package* version is a different number,
owned by
[`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md).

**How this build differs from stock.**
The committed [`src/Makevars`](/src/Makevars) is the authoritative
flag list; the load-bearing ones:
`-DDUCKDB_DISABLE_PRINT` (the engine cannot write to the console
behind R's back),
`-DDUCKDB_EXTENSION_AUTOLOAD_DEFAULT` (autoload on,
autoinstall stays off —
[`usage/extensions/`](/handbook/usage/extensions/README.md)),
the linked extension set (`parquet`, `core_functions`),
`-DDUCKDB_RSTRTMGR` and `-DDUCKDB_PLATFORM_RTOOLS=1` on Windows
(the `_mingw` platform string extension downloads key on),
and `-DBROTLI_ENCODER_CLEANUP_ON_OOM`
(an R package must not `exit()`).
jemalloc is excluded from the generated source list;
enabling it deliberately is open
([#2365](https://github.com/duckdb/duckdb-r/issues/2365)).
Compiler warnings from the vendored tree are noise the shipped
build does not silence
([#1829](https://github.com/duckdb/duckdb-r/issues/1829));
the no-suppression policy is
[`glue/`](/handbook/architecture/glue/README.md)'s.
