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
* **Prerelease** — while a release stabilises, only `main` and the dev
  branches move, so an unfinished release is abandoned by walking away;
  what ships is an ancestor of what was revdep-tested;
  a fold-back fix reaches `main` before any series;
  and at the glue freeze every releasing series carries identical glue.

Read every statement as a claim about **trees, not ancestry**:
`main` is a rebuilt linear history that shares no merge-base with
the parked baselines, so "X equals Y plus a rename" compares working trees.

**Most invariants are enforced by nothing** —
they are conventions, kept by the loop's routine and by review;
a few hold mechanically
(the vendor counter, the advance script's ancestor check on `-green`).
How well an unenforced one holds is measurable rather than assumed:
[`experiments/2026-07-main-dev-review/`](/experiments/2026-07-main-dev-review/README.md)
counted the R-side commits in one series' active range, and
[`experiments/2026-08-02-lts-drift/`](/experiments/2026-08-02-lts-drift/README.md)
measured how far the LTS flavor has drifted from its baseline.

*To deepen: absorb the statements
with their enforcement notes from `BRANCHES.md`.*
