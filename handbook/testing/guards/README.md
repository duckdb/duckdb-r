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

**Two companion scans, for what reading file contents cannot see.**
The rename runs *once*, when a series is seeded,
so anything that arrives on a flavored branch afterwards —
a commit ported from `main`
([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md))
— brings the mainline name with it and nothing rewrites it.
Both scans are empty on the mainline flavor, where that name is the right one.

* `flavor_unflavored_paths()` catches a file the patch *renames*
  arriving under its mainline name.
  Such a file carries the name in its name rather than its contents,
  so the content scan looks straight past it —
  and the file is then simply not read.
  `src/duckdb-win.def` on a `duckdb.dev` build
  is not the export list R's `share/make/winshlib.mk` looks for,
  so the Windows link generates one from every object
  and overruns the PE export table.
* `flavor_mainline_readme_offenders()` catches an install call
  naming the mainline package in `README.md` or `.github/README.md`.
  Those two are *generated* from `README.Rmd`,
  which is what the content scan reads in their place;
  they pass whether or not their source was flavored,
  so a ported README lands mainline text on a flavored branch unseen.
  `.github/README.md` is the front page GitHub renders for the branch,
  which makes it the likeliest of the three to be read by a user.

All three run in the same `rcc-smoke` step
(`.github/workflows/custom/after-install/action.yml`)
and are wrapped for the suite by
`tests/testthat/test-flavor-package-name.R`.
