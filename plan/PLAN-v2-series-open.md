# Opening the v2.0 series

*A plan for the next series opening, not a description of the system.
[`.claude/skills/series-open/SKILL.md`](/.claude/skills/series-open/SKILL.md) owns the routine,
[`.claude/skills/series-forward/SKILL.md`](/.claude/skills/series-forward/SKILL.md) the rebuild it leans on,
and [`operations/releases/process/`](/handbook/operations/releases/process/README.md) the release around it.
Where a skill and this document disagree, the skill is right.*

Upstream has cut `v2.0-cyanoptera`, so the line exists and nothing here serves it.
Every series opened so far was opened for a line nothing here tracked, and this one is the opposite case:
the preview line has been vendoring upstream `main` since it was opened,
so the commits `cyanoptera` inherits below the fork point are already in `main-build`,
each with the glue its gate demanded.
The opening is a fission, and it has two halves that are worth doing together:
`v2.0-cyanoptera` gets those commits, and `main-build` stops carrying them.
The placeholders are `series-open/SKILL.md`'s.

## What the first run established

The opening was driven as far as the seed on 2026-09-13, and the numbers it turned up are recorded here
rather than left to be re-derived.

* **The fork point is `a00803f7687ca3d7188d417216e288c5c4b22b58`**, 2026-09-02.
  `git merge-base` gives `7074015a`, a week newer, so the first-parent recipe is load-bearing exactly as
  [`scripts/VENDORING.md`](/scripts/VENDORING.md) warns.
* **`main-build` vendors that commit exactly**, at `01aa52689`, so the parent buffer's fork-point commit
  is the fork point itself and step 1 of the derived opening needs no search.
* **The replay range is `30ae31408..01aa52689`**: 1406 vendor commits and 3 non-vendor ones,
  all three `fix(patch)` entries the buffer took for itself.
* **`cyanoptera` has 193 first-parent commits of its own** above the fork point, which is the walk.
* **The seed builds.** `duckdb.2.0.dev` at `1.99.99.9000.0`, a cold compile of fourteen minutes on four cores.

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

The derived opening, `series-open/SKILL.md`'s *When another series already vendors the line*:
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
  A forward folds those back from its twin by vendored SHA (`series-loop/SKILL.md`, stage 5);
  a derived opening has a twin too, the same `main-dev`, and nothing wires it up.
  Left as is, each fix returns as a red in the new series' CI, once, at a repair plus a replay above it.
  Teaching stage 5 to match a derived series against the series it was derived from is the one
  tooling change this plan asks for, and the one measurement worth taking first:
  the `main-fwd` run needed a carry on 10 of 802 buffered commits
  ([`experiments/2026-08-09-series-carry-scope/`](/experiments/2026-08-09-series-carry-scope/README.md)),
  and whether a cross-flavor fission looks like that is not known.
* **The rename surface, which is measured and empty.** The picks were written under `dev` and land under `2.0.dev`,
  so any that touched a file [`scripts/flavor.patch`](/scripts/flavor.patch) rewrites would conflict on the name.
  None does: across the 1409 commits of the replay range, the number touching any file that patch rewrites,
  other than `DESCRIPTION`, is zero, and `DESCRIPTION` is the `ours-version` driver's on every commit anyway.
  So the flavor crossing costs nothing here, and the trade it was weighed against was the expensive reading.
  The measurement is a file-level count and stays true only while the buffer does not move,
  which the drained state below is what fixes.

## The main half: the forward `main` needs anyway

`main-build` walks upstream `main` from the series' own beginning,
a stretch of history that now belongs to `cyanoptera`,
and its seed sits at an older `main` than today's.
Both are seed-and-lineage work, and so is the preview prefix,
so `main` takes one forward counterpart and the three land together
([`series-forward/SKILL.md`](/.claude/skills/series-forward/SKILL.md)).
`main-fwd-build` is the regenerated seed carrying the preview prefix,
then one vendor commit at the fork point, which is `series-open` step 4's,
taken with `scripts/vendor.sh` and subject to that step's glue-rewind check,
then a replay of the buffer's commits above the fork point.
That is the re-rooted shape reached without force-pushing a live buffer:
what installs it is the ordinary cutover, which a human runs and the loop only reports.

**Re-rooting is what makes the forward affordable**, and is the reason to do both halves as one change.
A plain forward replays the whole buffer, and the loop then puts every replayed commit through CI.
Re-rooted, `main-fwd-dev` has the mainline commits to verify and nothing below the fork point:
the commits the fission moves to `cyanoptera` are exactly the ones `main` no longer re-verifies.

**v2.0 takes no counterpart of its own.**
A forward exists to protect a green that consumers already read, and a line opened today has none.
`series-open` step 3 creates the four baseline refs equal and the series starts there;
`series-forward-build.sh` is borrowed for the replay
and says nothing about which refs the opening writes.

**Timing.** `main-build` and `main-build-base` both read `1.5.5.9010.1418`, so the buffer is drained,
which fixes the replay range rather than leaving it moving under the rebuild.

## What is left at the flip

When 2.0 lands on `main`, the preview line is rebuilt on a base carrying the `cyanoptera` release tree,
while the re-rooted buffer's commits are diffs against the fork-point tree.
The first replayed commit therefore still walks the engine backwards, by the release-branch delta.
The re-root shrinks that from the whole chain to that delta, and does not remove it.

What removes it is upstream's **back-merge of `cyanoptera` into `main`**.
After it, `main-build` has a vendor commit whose tree is not behind the release,
and a forward may range-limit above that commit and start on a base that matches.
Upstream does back-merge, which is why the fork point needs the first-parent recipe at all.
**It has already landed, twice**: `56b103b7f7` on 2026-09-08 and `ca5ce12b7d` on 2026-09-10,
and `main-build` has vendored both.
So the waiting this section described is over before it started:
the main half may range-limit its replay above the commit that vendors `ca5ce12b7d`
and start on a base that matches, rather than replaying the buffer whole
and accepting a backwards step at its root.
What remains is to confirm that commit is the newest such back-merge when the forward is actually run.

## r-universe has to be told

`duckdb.2.0.dev` is a package that does not exist yet,
and nothing in this repository creates it:
the registration is the universe's own, outside this tree
([`branches/flavors/`](/handbook/branches/flavors/README.md)).
Today `duckdb.r-universe.dev` carries `duckdb`, `duckdb.1.4`
and the three `.dev` flavors, and `krlmlr.r-universe.dev` carries the three `.dev` flavors,
so the new series needs an entry and `main`'s forward needs none.
`scripts/r-universe-check.sh` is what says the registration took,
listing exactly the packages whose upstream is this repository.
Until it appears there, a series is covered only by the per-commit gate,
which is Linux on one R version.

## Sequencing

The derived opening removes most of the reason to hurry:
what waiting costs is now the `cyanoptera`-only commits to walk, not the whole shared history.
Two things do want ordering.
`v1.5-variegata` had a live `-fwd` counterpart with a cutover pending;
that cutover has since run, and no `-fwd` ref remains in the fork,
so re-rooting `main-build` no longer puts two lineages in flight at once.
And the v1.5.6 release runs from `main` on the v1.5 line, unchanged,
needing to know nothing about either half of this.

## What this plan owes before it can be executed

* The carry scope for a derived series. The rename surface's conflict count is done, and is zero.
* A reading of `scripts/series-check.sh` and `scripts/series-converge.sh` against a derived series.
  Both were written for a series with one lineage, and a derived one has a parent they do not know about.
* The one open decision: whether the buffer's flavor is worth removing altogether.
  Nothing publishes `-build` and the compile gate does not care about the package name,
  so an unflavored buffer would let one chain serve every series that shares upstream history,
  and it is a larger change than either half above.
