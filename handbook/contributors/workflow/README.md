# Workflow

Making a change, from branch to merged pull request.
Little of this is codified; what is settled:

* Branch from the branch the pull request targets, and open it there:
  for most changes a release branch, not `main`.
  [`operations/review/`](/handbook/operations/review/README.md) names the branch,
  and owns the review side too: what gets checked, and who drives CI.
  The pull request merges without a merge commit
  ([`branches/invariants/`](/handbook/branches/invariants/README.md)).
* Write the pull request title as a
  [Conventional Commit](https://www.conventionalcommits.org),
  phrased to be read:
  it is what squashes onto the branch it targets.
  The commit messages inside the branch are discarded.
* Write no `NEWS.md` entry for the change
  ([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
* Run the tests the change touches
  ([`testing/suite/`](/handbook/testing/suite/README.md));
  the full suite can also be left to CI on a pull request that runs `rcc`.
  Add a test with every bug fix.
* Write R to the tidyverse style and design guides,
  and read the deviations before assuming a rule applies here
  ([`architecture/r-layer/style/`](/handbook/architecture/r-layer/style/README.md));
  the C++ has house rules of its own
  ([`architecture/glue/conventions/`](/handbook/architecture/glue/conventions/README.md)).
* Layout is a formatter's output, never a review comment.
  Where CI suggests formatting on the pull request,
  accept it rather than arguing with it.
  A snapshot the change legitimately moved is accepted deliberately
  ([`testing/snapshots/`](/handbook/testing/snapshots/README.md)).
* Never edit generated or vendored files
  ([`architecture/`](/handbook/architecture/README.md),
  [`operations/vendoring/`](/handbook/operations/vendoring/README.md)).
* Regenerate `man/*.Rd` with roxygen2 installed from GitHub, `pak::pak("r-lib/roxygen2")`, not with the CRAN release.
  `DESCRIPTION` records the development version in `Config/roxygen2/version`,
  and CI's roxygen step installs `r-lib/roxygen2` too
  ([`.github/workflows/R-CMD-check.yaml`](/.github/workflows/R-CMD-check.yaml)).
* A script only ever run on a CI runner may assume GNU tools;
  one a contributor may run on their own machine will meet macOS,
  where `sed` is BSD.
  Where such a script wants GNU behaviour it locates GNU sed —
  `gsed` first, then `sed` — and refuses to run when neither is GNU,
  rather than writing every expression to what the two agree on
  ([`scripts/flavor.sh`](/scripts/flavor.sh)).

*To deepen: write the path from lived practice,
including how a contributor without push access gets CI green.*
