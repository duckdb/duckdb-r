# Configuration

The knobs that change how the package builds.
What the build does with them is
[`source-build/`](/handbook/build/source-build/README.md)'s;
runtime settings that share the `DUCKDB_R_` prefix are listed at
the end.

Read at build time:

| Knob | What it does |
|---|---|
| `MAKEFLAGS` | Parallelism. When unset, `configure` fills it in via [`scripts/setup-makeflags.R`](/scripts/setup-makeflags.R) — capped at `-j2` unless `NOT_CRAN` is truthy, per CRAN policy. Set `-j$(nproc)` yourself for local builds. |
| ccache | Not a variable — wrap the compilers in `~/.R/Makevars`, inferring each default with `R CMD config` and prepending `ccache`. Repeat builds of the vendored tree drop from minutes to seconds. |
| `UserNM` | `UserNM=true` skips the `nm` symbol sweep at install time. Never for `R CMD check` — [`source-build/`](/handbook/build/source-build/README.md) says what it blinds. |
| `DUCKDB_R_USE_SYSTEM_LIB` | The fast path — [`fast-paths/`](/handbook/build/fast-paths/README.md). |
| `DUCKDB_R_LIB_DIR` | Where the fast path looks for `libduckdb` before `pkg-config` and the usual directories. |
| `DUCKDB_R_PREBUILT_ARCHIVE` | Path to a `.tar` of vendored object files: reused if it exists, written after the build if not. A CI cache device; locally ccache does the same job better. |
| `PKG_BUILD_EXTRA_FLAGS` | pkgbuild's knob (`load_all()`, not `R CMD INSTALL`): default merges `-UNDEBUG -Wall -pedantic -g -O0` over `~/.R/Makevars`; set `false` to keep your own optimisation flags. |

Read at *vendoring* time by
[`scripts/rconfigure.py`](/scripts/rconfigure.py) —
setting them at install time does nothing, because the generated
`src/Makevars` is committed:
`DUCKDB_R_EXTENSIONS` (extra linked extensions beyond `parquet`
and `core_functions`),
`DUCKDB_DEBUG_MOVE`, `DUCKDB_R_LINENR`, `DUCKDB_PATH`
([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).

Not build knobs, documented where they act:
`DUCKDB_R_HOME` and `DUCKDB_R_TEMP_DIRECTORY`
([`usage/storage/`](/handbook/usage/storage/README.md)),
`DUCKDB_R_ALLOW_EXTENSIONS`
([`usage/extensions/`](/handbook/usage/extensions/README.md)),
`DUCKDB_R_RUN_TESTS`
([`testing/guards/`](/handbook/testing/guards/README.md)),
`DUCKDB_R_POISON_ENGINE`
([`operations/ci/matrix/`](/handbook/operations/ci/matrix/README.md)),
and `DUCKDB_R_LIB_VERSION` / `DUCKDB_R_LIB_URL`, which steer
`install-libduckdb.sh`
([`fast-paths/`](/handbook/build/fast-paths/README.md)).
There is no knob for the C++ standard, optimisation, or warnings:
`src/Makevars.in` pins `CXX_STD = CXX17` and leaves the rest to
R's `Makeconf`.
