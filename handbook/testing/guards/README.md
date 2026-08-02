# Guards

Two checks that fail loudly rather than let a defect ship:
the CRAN guard, which keeps DuckDB's bundled C++ engine
out of CRAN's check farm,
and the flavor-name guard, which keeps the package name
from being written down anywhere the flavor rename cannot reach.

## The CRAN guard

The suite and the runnable examples both start the bundled engine.
That is too heavy for CRAN's check farm in time and in memory,
and past checks there were fragile in ways we could not reproduce.
The guard prevents a submission that spends the farm's budget on the engine —
and, symmetrically, it prevents a green local `R CMD check`
that quietly ran no tests at all,
because whenever it declines it says so in a framed message
that names the environment variable to set.

The decision is not testthat's usual `NOT_CRAN` dance.
`tests/testthat.R` decides for itself whether to call `test_check()` at all:

* `DUCKDB_R_RUN_TESTS` always wins.
  A true-ish value (`true`, `1`, `yes`, `on`, case- and space-insensitive)
  runs the suite; a false-ish value (`false`, `0`, `no`, `off`) forces it off.
* With no explicit setting,
  the suite runs when `GITHUB_ACTIONS` is `true`
  or when `MY_UNIVERSE` is non-empty —
  our own CI and r-universe respectively,
  both of which are GitHub Actions.
* Everywhere else, including CRAN, nothing runs.

The same decision exists a second time in `R/cran-guard.R`
as `duckdb_run_tests_enabled()`,
which gates the runnable examples through `examples_enabled()` —
the condition behind every
`@examplesIf simulate_duckdb()$env$examples_enabled()` in `R/`.
The duplication is deliberate:
`tests/testthat.R` inlines the logic
so that the guard is self-contained and readable
without loading the package it is about to test.
Both halves emit a message when they decline,
so a skipped example is as visible as a skipped suite.

Boundaries.
`NOT_CRAN` plays no part in the decision:
setting it alone does not run the suite.
`scripts/snapshot-accept.sh` sets `NOT_CRAN=true` and `DUCKDB_R_RUN_TESTS=true`
together, and it is the second of the two that opens this gate.
The guard lives in `tests/testthat.R`,
which `testthat::test_local()` never reads,
so the local fast loop is never gated —
see [`testing/suite/`](/handbook/testing/suite/README.md).
And the guard is a gate on the whole suite, not a per-test skip;
the `skip_on_*()` helpers that decide individual tests
belong to the suite's helpers, not here.

That the gate actually holds is checked, not assumed.
One matrix entry builds the engine with a tripwire
(`-DDUCKDB_R_POISON_ENGINE`, declared in `src/include/rapi.hpp`)
and forces `DUCKDB_R_RUN_TESTS=false`,
so any test or example that still reaches the engine aborts the check —
see [`operations/ci/matrix/`](/handbook/operations/ci/matrix/README.md).

## The flavor-name guard

Every flavor but the mainline one ships this package under a different name,
so a literal `duckdb` written into the sources
keeps pointing at the mainline package in those builds.
It works on `main`, breaks everywhere else, and breaks silently —
usually noticed by a user rather than by CI.
The rename itself is
[`branches/flavors/`](/handbook/branches/flavors/README.md)'s topic;
the run-time seam that code is supposed to use instead,
`get_package_name()`, is
[`architecture/r-layer/`](/handbook/architecture/r-layer/README.md)'s.
The guard is what makes ignoring the seam impossible to do by accident.

`flavor_package_name_offenders()` in `scripts/flavor-package-name.R`
scans the tree and returns every hard-coded occurrence
as a `path:line: content` string.
It reads the allowlist out of `scripts/flavor.patch` itself —
the trimmed `-` lines of each hunk, keyed by path —
so what the rename already accounts for cannot drift
from what the scan tolerates.
The R-level surface (`R/`, `man/`, `tests/`, `vignettes/`,
and the Markdown files at the top level)
is scanned for `duckdb::`, `duckdb:::`, and `"duckdb"`;
the C++ glue (`src/`, `inst/include/`, excluding the vendored `src/duckdb/`)
only for the quoted form,
because `duckdb::` there is the engine's own C++ namespace
and has nothing to do with the R package name.

A new hit is meant to be resolved, not silenced.
In code, ask for the name at run time with `get_package_name()`.
In docs, do not qualify our own objects at all.
If the literal really names something else that happens to be spelled the same —
the DuckDB CLI executable, say —
write it in two pieces as `paste0("duck", "db")` so it reads as what it is.
Otherwise, teach `scripts/flavor.patch` to rewrite it.

The scan is deliberately base R only
and does not need the package loaded,
because CI runs it straight against a plain checkout:
a step in `.github/workflows/custom/after-install`,
restricted to the `rcc-smoke` job.
It reads the checkout and nothing else,
so every other matrix entry would return the same answer
and running it once is enough.

`tests/testthat/test-flavor-package-name.R` wraps the same function
for `testthat::test_local()`,
and skips when `scripts/flavor-package-name.R` is not next to the sources.
That skip is not a fallback — it is the reason the CI step exists.
`R CMD check` runs the tests from a built tarball,
and `scripts/` is `.Rbuildignore`d,
so neither the scan nor the patch it reads is present there
and the test can only skip.
Delete the CI step and the guard is gone
in the one place it would ever have fired;
delete the guard entirely
and a hard-coded `duckdb:::` reaches the wrong package,
or no package at all,
in every flavored build.

Limits.
The scan is a text search over a fixed file list,
so it cannot tell a deliberate literal from a mistake —
hence the `paste0()` convention rather than an inline exemption.
Only the top-level Markdown files are scanned,
which leaves `handbook/` and `scripts/*.md` uncovered;
both are `.Rbuildignore`d and ship to nobody,
but a handbook page that qualifies our own objects with `duckdb::`
would still be wrong on every flavor and the guard will not say so.
Snapshots under `tests/testthat/_snaps/` are outside the scan as well.
