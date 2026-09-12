# Opening the v2.0 series

*A plan for the next series opening, not a description of the system.
[`.claude/skills/series-open.md`](/.claude/skills/series-open.md) owns the routine,
[`.claude/skills/series-forward.md`](/.claude/skills/series-forward.md) the rebuild it leans on,
and [`operations/releases/process/`](/handbook/operations/releases/process/README.md) the release around it.
Where a skill and this document disagree, the skill is right.*

Upstream has cut `v2.0-cyanoptera`, so the line exists and nothing here serves it.
Every series opened so far was opened for a line nothing here tracked, and this one is the opposite case:
the preview line has been vendoring upstream `main` since it was opened,
so the commits `cyanoptera` inherits below the fork point are already in `main-build`,
each with the glue its gate demanded.
The opening is a fission, and it has two halves that are worth doing together:
`v2.0-cyanoptera` gets those commits, and `main-build` stops carrying them.
The placeholders are `series-open.md`'s.

## The rule everything here turns on

A replay may start above a buffer's beginning
**only if the new base already vendors the upstream commit the range starts at.**
A vendor commit's diff is what vendoring changed, not the tree it produced,
so a range that starts higher lands its first commit on whatever the base happens to vendor.
Where that is an older upstream tree, the series opens with the backwards-and-skip-ahead step
[`scripts/VENDORING.md`](/scripts/VENDORING.md) records `main-dev` having taken once,
and a bisect across that commit answers nothing.
Nothing checks this: the pick applies cleanly either way.

The rule is why each half below replays or re-roots from a commit the base actually vendors,
and it is what the residual question at the end is about.

## The v2.0 half: replay onto its own seed

The derived opening, `series-open.md`'s *When another series already vendors the line*:
seed from `main` with flavor `2.0.dev` and the preview prefix `1.99.99.9000`
([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)),
create the four refs equal,
replay `main-build` from its own first vendor commit up to the commit that vendors the fork point,
then walk `cyanoptera` forward for what it has of its own.
The replay is `scripts/series-forward-build.sh <fork-point commit> <main's seed>`,
and it satisfies the rule by starting where the chain starts.

**Replaying rather than branching is what pays the flavor crossing once.**
Pointing a new ref into `main-build` would share the commits and cost nothing up front,
but the buffer would then carry flavor `dev` under a `2.0.dev` series,
and every commit stage 5 mints would cross flavors for the life of the line.
A replay crosses once, at creation, where a conflict is a conflict a human is already watching for.
What it costs is that the two buffers share content and not objects,
which is the deliberate answer to whether ancestry is wanted here: it is not.

Two things the new series does not inherit, and both are work:

* **What CI taught the preview line.** `-build` carries what compiles, and the test-side fixes live on `main-dev`.
  A forward folds those back from its twin by vendored SHA (`series-loop.md`, stage 5);
  a derived opening has a twin too, the same `main-dev`, and nothing wires it up.
  Left as is, each fix returns as a red in the new series' CI, once, at a repair plus a replay above it.
  Teaching stage 5 to match a derived series against the series it was derived from is the one
  tooling change this plan asks for, and the one measurement worth taking first:
  the `main-fwd` run needed a carry on 10 of 802 buffered commits
  ([`experiments/2026-08-09-series-carry-scope/`](/experiments/2026-08-09-series-carry-scope/README.md)),
  and whether a cross-flavor fission looks like that is not known.
* **The rename surface.** The picks were written under `dev` and land under `2.0.dev`,
  so any that touched a file [`scripts/flavor.patch`](/scripts/flavor.patch) rewrites conflicts on the name.
  `scripts/series-glue.sh` over the buffer's range ranks the adapted files by how often each was touched,
  which is what says whether this is a handful of conflicts or a running cost.

## The main half: re-root `main-build` at the bifurcation

`main-build` currently walks upstream `main` from the series' own beginning,
which is a stretch of history that now belongs to `cyanoptera`.
Squash the vendor commits below the fork point into one, keeping the seed and everything above:
the buffer becomes the seed, one vendor commit carrying the fork-point tree, and the mainline commits.
That is the shape `series-open` step 4 produces for a line opened at its fork point,
reached from the other direction.

Details that decide whether it is safe:

* **Keep the fork-point commit's version.** The squashed commit takes it,
  so the vendor counter above is untouched and `-dev`'s ordering is unaffected.
* **`-dev` is not rewritten.** It keeps all of its history, including the commits below the fork point,
  which r-universe has already published as `duckdb.dev` versions.
* **The anchor still resolves.** Stage 5 finds `-dev`'s newest vendored SHA on `-build`;
  that SHA is the buffer tip, which the squash does not touch.
  Traced against `scripts/series-advance.sh`, the post-squash state reports "buffer empty" and writes nothing,
  which is correct.
* **`-build-base` self-heals**, being recomputed from the match and force-pushed on the next stage 3.

**Do it while the buffer is drained.** It is, today:
`main-build` and `main-build-base` both read `1.5.5.9010.1418`,
so everything vendored has been consumed and verified, and `main-dev` sits at the same vendor counter.
A re-root with commits in flight would have to reason about what stage 5 was mid-way through;
this one does not.

## What is left at the flip

When 2.0 lands on `main`, the preview line is rebuilt on a base carrying the `cyanoptera` release tree,
while the re-rooted buffer's commits are diffs against the fork-point tree.
The first replayed commit therefore still walks the engine backwards, by the release-branch delta.
The re-root shrinks that from the whole chain to that delta, and does not remove it.

What removes it is upstream's **back-merge of `cyanoptera` into `main`**.
After it, `main-build` has a vendor commit whose tree is not behind the release,
and a forward may range-limit above that commit and start on a base that matches.
Upstream does back-merge, which is why the fork point needs the first-parent recipe at all;
when it lands is upstream's business.
So: wait for it where the timing allows, and where it does not,
replay the re-rooted buffer whole and accept one backwards step at its root,
which is a documented step at a known commit rather than a surprise in the middle of a chain.

## Sequencing

The derived opening removes most of the reason to hurry:
what waiting costs is now the `cyanoptera`-only commits to walk, not the whole shared history.
Two things do want ordering.
`v1.5-variegata` has a live `-fwd` counterpart with a cutover pending,
and re-rooting `main-build` while another series is mid-forwarding puts two lineages in flight at once.
And the v1.5.6 release runs from `main` on the v1.5 line, unchanged,
needing to know nothing about either half of this.

## What this plan owes before it can be executed

* The two measurements above: the carry scope for a derived series, and the rename surface's conflict count.
* A reading of `scripts/series-check.sh` and `scripts/series-converge.sh` against a derived series.
  Both were written for a series with one lineage, and a derived one has a parent they do not know about.
* The one open decision: whether the buffer's flavor is worth removing altogether.
  Nothing publishes `-build` and the compile gate does not care about the package name,
  so an unflavored buffer would let one chain serve every series that shares upstream history,
  and it is a larger change than either half above.
