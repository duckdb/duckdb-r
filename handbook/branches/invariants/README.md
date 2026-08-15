# Invariants

What every series guarantees,
and what would actually catch a violation.
The statements themselves live in
[`BRANCHES.md` § Series Invariants](/BRANCHES.md#series-invariants),
where each carries a number.
The numbers are a filing device for that document,
not a way to cite an invariant elsewhere:
a page that depends on one says what it says.

The families, in one breath:

* **Structural** — the LTS flavor is the released tree plus the rename,
  and then mostly frozen:
  it moves only for bug fixes
  and for what R-devel on r-universe requires.
  The dev baseline equals the released tree on legacy series only;
  a series-loop seed is flavored from day one.
* **Linearity** — the active history is linear and merge-free,
  so it stays bisectable; forward-ports are cherry-picks.
* **Flavor / identity** — the names inside a branch agree with each other,
  everywhere in the branch.
* **Version** — each strand advances its own counter and freezes the other
  ([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
* **Source of truth** — R-side work is born on `main` and reaches
  a series by forwarding, never the reverse;
  the one exception is vendor-coupled glue on the preview line,
  born beside the vendor commit that forces it.
* **CI / green** — a `-green` ref only ever fast-forwards to
  commits with recorded successful runs.
* **Forward convergence** — at the end of a forwarding, `<S>-dev` and
  `<S>-fwd-dev` are identical, or every difference between them is
  explicable. A forward is the same series rebuilt on a newer `main`
  ([`.claude/skills/series-forward.md`](/.claude/skills/series-forward.md)),
  so the histories differ by construction and only the trees carry the
  claim.
* **Prerelease** — while a release stabilises, only `main` and the dev
  branches move, so an unfinished release is abandoned by walking away;
  what ships is an ancestor of what was revdep-tested;
  a fold-back fix reaches `main` before any series;
  and at the glue freeze every releasing series carries identical glue.

Read every statement as a claim about **trees, not ancestry**:
`main` is a rebuilt linear history that shares no merge-base with
the parked baselines, so "X equals Y plus a rename" compares working trees.

**Most invariants are enforced by nothing** —
they are conventions, kept by the loop's routine and by review.
Exactly two checks run on every firing, both in
[`scripts/series-advance.sh`](/scripts/series-advance.sh):
`-green` moves only where `git merge-base --is-ancestor` says the move
is a fast-forward, and a replay is kept only once every vendor commit in
it is confirmed to carry a version strictly above its parent's.
`-build-base` is not a third: it is set rather than advanced,
recomputed from the match each time and force-pushed,
which is why nothing gates it.

Forward convergence sits between the two families:
it is **measured on every firing and enforced by nobody**.
[`scripts/series-converge.sh`](/scripts/series-converge.sh) reports it,
and [`scripts/series-cutover.sh`](/scripts/series-cutover.sh) prints the
same reading immediately before it asks to swap the refs —
but neither refuses, because the invariant's second half is
*explicable*, and whether a difference is explicable is a judgement no
script can make. What the tooling can do, and does, is keep the list of
differences it explains away short and evidenced, so that what is left
is a work list rather than a verdict.
The structural and flavor families hold **by construction** —
the rename is one patch applied by
[`scripts/flavor.sh`](/scripts/flavor.sh), which prepares and checks the
whole thing before it commits anything, so the patch is the surface.
Linearity and the dev baseline are checked by nothing at all;
no script reads `dev-base`, and none counts parents.

How well an unenforced one holds is measurable rather than assumed:
[`experiments/2026-07-main-dev-review/`](/experiments/2026-07-main-dev-review/README.md)
counted the R-side commits in one series' active range, and
[`experiments/2026-08-02-lts-drift/`](/experiments/2026-08-02-lts-drift/README.md)
measured how far the LTS flavor has drifted from its baseline.

*To deepen: say what would catch the two that nothing catches.
Linearity and the dev baseline are the invariants a violation of
reaches a release, and what a check for either would cost —
where it would run, and what it would refuse —
is written down nowhere.*
