# Per-commit builds

Every commit on a series branch gets a gate verdict of its own:
[`each.yaml`](/.github/workflows/each.yaml) plans contiguous,
cost-balanced **shards** of commits and gives each shard one job,
which builds and tests its commits one by one in a single workspace,
and the verdicts live on the orphan `rcc` branch —
so every `*-dev` branch is bisectable end to end
([`branches/invariants/`](/handbook/branches/invariants/README.md)).

## The contract

What every consumer of this workflow can rely on:

* **Commits considered** — `<S>-green..HEAD` on a series branch,
  else first-parent history since `SINCE`; undecided ones only.
* **Marker written** — a commit status, context `rcc`,
  `pending` before a commit and `success`/`failure` after it,
  written by the leg.
* **Re-trigger a commit** — rebase it past the boundary and force-push.
* **Results** — on the `rcc` branch:
  `runs2.d/<xx>/<sha>.ndjson` for a new record,
  `runs2.ndjson` for the aggregate it is merged into,
  `logs2/<sha>.log` for the log.
* **Gate applied per commit** — style, snapshots, roxygen, clean tree,
  `R CMD check`, pkgdown, in that order.
* **Accepted snapshots** — pushed as `snapshot-<sha>-rcc-smoke-null`.
* **Triggers** — push to `each-*` / `*-dev`, `workflow_dispatch`,
  `workflow_call`.

The snapshot branches are load-bearing, so `rcc-one.sh` reproduces them
rather than just leaving the accepted snapshots in the tree.
Their name is deliberately **frozen** rather than derived:
upstream builds it from `github.job` (`rcc-smoke`) and an empty matrix (`null`),
and here the job is `build` and there *is* a matrix,
so deriving it the same way would silently rename every future branch.
The commit is written through a temporary index —
identity, message and parent matching `peter-evans/create-pull-request` —
so the working tree keeps its diff and the `clean` gate still fails the commit.
This is why the `build` job needs `contents: write`.

The commit status is a display surface: nothing decides from it.
Selection reads the verdict store on the `rcc` branch instead.
[`series-check.sh`](/scripts/series-check.sh) and
[`series-advance.sh`](/scripts/series-advance.sh) read the per-commit record
first and fall back to the aggregate,
so they see a verdict minutes after it happens rather than at the end of a run.
[`rcc-logs.sh`](/scripts/rcc-logs.sh) writes records to the same place.

### Bounded by `<S>-green`

On a `<S>-dev` branch with a sibling `<S>-green`, only `<S>-green..HEAD` is
scanned — everything at or before green is trusted and never rebuilt.
If green exists but is not an ancestor of HEAD, *nothing* is planned:
the branch is mid-surgery or on another lineage,
and an unbounded scan would flood the queue.
Branches without a green sibling fall back to first-parent history since `SINCE`.

The per-commit logs stay readable to `series-check.sh`,
which classifies a failure by what its harvested log contains.
`rcc-one.sh` therefore emits `Changes detected in workflow_dispatch build`
verbatim when the tree is dirty,
so style and roxygen drift is recognised as such
rather than landing in the `unclassified` bucket.

### The green marker

Setting the commit status *is* the job, so the leg does it directly:
`each-shard.sh` POSTs `pending` to `repos/.../statuses/<sha>` before a commit
and `success`/`failure` after it, context `rcc` —
the same call `rcc-smoke` makes inline in its own "Update status for rcc" steps.

`R-CMD-check-status.yaml` and the `rcc-smoke-sha` artifact that feeds it are
core-set content from
[`cynkra/cynkratemplate`](https://github.com/cynkra/cynkratemplate),
and the commit status they write is what branch protection reads on ordinary
pushes and pull requests.
They do not fire for this workflow: `each-rcc` is not named `rcc`.

### What selection actually reads

A commit is planned or skipped according to the **verdict store** —
the record the `rcc` branch holds at `runs2.d/<xx>/<sha>.ndjson`,
which the deciding leg publishes within seconds.
[`scripts/rcc-decided.sh`](/scripts/rcc-decided.sh) is that read,
for the planner and for a resuming leg alike,
and it is one tree-only fetch rather than a request per commit.
A dead leg simply writes nothing, and no record means undecided,
which is the truth — so no marker needs ageing out.

The remaining selection details:

* A commit the store does not mention is planned rather than skipped:
  the enumeration drives the decision, not the store's contents.
* Reachability is not emptiness.
  A store that cannot be read stops the plan rather than reporting nothing
  decided, which would replan the whole range.
* A `retry-<S>-dev` branch — the series' own branch name with a prefix, see
  [`series-loop.md`](/.claude/skills/series-loop.md) — replans **its tip**
  even when that commit already carries a verdict,
  so one commit can be judged again on its own SHA
  instead of being amended and taking its descendants with it.
  The prefix is stripped to derive the series,
  so the scan anchors on `<S>-green` and needs no ref of its own;
  a retry branch naming a series with no green plans nothing at all,
  because the fallback scan reaches into `main`,
  where no commit has a verdict.

## Architecture

```
plan  (1 job, ~30 s)
  ├─ git log --first-parent --after=$SINCE          → candidate commits
  ├─ scripts/rcc-decided.sh (one tree-only fetch)   → verdicts already on `rcc`
  ├─ scripts/each-cost.py                           → objects each commit invalidates
  ├─ scripts/each-partition.py
  │    ├─ greedy contiguous fill under the leg deadline → fewest shards
  │    └─ replan at shorter deadlines while affordable  → shortest wall clock
  └─ plan.json (artifact) + matrix (job output)

build (one job per shard, throttled by max-parallel)
  ├─ R + dependencies + ccache + formatters          ← paid once per shard
  └─ for sha in shard (oldest → newest):
       skip if already decided (a re-run resumes, it does not restart)
       reset workspace → rcc status pending
       → scripts/rcc-one.sh → rcc status success/failure
       → capture the log, whole and per stage
       → on failure, quote each failed stage's tail into the job summary
       → publish record + log to the `rcc` branch    ← seconds after the verdict
     ... stops at its own deadline and defers the rest

harvest (1 job, if: always())
  ├─ fill in records for commits whose leg never got to publish
  └─ append the new records to runs2.ndjson
```

The files:

* [`.github/workflows/each.yaml`](/.github/workflows/each.yaml) —
  plan → build → harvest.
* [`scripts/each-plan.sh`](/scripts/each-plan.sh) —
  enumerate, read verdicts, weigh, partition.
* [`scripts/each-cost.py`](/scripts/each-cost.py) —
  unity-object reach; the cost model's only input.
* [`scripts/each-partition.py`](/scripts/each-partition.py) —
  the cost model, the greedy fill, and the rebalance pass.
* [`scripts/each-shard.sh`](/scripts/each-shard.sh) —
  one leg: many commits, one workspace.
* [`scripts/rcc-one.sh`](/scripts/rcc-one.sh) —
  the per-commit gate, extracted from `rcc-smoke`.
* [`scripts/rcc-part-push.sh`](/scripts/rcc-part-push.sh) —
  publish one commit's record from the leg that decided it.
* [`scripts/rcc-decided.sh`](/scripts/rcc-decided.sh) —
  the other direction: which commits the store has decided.
* [`scripts/rcc-merge.sh`](/scripts/rcc-merge.sh) —
  bring `runs2.ndjson` level with the per-commit records.
* [`scripts/rcc-consolidate.sh`](/scripts/rcc-consolidate.sh) —
  manual: make the layouts agree, GC old logs, squash the branch.
* [`scripts/each-harvest.sh`](/scripts/each-harvest.sh) —
  fan-in: reconcile what the legs could not publish.
* [`scripts/rcc-run-fields.jq`](/scripts/rcc-run-fields.jq) —
  the run-object projection all three writers share.
* [`scripts/rcc-parts-test.sh`](/scripts/rcc-parts-test.sh) —
  offline checks for the layout's invariants,
  and the source of the concurrency measurements below.

### No running marker, by design

Nothing anywhere records "this commit is being built right now",
and nothing should.
Two mechanisms keep a commit from being built twice, and neither is a marker:

1. **One planning-and-building pass per branch at a time.**
   `each.yaml`'s `concurrency` group is `each-rcc-<ref>`, with
   `cancel-in-progress: false` — a second push queues behind the first
   rather than killing it,
   because a killed leg leaves its in-flight commit undecided.
   So two runs never plan the same branch concurrently.
2. **Work selection is a pure function of durable verdicts.**
   The planner asks one question per commit — is there a verdict for it? —
   and the answer lives on the `rcc` branch, which outlives every runner.
   A leg that dies takes no state with it: its decided commits are already
   published, and the rest are simply undecided again.

The `pending` status is a **display** artifact:
it tells a human looking at the commit list that something is happening.
`each-shard.sh` treats it as undecided,
because it is the state a killed leg leaves behind.

### Why reuse works even though every commit starts from a clean tree

The leg does `git checkout --force` and `git clean -qfdx` before each commit.
That looks like it throws away the previous commit's work,
and for object files it does — but object files were never going to survive.
`R CMD check` runs `R CMD build` first,
which copies the package and compiles from the copy;
worse, this package's `cleanup` script tars `src/duckdb` away and deletes it.
Timestamp-based incremental `make` cannot cross a commit boundary here.

What does survive is **ccache**, which is content-addressed
and lives outside the workspace for the whole job.
A typical adjacent vendor commit recompiles about five of the unity objects —
roughly 98% hits, measured in
[`experiments/2026-03-vendor-build-cost/`](/experiments/2026-03-vendor-build-cost/README.md).
Cleaning the workspace also means every commit's verdict is identical to one
from a fresh checkout, which is what keeps the semantics honest.

### All four cores, and no within-job parallelism

`install/action.yml` derives `-j` from `parallel::detectCores()`,
because the compile phase dominates a build:
measured on a 4-core box, 8 vendored unity objects with ccache disabled,
70.8 s at `-j2` against 43.1 s at `-j4` — 1.64×, at identical user time.

Backgrounding gates on top of that buys much less than it looks like.
`style` → `snapshots` → `roxygen` all mutate the working tree and `clean` exists
to observe their union, so that chain is serial by construction;
`check` then builds from the same tree.
The only clean overlap is `check` ∥ `pkgdown`, which is also the one pair where
two compile-bound phases would collide.
The real idle-core opportunity is commit N's serial tail (tests, roxygen,
pkgdown) against commit N+1's parallel head — cross-commit pipelining, needing
two workspaces — and it is deliberately not attempted here.

Oversubscription is a non-issue today because `-j` is the only knob:
the package requests no `-flto` and R's `Makeconf` reports `LTO =` empty,
so there is no LTRANS fan-out multiplying against make;
and without `Config/testthat/parallel` the suite runs serially.
If gates are ever overlapped, the mechanism is a counting semaphore
(`flock` over N slots) with each gate declaring its width — not a make
jobserver, which cannot span separate `R CMD INSTALL` and `rcmdcheck` processes.

The legs run on **`ubuntu-26.04`**, the image `rcc-smoke` uses.
That is a parity requirement, not housekeeping: the gate exists to reproduce
`rcc-smoke`'s verdict, and a verdict that depends on the runner image is not a
reproduction. `install/action.yml` already carries the 26.04-specific
`sudo -E` workaround the image needs.

The leg therefore does **not** use `custom/after-install`:
its ccache is capped at 200 MB and its `duckdb.tar` archive is keyed on the
whole vendored tree, so both are per-commit constructs
that a multi-commit job cannot use.
The leg keeps one 8 GB local cache instead.

The gate runs as a script rather than a reusable workflow or a composite action:
`uses:` is a job-level key and a workflow cannot loop over a composite action,
so a shell loop ([`rcc-one.sh`](/scripts/rcc-one.sh))
is the only construct that runs the same gate N times in one job.

## Planning

### The cost model

A leg's wall clock is

```
estimate_minutes = SETUP + FULL + Σ min(FLOOR + OBJECT_SECONDS × objects, FULL)
                                                        over all but the first
build_minutes    = estimate_minutes − SETUP
```

Four constants, each measuring one thing:

| Constant | Default | What it is |
|---|---|---|
| `SETUP_MINUTES` | 5 | checkout, `install/action.yml`, `style` — paid once per leg |
| `FULL_BUILD_MINUTES` | 40 | a build on an empty ccache: every object of `src/include/sources.mk` |
| `FLOOR_MINUTES` | 6 | one commit with nothing to recompile: link, install, `R CMD check`, the gates |
| `OBJECT_SECONDS` | 9.7 | marginal cost of recompiling one unity object |

The **first** commit of a leg pays `FULL` rather than its own weight,
because it starts on an empty ccache and rebuilds everything
no matter how little it changed.
Every later commit pays only for the objects it invalidates,
capped at `FULL` — a commit that touches a wide header cannot cost more than
building the world.
`build_minutes` is what [`each-shard.sh`](/scripts/each-shard.sh) measures
itself against, since its deadline starts after setup;
`estimate_minutes` is what the job takes.

The constants are fitted by least squares to the 29 commits of runs
[30406932093](https://github.com/krlmlr/duckdb-r/actions/runs/30406932093)
(`main-fwd-dev`, 24 commits over two legs)
and [30422580063](https://github.com/krlmlr/duckdb-r/actions/runs/30422580063)
(`v1.5-variegata-fwd-dev`, 5 commits, one leg),
**RMSE 1.3 min** across the 26 warm builds, which span 4.9 to 38.0 minutes:

| objects | predicted | measured |
|---|---|---|
| 2 | 6.3 | 4.9, 5.2, 5.8, 5.9, 6.9 |
| 3 | 6.5 | 6.0, 6.1, 6.4, 6.5 |
| 23 | 9.7 | 10.3 |
| 53 | 14.6 | 16.5, 16.6 |
| 139 | 28.4 | 27.3 |
| 177 | 34.5 | 36.5 |
| 219 | 40.0 (capped) | 38.0 |

The three cold builds came in at 40.4, 39.7 and 40.1 minutes —
flat, and independent of what their commit changed, exactly as the model says.
Whole legs land within a few percent:
one leg's 12 commits were predicted at 243 min and took 252,
and the other's first 12 at 304 against 302.
Every leg records `duration_seconds` per commit and
[`each-harvest.sh`](/scripts/each-harvest.sh) carries it onto the `rcc` branch
as `.timing`, so the fit can be redone against any range at any time.

### Pass 1: the fewest legs

Shards must be **contiguous** — that is what makes consecutive checkouts cheap —
so this is not bin packing.
Partitioning a sequence into the fewest contiguous parts under a fixed budget
is solved exactly by a single greedy left-to-right pass, in O(n).

Balancing by predicted time rather than commit count is what isolates expensive
commits: on a thousand-commit `main-dev` backlog the greedy pass emits legs of
7 to 27 commits, a 3.9× spread in count,
to hold them all under one deadline.

### Pass 2: the shortest wall clock

The greedy pass minimises **legs**, which is close enough to minimising
runner-minutes to serve as the cost baseline.
It is a poor answer for wall clock at every size, and for a small batch it is
the *worst* answer.
The default leg deadline is 300 minutes and a cheap commit costs ~6,
so 25 commits fit in two legs — and the branch tip waits five hours for a
verdict that 20 legs would have delivered in fifty minutes.
This is the common case, not the corner case:
a series-loop batch is capped at 100 commits and is usually far smaller.

So a second pass buys the wall clock back,
by **running pass 1 again against shorter deadlines**
and keeping whichever of those plans finishes soonest.
Pass 1 at deadline `B` is a one-parameter family of *complete* plans —
the lower `B`, the more legs, the more cold builds —
so pass 2 only has to pick a `B`,
and every plan it can pick is contiguous, balanced and inside the real deadline
by construction.
Two limits bound the search:

* **`SPLIT_FACTOR`** (default 1.5, `scripts/each-plan.sh`).
  The plan may cost at most this multiple of the pass-1 plan's runner-minutes.
  `1.0` disables the pass entirely.
* **`MAX_SHARDS`** (default 250, `scripts/each-plan.sh`),
  and the commit count: one commit cannot be cut in half.

Ranking is by `makespan()`, which models `MAX_PARALLEL` throttling,
and ties go to the cheapest plan:
an extra leg costs a cold build plus a job setup, so it has to buy real time.

Neither axis is monotone in `B`, which is why the whole family is evaluated
rather than walked in one direction:

* **Wall clock** falls with more legs only until the matrix runs out of slots.
  At `P` slots, `P` legs finish in one wave and `P + 1` take two —
  one extra leg can nearly *double* the wall clock.
  A plan cannot be ranked by its longest leg; it has to be scheduled.
* **Runner cost** usually rises with more legs, but not always.
  A commit that invalidates the whole unity build already pays `FULL`,
  so a cut placed just before one is free but for the job setup.
  More legs can be genuinely cheaper than fewer,
  and a plan rejected on cost says nothing about the next one.

Measured on a 77-commit `main-fwd-dev` batch:

| `SPLIT_FACTOR` | shards | wall clock | runner time |
|---|---|---|---|
| 1.0 (off) | 4 | 303 min | 978 min |
| 1.25 | 15 | 93 min | 1219 min |
| **1.5** | **20** | **79 min** | **1354 min** |
| 2.0 | 20 (`max-parallel`) | 79 min | 1354 min |

The default trades 1.38× the compute for **3.8× the wall clock**.
Past 1.5 the curve is flat: `max-parallel` takes over as the binding limit.

**The pass does not stop at `MAX_PARALLEL`.**
That is the width of a wave, not a ceiling on legs,
and pass 1 routinely emits more legs than that on its own.
A thousand-commit backlog plans to 67 legs against 20 slots: four waves,
the last of them one-third full, every leg packed to the 300-minute deadline.
Rebalancing to 79 legs keeps the wave count at four
but shortens the longest leg from 300 to ~254 minutes —
2.3 hours of wall clock for twelve runner-minutes, 0.06%,
because the twelve extra legs start on wide-header commits that were paying for
a full rebuild anyway.
The gain grows with the slot count, since a wider matrix leaves a lumpier tail.

The pass is still a no-op where it should be —
`SPLIT_FACTOR: 1.0`, a batch already at `MAX_SHARDS`,
or a plan whose waves are already even.

### Numbering, and the order they are queued in

These are two separate decisions that happen to agree.

A shard's **number** runs with the history: shard 1 holds the oldest commits of
the plan, shard N the branch tip, and adjacent numbers are adjacent slices.
So a leg's number reads the way its commits do, and the numbering starts at
one rather than at zero.

The **order** they are queued in is the same: oldest shard first, so that
under `max-parallel` throttling the oldest undecided slice is decided first.
That is the end the series loop can actually move from — `<S>-green` advances
over a *contiguous* run of green commits, so a decided tip sitting above an
undecided gap advances nothing.
The matrix therefore starts at shard 1 and finishes with shard N.
Within a shard, commits run oldest-first too, for cache locality.

Numbers are assigned after the matrix cap has dropped the oldest shards,
so shard 1 is the oldest shard *this run* will build,
not the oldest one the planner considered.

### Which commit invalidates how many unity files

[`scripts/each-cost.py`](/scripts/each-cost.py) answers this exactly,
without building anything, in about 3.5 seconds.
It reads the objects from `src/include/sources.mk`,
resolves every `#include "..."` edge in `src/duckdb/**`,
and does one BFS per object.
Each file ends up with a bitmask of the objects that transitively include it;
a commit's cost is the population count of the OR over its changed paths.

Sanity checks against the tree:

| path | objects |
|---|---|
| `src/execution/operator/join/physical_hash_join.cpp` | 1 |
| `src/include/duckdb/main/client_context.hpp` | 170 |
| `src/include/duckdb/common/types.hpp` | 214 |
| `src/include/duckdb/common/exception.hpp` | 217 |

And across 120 real `v1.5-variegata-dev` commits:

| invalidated objects | commits |
|---|---|
| 0 (no C++ at all) | 55 |
| 1–5 | 43 |
| 6–30 | 12 |
| 31–100 | 2 |
| >100 (wide header) | 8 |

Median 2, mean 15, max 209 —
the bimodal distribution predicted from the measured ccache timings
([`experiments/2026-03-vendor-build-cost/`](/experiments/2026-03-vendor-build-cost/README.md)),
now derived statically and per commit.

Resolution is deliberately an over-approximation:
an include target is matched against a path-suffix index,
so an ambiguous `#include "types.hpp"` counts for every `types.hpp` in the tree.
Over-estimating isolates a commit that did not need isolating —
a little parallelism, no correctness.
The map is built once from the branch tip and reused for the whole range;
reach drifts slowly, and a stale weight only mis-balances a shard.

## When a leg is lost

Nothing restarts the batch. `fail-fast: false` keeps the siblings running,
every other leg keeps its verdicts,
and the next `each-rcc` run recomputes its to-do list from the verdict store,
so it replans only the commits that are actually undecided.
The blast radius of a lost runner is, by construction, one leg.

What survives a runner that stops executing steps:

* **A commit's verdict** — the commit status, and the record the leg published
  seconds after deciding it. Both survive.
* **The plan** — the `each-plan` artifact from the `plan` job. Survives.
* **A commit in flight** — no record, so the next run replans it.
* **Records a leg never got to publish** — only in the leg's artifact,
  uploaded in its last step, so a lost runner never gets there;
  the fan-in reconstructs them.

A re-run resumes rather than restarts:
the leg skips a commit that already carries a decided record,
so "Re-run failed jobs" costs what was lost rather than what the shard held.
`pending` deliberately does not count as decided —
that is precisely the state a killed leg leaves behind,
and redoing it is what the re-run is for.
Both artifact uploads carry `overwrite: true`,
so "Re-run all jobs" does not fail on an artifact name conflict.
The fan-in is guarded on the planner having succeeded,
so it does not check out the `rcc` branch to reconcile a run that never built.

Two edges are worth stating plainly.

**Nothing schedules `each-rcc`.**
It fires on push to `each-*`/`*-dev`, on `workflow_dispatch`, and on
`workflow_call`.
After a lost leg the branch is left with one `pending` commit and a tail of
statusless ones, and the replanning that would pick them up does not happen
until somebody pushes to that branch or dispatches the workflow.
The replanning is correct; it is not automatic.

**The series loop's documented recovery discards good results.**
[`series-loop.md`](/.claude/skills/series-loop.md) says that a commit still
missing from the harvest after 12 hours should be presumed lost, and repaired by
amending it and replaying the tail.
Replaying mints a new SHA for every commit after it,
so one lost leg costs a rebuild of every *already-green* commit newer than the
commit it was in the middle of.
That recovery is the right answer when a commit genuinely cannot get a verdict,
but it is the last resort:
re-running the failed job, or dispatching `each-rcc` again,
costs only the commits that are undecided.

## The verdict store

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

### Why both layouts

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

### Consolidation

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

### A newer verdict wins

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

### What publishing from a leg costs

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

### How bad is the race

Measured by [`rcc-parts-test.sh`](/scripts/rcc-parts-test.sh) —
20 concurrent writers against a copy of the real branch,
each publishing back to back with no build in between,
so roughly 100× the real rate.
Of 100 records published, **none were lost and none gave up**;
51% succeeded on the first attempt, 87% landed within four,
and the deepest retry was 9.
Only the first two of those are invariants —
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

## GitHub Actions limits this works within

| Limit | Value | How the design stays inside it |
|---|---|---|
| Jobs per matrix | 256 per workflow run | `MAX_SHARDS` defaults to 250, and bounds the rebalance pass as well as the fill |
| Job execution time | 6 h | shard budget 300 min, job `timeout-minutes: 350`, and the leg stops itself and defers the rest |
| Workflow run duration | 35 days | a thousand-commit backlog is under a day at `max-parallel: 20` |
| Concurrent jobs | plan-dependent | `max-parallel` keeps the run a good neighbour, and is the wave width the rebalance pass plans against |
| `GITHUB_TOKEN` REST requests | 1000 per hour per repository | see below |
| Reusable workflow nesting | 10 levels, 50 unique per file | not used |

The rate limit is the one that rules out the obvious implementation.
Reading one commit status per REST call costs one request per commit,
so a 3000-commit scan cannot complete at all.
That constraint is what a git-native verdict store answers outright:
reading the store is one fetch regardless of range.

Writing statuses stays REST (there is no batch endpoint), two per commit.
That is a *rate*, not a burst: at `max-parallel: 20` and ~20 min per commit
the whole run issues on the order of 80 requests per hour.
Publishing a record is a git push, not an API call,
so it does not enter this budget at all.

### Scale

A planner run over the newest 1000 commits of `main-fwd-build`,
every commit treated as undecided, takes 5.4 s end to end,
including building the reach map, and emits 79 shards
of 8 to 19 commits (median 12), estimated at 159 to 264 minutes each.

`main-fwd-build` is close to the worst case for this design,
and that is the useful thing about measuring on it.
Its churn is far heavier than `v1.5-variegata-dev`'s:

| invalidated unity objects | `main-fwd-build` | `v1.5-variegata-dev` |
|---|---|---|
| 0 (no C++) | 0.3% | 46% |
| 1–5 | 42% | 36% |
| 6–30 | 14% | 10% |
| 31–100 | 10% | 2% |
| >100 (wide header) | **34%** | 7% |
| median / mean | 16 / 76 | 2 / 15 |

A third of these commits are wide-header commits,
so a third of them get little from the warm cache — and the shards shrink
accordingly, which is exactly what cost balancing is for.
Against one run per commit that is 79 jobs instead of 1000,
and 338 runner-hours instead of 883 — **2.6×** less compute,
against 3.6× on the much cheaper `v1.5-variegata-dev` distribution.
That is the honest range, with the worst case at the low end.

Extrapolating the same shard density, a 3000-commit mainline replay
is ~240 shards — still inside the 250 cap, still one run, but close enough
to it that a bigger backlog would need a second run or a larger shard budget.

## Operating it

Everything is an input on `workflow_dispatch`,
and the ones worth setting repo-wide are repository variables:

| Knob | Input | Variable | Default |
|---|---|---|---|
| Earliest commit date | `since` | `EACH_RCC_SINCE` | `2026-01-01` |
| Concurrent shards | `max-parallel` | `EACH_RCC_MAX_PARALLEL` | `20` |
| Build-time target per shard | `shard-budget-minutes` | — | `300` |
| Compute traded for wall clock | `split-factor` | `EACH_RCC_SPLIT_FACTOR` | `1.5` |
| Cap on commits considered | `max-commits` | — | `0` (no cap) |
| Rebuild decided commits | `force` | — | `false` |
| Log lines quoted per failed stage | — | `EACH_RCC_SUMMARY_TAIL` | `50` |
| Gates to run | — | `EACH_GATES` | all six |

The defaults above are the workflow's, set in
[`each.yaml`](/.github/workflows/each.yaml);
the scripts carry their own fallbacks for a direct invocation,
and those differ — `each-plan.sh` falls back to `MAX_PARALLEL=8`,
for instance, where the workflow passes 20.

`EACH_GATES` can drop individual gates, but `pkgdown` is **not** a candidate:
a pkgdown failure is a real failure and has to be dealt with,
so the gate stays on.

The lever for a slow *large* batch is `max-parallel`,
which decides how many waves it takes.
The lever for a slow *small* batch is `split-factor`:
under `max-parallel` legs the run is one wave,
and the only way to shorten it is to make the longest leg shorter.
A large batch gets some of this for free — rebalancing evens out the waves at
almost no compute — but shortening it *further* is what `split-factor` pays for.
Set `split-factor` to `1.0` to get the fewest-legs, cheapest-compute
behaviour back.

### Reading a failure without opening the log

A leg is one job for up to ~20 commits and up to five hours of output.
The leg's job summary says which commit went red and why.
The result table names the stages that failed —
a commit's cell reads `failure (check, pkgdown)`, not just `failure` —
and below it each failed stage gets a collapsed `<details>` block holding the
last `EACH_RCC_SUMMARY_TAIL` lines of *that stage's* output,
which is enough to tell a compile error from a failing test.
Setting the variable to `0` turns the excerpts off.

The excerpt is not the record.
The whole per-commit log still goes to `logs2/<sha>.log` on the `rcc` branch,
which is what [`series-check.sh`](/scripts/series-check.sh) classifies against;
the summary is the fast path for a human.
Two details make it work in practice:

* [`rcc-one.sh`](/scripts/rcc-one.sh) writes each stage's output to its own file
  under `EACH_STAGE_DIR` and its verdict to `outcomes.tsv`,
  rather than the leg parsing the combined log back apart.
  Nothing is buffered that was not already buffered —
  the leg redirects the whole commit to a file and prints it once the commit is
  over — and a stage with a log but no verdict is precisely the stage the leg's
  `timeout` killed, so that one is quoted too.
* Excerpts stop at 900 kB, because GitHub truncates a step summary at 1 MiB and
  a truncated summary would take the result table with it.
  How many were dropped is stated.

### Failure modes and what happens

* **A commit fails its gate** — `rcc=failure`, the leg keeps going,
  record and log published from the leg,
  failed stages' tails in the job summary.
* **A leg runs out of budget** — remaining commits stay statusless,
  the next run replans them.
* **A leg dies hard mid-commit** — that commit has no record,
  so the next run replans it;
  every commit the leg had already decided is on the `rcc` branch.
* **A leg is re-run after dying** — commits it already decided are skipped,
  not rebuilt.
* **A leg cannot reach the `rcc` branch** — logged, never fatal;
  the fan-in collects the record from the artifact.
* **The whole run is cancelled** — no fan-in,
  but the legs' own records are already on the branch;
  `rcc-logs.yaml` covers whatever is left on its next tick.
* **The `plan` job fails** — `build` and the fan-in are both skipped.
* **History is force-pushed mid-run** — unreachable SHAs fail checkout
  and are skipped; new SHAs are picked up next run.
* **More than `MAX_SHARDS` shards planned** — oldest shards deferred,
  reported in the job summary.
* **Two writers publish records at once** — different files, no conflict;
  the loser of the ref race re-reads the tip and re-commits
  ([`rcc-part-push.sh`](/scripts/rcc-part-push.sh)).
* **Two writers extend the aggregate at once** — the push is rejected, and
  [`rcc-push.sh`](/scripts/rcc-push.sh) resets onto the new tip, re-derives,
  and appends what is still missing before retrying.
* **A retry overturns a verdict** — the newer record and log replace the older
  ones, in the part and in the aggregate's line.
* **An earlier run's fan-in lands after a retry** — it sees a higher run id on
  the branch and keeps that record; the stale verdict is not replayed.
* **A retry turns a failure green** — the record is replaced and the log it
  overturned is dropped, on whichever path publishes first.
* **A leg is re-run after publishing failed** — its artifact is named per
  attempt, so the earlier attempt's records stay collectable.
* **A writer lands during a consolidation** — the lease refuses the force-push;
  nothing is lost, re-dispatch it.

Nothing here needs a lock for correctness.
Progress is durable per commit,
and every run recomputes its own to-do list from ground truth.

**No writer takes a lock, and that is deliberate.**
Records live one per file, so two writers adding different commits cannot
conflict at all, and `runs2.ndjson` is appended to rather than merged.
A shared concurrency group would be worse than the race:
only one run may be *pending* per group,
so a third writer queued behind the second cancels it outright,
and a cancelled fan-in takes the only copy of its per-commit logs with it.
The reset-and-re-derive recovery covers the two writers that touch the
aggregate: both producers dedupe against what is on the branch,
so a retry only re-adds what the winner did not already record.
Rebasing would be the wrong recovery — the aggregate is a single file every
writer extends, so a genuine collision means both sides changed it with no
separating context.

## Limits

Two properties of the cost model are worth knowing before trusting a plan:

* **It counts objects, not object *sizes*.**
  A `ub_*.o` group compiles dozens of `.cpp` files and a leaf object compiles
  one, and the model charges the same `OBJECT_SECONDS` for both.
  The fit absorbs this on average — a wide-header commit reaches mostly `ub_*`
  objects and a narrow one mostly leaves — but it is why the residuals go one
  way at 53 objects (16.5 measured against 14.6 predicted)
  and the other at 219 (38.0 against a capped 40.0).
  Weighting each object by its translation unit's size would remove the bias;
  `each-cost.py` already has the graph it would need.
* **The fit is 29 commits from two branches**, both heavy on vendor churn.
  An R-only batch — 0 invalidated objects throughout — is not represented,
  and `FLOOR_MINUTES` is the constant that would move.

Rebalancing also raises the concurrency footprint:
a 77-commit batch asks for 20 runners instead of 4, for an hour.
Peak concurrency is still capped by `max-parallel` —
a large batch gains legs without gaining slots —
but it is the whole account's Actions concurrency,
so other workflows queue behind it where they used not to.

The scripts run from *the branch being checked*,
so a `*-dev` branch picks up a change to this workflow only once it is
forward-ported there — the same constraint every CI change in this repository
has, and the series loop's stage 4
([`series-port.sh`](/scripts/series-port.sh)) is what does it.
`R-CMD-check.yaml` and `R-CMD-check-status.yaml` come from
[`cynkra/cynkratemplate`](https://github.com/cynkra/cynkratemplate)
rather than from here, so they are not edited:
`rcc-one.sh` reproduces the gates they apply, and the two can drift,
which is why the gate list is reviewed
whenever `R-CMD-check.yaml` is forward-ported.

*To deepen: state what the first live consolidation and the first live publish
against the real remote changed, and fold the vendoring-simplification plan's
remaining per-commit items
([`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md))
in as they land.*
