# Configuration

The knobs that change how the package builds.
What the build does with them is
[`source-build/`](/handbook/build/source-build/README.md)'s;
runtime settings that share the `DUCKDB_R_` prefix
belong to the leaves that own them.

Read at build time:

* **`MAKEFLAGS`** — parallelism.
  When unset, `configure` fills it in via
  [`tools/setup-makeflags.R`](/tools/setup-makeflags.R) —
  capped at `-j2` unless `NOT_CRAN` is truthy, per CRAN policy.
  Set `-j$(nproc)` yourself for local builds.
  The helper lives in `tools/` because `R CMD build` keeps that directory
  and drops `scripts/` (`.Rbuildignore`),
  so a package installed from the tarball can still read it.
  `configure` takes its output only when it is a `-jN`:
  `Rscript` reports a file it cannot open on *stdout*,
  so a helper it cannot find would otherwise be exported as `MAKEFLAGS`
  verbatim, and the build would run serially with no visible error.
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
  The `-UNDEBUG` is the consequential one,
  because it compiles the engine with its assertions live.

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

**The assert-enabled engine is `load_all()`'s alone.**
Nothing here defines `DEBUG` or `DUCKDB_FORCE_ASSERT`,
so `D_ASSERT` is plain `assert` in every build this package makes,
and `-UNDEBUG` is what puts the condition back into the code.
The engine guards the code that only an assertion needs with `D_ASSERT_IS_ENABLED`,
which upstream defines only on the branch those two macros select,
so the guard and the assertion disagree exactly under `-UNDEBUG`:
a helper compiled out while the assertion that calls it stays,
which is a compile error rather than a quiet difference in behaviour.
One site in the vendored engine has that shape, `src/duckdb/src/function/variant/variant_shredding.cpp`,
so `load_all()` from source stops there, with `IsVariantStringType` not declared,
until [#2841](https://github.com/duckdb/duckdb-r/pull/2841) patches the macro to agree.
`PKG_BUILD_EXTRA_FLAGS=false` gets past it with R's own flags, the ones `R CMD INSTALL` uses,
and the fast path compiles no engine at all.

**No CI job reaches that compile**, so a contributor's first `load_all()` is what finds a break of this kind.
A job on the fast path compiles no engine,
and a job that builds one installs it in the checkout before any gate runs,
so a later `load_all()`, the `roxygen` gate's among them
([`operations/ci/per-commit/legs/`](/handbook/operations/ci/per-commit/legs/README.md)),
finds `src/duckdb.so` newer than the sources and recompiles nothing.
