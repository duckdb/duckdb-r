# Review

Pull-request flow: what a review checks, who drives CI to green,
and the stewardship routines that watch open pull requests.
Little of this is written down yet; the flow lives in practice.

What is settled:

* Pull requests target `main` and land as a **squash commit**,
  so the branch becomes one commit and the history stays linear
  ([`branches/invariants/`](/handbook/branches/invariants/README.md)).
  The pull-request title is that commit's subject
  ([`contributors/workflow/`](/handbook/contributors/workflow/README.md)).
* A review checks the change against the owning leaves of this
  handbook — the invariants, the flavor seam, the no-suppression
  policy — and that snapshots changed only where the diff explains
  them ([`testing/snapshots/`](/handbook/testing/snapshots/README.md)).
* The author drives CI to green; formatting suggestions arrive on
  the PR from the format workflow
  ([`operations/ci/workflows/`](/handbook/operations/ci/workflows/README.md)).
* Scheduled agent routines steward open PRs — watching CI,
  rebasing, and answering review comments — under the same rule
  as every routine: automation prepares, a person concludes.

*To deepen: write the flow from lived practice — what a steward
may do unprompted, what needs the maintainer.*
