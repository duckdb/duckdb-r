# Guards

The checks that fail loudly rather than let a defect ship:
the CRAN guard,
which keeps the bundled engine off CRAN's check farm,
the flavor-name guard,
which keeps the package name from being written
where the rename cannot reach,
and the vendored-warning guard,
which keeps a compiler warning from being silenced
instead of fixed.

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

**The vendored-warning guard.**
[`scripts/vendored-warnings.sh`](/scripts/vendored-warnings.sh)
enforces the rule that no warning is suppressed
([`architecture/glue/`](/handbook/architecture/glue/README.md)),
and it takes two halves because a warning can go quiet two ways.

A suppression can hide from `R CMD check`.
`tools:::.check_pragmas()` matches one spelling of
`#pragma GCC diagnostic ignored`;
the preprocessor accepts several,
so a pragma written with a space after the `#`,
or with doubled spaces inside,
silences the compiler while the check reports nothing.
The guard therefore greps the patch stack
for every diagnostic an added line turns off, whatever the spacing,
and compares that against an inventory the script carries:
a suppression that is not written down fails the check,
and writing one down means giving the reason.
Reading `patch/` rather than `src/duckdb/`
is also what keeps upstream out of it —
several vendored libraries ship suppressions in the same spelling,
and respelling files we re-sync from upstream
would be a patch maintained forever against no defect of ours.

The warnings themselves need a compiler,
which is the other half.
The guard syntax-checks the vendored libraries
whose patches claim warning-freedom for them,
under the diagnostics CRAN's clang flavor uses,
and fails on any warning;
the script names those libraries
and says why the remaining ones are out.
It runs clang rather than the compiler `R CMD config CXX` reports,
because the diagnostics
[`patch/0003-Fix-clang-warnings-in-re2.patch`](/patch/0003-Fix-clang-warnings-in-re2.patch)
fixes are clang's alone and GCC is silent on the same code.
Syntax-only checking keeps it to seconds,
so it runs as a step of the smoke test beside the flavor scan;
the suite is the wrong home,
because `R CMD check` runs from a tarball
on farms that need not have clang at all.

Two things stay outside it:
a library no patch of ours makes a claim for,
whose upstream warnings are not this repository's to answer for,
and a suppression written straight into the glue
rather than introduced through a patch.
