# Per-commit builds

How every commit on a series branch gets a gate verdict of its own:
the `each-rcc` workflow that plans cost-balanced shards of commits,
the orphan `rcc` branch that stores the verdicts,
and the cost model that decides where the shards are cut.
The point is bisectability — every commit on a `*-dev` branch is green,
so the branch can be bisected end to end.

The vendoring routine that produces the commits is
[`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)'s,
the green marker as a *series guarantee* is
[`branches/invariants/`](/handbook/branches/invariants/README.md)'s,
platforms and R versions are
[`operations/ci/matrix/`](/handbook/operations/ci/matrix/README.md)'s,
and the rest of the workflow inventory is
[`operations/ci/workflows/`](/handbook/operations/ci/workflows/README.md)'s.

## The three jobs

[`.github/workflows/each.yaml`](/.github/workflows/each.yaml) is one run
with three jobs.

```
plan   (1 job)
  ├─ enumerate candidate commits from git
  ├─ scripts/rcc-decided.sh    → which of them already have a verdict
  ├─ scripts/each-cost.py      → how many objects each one invalidates
  ├─ scripts/each-partition.py → contiguous, cost-balanced shards
  └─ plan.json (artifact) + the matrix and max-parallel as job outputs

build  (one job per shard, throttled by max-parallel)
  ├─ R, dependencies, ccache, formatters      ← paid once per shard
  └─ for each commit, oldest first:
       skip it if the store already decided it (a re-run resumes)
       reset the workspace → rcc status pending
       → scripts/rcc-one.sh → rcc status success/failure
       → quote each failed stage's tail into the job summary
       → publish the record and log to the `rcc` branch, within seconds

harvest (1 job, if: always())
  ├─ fill in records for commits whose leg never got to publish
  └─ append the new records to runs2.ndjson
```

Every job is guarded by `if: github.repository == 'krlmlr/duckdb-r'`,
so the workflow is inert in `duckdb/duckdb-r` and in forks:
the series branches it exists to prove live in that one repository.

The scripts are
[`each-plan.sh`](/scripts/each-plan.sh) (enumerate, read verdicts, weigh,
partition),
[`each-cost.py`](/scripts/each-cost.py) (object reach, the model's only input),
[`each-partition.py`](/scripts/each-partition.py) (the model and both passes),
[`each-shard.sh`](/scripts/each-shard.sh) (one leg: many commits, one
workspace),
[`rcc-one.sh`](/scripts/rcc-one.sh) (the gate itself, once),
[`rcc-part-push.sh`](/scripts/rcc-part-push.sh),
[`rcc-decided.sh`](/scripts/rcc-decided.sh),
[`rcc-merge.sh`](/scripts/rcc-merge.sh),
[`each-harvest.sh`](/scripts/each-harvest.sh),
[`rcc-consolidate.sh`](/scripts/rcc-consolidate.sh), and
[`rcc-parts-test.sh`](/scripts/rcc-parts-test.sh),
which checks the record layout's invariants offline and is the source of most
of the measured numbers below.

`each-rcc` fires on push to `each-*` and `*-dev`, on `workflow_dispatch`, and
on `workflow_call`.
**Nothing schedules it.**
After a lost leg the branch is left with a tail of undecided commits, and the
replanning that would pick them up waits for the next push or dispatch.
The replanning is correct; it is not automatic.

## What gets planned

On a `<S>-dev` branch with a sibling `<S>-green`, only `<S>-green..HEAD` is
scanned: everything at or before green is trusted and never rebuilt.
If green exists but is not an ancestor of HEAD, *nothing* is planned — the
branch is mid-surgery or on another lineage, and an unbounded scan would flood
the queue.
A branch with no green sibling falls back to the first-parent history since
`SINCE`.

A commit is planned when the verdict store does not mention it — the
enumeration drives the decision, not the store's contents, so an unmentioned
commit is planned rather than skipped.
A store that cannot be *read* stops the plan rather than reporting nothing
decided, which would replan the whole range — reachability is not emptiness.
And a `retry-<S>-dev` branch replans **its tip** even when that commit already
carries a verdict, so one commit can be judged again on its own SHA instead of
being amended and taking its descendants with it;
the prefix is stripped to derive the series, so the scan still anchors on
`<S>-green`, and a retry branch naming a series with no green plans nothing at
all, because the fallback scan reaches into `main`, where no commit has a
verdict.

### The gate

[`rcc-one.sh`](/scripts/rcc-one.sh) applies its gates in order:
`style`, `snapshots`, `roxygen`, `clean`, `check`, `pkgdown`.
`EACH_GATES` can drop individual ones.
`pkgdown` is not a candidate: a pkgdown failure is a real failure and has to be
dealt with.

The `snapshots` gate publishes accepted snapshots as a branch
`snapshot-<sha>-rcc-smoke-null` off the commit under test
(see [`testing/snapshots/`](/handbook/testing/snapshots/README.md)).
Those branches accumulate — one per accepted snapshot — and tooling looks them
up by name, so the
name is **frozen** rather than derived: upstream builds it from `github.job`
and an empty matrix, and here the job is `build` and there *is* a matrix, so
deriving it the same way would silently rename every future branch.
The commit is written through a temporary index, so the working tree keeps its
diff and the `clean` gate still fails the commit — which is why the `build` job
needs `contents: write`.

Failure classification downstream reads the log, not the exit code, so
`rcc-one.sh` emits `Changes detected in workflow_dispatch build` verbatim when
the tree is dirty; style or roxygen drift is then recognised as such by
[`series-check.sh`](/scripts/series-check.sh) rather than landing in its
`unclassified` bucket.

### The commit status is display only

The leg POSTs `pending` to the commit status with context `rcc` before a commit
and `success`/`failure` after it.
Nothing decides from that status: selection reads the verdict store, and so
does a resuming leg.
[`rcc-decided.sh`](/scripts/rcc-decided.sh) is that read for both, so the two
cannot disagree about what "decided" means.

A `PENDING_TTL_HOURS` heuristic once aged out the `pending` a dead leg left
wedged, back when statuses and records were two stores answering one question.
**No script or workflow implements that knob any more.**
A commit with no record is undecided, and the next run replans it;
a `pending` status is safe to disbelieve.

`R-CMD-check-status.yaml` and the `rcc-smoke-sha` artifact that feeds it stay
untouched — template content from
[`cynkra/cynkratemplate`](https://github.com/cynkra/cynkratemplate), writing the
status branch protection reads on ordinary pushes and PRs.
The sharded path needs no successor to that artifact, whose only job is to
carry a SHA across a `workflow_run` boundary that does not exist here.

### No running marker, by design

Nothing records "this commit is being built right now", and nothing should.
Two mechanisms keep a commit from being built twice, and neither is a marker:
the `concurrency` group `each-rcc-<ref>` with `cancel-in-progress: false`, so a
second push queues behind the first rather than killing it and leaving an
in-flight commit undecided; and work selection being a pure function of durable
verdicts, which outlive every runner.
A leg that dies takes no state with it.
The intent to take statuses out of selection altogether is
[`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md)'s.

## Why one job per shard is cheaper

The leg does `git checkout --force` and `git clean -qfdx` before each commit,
discarding the previous commit's object files — which were never going to
survive anyway.
`R CMD check` runs `R CMD build` first, which compiles from a copy of the
package, and this package's `cleanup` script tars `src/duckdb` away and deletes
it, so timestamp-based incremental `make` cannot cross a commit boundary here.

What survives is **ccache**, content-addressed and living outside the workspace
for the whole job, capped at 8 GB.
A typical adjacent vendor commit recompiles a handful of the unity objects
`src/include/sources.mk` lists — roughly 98% hits, measured over eight
consecutive `v1.5` commits and recorded in Appendix A of the superseded
vendoring-loop design
([`plan/history/vendoring-loop.md`](/plan/history/vendoring-loop.md#a2-ccache-behaviour-on-adjacent-commits-8-consecutive-v15-commits)).
Cleaning the workspace also means every commit's verdict is identical to one
from a fresh checkout, which keeps the semantics honest.
The leg deliberately does not use `custom/after-install`: its ccache is capped
at 200 MB and its `duckdb.tar` archive is keyed on the whole vendored tree, so
both are per-commit constructs a multi-commit job cannot use.

Legs run on `ubuntu-26.04`, the image `rcc-smoke` uses.
That is a parity requirement: a verdict that depends on the runner image is not
a reproduction of the one the gate exists to reproduce.

Within a job the only parallelism is `make`'s.
`install/action.yml` used to pin `MAKEFLAGS = -j2` on a 4-vCPU runner; measured
on a 4-core box, 8 vendored unity objects with ccache disabled took **70.8 s at
`-j2` against 43.1 s at `-j4`** — 1.64×, at identical user time.
The action now derives `-j` from `parallel::detectCores()`.
Backgrounding gates buys little on top: `style` → `snapshots` → `roxygen` all
mutate the working tree and `clean` observes their union, so that chain is
serial by construction, and the only clean overlap is `check` ∥ `pkgdown`, the
one pair where two compile-bound phases would collide.
Cross-commit pipelining is the real idle-core opportunity, needs two
workspaces, and is deliberately not attempted.
Oversubscription is a non-issue because `-j` is the only knob: the package
requests no `-flto` and R's `Makeconf` reports `LTO =` empty, and without
`Config/testthat/parallel` the suite runs serially.
Peak RSS per unity object measured about 834 MB, so four in flight is ~3.3 GB
of 16.

## The cost model

A leg's wall clock is

```
estimate_minutes = SETUP + FULL + Σ min(FLOOR + OBJECT_SECONDS × objects, FULL)
                                                        over all but the first
build_minutes    = estimate_minutes − SETUP
```

Four constants, each measuring one thing, each a default in
[`each-partition.py`](/scripts/each-partition.py):

| Constant | Default | What it is |
|---|---|---|
| `SETUP_MINUTES` | 5 | checkout, `install/action.yml`, `style` — paid once per leg |
| `FULL_BUILD_MINUTES` | 40 | a build on an empty ccache: every object `src/include/sources.mk` lists |
| `FLOOR_MINUTES` | 6 | one commit with nothing to recompile: link, install, `R CMD check`, the gates |
| `OBJECT_SECONDS` | 9.7 | marginal cost of recompiling one unity object |

The **first** commit of a leg pays `FULL` rather than its own weight, because
it starts on an empty ccache and rebuilds everything no matter how little it
changed.
Every later commit pays only for the objects it invalidates, capped at `FULL`:
a commit that touches a wide header cannot cost more than building the world.
`build_minutes` is what the leg measures itself against, since its deadline
starts after setup; `estimate_minutes` is what the job takes.

### The constants are measured, not borrowed

They were fitted by least squares to the 29 commits of two real runs on
`main-fwd-dev` and `v1.5-variegata-fwd-dev`, giving **RMSE 1.3 min** across the
26 warm builds, which span 4.9 to 38.0 minutes:

| objects | predicted | measured |
|---|---|---|
| 2 | 6.3 | 4.9, 5.2, 5.8, 5.9, 6.9 |
| 3 | 6.5 | 6.0, 6.1, 6.4, 6.5 |
| 23 | 9.7 | 10.3 |
| 53 | 14.6 | 16.5, 16.6 |
| 139 | 28.4 | 27.3 |
| 177 | 34.5 | 36.5 |
| 219 | 40.0 (capped) | 38.0 |

The three cold builds came in at 40.4, 39.7 and 40.1 minutes — flat, and
independent of what their commit changed, exactly as the model says.
Whole legs land within a few percent: one leg's 12 commits were predicted at
243 min and took 252, another's first 12 at 304 against 302.

They replaced pre-2026 estimates (`COLD_MINUTES=22`, `FLOOR_MINUTES=11`,
`OBJECT_SECONDS=4.3`) that charged nearly twice too much for a cheap commit and
half too little for an expensive one, compressing the predicted spread so that
legs of "equal" cost were not equal and one full of wide-header commits overran
its 300-minute deadline.
Every leg now records `duration_seconds` per commit and
[`each-harvest.sh`](/scripts/each-harvest.sh) carries it onto the `rcc` branch
as `.timing`, so the fit can be redone against any range at any time.

### Weighing a commit

[`each-cost.py`](/scripts/each-cost.py) answers "how many unity objects does
this commit invalidate" without building anything, in a few seconds.
It reads the object list from `src/include/sources.mk` — many of them `ub_*.o`
groups that `#include` dozens of `.cpp` files each — resolves every
`#include "..."` edge in `src/duckdb/**`, and does one BFS per object.
Each file ends up with a bitmask of the objects that transitively include it,
and a commit's cost is the population count of the OR over its changed paths.

Sanity checks, measured against the vendored tree as it stood then:

| path | objects |
|---|---|
| `src/execution/operator/join/physical_hash_join.cpp` | 1 |
| `src/include/duckdb/main/client_context.hpp` | 170 |
| `src/include/duckdb/common/types.hpp` | 214 |
| `src/include/duckdb/common/exception.hpp` | 217 |

Across 120 real `v1.5-variegata-dev` commits the distribution is bimodal:
55 touch no C++ at all, 43 invalidate 1–5 objects, 12 invalidate 6–30,
2 invalidate 31–100, and 8 are wide-header commits invalidating more than 100.
Median 2, mean 15, max 209.

Resolution is deliberately an over-approximation: an include target is matched
against a path-suffix index, so an ambiguous `#include "types.hpp"` counts for
every `types.hpp` in the tree.
Over-estimating isolates a commit that did not need isolating — a little
parallelism, no correctness.
The map is built once from the branch tip and reused for the whole range;
reach drifts slowly, and a stale weight only mis-balances a shard.

### Two passes

**Pass 1 minimises legs.**
Shards must be **contiguous** — that is what makes consecutive checkouts
cheap — so this is not bin packing: partitioning a sequence into the fewest
contiguous parts under a fixed budget is solved exactly by one greedy
left-to-right pass, in O(n).
Balancing by predicted time rather than commit count is what isolates expensive
commits: on 998 undecided `main-dev` commits it emits legs of 7 to 27 commits,
a 3.9× spread in count, to hold them all under one deadline.

**Pass 2 minimises wall clock**, by running pass 1 again against *shorter*
deadlines and keeping whichever plan finishes soonest.
Pass 1 at deadline `B` is a one-parameter family of complete plans, so pass 2
only picks a `B`, and every plan it can pick is contiguous, balanced and inside
the real deadline by construction.
Without it a small batch waits for nothing: at a 300-minute deadline and ~6
minutes a cheap commit, 25 commits fit in two legs and wait five hours for a
verdict 20 legs would have delivered in fifty minutes.

`SPLIT_FACTOR` (default 1.5) caps the plan at that multiple of the pass-1
plan's runner-minutes, with `1.0` disabling the pass; `MAX_SHARDS` and the
commit count bound it from the other side.
Ranking is by a `makespan()` that models `max-parallel` throttling, ties going
to the cheapest plan.
The whole family is evaluated rather than walked in one direction, because
neither axis is monotone in `B`: wall clock falls with more legs only until the
matrix runs out of slots, where `P + 1` legs take two waves against `P` legs'
one; and runner cost usually rises with more legs but not always, since a
commit that invalidates the whole unity build already pays `FULL`, so a cut
just before one is free but for the job setup.

On a live 77-commit `main-fwd-dev` batch:

| `SPLIT_FACTOR` | shards | wall clock | runner time |
|---|---|---|---|
| 1.0 (off) | 4 | 303 min | 978 min |
| 1.25 | 15 | 93 min | 1219 min |
| **1.5** | **20** | **79 min** | **1354 min** |
| 2.0 | 20 (`max-parallel`) | 79 min | 1354 min |

The default trades 1.38× the compute for **3.8× the wall clock**.
Past 1.5 the curve is flat: `max-parallel` becomes the binding limit.

The pass deliberately does not stop once it has `max-parallel` legs, because
`max-parallel` is the width of a wave, not a ceiling on legs, and pass 1
routinely emits more on its own.
On the 1039-commit `main-dev` backlog pass 1 emits 67 legs against 20 slots —
four waves, the last a third full, every leg packed to the 300-minute deadline.
Rebalancing to 79 legs keeps four waves but shortens the longest leg to about
254 minutes, cutting wall clock from **19.2 h to 16.9 h** for twelve extra
runner-minutes out of 19,247 — 0.06%, because those twelve legs start on
wide-header commits that were paying for a full rebuild anyway.
The gain grows with the slot count: at `max-parallel: 40` that backlog goes
from 10.0 h to 8.5 h, and at 60 from 9.5 h to 6.0 h.
The pass is a no-op where it should be — `SPLIT_FACTOR: 1.0`, a batch already
at `MAX_SHARDS`, or a plan whose waves are already even.

### Numbering and order

A shard's **number** runs with the history: shard 1 holds the oldest commits of
the plan, shard N the branch tip, and adjacent numbers are adjacent slices.
The **order** they are queued in is the same, so that under `max-parallel`
throttling the oldest undecided slice is decided first — the end the series
loop can move from, since `<S>-green` advances only over a *contiguous* run of
green commits.
Within a shard, commits run oldest-first too, for cache locality.
Numbers are assigned after the matrix cap has dropped the oldest shards, so
shard 1 is the oldest shard *this run* will build.

### What it buys

Planning the newest 1000 commits of `main-fwd-build`, every one treated as
undecided, takes 5.4 s end to end including the reach map, and yields 79 shards
of 8–19 commits (median 12), estimated at 159–264 min each.
That branch is close to the worst case for this design, which is why it is
worth measuring on: 34% of its commits are wide-header commits against 7% on
`v1.5-variegata-dev`, and its median/mean object count is 16/76 against 2/15.

| | sharded | one run per commit |
|---|---|---|
| jobs | **79** | 1000 |
| runner-hours | **338** | 883 |
| wall clock at `max-parallel: 20` | **~18 h** (4 waves) | — |

That is **2.6×** less compute on the worst case, against 3.6× on the much
cheaper `v1.5-variegata-dev` distribution — the honest range.
At `max-parallel: 8` the same backlog is ~44 h; at 60, ~9 h.
Extrapolating the same shard density, a 3000-commit mainline replay is about
240 shards — still inside the 250 cap, but close enough that a bigger backlog
would need a second run or a larger shard budget.

## The verdict store

The verdict store is the orphan `rcc` branch, which shares no history with the
default branch and holds only collected data:

```
runs2.d/<xx>/<sha>.ndjson     one record, one line — where a record lands first
runs2.ndjson                  every record, in arrival order — extended, never rewritten
logs2/<sha>.log               the whole per-commit log
```

The two files are differently shaped, not redundant.
`runs2.d/` is the **write** surface: one file per commit lets twenty legs
publish at once without a lock, and the 256-way `<xx>` fan-out keeps each push
from rewriting a large tree.
`runs2.ndjson` is the **read** surface: one file makes "what happened to every
commit in this range" a single fetch rather than N.
They drift slightly and harmlessly — records predating the split live only in
the aggregate, and a record published seconds ago may not be merged into it
yet — so readers try the per-commit file and fall back to the aggregate
([`series-check.sh`](/scripts/series-check.sh) and
[`series-advance.sh`](/scripts/series-advance.sh) both do).
The pair is the whole truth and neither has to be complete alone.

Publishing per commit rather than at the end of the run is what makes the
series loop's cycle time minutes instead of hours: the loop gates on the
*records*, so under the old fan-in barrier a verdict waited for the slowest leg
in the run.
It also removed the window in which a leg's artifact was the only copy of a
per-commit log, which a cancelled run lost.

Ownership is lopsided, and that is what makes the concurrency work.
A leg adds its own record and log; the fan-in adds records a leg could not
publish; `rcc-logs.yaml` adds records for commits it finds undecided.
None of them rewrites anything except a verdict it is overturning.
[`rcc-merge.sh`](/scripts/rcc-merge.sh) appends the aggregate's missing lines
and replaces stale ones; only
[`rcc-consolidate.sh`](/scripts/rcc-consolidate.sh) rewrites the branch, and
only by hand.
`runs2.ndjson` is extended, never regenerated, so the ~4.5k records that
predate the split stay byte for byte where they are and every future diff is
just the records it added.
Losing a push race is then cheap: reset onto the winner, recompute the
difference — now *smaller*, because the winner appended some of it — append,
retry, with no producer running again.
`BACKFILL=1 scripts/rcc-merge.sh` splits the historical records into parts on
request.

### Publishing is cheap

The `rcc` branch runs to hundreds of megabytes, almost all of it harvested logs
at about a megabyte each, and a leg needs none of those bytes to add one file.
So [`rcc-part-push.sh`](/scripts/rcc-part-push.sh) keeps a blobless, shallow,
checkout-less clone (`--filter=blob:none --depth 1`) that fetches trees only,
and builds the commit with plumbing: `read-tree`, `hash-object -w`,
`update-index`, `write-tree --missing-ok`, `commit-tree`, push.
Measured against a copy of the real branch: **2.1 MB of clone against a 222 MB
branch, and ~130 ms per publish once warm.**

One trap is worth recording because it is invisible.
Plain `git write-tree` verifies that every index entry's object is present,
which in a blobless clone means lazily fetching every log on the branch — the
whole of it, per leg.
`--missing-ok` suppresses the check, and `GIT_NO_LAZY_FETCH=1` is exported so
that any *other* route to the same mistake fails loudly instead of quietly
downloading the branch.

What is genuinely spent is commits: the branch grows by one per record rather
than one per run, so a 1000-commit backfill adds ~1000 commits to `rcc`.

### The race is bounded

[`rcc-parts-test.sh`](/scripts/rcc-parts-test.sh) hammers a copy of the real
branch with 20 concurrent writers publishing back to back with no build in
between — roughly 100× the real rate:

| | |
|---|---|
| records published | 100 |
| records lost | **0** |
| succeeded on the first attempt | 51% |
| landed within 4 attempts | 87% |
| needed 5 or more | 13% (deepest: 9 of 20) |
| gave up | 0 |

Only the first two rows are invariants; the rest moves with machine load, and
that tail is what saturation looks like rather than what the branch looks like.
The retry budget is sized for it: a retry is one fetch and one push, the
backoff caps at 8 s, so the whole budget is about two minutes against a build
measured in tens of them.
At the real rate — 20 legs at one commit per ~10 minutes, so about two pushes a
minute — the chance a given push overlaps another is around 7%, and losing
costs a second.

None of it is load-bearing.
A failed publish is logged and ignored, never fatal; legs still upload their
artifacts, the fan-in still runs `if: always()`, and `rcc-logs.yaml` still
ticks every 30 minutes as the backstop.

### A newer verdict wins

A record is normally written once, which is what makes every writer idempotent.
The exception is a retry, whose point is to overturn a verdict, so the newer
one replaces the older one everywhere:
`rcc-part-push.sh` compares blob ids in the index, so re-publishing an
identical record costs nothing and a changed one replaces both the record and
its now-stale log;
`each-harvest.sh` compares the artifact's verdict against whichever layout
holds the commit;
`rcc-merge.sh` replaces the aggregate's *line* rather than appending a second
one, because readers take the first match for a SHA.
A verdict that stops being a failure also takes its log with it, removed
explicitly by both the leg and the fan-in, since a success has no log to hand
over.

"Newer" is **checked, not assumed**.
A leg's verdict is on the branch within seconds, but its run's fan-in lands
when the whole run is done — so a retry can overturn a commit while the run
that first failed it is still building, and replaying that run's artifact
afterwards would put the stale verdict back, with nothing to repair it.
The fan-in therefore compares run ids, which increase per repository and which
a re-run keeps, and leaves alone any record written by a higher run id.

The planner names the commits it replanned *despite* a verdict in the plan's
`replanned_despite_verdict`, and the leg reads the intent from there rather
than from an env var the workflow would have to keep in agreement with the
planner's own logic.

### Consolidation

[`rcc-consolidate.yaml`](/.github/workflows/rcc-consolidate.yaml) is
`workflow_dispatch`-only and defaults to a dry run;
set the `apply` input to actually rewrite the branch.
Measured on the live branch as it stood when the script was written:

| | before | after |
|---|---|---|
| commits | 181 | **2** |
| records | 4601 aggregate / 4572 parts | 4601 / **4601** |
| logs | 2496 | **856** |
| objects | 218 MB | **74 MB** |

Three things happen.
The layouts are made to agree: every aggregate-only record is split into a
part, and the aggregate is rebuilt as exactly the parts' concatenation, ordered
by when each verdict was written.
Logs past `log-retention-days` (30) are dropped, along with any log whose
commit has no record — logs are ~1 MB each and ~90% of the branch, records
~2 KB, and a log earns its keep by letting `series-check.sh` classify a failure
for a commit the loop is still working on.
**Records are never dropped**, so the verdict outlives the evidence and
`.timing.failed_stages` still names the gate that broke.
And the history is squashed to two commits, an empty `Initial` and the current
state, with the root *inherited* when one is already there — two consolidations
must not mint two roots.

It is manual because a rewrite is the one operation that wants an operator who
knows nothing else is mid-flight, which a schedule cannot know.
The push carries `--force-with-lease`, so a writer that *did* land in between
refuses the push instead of losing its record.

No writer takes a lock, and the fan-in is deliberately **not** in
`rcc-logs.yaml`'s concurrency group even though both push to the same branch:
only one run may be *pending* per group, so a third writer queued behind the
second cancelled it outright, and a cancelled fan-in took the only copy of its
per-commit logs with it.
Writers that race and retry lose strictly less than writers that get evicted.

## Operating it

Everything is an input on `workflow_dispatch`, and the ones worth setting
repo-wide are repository variables:

| Knob | Input | Variable | Default |
|---|---|---|---|
| Earliest commit date | `since` | `EACH_RCC_SINCE` | `2026-01-01` |
| Concurrent shards | `max-parallel` | `EACH_RCC_MAX_PARALLEL` | `20` |
| Build-time target per shard | `shard-budget-minutes` | — | `300` |
| Compute traded for wall clock | `split-factor` | `EACH_RCC_SPLIT_FACTOR` | `1.5` |
| Cap on commits considered | `max-commits` | — | `0` (no cap) |
| Rebuild decided commits | `force` | — | `false` |
| Log lines quoted per failed stage | — | `EACH_RCC_SUMMARY_TAIL` | `50` |

`force` is a `workflow_dispatch` input only; `workflow_call` does not expose it.
`each-plan.sh`'s own default for `max-parallel` is 8, but the workflow always
passes a value, so 20 is what a run gets unless the variable or the input says
otherwise.

The lever for a slow *large* batch is `max-parallel`, which decides how many
waves it takes.
The lever for a slow *small* batch is `split-factor`: under `max-parallel` legs
the run is one wave, and the only way to shorten it is to make the longest leg
shorter.
Set `split-factor` to `1.0` for the fewest-legs, cheapest-compute behaviour.

### Reading a failure without opening the log

A leg is one job for up to ~20 commits and up to five hours of output, so
"which commit went red, and why" would otherwise mean expanding the right
`::group::` in a very long job log.
The leg's job summary answers both directly.
The result table names the stages that failed — a commit's cell reads
`failure (check, pkgdown)`, not just `failure` — and below it each failed stage
gets a collapsed `<details>` block holding the last `EACH_RCC_SUMMARY_TAIL`
lines of *that stage's* output, which is enough to tell a compile error from a
failing test.
Setting the variable to `0` turns the excerpts off.

Two details make it work.
`rcc-one.sh` writes each stage's output to its own file under `EACH_STAGE_DIR`
and its verdict to `outcomes.tsv`, rather than the leg parsing the combined log
back apart; nothing is buffered that was not already buffered, and a stage with
a log but no verdict is precisely the stage the leg's `timeout` killed, so that
one is quoted too.
And excerpts stop at 900 kB, because GitHub truncates a step summary at 1 MiB
and a truncated summary would take the result table with it; how many were
dropped is stated.

The excerpt is not the record.
The whole per-commit log still goes to `logs2/<sha>.log`, which is what
`series-check.sh` classifies against.
The vendoring operator's view of a red run — which failures mean what, and what
to do about them — is
[`operations/vendoring/troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md)'s.

### Failure modes

| Situation | Outcome |
|---|---|
| A commit fails its gate | `rcc=failure`, the leg keeps going, record and log published from the leg, failed stages' tails in the job summary |
| A leg runs out of budget | remaining commits stay undecided, next run replans them |
| A leg dies hard mid-commit | that commit stays `pending` and undecided; every commit it had already decided is on the `rcc` branch; the next run replans it |
| A leg is re-run after dying | commits it already decided are skipped, not rebuilt |
| A leg cannot reach the `rcc` branch | logged, never fatal; the fan-in collects the record from the artifact |
| The whole run is cancelled | no fan-in, but the legs' own records are already on the branch; `rcc-logs.yaml` covers the rest on its next tick |
| The `plan` job fails | `build` and the fan-in are both skipped |
| History is force-pushed mid-run | unreachable SHAs fail checkout and are skipped; new SHAs picked up next run |
| More than 250 shards planned | oldest shards deferred, reported in the job summary |
| Two writers publish records at once | different files, no conflict; the loser of the ref race re-reads the tip and re-commits |
| Two writers extend the aggregate at once | the push is rejected, and [`rcc-push.sh`](/scripts/rcc-push.sh) resets onto the new tip, re-derives, and appends what is still missing before retrying |
| A retry overturns a verdict | the newer record and log replace the older ones, in the part and in the aggregate's line |
| An earlier run's fan-in lands after a retry | it sees a higher run id on the branch and keeps that record; the stale verdict is not replayed |
| A retry turns a failure green | the record is replaced and the log it overturned is dropped, on whichever path publishes first |
| A leg is re-run after publishing failed | its artifact is named per attempt, so the earlier attempt's records stay collectable |
| A writer lands during a consolidation | the lease refuses the force-push; nothing is lost, re-dispatch it |

Nothing here needs a lock for correctness.
Progress is durable per commit, and every run recomputes its own to-do list
from ground truth.
`fail-fast: false` keeps siblings running when one leg dies, `timeout-minutes`
is 350 against GitHub's 6-hour ceiling so the leg stops itself and reports what
it deferred rather than being killed mid-commit, and the blast radius of a lost
runner is one leg.
Re-running the failed job or dispatching `each-rcc` again costs only the
undecided commits — which matters, because the series loop's last-resort repair
(amending a commit that cannot get a verdict and replaying the tail) mints a
new SHA for every commit after it, so one lost leg would otherwise cost a
rebuild of every already-green commit newer than it.

## Limits

**GitHub Actions bounds the design in five places.**
A matrix generates at most 256 jobs per run, so `MAX_SHARDS` defaults to 250
and bounds the rebalance pass as well as the fill.
A job may run 6 hours, so the shard budget is 300 minutes and the job timeout
350.
A run may last 35 days, which 1000 commits at ~18 h never approaches.
Concurrency is plan-dependent, and `max-parallel` keeps the run a good
neighbour.
And `GITHUB_TOKEN` gets 1000 REST requests per hour per repository — the limit
that ruled out the obvious implementation, since reading one commit-status per
call costs one request per commit and a 3000-commit scan could not complete at
all.
A git-native verdict store answers that outright: reading it is one fetch
regardless of range, and publishing a record is a git push rather than an API
call.
Writing statuses stays REST, 2 per commit, which at `max-parallel: 20` and
~20 min per commit is on the order of 180 requests per hour — a rate, not a
burst.

**`workflow_call` is not the mechanism.**
Calling `R-CMD-check.yaml` from a matrix job is mechanically valid and would
buy one run to cancel and one run id for the logs, but a `uses:` job does not
run the called workflow *inside* your job: GitHub schedules its jobs on
separate runners, so the topology is one runner per commit merely re-parented,
and amortised setup and a warm ccache are precisely what it cannot deliver.
Nor does it scale: each call expands to more than one job against the 256-job
ceiling, and while nested matrices can exceed 256, the one public write-up
([community discussion #38704](https://github.com/orgs/community/discussions/38704))
reports the run page failing to load past roughly 600 jobs and Actions being
disabled on the account that tried it.
`R-CMD-check.yaml` is also forward-ported from `duckdb/duckdb-r@main`, so a
repo-specific `workflow_call` interface there would be a permanent merge tax.
Relatedly, `uses:` is a **job-level** key: one job calls at most one reusable
workflow and may not carry `steps`, and a workflow cannot loop over composite
actions either.
A shell loop is the only construct that can run the same gate N times in one
job, which is why the gate is a script.

**A `*-dev` branch runs the scripts it carries.**
`each.yaml` runs from the branch it is checking, so a branch picks up a change
to the sharded path only once the new scripts are forward-ported to it — the
same constraint every CI change in this repository has, automated by the series
loop.
The legacy per-commit dispatcher has been retired outright:
`scripts/each-rcc.sh`, this workflow's `dispatch` mode, `scripts/vendor-gate.sh`
and `cancel-rcc-dispatch.yaml` are gone, as is `vendor.yaml`.
Rolling back is therefore a revert rather than a variable flip — an escape
hatch that is never reached for is not insurance but a second path everything
else has to keep being correct against.

**What is not yet validated**, in rough order of risk:

* `rcc-one.sh` is a *port*, not a call.
  It reproduces the gates `rcc-smoke` applies on its `workflow_dispatch` path,
  and since `R-CMD-check.yaml` is forward-ported from upstream the two can
  drift.
  With the legacy path retired there is no automated parity check; drift is
  caught by reviewing the gate list whenever `R-CMD-check.yaml` is
  forward-ported.
* The cost model counts objects, not object *sizes*.
  A `ub_*.o` group compiles dozens of `.cpp` files and a leaf object compiles
  one, and both are charged the same `OBJECT_SECONDS`.
  The fit absorbs this on average, but it is why the residuals go one way at
  53 objects and the other at 219.
  Weighting each object by its translation unit's size would remove the bias,
  and `each-cost.py` already has the graph it would need.
* The fit is 29 commits from two branches, both heavy on vendor churn.
  An R-only batch — 0 invalidated objects throughout — is not represented, and
  `FLOOR_MINUTES` is the constant that would move.
* An 8 GB ccache on a standard runner should hold about 17 trees' worth of
  compressed objects, and only the previous commit's are needed.
  Not measured on a runner.
* Rebalancing raises the concurrency footprint: a 77-commit batch now asks for
  20 runners instead of 4, for an hour.
  Peak concurrency is still capped by `max-parallel`, but it is the whole
  account's Actions concurrency, so other workflows queue behind it where they
  used not to.
* The publish path's invariants are checked offline against a copy of the real
  branch, not against GitHub.
  HTTPS latency makes the collision window a second or two rather than 130 ms,
  and `--filter=blob:none` is a server capability.
  The fallbacks are in place — a refused filtered fetch retries unfiltered, and
  a publish that cannot succeed is logged and left to the fan-in — so the
  failure mode is a slow leg or a late record, not a lost one.
* The two record layouts coexist between consolidations.
  Records written before the split live only in `runs2.ndjson`, and
  `rcc-decided.sh` reads parts only.
  That is deliberate: every pre-split record belongs to a commit far below
  every series' green, and green bounds the planner's range, so the cost of the
  gap is a rebuild rather than a wrong verdict.
* `rcc-consolidate.sh` has only been run against a copy.
  It force-pushes an orphan branch that the accumulated snapshot branches and
  several workflows read, and the first real run is the one that proves the fetch
  refspecs elsewhere tolerate it.
  Dry run first.

Where this is heading is
[`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md);
the design it narrows is primitive **B** of
[`plan/history/vendoring-loop.md`](/plan/history/vendoring-loop.md#b-build-primitive--synchronous-sharded-matrix-ci-new-rcc-matrixyaml),
landed inside the existing `each-rcc` rather than as a new workflow because the
selection semantics were already there.
Implementing it corrected that plan twice — §4.2 attributes within-shard reuse
to incremental `make` when it is ccache, and §4.3's reverse-include map now
exists — and refused a third explanation: §4.4 attributes the per-commit floor
to the LTO link, and there is no LTO in this build, so `FLOOR_MINUTES` was left
to be measured rather than inheriting that story.
