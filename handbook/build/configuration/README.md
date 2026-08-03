# Configuration

The knobs that change how the package builds.
What the build does with them is
[`source-build/`](/handbook/build/source-build/README.md)'s;
runtime settings that share the `DUCKDB_R_` prefix
belong to the leaves that own them.

Read at build time:

* **`MAKEFLAGS`** — parallelism.
  When unset, `configure` fills it in via
  [`scripts/setup-makeflags.R`](/scripts/setup-makeflags.R) —
  capped at `-j2` unless `NOT_CRAN` is truthy, per CRAN policy.
  Set `-j$(nproc)` yourself for local builds.
* **ccache** — not a variable:
  wrap the compilers in `~/.R/Makevars`,
  inferring each default with `R CMD config` and prepending `ccache`.
  Repeat builds of the vendored tree drop from minutes to seconds.
* **`UserNM`** — `UserNM=true` skips the `nm` symbol sweep at install time.
  Never for `R CMD check`: it blinds the check's symbol scan.
* **`DUCKDB_R_USE_SYSTEM_LIB`** — the fast path —
  [`fast-paths/`](/handbook/build/fast-paths/README.md).
* **`DUCKDB_R_LIB_DIR`** — where the fast path looks for `libduckdb`
  before `pkg-config` and the usual directories.
* **`DUCKDB_R_PREBUILT_ARCHIVE`** — path to a `.tar` of vendored object files:
  reused if it exists, written after the build if not.
  A CI cache device; locally ccache does the same job better.
* **`PKG_BUILD_EXTRA_FLAGS`** — pkgbuild's knob
  (`load_all()`, not `R CMD INSTALL`):
  the default merges `-UNDEBUG -Wall -pedantic -g -O0` over `~/.R/Makevars`;
  set `false` to keep your own optimisation flags.

Read at *vendoring* time by
[`scripts/rconfigure.py`](/scripts/rconfigure.py) —
setting them at install time does nothing, because the generated
`src/Makevars` is committed
([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)):

* **`DUCKDB_R_EXTENSIONS`** — extensions linked beyond the standing set
  ([`usage/extensions/`](/handbook/usage/extensions/README.md)).
* **`TREAT_WARNINGS_AS_ERRORS`** — appends `-Werror`.
* **`DUCKDB_DEBUG_MOVE`**, **`DUCKDB_R_LINENR`** — debug flags.
* **`DUCKDB_PATH`** — where the upstream checkout is read from.

Not every `DUCKDB_R_` variable is a build knob:
one that acts at run time or in a helper script
is documented at the leaf that owns its topic,
and this page names only what the build reads.
There is no knob for the C++ standard or optimisation:
`src/Makevars.in` pins `CXX_STD = CXX17` and leaves the rest to R's `Makeconf`.
