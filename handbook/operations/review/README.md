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
  The other changes nothing but tooling that takes effect from `main`'s copy,
  with the files generated from it and the handbook pages that describe only that tooling,
  which go with it so that each branch's pages describe the tooling that branch carries.
  Where a release branch's own copy needs the same change too, it is picked onto that branch once it has merged.
  A change that mixes such tooling with anything else is split by default:
  its tooling to `main`, the rest to the release branch.
* **Where tooling takes effect decides its target, not that it is tooling.**
  `main`'s copy is what the series loop runs, and what a workflow firing on a series ref runs,
  since the loop's port stage brings every series' tooling,
  `series_tooling` in [`scripts/series-config.sh`](/scripts/series-config.sh), level with `main`'s.
  It is also what GitHub runs on a `schedule`, `workflow_run` or `pull_request_target` trigger, `main` being the default branch
  ([events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)).
  A release branch's own copy runs on a `push` or `workflow_dispatch` run on that branch,
  and on a `pull_request` or `merge_group` run into it, which reads the merge into its base;
  so do the scripts these call, such as the handbook check, and `flavor.sh` when a series seeds on the branch.
  Tooling that takes effect only from a release branch's own copy, such as a trigger that fires only for release branches,
  targets that branch like any other change and reaches `main` by the forward merge.
  The release-branch pattern in the `pull_request` trigger of `R-CMD-check.yaml` is such a change,
  and a change to a file `cynkra/cynkratemplate` owns goes to the template too, as `operations/ci/workflows/` says.
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
