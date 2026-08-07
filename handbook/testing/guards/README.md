# Guards

The checks that fail loudly rather than let a defect ship:
the CRAN guard,
which keeps the bundled engine off CRAN's check farm,
and the flavor-name guard,
which keeps the package name from being written
where the rename cannot reach.

**The CRAN guard.**
The suite and the runnable examples both start the bundled engine —
too heavy for CRAN's farm.
`tests/testthat.R` decides for itself,
in inlined, self-contained logic:
`DUCKDB_R_RUN_TESTS` always wins (true-ish on, false-ish off);
otherwise the suite runs when `GITHUB_ACTIONS` is `true` or
`MY_UNIVERSE` is non-empty; everywhere else — including CRAN —
nothing runs, and a framed message says so and names the variable.
The same decision exists a second time as
`duckdb_run_tests_enabled()` (`R/cran-guard.R`),
gating the examples through `examples_enabled()`.
`NOT_CRAN` plays no part in this decision;
individual skips elsewhere in the suite do read it.
That the gate holds is *checked*, not assumed:
a matrix entry builds the engine with a tripwire
(`-DDUCKDB_R_POISON_ENGINE`) and forces the tests off,
so any test or example that still reaches the engine aborts
([`operations/ci/matrix/`](/handbook/operations/ci/matrix/README.md)).

**The flavor-name guard.**
`flavor_package_name_offenders()`
([`scripts/flavor-package-name.R`](/scripts/flavor-package-name.R))
scans the tree for the hard-coded package name —
`duckdb::`, `duckdb:::`, `"duckdb"` on the R surface,
the quoted form only in the glue,
where `duckdb::` is the engine's own namespace.
The allowlist is read out of `scripts/flavor.patch` itself,
so what the rename accounts for
cannot drift from what the scan tolerates.
CI runs it against a plain checkout, and
`tests/testthat/test-flavor-package-name.R` wraps it for the suite.
Resolve a hit, don't silence it:
`get_package_name()` in code, no self-qualification in docs,
`paste0("duck", "db")`
when the literal genuinely names something else,
or teach `scripts/flavor.patch` the rename.
The scan covers what ships;
`handbook/` is outside it and is written for the mainline flavor
([`branches/flavors/`](/handbook/branches/flavors/README.md)).
