# The verdict store

The orphan `rcc2` branch: how a verdict is published seconds after it exists,
why every record is its own file,
and what keeps a dozen writers from colliding.
Who reads it, and to decide what, is
[`selection/`](/handbook/operations/ci/per-commit/selection/README.md)'s.

A verdict reaches the branch seconds after it exists,
not at the end of the run.
That latency is the series loop's cycle time, because
[`series-check.sh`](/scripts/series-check.sh) gates on the *records*,
not the statuses.

The store is one file per commit and nothing else:

```
runs2.d/<xx>/<sha>.ndjson     the verdict, one line of JSON, ~2 KB
logs2.d/<xx>/<sha>.log        the harvested output of a failure, ~1 MB
```

Two writers recording different commits touch different paths,
so there is nothing to conflict on,
and a loser of the ref race re-reads the tip and re-commits its own files.
Both directories carry the same 256-way fan-out
on the SHA's first two hex digits, for the same reason:
adding one file rewrites one small tree
rather than a tree with every entry in it.

## Why no aggregate

There used to be one — `runs2.ndjson`, every record concatenated in arrival
order, with the per-commit files feeding it through a merge step.
It bought "read the whole range in one `git show`",
and it cost that merge step, a rule for replacing a line a retry had made stale,
a two-layout fallback in every reader, and half of the consolidation.

Nothing needed what it bought.
The loop reads records one at a time,
through `git show origin/rcc2:runs2.d/…`,
because a per-commit lookup is what a per-commit verdict deserves.
So the aggregate is gone, with no replacement
(D2 of [`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md)),
and with it `rcc-merge.sh`, `rcc-push.sh` and `rcc-part-push.sh`.
What is left is one writer,
[`rcc-publish.sh`](/scripts/rcc-publish.sh),
which stages a directory shaped like the branch and pushes it;
the mechanics those three shared — the store's paths, the checkout-less clone,
the retention window, the squash — live in
[`rcc-lib.sh`](/scripts/rcc-lib.sh).

One file that every writer extends is also the one file two writers can
genuinely disagree about.
Removing it is what let the recovery go too:
a rejected push used to mean resetting onto the winner and re-running the
producer, because a textual conflict at EOF has no better resolution.
Now it means re-reading the tip and re-staging the same files.

## Who writes what

| Writer | Frequency | Touches |
|---|---|---|
| an `each-rcc` leg | once per commit built (~2/min at `max-parallel: 20`) | its own record, its own log |
| the run's fan-in | once per run | records and logs the legs could not publish |
| `rcc-logs.yaml` | every 30 min | records for commits it finds undecided |
| [`rcc-consolidate.sh`](/scripts/rcc-consolidate.sh) | by hand | **all of it** |

Nobody rewrites anything that is not their own commit's —
except a verdict they are overturning, below —
and that is what makes the concurrency work without a lock.

## Retention is one window

The store keeps `RCC_RETENTION_DAYS` (30) of history,
**records and logs alike**,
and [`rcc-consolidate.sh`](/scripts/rcc-consolidate.sh) enforces it.
Logs are still the bulk of what goes — about a megabyte each against ~2 KB for
a record — but keeping a verdict for a commit decided months ago and long since
repaired only postpones the same deletion,
and one number is easier to reason about than two.

That the window is *one* number makes it load-bearing in both directions:

* a producer must not look further back than the window,
  or it re-derives every tick exactly what the next consolidation drops.
  [`rcc-logs.sh`](/scripts/rcc-logs.sh) therefore derives its `SINCE`
  from `RCC_RETENTION_DAYS` rather than from a fixed date;
* a consumer must not ask about a commit older than the window.
  Selection is bounded by `<S>-green`, which is far newer,
  and the cost of being wrong is a rebuild rather than a wrong verdict.

## Consolidation

`rcc-consolidate.sh` is `workflow_dispatch`-only
([`rcc-consolidate.yaml`](/.github/workflows/rcc-consolidate.yaml))
and defaults to a dry run.
Two things happen:

1. **Records and logs past the window are dropped**,
   along with any log whose commit has no record at all —
   nothing reads those and nothing can date them.
2. **The history is squashed to two commits**: an empty `Initial`,
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
[`rcc-store-test.sh`](/scripts/rcc-store-test.sh).

## Where `rcc2` came from

The store used to live on `rcc`, which accumulated four layouts —
one per generation of the harvest — and 181 commits holding every log ever
harvested, at ~220 MB.
Reconciling that in place was possible, and had been done;
what it could not do was shed the history,
or free the readers from carrying a fallback for the layout underneath.

[`rcc-cutover.sh`](/scripts/rcc-cutover.sh) reads `rcc` once and writes `rcc2`
as two commits — an empty root and everything that survives the window.
Records come from both old layouts, the part winning where they differ;
flat `logs2/<sha>.log` files move under the fan-out;
a legacy `logs/<run-id>.log` is recovered as its commit's log
when that run decided exactly one commit,
and dropped rather than guessed at when it did not.
`rcc` is never written to, and is left whole:
deleting it is a separate step for whenever nothing reads it.

### Runbook: the cutover

Run once, from a terminal, against the repository that holds `rcc`.
It moves ~220 MB over the wire and rewrites the worktree in place,
so give it a worktree of its own:

```sh
git fetch origin '+refs/heads/rcc:refs/heads/rcc'
git worktree add ../rcc-cutover rcc

OUT_DIR=../rcc-cutover scripts/rcc-cutover.sh            # dry run: reports only
OUT_DIR=../rcc-cutover APPLY=1 scripts/rcc-cutover.sh    # writes and pushes rcc2

git worktree remove --force ../rcc-cutover
```

The dry run prints what it would distribute and what ages out;
read it before applying.
`APPLY=1` pushes `rcc2` and nothing else,
and the script refuses outright if `rcc2` already exists
(`FORCE=1` overrides, and discards whatever has been published there).

**Do this before the producers start writing.**
Until `rcc2` exists, the first leg to publish creates it as an empty orphan,
which is correct but starts the store with no history —
and then the cutover's refusal is the only thing standing between you and
discarding it.

## A newer verdict wins

A record is normally written once, which is what makes every writer idempotent.
The exception is a **retry**: `retry-<S>-dev` asks for a commit that already has
a verdict to be judged again on its own SHA, and the point is to overturn it.
So the newer verdict replaces the older one everywhere —

* [`rcc-publish.sh`](/scripts/rcc-publish.sh) compares blob ids in the index,
  so re-publishing an identical record costs nothing
  and a changed one replaces it;
* [`each-harvest.sh`](/scripts/each-harvest.sh) compares the artifact's verdict
  against what the branch holds, and replaces on a difference.

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
both the leg and the fan-in list the log path for *removal* instead,
which is what the staging directory's `.remove` file carries.
A failure that could not capture a log of its own removes nothing:
whatever the branch holds is that commit's, from an earlier attempt,
and a log we failed to capture is no reason to delete one we have.

The planner names the commits it replanned *despite* a verdict in the plan's
`replanned_despite_verdict`, and the leg reads it from there.
Without that the resume check would skip exactly the commit a retry exists to
rebuild, and the workflow would have to keep an env var in agreement with the
planner's own logic — which it could not,
since the planner decides on the branch name.

## What publishing from a leg costs

Publishing has to be cheap, or the latency is not worth buying.
Almost all of the store is harvested logs,
and a leg needs none of those bytes to add one file. So
[`rcc-publish.sh`](/scripts/rcc-publish.sh) keeps a blobless, shallow,
checkout-less clone (`--filter=blob:none --depth 1`), which fetches trees only,
and builds the commit with plumbing: `read-tree`, `hash-object -w`,
`update-index`, `write-tree --missing-ok`, `commit-tree`, push.
Measured against a copy of the real branch,
the clone is under 1% of the branch and a publish takes ~130 ms once warm.

The fan-in wants one thing more — what the branch currently says about each
commit in its artifacts — and gets it from the same helper with a different
filter: `--filter=blob:limit=16k` brings every record and no log,
because a record is ~2 KB and a log is ~1 MB.
One fetch, and every comparison it needs is then local.

Two traps are worth recording because both are completely invisible.

Plain `git write-tree` verifies that every index entry's object is present,
which in a blobless clone means lazily fetching every harvested log —
the whole branch, per leg.
`--missing-ok` suppresses the check
(every entry came either from the remote's own tree
or from the blob written moments earlier),
and `GIT_NO_LAZY_FETCH=1` is exported so that any *other* route to the same
mistake fails loudly instead of quietly downloading the branch.

The second one only fires on a **replacement**, which is why it stayed hidden.
`git push` sends a *thin* pack by default:
the sender may delta against objects the receiver already has,
and to do that it has to read them.
Publishing a record at a path the branch has never held has no such base and
pushes fine; publishing one that *replaces* an existing record makes git want
the old blob — a promised object — and the push dies with
"could not fetch … from promisor remote".
Since replacement is exactly what a retry does,
and what the fan-in does when a leg's verdict has changed,
the failure would have been retry-only and rare.
`--no-thin` on the push is the fix,
and [`rcc-store-test.sh`](/scripts/rcc-store-test.sh) covers it:
a verdict is replaced there from a clone that never wrote the first one.

## How bad is the race

Measured by [`rcc-store-test.sh`](/scripts/rcc-store-test.sh) —
20 concurrent writers against a local remote,
each publishing back to back with no build in between,
so roughly 100× the real rate.
Of 100 records published, **none were lost and none gave up**;
58% succeeded on the first attempt, 90% landed within four,
and the deepest retry was 7.
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
than one per run, so a 1000-commit backfill adds ~1000 commits to the store.
Each is one small blob and two small trees —
which is what the 256-way fan-out is for.
A single flat directory of ten thousand records would rewrite the whole tree on
every push.

And none of it is load-bearing.
Legs still upload their artifacts, the fan-in still runs `if: always()`,
and `rcc-logs.yaml` still ticks every 30 minutes.
A failed publish is logged and ignored — it never fails the leg —
and the record is collected the old way, one job later.

*To deepen: state what the first live cutover, the first live consolidation and
the first live publish against the real remote changed, and fold the
vendoring-simplification plan's remaining per-commit items
([`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md))
in as they land.*
