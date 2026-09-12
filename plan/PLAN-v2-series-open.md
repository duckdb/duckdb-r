# Opening the v2.0 series

*A plan for the next series opening, not a description of the system.
[`.claude/skills/series-open.md`](/.claude/skills/series-open.md) owns the routine,
[`.claude/skills/series-forward.md`](/.claude/skills/series-forward.md) the rebuild it leans on,
and [`operations/releases/process/`](/handbook/operations/releases/process/README.md) the release around it.
Where a skill and this document disagree, the skill is right.*

Every series opened so far was opened for a line nothing here tracked.
The next one is not.
Upstream will cut `v2.0-<codename>` off `main`, and the preview line has been vendoring upstream `main`
since it was opened, so the new series is only nominally born from nothing:
the commits it needs below the fork point are already in `main-build`, each with the glue its gate demanded.
The placeholders are `series-open.md`'s, `<U>` for the upstream release branch above all.
The opening is a fission of the preview line, and the reciprocal half of that fission,
what becomes of the preview line itself, is the part with the sharp edges.

## The rule everything here turns on

A replay may start above a buffer's beginning
**only if the new base already vendors the upstream commit the range starts at.**
A vendor commit's diff is what vendoring changed, not the tree it produced,
so a range that starts higher lands its first commit on whatever the base happens to vendor.
Where that is an older upstream tree, the series opens with the backwards-and-skip-ahead step
[`scripts/VENDORING.md`](/scripts/VENDORING.md) records `main-dev` having taken once,
and a bisect across that commit answers nothing.
Nothing checks this: the pick applies cleanly either way.

The rule is why the derived opening below replays the parent buffer from its own beginning
and why the preview line cannot be range-limited until `main` carries the 2.0 release.

## The sequence

**Before the cut.** Give the preview line the prefix of the line it previews at its next forward,
`1.99.99.9000` while 2.0 is unreleased
([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
`main-dev` publishes as `duckdb.dev` at `1.5.5.9020.<n>` today,
which says it is a development version of the released line, and it is not one.
Doing this before the cut costs one forward that is due anyway and takes one decision out of the messy window.

**The v1.5.6 release** runs unchanged, from `main`, on the v1.5 line.
Nothing about it needs to know that a series is about to be opened.

**Opening `v2.0-<codename>`** is the derived opening,
`series-open.md`'s *When another series already vendors the line*:
seed from `main` at 1.5.6 with flavor `2.0.dev` and prefix `1.99.99.9000`,
create the four refs equal,
replay `main-build` from its own first vendor commit up to the commit that vendors the fork point,
then walk `<U>` forward for what the release branch has of its own.
The replay is `scripts/series-forward-build.sh <fork-point commit> <main's seed>`,
and it satisfies the rule above by starting where the chain starts.

Two things this series does not inherit, and both are work:

* **What CI taught the preview line.** `-build` carries what compiles, and the test-side fixes live on `main-dev`.
  A forward folds those back from its twin by vendored SHA (`series-loop.md`, stage 5);
  a derived opening has a twin too, the same `main-dev`, and nothing wires it up.
  Left as is, each fix returns as a red in the new series' CI, once, at a repair plus a replay above it.
  Teaching stage 5 to match a derived series against the series it was derived from is the one
  tooling change this plan asks for, and the one measurement worth taking first:
  the `main-fwd` run needed a carry on 10 of 802 buffered commits
  ([`experiments/2026-08-09-series-carry-scope/`](/experiments/2026-08-09-series-carry-scope/README.md)),
  and whether a cross-flavor fission looks like that is not known.
* **The flavor.** The picks were written under `dev` and land under `2.0.dev`,
  so any that touched a file [`scripts/flavor.patch`](/scripts/flavor.patch) rewrites conflicts on the name.
  A forward never crosses flavors and this does, so the conflicts are new in kind rather than in number.

**The 2.0 release** then runs like any other, and this is what opening the series buys.
`v2.0-<codename>` was seeded from `main`, so `main` is an ancestor of it,
and the release is the ordinary linear move of the tagged content onto the release branch.
The atomic fast-forward flip that
[`operations/releases/process/`](/handbook/operations/releases/process/README.md)
describes for a preview line, with its ancestry established once just before the flip,
is what a repository without a v2.0 series would have to do instead.
Opening the series is what removes it, and that is worth stating in the leaf once this is done.

**Re-deriving the preview line** happens after 2.0 is on `main`, not at the cut.
Its base is then a tree that vendors `v2.0.0`, so the forward can drop everything the base already is
and replay only what upstream `main` has of its own.
The prefix moves with it, to `2.0.99.9000`, because the line it previews is 2.1 from that point on.
That is the rewind the sequence needs, and where it rewinds to is the question below.

## Where the preview line rewinds to

The fork point is the intuitive answer and the wrong one.
A base at `v2.0.0` vendors the fork point *plus* whatever the release branch added,
so a replay starting just above the fork point moves the engine backwards by exactly those commits.
The first buffer commit that may be replayed onto such a base is the one vendoring upstream `main`'s
**back-merge of the release branch**, after which main's tree is not behind `v2.0.0` any more.
Upstream does back-merge, which is why the fork point needs the first-parent recipe at all,
so the commit exists; when it lands is upstream's business and not ours.

Three ways to live with that:

* **Wait for the back-merge**, and rewind to the buffer commit that vendors it.
  Costs nothing, needs no new tooling,
  and leaves the preview line running on its old lineage meanwhile, which is what a `-fwd` counterpart is for.
* **Seed the preview line from the v2.0 series** rather than from `main`, at its fork-point commit,
  and rewind exactly to the fork point.
  This is the construction that makes the range-limit exactly right,
  and it is what "the main series starts where v2.0 is" means.
  It costs a reflavor, `2.0.dev` back to `dev`, which `scripts/flavor.sh` does not offer:
  it applies the rename to an unflavored tree, and there is no unflavored branch to apply it to.
* **Replay the whole buffer** onto `main` at 2.0.0, as a forward does today.
  Correct, and it makes the series spend a thousand commits climbing back to where its base already was,
  each one a commit CI judges.

Waiting for the back-merge is the recommendation, and replaying the whole buffer is the fallback
if upstream has not back-merged by the time the preview line needs forwarding for other reasons.
Seeding from the v2.0 series is the one to reach for only if the reflavor turns out to be cheap.

## What this plan owes before it can be executed

* The measurement above: how much stage 5 would have to carry into a derived series, and from where.
* A reading of `scripts/series-check.sh` and `scripts/series-converge.sh` against a derived series.
  Both were written for a series with one lineage, and a derived one has a parent they do not know about.
* Confirmation of the codename, the fork point, and the upstream release date, none of which are ours to set.
