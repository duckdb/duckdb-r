# Workflows

The inventory under [`.github/workflows/`](/.github/workflows):
one line per workflow — what fires it, what it does.
The workflow files are the ground truth;
this table is the map.

| Workflow | Fires on | Does |
|---|---|---|
| [`R-CMD-check.yaml`](/.github/workflows/R-CMD-check.yaml) | push and PR to the main branches and `cran-*` | the `rcc` check across the matrix ([`matrix/`](/handbook/operations/ci/matrix/README.md)) |
| [`R-CMD-check-dev.yaml`](/.github/workflows/R-CMD-check-dev.yaml) | daily cron; push to `cran-*`, tags | the check against R-devel |
| [`R-CMD-check-status.yaml`](/.github/workflows/R-CMD-check-status.yaml) | `rcc` runs starting/finishing | mirrors run state onto commit statuses |
| [`each.yaml`](/.github/workflows/each.yaml) | push to `*-dev` and `each-*`; dispatch | per-commit sharded builds ([`per-commit/`](/handbook/operations/ci/per-commit/README.md)); fork only |
| [`rcc-logs.yaml`](/.github/workflows/rcc-logs.yaml) | half-hourly cron | harvests run records onto the `rcc` branch |
| [`rcc-consolidate.yaml`](/.github/workflows/rcc-consolidate.yaml) | dispatch | rewrites the `rcc` branch (dry run by default) |
| [`fledge.yaml`](/.github/workflows/fledge.yaml) | push to `main`; dispatch | version bump and `NEWS.md` via fledge ([`releases/versioning/`](/handbook/operations/releases/versioning/README.md)) |
| [`sync.yaml`](/.github/workflows/sync.yaml) | hourly cron | fast-forwards the fork's `main` from canonical |
| [`format-suggest.yaml`](/.github/workflows/format-suggest.yaml) | `pull_request_target` | posts formatting suggestions; treats fork code strictly as data |
| [`commit-suggest.yaml`](/.github/workflows/commit-suggest.yaml) | after an `rcc` run on a PR | turns the run's changes patch into review suggestions |
| [`pkgdown.yaml`](/.github/workflows/pkgdown.yaml) | push to `docs*`, `cran-*`; dispatch | builds the site (main is covered by `rcc`) |
| [`rhub.yaml`](/.github/workflows/rhub.yaml) | push to `cran-*`; dispatch | R-hub checks ([`releases/cran/`](/handbook/operations/releases/cran/README.md)) |
| [`revdep.yaml`](/.github/workflows/revdep.yaml) | push to `revdep*` | reverse-dependency checks ([`testing/revdep/`](/handbook/testing/revdep/README.md)) |
| [`lock.yaml`](/.github/workflows/lock.yaml) | daily cron | locks threads a year after closing |
| [`HighPriorityIssues.yml`](/.github/workflows/HighPriorityIssues.yml) | issue labeled | mirrors High-Priority issues internally |
| [`copilot-setup-steps.yaml`](/.github/workflows/copilot-setup-steps.yaml) | changes to itself | environment bootstrap for coding agents |
| [`pr-commands.yaml`](/.github/workflows/pr-commands.yaml) | issue comments | `/document` and `/style` commands on PRs |

Never add a `.github/README.md` — GitHub would surface it as the
repository front page (precedence `.github/` → root → `docs/`).
