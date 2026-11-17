# Review

Pull-request flow: which branch a pull request targets, what a review checks, and who drives CI to green.
Little of this is written down yet; the flow lives in practice.

What is settled:

* **A pull request targets the oldest active release branch the change applies to**, `v2.0-cyanoptera` today,
  and the change reaches the newer lines by a forward merge
  ([`branches/model/`](/handbook/branches/model/README.md)).
  The active release branches are the CRAN row's `upstream` in [`scripts/series.yaml`](/scripts/series.yaml)
  and every `releases_from` other than `main` on a row not declared `stale: true`,
  the set the `FORWARD-PORT` block of [`scripts/series-check.sh`](/scripts/series-check.sh) orders by version.
  Branch from that branch and name it as the base:
  `main` is the repository's default branch, so GitHub and `gh pr create` propose it otherwise.
* **Two kinds of change target `main` instead.**
  One concerns only the line `main` previews, such as glue or a test for an engine change only `main` vendors.
  The other changes nothing but tooling that runs from `main`'s copy,
  with the files generated from it and the handbook pages that describe only that tooling,
  which go with it so that each branch's pages describe the tooling that branch carries.
  It reaches a release branch as a pick only where that branch's own copy needs the change too.
  A change that mixes such tooling with anything else is split by default:
  its tooling to `main`, the rest to the release branch.
* **Where tooling takes effect decides its target, not that it is tooling.**
  The series loop runs `main`'s copy of the series scripts and skills,
  and its port stage makes every series' tooling, `series_tooling` in [`scripts/series-config.sh`](/scripts/series-config.sh),
  byte-identical to `main`'s, so a workflow firing on a series ref runs `main`'s copy too.
  GitHub runs `main`'s copy of a scheduled, `workflow_run` or `pull_request_target` workflow, since `main` is the default branch
  ([events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)).
  A `pull_request` or `push` trigger runs from the branch it fires on instead,
  so a change to how a release branch itself is built or checked, such as those triggers in `R-CMD-check.yaml`,
  targets that release branch like any other change and reaches `main` by the forward merge.
* A `patch/` entry is opened against each line whose engine needs it,
  since a forward merge keeps the newer line's engine, `patch/` included.
  A landing's review and its forward merge take the bases [`series-land`](/.claude/skills/series-land/SKILL.md) gives them,
  and an open pull request keeps its base until the maintainer changes it.
* A pull request lands as a **squash commit**,
  so the branch becomes one commit and the history stays linear
  ([`branches/invariants/`](/handbook/branches/invariants/README.md));
  a forward merge is the one kept as a merge commit.
  The pull-request title is that commit's subject
  ([`contributors/workflow/`](/handbook/contributors/workflow/README.md)).
* A review checks the change against the owning leaves of this
  handbook — the invariants, the flavor seam, the no-suppression
  policy, the tidyverse rules R answers to
  ([`architecture/r-layer/style/`](/handbook/architecture/r-layer/style/README.md))
  — and that snapshots changed only where the diff explains
  them ([`testing/snapshots/`](/handbook/testing/snapshots/README.md)).
* A review asks no `NEWS.md` entry of a pull request
  ([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
* The author drives CI to green.
  Which workflows a pull request starts depends on the branch it targets
  ([`operations/ci/workflows/`](/handbook/operations/ci/workflows/README.md)).
* An agent may be asked to watch a pull request — CI, review comments,
  merge conflicts — for the length of a session.
  Nothing here is scheduled: the only scheduled agent routine in this
  repository is the series loop
  ([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).

*To deepen: write the flow from lived practice — what an agent
may do unprompted on a pull request, and what needs the maintainer.*
