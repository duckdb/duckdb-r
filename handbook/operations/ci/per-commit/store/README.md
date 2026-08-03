# The verdict store

The orphan `rcc` branch: how a verdict is published seconds after it exists,
why the records live in two layouts,
and what keeps a dozen writers from colliding.
Who reads it, and to decide what, is
[`selection/`](/handbook/operations/ci/per-commit/selection/README.md)'s.

A verdict reaches the `rcc` branch seconds after it exists,
not at the end of the run.
That latency is the series loop's cycle time, because
[`series-check.sh`](/scripts/series-check.sh) gates on the *records*,
not the statuses.

Records land one per file, and the aggregate is fed from them:

```
runs2.d/<xx>/<sha>.ndjson     one record, one line -- where a record lands first
runs2.ndjson                  every record, in arrival order -- extended, never rewritten
logs2/<sha>.log               unchanged; already one file per commit
```

Two writers recording different commits touch different paths,
so there is nothing to conflict on,
and a loser of the ref race re-reads the tip and re-commits its one file.
The alternative — regenerating `runs2.ndjson` from the parts on every write —
would rewrite the branch's principal file for byte-determinism nothing needs.
[`rcc-merge.sh`](/scripts/rcc-merge.sh) instead **appends the records the
aggregate does not yet have**, and touches nothing else:

* the records that predate `runs2.d/` stay exactly where they are,
  in the order they were collected, byte for byte;
* every future commit's diff is the records it added,
  so `git log -p` on the branch stays readable;
* a record that exists only in the aggregate is left alone.

`BACKFILL=1 scripts/rcc-merge.sh` splits the historical records out on request;
it is a capability, not a step on the path.

The merge needs nothing but the branch — it is a set difference (commits with a
part, minus commits already in the aggregate) followed by an append.
So it is idempotent, and losing a push race is cheap:
reset onto the winner, recompute the difference,
which is now *smaller* because the winner appended some of it, append, retry.
No producer runs again.

## Why both layouts

They are not redundant so much as differently shaped:

* `runs2.d/<xx>/<sha>.ndjson` is the **write** surface.
  One file per commit is what lets twenty legs publish at once without a lock.
* `runs2.ndjson` is the **read** surface.
  One file is what makes "what happened to every commit in this range"
  a single fetch rather than N.

In normal operation they drift slightly, in two directions that are both
harmless: records that predate the split live only in the aggregate,
and a record published seconds ago may not be merged into it yet.
Readers cope by trying the per-commit file and falling back
([`series-check.sh`](/scripts/series-check.sh)),
so the pair is the whole truth and neither has to be complete alone.

Ownership is deliberately lopsided,
because that is what makes the concurrency work:

| Writer | Adds | Rewrites |
|---|---|---|
| an `each-rcc` leg | its own record and log | nothing¹ |
| the run's fan-in | records a leg could not publish | nothing¹ |
| `rcc-logs.yaml` | records for commits it finds undecided | nothing¹ |
| `rcc-merge.sh`, from the last two | the aggregate's missing lines | a line a retry made stale |
| [`rcc-consolidate.sh`](/scripts/rcc-consolidate.sh) | — | **all of it**, by hand |

¹ except a verdict it is overturning — see below.

Everything routine is additive. The three destructive operations — making the
layouts agree, deleting logs, discarding history — belong to one manually
dispatched workflow
([`rcc-consolidate.yaml`](/.github/workflows/rcc-consolidate.yaml)),
where they happen once and under supervision.

## Consolidation

`rcc-consolidate.sh` is `workflow_dispatch`-only and defaults to a dry run.
Three things happen:

1. **The layouts are made to agree.** Every aggregate-only record is split into
   a part, and the aggregate is then rebuilt as exactly the parts'
   concatenation, ordered by when each verdict was written.
   This is the one place where migrating is right:
   the branch is being rewritten anyway, so there is no flag-day commit to avoid.
2. **Logs past `LOG_RETENTION_DAYS` are dropped** (30, in
   [`rcc-consolidate.sh`](/scripts/rcc-consolidate.sh)),
   along with any log whose commit has no record at all.
   Logs are about a megabyte each and most of the branch; records are ~2 KB.
   A log earns its keep by letting `series-check.sh` classify a failure —
   which matters for a commit the loop is still working on,
   not for one decided months ago and long since repaired.
   **Records are never dropped**, so the verdict outlives the evidence,
   and `.timing.failed_stages` still names the gate that broke.
3. **The history is squashed to two commits**: an empty `Initial`,
   and the whole current state.
   The root is *inherited* when one is already there —
   two consolidations must not mint two roots,
   or each would invalidate every clone twice over.

Why manual: every other writer is additive and races safely,
so a rewrite is the one operation that wants an operator who knows nothing else
is mid-flight. A schedule cannot know that.
The push carries `--force-with-lease` as the backstop,
so a writer that *did* land in between refuses the push instead of losing its
record — verified in
[`rcc-parts-test.sh`](/scripts/rcc-parts-test.sh).

## A newer verdict wins

A record is normally written once, which is what makes every writer idempotent.
The exception is a **retry**: `retry-<S>-dev` asks for a commit that already has
a verdict to be judged again on its own SHA, and the point is to overturn it.
So the newer verdict replaces the older one everywhere —

* [`rcc-part-push.sh`](/scripts/rcc-part-push.sh) compares blob ids in the index,
  so re-publishing an identical record costs nothing
  and a changed one replaces both the record and its now-stale log;
* [`each-harvest.sh`](/scripts/each-harvest.sh) compares the artifact's verdict
  against whichever layout holds the commit, and replaces on a difference;
* [`rcc-merge.sh`](/scripts/rcc-merge.sh) replaces the aggregate's *line* rather
  than appending a second one — readers take the first match for a SHA
  (`series-check.sh` greps with `-m 1`), so an appended line would be invisible.

Two writers can only collide here if they are deciding the same commit at the
same moment, which the planner does not produce; if it somehow happened, the
retry loop converges on whichever wrote last.

**"Newer" is checked, not assumed.**
A leg's verdict is on the branch within seconds,
but its run's fan-in lands when the *whole run* is done — possibly hours later.
So a retry can correctly overturn a commit while the run that first failed it is
still building, and replaying that run's artifact afterwards would put the stale
verdict back.
Nothing would repair it: the commit status is already the retry's,
so the planner never rebuilds,
and the backstop skips commits that have a record.
The fan-in therefore compares run ids — they increase per repository,
and a re-run keeps the id of the run it re-runs —
and leaves alone any record written by a *higher* run id than its own.

A verdict that stops being a failure also takes its log with it.
That case cannot be caught by comparing what a writer was handed,
because a success has no log to hand over;
both the leg and the fan-in remove the log explicitly
when the state is no longer a failure.

The planner names the commits it replanned *despite* a verdict in the plan's
`replanned_despite_verdict`, and the leg reads it from there.
Without that the resume check would skip exactly the commit a retry exists to
rebuild, and the workflow would have to keep an env var in agreement with the
planner's own logic — which it could not,
since the planner decides on the branch name.

## What publishing from a leg costs

Publishing has to be cheap, or the latency is not worth buying.
Almost all of the `rcc` branch is harvested logs,
and a leg needs none of those bytes to add one file. So
[`rcc-part-push.sh`](/scripts/rcc-part-push.sh) keeps a blobless, shallow,
checkout-less clone (`--filter=blob:none --depth 1`), which fetches trees only,
and builds the commit with plumbing: `read-tree`, `hash-object -w`,
`update-index`, `write-tree --missing-ok`, `commit-tree`, push.
Measured against a copy of the real branch,
the clone is under 1% of the branch and a publish takes ~130 ms once warm.

One trap is worth recording because it is completely invisible.
Plain `git write-tree` verifies that every index entry's object is present,
which in a blobless clone means lazily fetching every harvested log —
the whole branch, per leg.
`--missing-ok` suppresses the check
(every entry came either from the remote's own tree
or from the blob written moments earlier),
and `GIT_NO_LAZY_FETCH=1` is exported so that any *other* route to the same
mistake fails loudly instead of quietly downloading the branch.

## How bad is the race

Measured by [`rcc-parts-test.sh`](/scripts/rcc-parts-test.sh) —
20 concurrent writers against a copy of the real branch,
each publishing back to back with no build in between,
so roughly 100× the real rate.
Of 100 records published, **none were lost and none gave up**;
51% succeeded on the first attempt, 87% landed within four,
and the deepest retry was 9.
Nothing lost and nothing given up are the invariants —
the distribution moves from run to run with machine load.
That tail is what saturation looks like, not what the branch looks like:
with 20 writers pushing back to back there is always someone else mid-push,
so a loser can be starved for several rounds.
The retry budget is sized for it — a retry is one fetch and one push,
the backoff caps at 8 s, so the whole budget is about two minutes
against a build measured in tens of them.

At the real rate the arithmetic is dull, which is the point.
A publish is one fetch and one push, one or two seconds against GitHub;
20 legs at one commit per ~10 minutes issue about two pushes a minute;
so the chance that a given push overlaps another is around
2 s × 2/60 s ≈ 7%, and losing costs a second.

What is genuinely spent is commits: the branch grows by one per record rather
than one per run, so a 1000-commit backfill adds ~1000 commits to `rcc`.
Each is one small blob and two small trees —
which is what the 256-way fan-out is for.
A single flat directory of ten thousand records would rewrite the whole tree on
every push.

And none of it is load-bearing.
Legs still upload their artifacts, the fan-in still runs `if: always()`,
and `rcc-logs.yaml` still ticks every 30 minutes.
A failed publish is logged and ignored — it never fails the leg —
and the record is collected the old way, one job later.

*To deepen: state what the first live consolidation and the first live publish
against the real remote changed, and fold the vendoring-simplification plan's
remaining per-commit items
([`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md))
in as they land.*
