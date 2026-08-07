# Review

Pull-request flow: what a review checks, and who drives CI to green.
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
* The author drives CI to green.
* An agent may be asked to watch a pull request — CI, review comments,
  merge conflicts — for the length of a session.
  Nothing here is scheduled: the only scheduled agent routine in this
  repository is the series loop
  ([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).

*To deepen: write the flow from lived practice — what an agent
may do unprompted on a pull request, and what needs the maintainer.*
