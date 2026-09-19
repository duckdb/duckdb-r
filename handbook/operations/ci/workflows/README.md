# Workflows

The top-level workflow files under
[`.github/workflows/`](/.github/workflows):
one line each — what fires it, what it does.
The workflow files are the ground truth;
this table is the map.
Most of them are **not authored here**:
[`cynkra/cynkratemplate`](https://github.com/cynkra/cynkratemplate)
is the source of truth for the core set,
and an external process keeps this repository's copies level with it —
so editing one here puts the copy out of step,
and a change belongs in the template instead.
A file's own first line records what it was derived from,
which is the part of this a reader can check from the tree.

| Workflow | Fires on | Does |
|---|---|---|
| [`R-CMD-check.yaml`](/.github/workflows/R-CMD-check.yaml) | push and PR to the main branches and `cran-*`; daily cron; merge queue; dispatch | the `rcc` check across the matrix ([`matrix/`](/handbook/operations/ci/matrix/README.md)) |
| [`R-CMD-check-dev.yaml`](/.github/workflows/R-CMD-check-dev.yaml) | daily cron; push to `cran-*`, tags | the check against r-universe dev builds of each dependency, one job per dependency |
| [`R-CMD-check-status.yaml`](/.github/workflows/R-CMD-check-status.yaml) | `rcc` runs starting/finishing | mirrors run state onto commit statuses |
| [`each.yaml`](/.github/workflows/each.yaml) | push to `*-dev` and `each-*`; dispatch | per-commit sharded builds ([`per-commit/`](/handbook/operations/ci/per-commit/README.md)); fork only |
| [`rcc-logs.yaml`](/.github/workflows/rcc-logs.yaml) | dispatch; push when its own files change | backstop: harvests undecided commits' records onto the `rcc2` branch ([`per-commit/store/`](/handbook/operations/ci/per-commit/store/README.md)) |
| [`rcc-consolidate.yaml`](/.github/workflows/rcc-consolidate.yaml) | dispatch | rewrites the `rcc2` branch (dry run by default) |
| [`fledge.yaml`](/.github/workflows/fledge.yaml) | daily cron; dispatch; push only when this file changes | version bump and `NEWS.md` via fledge ([`releases/versioning/`](/handbook/operations/releases/versioning/README.md)) |
| [`format-suggest.yaml`](/.github/workflows/format-suggest.yaml) | `pull_request_target` | posts formatting suggestions; treats fork code strictly as data |
| [`commit-suggest.yaml`](/.github/workflows/commit-suggest.yaml) | after an `rcc` run on a PR | turns the run's changes patch into review suggestions |
| [`pkgdown.yaml`](/.github/workflows/pkgdown.yaml) | push to `docs*`, `cran-*`; dispatch | builds the site (main is covered by `rcc`) |
| [`rhub.yaml`](/.github/workflows/rhub.yaml) | push to `cran-*`; dispatch | R-hub checks ([`releases/cran/`](/handbook/operations/releases/cran/README.md)) |
| [`revdep4.yaml`](/.github/workflows/revdep4.yaml) | dispatch | **the reverse-dependency route** ([`testing/revdep/`](/handbook/testing/revdep/README.md)): each package's two halves sequentially, per-package containers, a work queue across packages |
| [`revdep2.yaml`](/.github/workflows/revdep2.yaml) | dispatch | revdep4's predecessor, both halves at once on one host ([`testing/revdep/`](/handbook/testing/revdep/README.md)) |
| [`revdep.yaml`](/.github/workflows/revdep.yaml) | push to `revdep*` | one old-vs-new `rcmdcheck` per reverse dependency ([`testing/revdep/`](/handbook/testing/revdep/README.md)) |
| [`lock.yaml`](/.github/workflows/lock.yaml) | daily cron | locks a thread after a year without activity |

**The composite actions these workflows call are not in this repository.**
They live in
[`cynkra/cynkratemplate`](https://github.com/cynkra/cynkratemplate/tree/main/.github/actions)
and are referenced as `cynkra/cynkratemplate/.github/actions/<name>@main` —
`check/`, `commit/`, `install/`, `style/`, `update-snapshots/`, `versions-matrix/`
and some thirty more.
They were copied into `.github/workflows/` until cynkra/cynkratemplate#121 served
them from one place instead, so a path under `.github/workflows/<name>/` in an
older page is that copy and not a file.
What stays here is `.github/workflows/custom/`, the hooks this package fills in.
