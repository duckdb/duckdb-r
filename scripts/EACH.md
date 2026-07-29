# `each-rcc` — building every commit as a sharded matrix

Status: **in production on the `*-fwd-dev` branches.**
Rollback is a repository-variable flip (`EACH_RCC_MODE=dispatch`), not a revert.
The cost model's constants are no longer borrowed —
they are fitted to measured legs; see [§3, *Can we compute breakpoints efficiently, and evenly?*](#can-we-compute-breakpoints-efficiently-and-evenly).

`.github/workflows/each.yaml` proves invariant **C1** from
[`BRANCHES.md`](../BRANCHES.md#ci--green):
every commit on a `*-dev` branch is green, so the branch is bisectable end to end.
It used to do that by dispatching one `rcc` workflow run per commit.
It now plans contiguous, cost-balanced **shards** and gives each shard one job,
which walks its commits in a single workspace.

This document is the design: what stays the same, what the runner-level
mechanics are, which GitHub Actions limits shape them,
and — since they came up first — why `workflow_call` is *not* the mechanism
that gets us there.

---

## 1. What does not change

The contract every consumer reads is untouched.

| Contract | Before | After |
|---|---|---|
| Commits considered | `<S>-green..HEAD` on a series branch, else first-parent since `SINCE`; no `rcc` status | same |
| Marker written | commit-status, context `rcc`, `pending` → `success`/`failure` | same, written by the leg |
| Re-trigger a commit | rebase it past the boundary and force-push | same |
| Results on the `rcc` branch | `runs2.ndjson` + `logs2/<sha>.log` | same schema, same paths, existing records untouched — plus `runs2.d/<xx>/<sha>.ndjson`, which new records land in first and which `runs2.ndjson` is extended from ([§3](#can-results-reach-the-rcc-branch-as-soon-as-they-exist)) |
| Gate applied per commit | style, snapshots, roxygen, clean tree, `R CMD check`, pkgdown | same, same order |
| Accepted snapshots | pushed as `snapshot-<sha>-rcc-smoke-null` | same name, same commit shape |
| Triggers | push to `each-*` / `*-dev`, `workflow_dispatch`, `workflow_call` | same, plus tuning inputs |

The snapshot branches are load-bearing — about 950 of them exist — so `rcc-one.sh`
reproduces them rather than just leaving the accepted snapshots in the tree.
Their name is deliberately **frozen** rather than derived:
upstream builds it from `github.job` (`rcc-smoke`) and an empty matrix (`null`),
and here the job is `build` and there *is* a matrix,
so deriving it the same way would silently rename every future branch.
The commit is written through a temporary index —
identity, message and parent matching `peter-evans/create-pull-request` —
so the working tree keeps its diff and the `clean` gate still fails the commit.
This is why the `build` job needs `contents: write`.

[`scripts/vendor-gate.sh`](vendor-gate.sh) needs no changes: it reads commit
statuses, which are untouched.

The readers of the `rcc` branch did need a change, but a compatible one. Records
are now one file per commit, with `runs2.ndjson` extended from them
([§3](#can-results-reach-the-rcc-branch-as-soon-as-they-exist)), so
[`series-check.sh`](series-check.sh) and [`series-advance.sh`](series-advance.sh)
read the per-commit record first and fall back to the aggregate — which is both
faster and how they see a verdict minutes after it happens rather than at the end
of the run. [`rcc-logs.sh`](rcc-logs.sh) writes records to the same place. Failure
classification still reads the harvested log, unchanged (see below).

### Bounded by `<S>-green`

Selection follows `scripts/each-rcc.sh` exactly, including the bound the series
loop introduced: on a `<S>-dev` branch with a sibling `<S>-green`, only
`<S>-green..HEAD` is scanned — everything at or before green is trusted and
never rebuilt — and if green exists but is not an ancestor of HEAD, *nothing* is
planned, because the branch is mid-surgery or on another lineage and an
unbounded scan would flood the queue. Branches without a green sibling fall back
to the first-parent history since `SINCE`.

The per-commit logs also stay readable to `scripts/series-check.sh`, which
classifies a failure by what its harvested log contains. `rcc-one.sh` therefore
emits `Changes detected in workflow_dispatch build` verbatim when the tree is
dirty, so style/roxygen drift is still recognised as such rather than landing in
the `unclassified` bucket.

### The green marker, and why `rcc-smoke-sha` has no successor

Setting the commit status *is* the job, so the leg does it directly:
`each-shard.sh` POSTs `pending` to `repos/.../statuses/<sha>` before a commit
and `success`/`failure` after it, context `rcc` —
the same call `rcc-smoke` makes inline in its own "Update status for rcc" steps.

The `rcc-smoke-sha` artifact exists only to carry a SHA across a `workflow_run`
boundary into `R-CMD-check-status.yaml`, and there is no such boundary here:
the leg already knows the SHA it just built.
Nothing is lost, because on the per-commit path that artifact was always empty —
its value is `steps.commit.outputs.sha`, which the `commit` action sets only when
it pushes a commit back, and on `workflow_dispatch` it fails on any diff instead.

Worth knowing when comparing the two paths:
`R-CMD-check-status.yaml` then falls back to `workflow_run.head_sha`,
which for a dispatched run is the tip of the *branch*, not the `ref` input.
In the last 400 records on the `rcc` branch that differs for **391 of 393**
dispatched runs, and every one of them carries the description `rcc / rcc-smoke`,
i.e. the status that stuck is the one `rcc-smoke` wrote inline.
So the `workflow_run` hop was decorating the branch tip, not the commit under test.
The new path has no such hop, and `each-rcc` is not named `rcc`,
so `R-CMD-check-status.yaml` does not fire for it at all.

Two selection details are new, and both only fire in states the old path never produced:

- A `pending` status older than `PENDING_TTL_HOURS` (default 6, matching
  `MAX_AGE_HOURS` in `vendor-gate.sh`) is treated as abandoned and replanned.
  Previously a leg that died hard left a commit wedged in `pending` forever.
- A commit missing from the status scan is replanned rather than skipped.
- A `retry-<S>-dev` branch — the series' own branch name with a prefix, see
  `.claude/skills/series-loop.md` — replans **its tip** even when that commit
  already carries a verdict, so one commit can be judged again on its own SHA
  instead of being amended and taking its descendants with it. The prefix is
  stripped to derive the series, so the scan anchors on `<S>-green` and needs no
  ref of its own; a retry branch naming a series with no green plans nothing at
  all, because the fallback scan reaches into `main`, where nothing carries an
  `rcc` status.

---

## 2. Architecture

```
plan  (1 job, ~30 s)
  ├─ git log --first-parent --after=$SINCE          → candidate commits
  ├─ GraphQL, 100 commits per request               → existing rcc statuses
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

Files:

| Path | Role |
|---|---|
| `.github/workflows/each.yaml` | plan → build → harvest, plus the legacy dispatch mode |
| `scripts/each-plan.sh` | enumerate, read statuses, weigh, partition |
| `scripts/each-cost.py` | unity-object reach; the cost model's only input |
| `scripts/each-partition.py` | the cost model, the greedy fill, and the rebalance pass |
| `scripts/each-shard.sh` | one leg: many commits, one workspace |
| `scripts/rcc-one.sh` | the per-commit gate, extracted from `rcc-smoke` |
| `scripts/rcc-part-push.sh` | publish one commit's record from the leg that decided it |
| `scripts/rcc-merge.sh` | bring `runs2.ndjson` level with the per-commit records |
| `scripts/rcc-consolidate.sh` | manual: make the layouts agree, GC old logs, squash the branch |
| `scripts/each-harvest.sh` | fan-in: reconcile what the legs could not publish |
| `scripts/rcc-run-fields.jq` | the run-object projection all three writers share |
| `scripts/rcc-parts-test.sh` | offline checks for the layout's invariants, and the source of the numbers below |
| `scripts/each-rcc.sh` | unchanged; still the legacy dispatcher |

### Why reuse works even though every commit starts from a clean tree

The leg does `git checkout --force` and `git clean -qfdx` before each commit.
That looks like it throws away the previous commit's work, and for object files it does —
but object files were never going to survive anyway.
`R CMD check` runs `R CMD build` first, which copies the package and compiles from the copy;
worse, this package's `cleanup` script tars `src/duckdb` away and deletes it.
Timestamp-based incremental `make` cannot cross a commit boundary here.

What does survive is **ccache**, which is content-addressed
and lives outside the workspace for the whole job.
A typical adjacent vendor commit recompiles ~5 of 341 unity objects — ~98% hits
(measured: [`VENDORING-LOOP.md` Appendix A.2](VENDORING-LOOP.md#a2-ccache-behaviour-on-adjacent-commits-8-consecutive-v15-commits)).
Cleaning the workspace also means every commit's verdict is identical to one from a fresh checkout,
which is what keeps the semantics honest.

### All four cores, and no within-job parallelism

The gate runs as a script, so backgrounding gates to fill the box is *possible*.
It is not what was leaving cores idle.
`install/action.yml` pinned `MAKEFLAGS = -j2` on a 4-vCPU runner,
so the phase that dominates a build was using half the machine.
Measured on a 4-core box, 8 vendored unity objects with ccache disabled:
**70.8 s at `-j2` versus 43.1 s at `-j4`** — 1.64x, at identical user time.
The action now derives `-j` from `parallel::detectCores()`.

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
Peak RSS per unity object is ~834 MB, so four in flight is ~3.3 GB of 16 GB.
If gates are ever overlapped, the mechanism is a counting semaphore
(`flock` over N slots) with each gate declaring its width — not a make
jobserver, which cannot span separate `R CMD INSTALL` and `rcmdcheck` processes.

The legs run on **`ubuntu-26.04`**, the image `rcc-smoke` uses.
That is a parity requirement, not housekeeping: the gate exists to reproduce
`rcc-smoke`'s verdict, and a verdict that depends on the runner image is not a
reproduction. `install/action.yml` already carries the 26.04-specific
`sudo -E` workaround the image needs.

The leg therefore does **not** use `custom/after-install`:
its ccache is capped at 200 MB and its `duckdb.tar` archive is keyed on the whole vendored tree,
so both are per-commit constructs that a multi-commit job cannot use.
The leg keeps one 8 GB local cache instead.

---

## 3. Answers to the questions this design started from

### Can we use `workflow_call` to run the `rcc` jobs unchanged?

Mechanically yes; usefully no.

Add `workflow_call` to `R-CMD-check.yaml`, then have `each.yaml` call it from a matrix job:

```yaml
build:
  strategy:
    matrix: ${{ fromJSON(needs.plan.outputs.commits) }}
  uses: ./.github/workflows/R-CMD-check.yaml
  with:
    ref: ${{ matrix.sha }}
```

That is valid — matrix strategies on reusable-workflow calls have been supported since August 2022.
It even buys two of the four advantages: the batch becomes one run to cancel,
and the logs land under one run id.

But a `uses:` job does not run the called workflow *inside* your job.
GitHub schedules the called workflow's jobs as **separate jobs on separate runners**.
So the topology is exactly today's — one runner per commit — merely re-parented.
The two efficiency advantages, amortised setup and a warm local ccache across adjacent commits,
are precisely the ones this cannot deliver, because there is no shared runner to amortise onto.

And it does not scale to the target.
A matrix generates at most **256 jobs per workflow run**,
and each `rcc` call expands to more than one job (`rcc-smoke` plus `rcc-smoke-check-matrix`),
so the real ceiling is well under 256 commits — not the 2000–3000 we want in one run.

Nesting matrices across reusable workflows *can* exceed 256 in practice:
both caller and callee may define a matrix and GitHub multiplies them.
It is a bad idea here. The one public write-up of the technique
([community discussion #38704](https://github.com/orgs/community/discussions/38704))
reports the run page failing to load past roughly 600 jobs,
and Actions being disabled on the account that tried it.
A 3000-job run would be unreadable exactly when a red commit needs finding.

There is also a maintenance cost: `R-CMD-check.yaml` is forward-ported
from `duckdb/duckdb-r@main` (see [`BRANCHES.md`](../BRANCHES.md)),
so a repo-specific `workflow_call` interface there is a permanent merge tax.

### Can a job have multiple tasks that each do a `workflow_call`?

No. `uses:` is a **job-level** key: one job calls at most one reusable workflow,
and such a job may not carry `steps` (nor `runs-on`, `env`, `timeout-minutes`,
`container`, `services`, `continue-on-error`).
The only fan-out available is `strategy.matrix` on the calling job,
which produces one job per combination — back to the previous answer.

Composite actions have the mirror-image limitation:
they *can* be steps inside a job, but a workflow cannot loop over them,
and their step list is static.
That is the whole reason the per-commit gate had to become a script
([`scripts/rcc-one.sh`](rcc-one.sh)): a shell loop is the only construct
that can run the same gate N times in one job.

### Can we limit matrix parallelisation?

Yes: `jobs.<id>.strategy.max-parallel`.
The planner emits it as a job output (`max_parallel`), clamped to the shard count,
so the workflow throttles itself without a hand-edit.
Defaults to 8; override per run with the `max-parallel` input,
or repo-wide with the `EACH_RCC_MAX_PARALLEL` variable.
The run-level `concurrency` group additionally keeps two `each-rcc` runs
for the same branch from overlapping, with `cancel-in-progress: false`
so a queued run waits for a long bulk build rather than killing it.

### Can we compute breakpoints efficiently, and evenly?

Yes, and the problem is easier than it looks —
but "evenly" turned out to be the wrong objective on its own.

#### The cost model

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
| `FULL_BUILD_MINUTES` | 40 | a build on an empty ccache: all 355 objects of `sources.mk` |
| `FLOOR_MINUTES` | 6 | one commit with nothing to recompile: link, install, `R CMD check`, the gates |
| `OBJECT_SECONDS` | 9.7 | marginal cost of recompiling one unity object |

The **first** commit of a leg pays `FULL` rather than its own weight,
because it starts on an empty ccache and rebuilds everything
no matter how little it changed.
Every later commit pays only for the objects it invalidates,
capped at `FULL` — a commit that touches a wide header cannot cost more than
building the world.
`build_minutes` is what [`each-shard.sh`](each-shard.sh) measures itself against,
since its deadline starts after setup;
`estimate_minutes` is what the job takes.

#### The constants are measured, not borrowed

Fitted by least squares to the 29 commits of runs
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

These numbers replace the pre-2026 estimates the model shipped with
(`COLD_MINUTES=22`, `FLOOR_MINUTES=11`, `OBJECT_SECONDS=4.3`),
which were wrong in a way that mattered:
they charged nearly twice too much for a cheap commit and half too little for an
expensive one, so the predicted spread was *compressed*.
Legs of "equal" predicted cost were not equal,
and a leg full of wide-header commits overran its 300-minute deadline and
deferred its last commit — which is what happened to the second leg of run
30406932093.
Every leg records `duration_seconds` per commit and
[`each-harvest.sh`](each-harvest.sh) now carries it onto the `rcc` branch
as `.timing`, so the fit can be redone against any range at any time.

#### Pass 1: the fewest legs

Shards must be **contiguous** — that is what makes consecutive checkouts cheap —
so this is not bin packing.
Partitioning a sequence into the fewest contiguous parts under a fixed budget
is solved exactly by a single greedy left-to-right pass, in O(n).

Balancing by predicted time rather than commit count is what isolates expensive
commits: on 998 undecided `main-dev` commits the greedy pass emits legs of 7 to
27 commits, a 3.9× spread in count, to hold them all under one deadline.

#### Pass 2: the shortest wall clock

The greedy pass minimises **legs**, which is close enough to minimising
runner-minutes to serve as the cost baseline.
It is a poor answer for wall clock at every size, and for a small batch it is
the *worst* answer.
The default leg deadline is 300 minutes and a cheap commit costs ~6,
so 25 commits fit in two legs — and the branch tip waits five hours for a verdict
that 20 legs would have delivered in fifty minutes.
This is the common case, not the corner case:
a series-loop batch is capped at 100 commits and is usually far smaller.
A large backlog looks like it should be immune, since every slot is busy anyway,
but it is not: see [below](#why-the-pass-cannot-stop-at-max_parallel).

So a second pass buys the wall clock back,
by **running pass 1 again against shorter deadlines**
and keeping whichever of those plans finishes soonest.
Pass 1 at deadline `B` is a one-parameter family of *complete* plans —
the lower `B`, the more legs, the more cold builds —
so pass 2 only has to pick a `B`,
and every plan it can pick is contiguous, balanced and inside the real deadline
by construction.
Two limits bound the search:

* **`SPLIT_FACTOR`** (default 1.5). The plan may cost at most this multiple of
  the pass-1 plan's runner-minutes. `1.0` disables the pass entirely.
* **`MAX_SHARDS`**, and the commit count: one commit cannot be cut in half.

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

On the live 77-commit `main-fwd-dev` batch:

| `SPLIT_FACTOR` | shards | wall clock | runner time |
|---|---|---|---|
| 1.0 (off) | 4 | 303 min | 978 min |
| 1.25 | 15 | 93 min | 1219 min |
| **1.5** | **20** | **79 min** | **1354 min** |
| 2.0 | 20 (`max-parallel`) | 79 min | 1354 min |

The default trades 1.38× the compute for **3.8× the wall clock**.
Past 1.5 the curve is flat: `max-parallel` takes over as the binding limit.

#### Why the pass cannot stop at `MAX_PARALLEL`

The version of pass 2 this replaces split the longest shard repeatedly
and stopped once it had `MAX_PARALLEL` of them,
on the reasoning that more legs than can run at once move no verdict earlier.
That is true only while the *whole plan* fits in one wave.
`MAX_PARALLEL` is not a ceiling on legs, it is the width of a wave,
and pass 1 routinely emits more legs than that on its own —
at which point a cap at `MAX_PARALLEL` is not a stopping rule, it is an
off switch, and the pass did nothing at exactly the sizes where the waves are
lumpiest.

The 1039-commit `main-dev` backlog is the case in point.
Pass 1 emits 67 legs against 20 slots: four waves, the last of them one-third
full, every leg packed to the 300-minute deadline.
The old pass declined to touch it at any `SPLIT_FACTOR`.
Rebalancing to 79 legs keeps the wave count at four but shortens the longest
leg to ~254 minutes:

| | old pass 2 | rebalanced |
|---|---|---|
| shards | 67 | 79 |
| longest leg | 300 min | 254 min |
| wall clock | **19.2 h** | **16.9 h** |
| runner time | 19,247 min | 19,259 min |

**2.3 hours of wall clock for twelve runner-minutes** — 0.06%, well inside even
a `SPLIT_FACTOR` of 1.001, because the twelve extra legs start on wide-header
commits that were paying for a full rebuild anyway.
The gain grows with the slot count, since a wider matrix leaves a lumpier tail:
at `max-parallel: 40` the same backlog goes from 10.0 h to 8.5 h,
and at 60 from 9.5 h to 6.0 h.

The pass is still a no-op where it should be —
`SPLIT_FACTOR: 1.0`, a batch already at `MAX_SHARDS`,
or a plan whose waves are already even.

#### Numbering, and the order they are queued in

These are two different things, and conflating them is what made the first
version confusing to read.

A shard's **number** runs with the history: shard 1 holds the oldest commits of
the plan, shard N the branch tip, and adjacent numbers are adjacent slices.
So a leg's number reads the way its commits do, and the numbering starts at
one rather than at zero.

The **order** they are queued in is the reverse: newest shard first, so that
under `max-parallel` throttling the branch tip — the thing the series loop and
the release flow wait on — is decided first.
The matrix therefore starts at shard N and finishes with shard 1.
Within a shard, commits run oldest-first, for cache locality.

Numbers are assigned after the matrix cap has dropped the oldest shards
(§4), so shard 1 is the oldest shard *this run* will build,
not the oldest one the planner considered.

### Can we measure which commit invalidates how many unity files?

Yes, exactly, without building anything, in about 3.5 seconds.

[`scripts/each-cost.py`](each-cost.py) reads the 341 objects from `src/include/sources.mk`,
resolves every `#include "..."` edge in `src/duckdb/**` (3517 files),
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

median 2, mean 15, max 209.
That is the bimodal distribution `VENDORING-LOOP.md` §4 predicted from ccache timings,
now derived statically and per commit.

Resolution is deliberately an over-approximation:
an include target is matched against a path-suffix index,
so an ambiguous `#include "types.hpp"` counts for every `types.hpp` in the tree.
Over-estimating isolates a commit that did not need isolating —
a little parallelism, no correctness.
The map is built once from the branch tip and reused for the whole range;
reach drifts slowly, and a stale weight only mis-balances a shard.

### What happens when one leg is terminated, aborted, or fails for platform reasons?

Nothing restarts the batch. `fail-fast: false` keeps the siblings running,
every other leg keeps its verdicts,
and the next `each-rcc` run recomputes its to-do list from commit statuses,
so it replans only the commits that are actually undecided.
The blast radius of a lost runner is, by construction, one leg.

What is durable, and what was not:

| State | Where it lives | Survives a runner that stops executing steps |
|---|---|---|
| A commit's verdict | commit-status, written before and after each commit | **yes** |
| The plan | `each-plan` artifact from the `plan` job | **yes** |
| The per-commit record and log | the leg's artifact, uploaded in its last step | **no** — a lost runner never gets there |
| The commit in flight | `pending` status, no verdict | wedged until `PENDING_TTL_HOURS` |

Three sharp edges came out of walking that through, and two of them are fixed here.

**A re-run of a leg used to restart its whole shard.**
`each-shard.sh` walked its slice of `plan.json` unconditionally,
so a leg that died at commit 20 of 27 and was re-run rebuilt all 27 —
on a cold ccache, which is also the slowest way to do it,
and quite possibly into the same deadline that made it defer commits the first time.
The leg now skips a commit that already carries a *decided* `rcc` status,
at the cost of one REST read per commit.
`pending` deliberately does not count as decided: that is precisely the state a
killed leg leaves behind, and redoing it is what the re-run is for.
So "Re-run failed jobs" now costs what was lost rather than what the shard held.

**"Re-run all jobs" used to fail outright.**
An artifact name has to be unique within a *run*, not within an attempt,
so the `plan` job's second upload of `each-plan` was rejected as a conflict.
`overwrite: true` on both uploads fixes it.

**The documented recovery discards good results.**
This is the one that actually looks like "self-healing restarts everything", and it
is not in this workflow at all — it is in the series loop.
[`series-loop.md`](../.claude/skills/series-loop.md) says that a commit still
missing from the harvest after 12 hours should be presumed lost, and repaired by
amending it and replaying the tail. Replaying mints a new SHA for every commit
after it, so one lost leg costs a rebuild of every *already-green* commit newer
than the commit it was in the middle of. That recovery is still the right answer
when a commit genuinely cannot get a verdict, but it should be the last resort:
re-running the failed job, or dispatching `each-rcc` again, now costs only the
commits that are undecided.

One edge is *not* fixed, and is worth stating plainly rather than leaving implied:
**nothing schedules `each-rcc`.**
It fires on push to `each-*`/`*-dev`, on `workflow_dispatch`, and on
`workflow_call`. After a lost leg the branch is left with one `pending` commit and
a tail of statusless ones, and the replanning that would pick them up does not
happen until somebody pushes to that branch or dispatches the workflow. The
replanning is correct; it is not automatic.

Two smaller things fell out of the same walk-through.
The fan-in is now guarded on the planner having succeeded — `shards` is the empty
string when it did not, and `'' != '0'` is true, so the job used to check out the
`rcc` branch to reconcile a run that never built anything.
And a lost artifact used to cost more than the record:
the backstop reconstructs the record from the commit status, but in place of the
per-commit log it stores the *run*-level log, which for a sharded run is every
leg's output concatenated and tailed to 10 000 lines.
`series-check.sh` classifies a failure by what its log contains, so such a log is
worse than absent — it can misclassify. Publishing per commit closes that window.

### Can results reach the `rcc` branch as soon as they exist?

Yes, and the interesting part is that it made the branch *less* contended rather
than more.

The old shape was a barrier. Legs uploaded artifacts and said nothing; one fan-in
job folded them in at the end. So a verdict waited for the slowest leg in the run
— up to the 350-minute job limit — even though the commit status had been green
for hours. That latency is the series loop's cycle time, because
[`series-check.sh`](series-check.sh) gates on the *records*, not the statuses. And
until the fan-in ran, the leg's artifact was the only copy of the per-commit log,
so a cancelled run lost them all.

#### Why one NDJSON file was the thing in the way

Every record arrived *through* `runs2.ndjson`. Two writers append at EOF with no
separating context, so a genuine collision is a textual conflict on essentially
every attempt, and the only recovery is to take the remote as the new base and
re-run the producer (see [`rcc-push.sh`](rcc-push.sh)). That is a fine trade for
two writers that push once per run. It does not survive twenty legs pushing after
every commit: collisions stop being rare, and each one costs a re-derivation —
for the scheduled backstop, a fresh scan of everything it had just recorded.

So records stopped arriving *through* that file. They now land one per file, and
the aggregate is fed from them:

```
runs2.d/<xx>/<sha>.ndjson     one record, one line -- where a record lands first
runs2.ndjson                  every record, in arrival order -- extended, never rewritten
logs2/<sha>.log               unchanged; already one file per commit
```

Two writers recording different commits touch different paths, so there is nothing
to conflict on, and a loser of the ref race re-reads the tip and re-commits its one
file.

#### An extension, not a migration

The obvious next step is to make `runs2.ndjson` fully *derived* — regenerate it
from the parts, in SHA order, on every write. That was the first version of this,
and it is the wrong trade. It buys byte-determinism nothing needs, and it pays for
it by rewriting the branch's principal file: 4.5k historical records reshuffled in
one flag-day commit, as a side effect of whichever job happens to push first.

[`rcc-merge.sh`](rcc-merge.sh) instead **appends the records the aggregate does not
yet have**, and touches nothing else:

- the ~4.5k records that predate `runs2.d/` stay exactly where they are, in the
  order they were collected, byte for byte. There is no flag-day commit and no
  window in which a reader sees the file half-changed;
- every future commit's diff is the records it added, so `git log -p` on the branch
  stays readable;
- a record that exists only in the aggregate is simply left alone. Readers try the
  per-commit file and fall back to the aggregate, so the two together are the whole
  truth and neither has to be complete on its own.

The merge needs nothing but the branch — it is a set difference (commits with a
part, minus commits already in the aggregate) followed by an append. So it is
idempotent, and losing a push race is cheap in a way re-deriving never was: reset
onto the winner, recompute the difference, which is now *smaller* because the
winner appended some of it, append, retry. No producer runs again.

Measured against a copy of the real branch, pushing 25 new records:

| | migration commit | each subsequent update |
|---|---|---|
| regenerate from parts, SHA-ordered | 1.37 MiB | 3–4 KiB |
| append what is missing | **none** | 3–4 KiB |

The steady state is the same — git deltas both perfectly well — so this is not a
bytes argument. The 1.37 MiB is a one-off, and small. What the extension actually
buys is that the riskiest operation in the change simply does not happen: the file
every consumer reads is never rewritten, so the change cannot go wrong there. The
capability is kept rather than discarded — `BACKFILL=1 scripts/rcc-merge.sh` splits
the historical records out on request — it is just not on the path.

The point of separating parts from the aggregate is who pays for which:

| Writer | Frequency | Touches |
|---|---|---|
| a matrix leg | once per commit built (~2/min at `max-parallel: 20`) | its own record, its own log |
| the fan-in | once per run | records the legs could not publish, and the aggregate |
| `rcc-logs.yaml` | every 30 min | records for commits it finds undecided, and the aggregate |

The frequent writers never touch the ~10 MB file. It is extended at exactly the
cadence it was written at before.

#### Do we need both, and who owns keeping them straight?

Both, and they are not redundant so much as differently shaped:

* `runs2.d/<xx>/<sha>.ndjson` is the **write** surface. One file per commit is
  what lets twenty legs publish at once without a lock.
* `runs2.ndjson` is the **read** surface. One file is what makes "what happened
  to every commit in this range" a single fetch rather than N — which is what
  `git show origin/rcc:runs2.ndjson` has always been good for.

In normal operation they drift slightly, in two directions that are both
harmless: records that predate the split live only in the aggregate, and a record
published seconds ago may not be merged into it yet. Readers cope by trying the
per-commit file and falling back
([`series-check.sh`](series-check.sh)), so the pair is the whole truth and
neither has to be complete alone.

Ownership is deliberately lopsided, because that is what makes the concurrency
work:

| Writer | Adds | Rewrites |
|---|---|---|
| an `each-rcc` leg | its own record and log | nothing¹ |
| the run's fan-in | records a leg could not publish | nothing¹ |
| `rcc-logs.yaml` | records for commits it finds undecided | nothing¹ |
| `rcc-merge.sh`, from the last two | the aggregate's missing lines | a line a retry made stale |
| [`rcc-consolidate.sh`](rcc-consolidate.sh) | — | **all of it**, by hand |

¹ except a verdict it is overturning — see below.

Everything routine is additive. The three destructive operations — making the
layouts agree, deleting logs, discarding history — belong to one manually
dispatched workflow ([`rcc-consolidate.yaml`](../.github/workflows/rcc-consolidate.yaml)),
where they happen once and under supervision.

#### Consolidation

`rcc-consolidate.sh` is `workflow_dispatch`-only and defaults to a dry run. What
it does, measured on the live branch:

| | before | after |
|---|---|---|
| commits | 181 | **2** |
| records | 4601 aggregate / 4572 parts | 4601 / **4601** |
| logs | 2496 | **856** |
| objects | 218 MB | **74 MB** |

Three things happen:

1. **The layouts are made to agree.** Every aggregate-only record is split into a
   part, and the aggregate is then rebuilt as exactly the parts' concatenation,
   ordered by when each verdict was written. This is the one place where
   migrating is right: the branch is being rewritten anyway, so there is no
   flag-day commit to avoid.
2. **Logs past `LOG_RETENTION_DAYS` (30) are dropped**, along with any log whose
   commit has no record at all. Logs are ~1 MB each and ~90% of the branch;
   records are ~2 KB. A log earns its keep by letting `series-check.sh` classify
   a failure — which matters for a commit the loop is still working on, not for
   one decided months ago and long since repaired. **Records are never dropped**,
   so the verdict outlives the evidence, and `.timing.failed_stages` still names
   the gate that broke.
3. **The history is squashed to two commits**: an empty `Initial`, and the whole
   current state. The root is *inherited* when one is already there — two
   consolidations must not mint two roots, or each would invalidate every clone
   twice over.

Why manual: every other writer is additive and races safely, so a rewrite is the
one operation that wants an operator who knows nothing else is mid-flight. A
schedule cannot know that. The push carries `--force-with-lease` as the backstop,
so a writer that *did* land in between refuses the push instead of losing its
record — verified in [`rcc-parts-test.sh`](rcc-parts-test.sh).

#### A newer verdict wins

A record is normally written once, which is what makes every writer idempotent.
The exception is a **retry**: `retry-<S>-dev` asks for a commit that already has
a verdict to be judged again on its own SHA, and the point is to overturn it. So
the newer verdict replaces the older one everywhere —

* [`rcc-part-push.sh`](rcc-part-push.sh) compares blob ids in the index, so
  re-publishing an identical record costs nothing and a changed one replaces both
  the record and its now-stale log;
* [`each-harvest.sh`](each-harvest.sh) compares the artifact's verdict against
  whichever layout holds the commit, and replaces on a difference;
* [`rcc-merge.sh`](rcc-merge.sh) replaces the aggregate's *line* rather than
  appending a second one — readers take the first match for a SHA
  (`series-check.sh` greps with `-m 1`), so an appended line would be invisible.

Two writers can only collide here if they are deciding the same commit at the
same moment, which the planner does not produce; if it somehow happened, the
retry loop converges on whichever wrote last.

The planner names the commits it replanned *despite* a verdict in the plan's
`replanned_despite_verdict`, and the leg reads it from there. Without that the
resume check above would skip exactly the commit a retry exists to rebuild, and
the workflow would have to keep an env var in agreement with the planner's own
logic — which it could not, since the planner decides on the branch name.

#### What publishing from a leg costs

It has to be cheap, or the latency is not worth buying. The `rcc` branch is
218 MB, almost all of it those 2.5k harvested logs at about a megabyte each, and a
leg needs none of those bytes to add one file. So
[`rcc-part-push.sh`](rcc-part-push.sh) keeps a blobless, shallow, checkout-less
clone (`--filter=blob:none --depth 1`), which fetches trees only, and builds the
commit with plumbing: `read-tree`, `hash-object -w`, `update-index`,
`write-tree --missing-ok`, `commit-tree`, push. Measured against a copy of the
real branch: **2.1 MB of clone against a 222 MB branch, and ~130 ms per publish
once warm.**

One trap is worth recording because it is completely invisible. Plain
`git write-tree` verifies that every index entry's object is present, which in a
blobless clone means lazily fetching all 2.5k logs — the whole 220 MB, per leg.
`--missing-ok` suppresses the check (every entry came either from the remote's own
tree or from the blob written moments earlier), and `GIT_NO_LAZY_FETCH=1` is
exported so that any *other* route to the same mistake fails loudly instead of
quietly downloading the branch.

#### How bad is the race?

Measured by [`rcc-parts-test.sh`](rcc-parts-test.sh) — 20 concurrent writers
against a copy of the real branch, each publishing back to back with no build in
between, so roughly 100× the real rate:

| | |
|---|---|
| records published | 100 |
| records lost | **0** |
| succeeded on the first attempt | 51% |
| landed within 4 attempts | 87% |
| needed 5 or more | 13% (deepest: 9 of 20) |
| gave up | 0 |

Only the first two rows are invariants; the distribution moves from run to run
with machine load. That tail is what saturation looks like, not what the branch
looks like: with 20 writers pushing back to back there is always someone else
mid-push, so a loser can be starved for several rounds. The retry budget is sized
for it — a retry is one fetch and one push, the backoff caps at 8 s, so the whole
budget is about two minutes against a build measured in tens of them.

At the real rate the arithmetic is dull, which is the point. A publish is one fetch
and one push, one or two seconds against GitHub; 20 legs at one commit per ~10
minutes issue about two pushes a minute; so the chance that a given push overlaps
another is around 2 s × 2/60 s ≈ 7%, and losing costs a second. The hammer test is
there to show the tail is bounded, not because the tail is expected.

What is genuinely spent is commits: the branch grows by one per record rather than
one per run, so a 1000-commit backfill adds ~1000 commits to `rcc`. Each is one
small blob and two small trees — which is what the 256-way fan-out is for. A single
flat directory of 10k records would rewrite a ~500 KB tree on every push.

And none of it is load-bearing. Legs still upload their artifacts, the fan-in still
runs `if: always()`, and `rcc-logs.yaml` still ticks every 30 minutes. A failed
publish is logged and ignored — it never fails the leg — and the record is
collected the old way, one job later.

---

## 4. GitHub Actions limits this works within

| Limit | Value | How the design stays inside it |
|---|---|---|
| Jobs per matrix | 256 per workflow run | `MAX_SHARDS` defaults to 250, and bounds the rebalance pass as well as the fill; 1000 `main-fwd-build` commits plan to 79 shards |
| Job execution time | 6 h | shard budget 300 min, job `timeout-minutes: 350`, and the leg stops itself and defers the rest |
| Workflow run duration | 35 days | 1000 `main-fwd-build` commits are ~18 h at `max-parallel: 20` |
| Concurrent jobs | plan-dependent | `max-parallel` (default 20) keeps the run a good neighbour, and is the wave width the rebalance pass plans against |
| `GITHUB_TOKEN` REST requests | 1000 per hour per repository | see below |
| Reusable workflow nesting | 10 levels, 50 unique per file | not used |

The rate limit is the one that quietly rules out the obvious implementation.
Reading one commit-status per REST call — what `each-rcc.sh` does today —
costs one request per commit, so a 3000-commit scan cannot complete at all.
The planner batches 100 commits per GraphQL request instead: the same scan is ~30 requests.

Writing statuses stays REST (there is no batch endpoint), 2 per commit,
plus one read per commit for the resume check
([§3](#what-happens-when-one-leg-is-terminated-aborted-or-fails-for-platform-reasons)).
That is a *rate*, not a burst: at `max-parallel: 20` and ~20 min per commit
the whole run issues on the order of 180 requests per hour.
Publishing a record is a git push, not an API call, so it does not enter this
budget at all.

### Scale, planned against a real backlog

The planner run below is not a simulation:
it is `each-plan.sh` over the newest **1000 commits of `main-fwd-build`**,
with every commit treated as undecided. It takes **5.4 s** end to end,
including building the reach map.

```
commits              1000
shards                 79      (matrix cap 250)
commits/shard          8 – 19  (median 12)
estimate/shard       159 – 264 min  (median 254)
```

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
to 8–19 commits accordingly, which is exactly what cost balancing is for
(estimates still land within 159–264 min).

| | sharded | one run per commit |
|---|---|---|
| jobs | **79** | 1000 |
| runner-hours | **338** | 883 |
| wall clock at `max-parallel: 20` | **~18 h** (4 waves) | — |

**2.6×** less compute here, against 3.6× on the much cheaper
`v1.5-variegata-dev` distribution — the honest range,
with the worst case at the low end.
At `max-parallel: 8` this backlog is ~44 h; at 60, ~9 h.

Extrapolating the same shard density, a 3000-commit mainline replay
is ~240 shards — still inside the 250 cap, still one run, but close enough
to it that a bigger backlog would need a second run or a larger shard budget.

Those figures predate the recalibration in §3 and were derived from the model,
not from measured legs;
the shard counts move a little under the fitted constants but the shape does not.
The current numbers for the two live backlogs, at `max-parallel: 20`:

| | `main-fwd-dev` | `main-dev` |
|---|---|---|
| commits to build | 77 | 1039 |
| shards, fewest-legs | 4 | 67 |
| shards, after rebalancing | **20** | **79** |
| wall clock | **79 min** (was 5.1 h) | **16.9 h** (was 19.2 h) |
| runner time | 22.6 h (was 16.3 h) | 321.0 h (was 320.8 h) |

---

## 5. Operating it

Everything is an input on `workflow_dispatch`, and the ones worth setting repo-wide
are repository variables:

| Knob | Input | Variable | Default |
|---|---|---|---|
| Legacy per-commit dispatch | `mode: dispatch` | `EACH_RCC_MODE` | `matrix` |
| Earliest commit date | `since` | `EACH_RCC_SINCE` | `2026-01-01` |
| Concurrent shards | `max-parallel` | `EACH_RCC_MAX_PARALLEL` | `20` |
| Build-time target per shard | `shard-budget-minutes` | — | `300` |
| Compute traded for wall clock | `split-factor` | `EACH_RCC_SPLIT_FACTOR` | `1.5` |
| Cap on commits considered | `max-commits` | — | `0` (no cap) |
| Rebuild decided commits | `force` | — | `false` |
| Log lines quoted per failed stage | — | `EACH_RCC_SUMMARY_TAIL` | `50` |

`EACH_GATES` can drop individual gates, but note that `pkgdown` is **not** a
candidate: a pkgdown failure is a real failure and has to be dealt with, so the
gate stays on.

The lever for a slow *large* batch is `max-parallel`, which decides how many
waves it takes.
The lever for a slow *small* batch is `split-factor`:
under `max-parallel` legs the run is one wave,
and the only way to shorten it is to make the longest leg shorter.
A large batch gets some of this for free — rebalancing evens out the waves at
almost no compute — but shortening it *further* is what `split-factor` pays for.
Set `split-factor` to `1.0` to get the fewest-legs, cheapest-compute
behaviour back.

### Reading a failure without opening the log

A leg is one job for up to ~20 commits and up to five hours of output,
so "which commit went red, and why" used to mean expanding the right
`::group::` in a very long job log.
The leg's job summary answers both directly.
The result table names the stages that failed —
a commit's cell reads `failure (check, pkgdown)`, not just `failure` —
and below it each failed stage gets a collapsed `<details>` block holding the
last `EACH_RCC_SUMMARY_TAIL` lines of *that stage's* output,
which is enough to tell a compile error from a failing test.
Setting the variable to `0` turns the excerpts off.

The excerpt is not the record.
The whole per-commit log still goes to `logs2/<sha>.log` on the `rcc` branch,
which is what [`scripts/series-check.sh`](series-check.sh) classifies against;
the summary is the fast path for a human.
Two details make it work in practice:

- [`scripts/rcc-one.sh`](rcc-one.sh) writes each stage's output to its own file
  under `EACH_STAGE_DIR` and its verdict to `outcomes.tsv`,
  rather than the leg parsing the combined log back apart.
  Nothing is buffered that was not already buffered —
  the leg redirects the whole commit to a file and prints it once the commit is
  over — and a stage with a log but no verdict is precisely the stage the leg's
  `timeout` killed, so that one is quoted too.
- Excerpts stop at 900 kB, because GitHub truncates a step summary at 1 MiB and
  a truncated summary would take the result table with it.
  How many were dropped is stated.

### Failure modes and what happens

| Situation | Outcome |
|---|---|
| A commit fails its gate | `rcc=failure`, the leg keeps going, record and log published from the leg, failed stages' tails in the job summary |
| A leg runs out of budget | remaining commits stay statusless, next run replans them |
| A leg dies hard mid-commit | that commit stays `pending`; every commit it had already decided is on the `rcc` branch already; `pending` is replanned after `PENDING_TTL_HOURS` |
| A leg is re-run after dying | commits it already decided are skipped, not rebuilt (§3) |
| A leg cannot reach the `rcc` branch | logged, never fatal; the fan-in collects the record from the artifact |
| The whole run is cancelled | no fan-in, but the legs' own records are already on the branch; `rcc-logs.yaml` covers whatever is left on its next tick |
| The `plan` job fails | `build` and the fan-in are both skipped |
| History is force-pushed mid-run | unreachable SHAs fail checkout and are skipped; new SHAs picked up next run |
| More than 250 shards planned | oldest shards deferred, reported in the job summary |
| Two writers publish records at once | different files, no conflict; the loser of the ref race re-reads the tip and re-commits ([`rcc-part-push.sh`](rcc-part-push.sh)) |
| Two writers extend the aggregate at once | the push is rejected, and [`rcc-push.sh`](rcc-push.sh) resets onto the new tip, re-derives, and appends what is still missing before retrying |
| A retry overturns a verdict | the newer record and log replace the older ones, in the part and in the aggregate's line (§3) |
| A writer lands during a consolidation | the lease refuses the force-push; nothing is lost, re-dispatch it |

Nothing here needs a lock for correctness.
Progress is durable per commit, and every run recomputes its own to-do list from ground truth.

That extends to the `rcc` branch itself, and it is why no writer takes a lock.
The tempting serialiser is a concurrency group shared with `rcc-logs.yaml`,
and it was one until the eviction rule caught up with it:
only one run may be *pending* per group,
so a third writer queued behind the second cancels it outright.
A cancelled fan-in is not a delayed fan-in —
it used to take the only copy of its per-commit logs with it.
Concurrent writers that retry lose strictly less than serialised writers that get evicted,
so the group is gone and no writer assumes it won.

What changed is that most collisions no longer exist to be resolved.
Records live one per file (§3), so two writers adding different commits cannot
conflict at all, and `runs2.ndjson` is appended to rather than merged.
The reset-and-re-derive recovery is still there for the two writers that touch the
aggregate, and is still safe for the same reason it always was: both producers
dedupe against what is on the branch, so a retry only re-adds what the winner did
not already record. Rebasing would still be the wrong recovery — the aggregate is a
single file every writer extends, so a genuine collision means both sides changed
it with no separating context.

---

## 6. Rollout

`each.yaml` runs the scripts from the *branch it is checking*,
so a `*-dev` branch picks up the sharded path only once the new scripts are forward-ported to it —
the same constraint every CI change in this repository has
(invariant **G1** in [`BRANCHES.md`](../BRANCHES.md#source-of-truth-cross-series)).
Until then that branch's copy of `each.yaml` is the old dispatcher, and keeps working.

`vendor.yaml` no longer exists — the series loop
(`.claude/skills/series-loop.md`) replaced it — so the only remaining caller of
`scripts/each-rcc.sh` is the legacy `dispatch` mode of this workflow.
Nothing has to be switched over; the two paths write the same marker, and the
planner skips any commit that already has one, so they never double-build.

Suggested order:

1. Land here; exercise on a scratch `each-*` branch by dispatching `each-rcc` manually.
2. Run the parity check from §7 item 1 — legacy and sharded over the same commit range — and compare verdicts.
3. Forward-port to the `*-dev` branches.
4. ~~Recalibrate the cost-model constants from real `duration_seconds`.~~ Done; see §3.

Rolling back at any point: set the repository variable `EACH_RCC_MODE=dispatch`.

---

## 7. What is not yet validated

Honest list, in rough order of risk:

1. **`rcc-one.sh` is a port, not a call.** It reproduces the gates `rcc-smoke`
   applies on its `workflow_dispatch` path. `R-CMD-check.yaml` is forward-ported
   from upstream, so the two can drift.
   A parity run — legacy dispatch and sharded build over the same commits,
   comparing verdicts — is the check that should precede cut-over.
2. **The cost model counts objects, not object *sizes*.**
   A `ub_*.o` group compiles dozens of `.cpp` files and a leaf object compiles
   one, and the model charges the same `OBJECT_SECONDS` for both.
   The fit absorbs this on average — a wide-header commit reaches mostly `ub_*`
   objects and a narrow one mostly leaves — but it is why the residuals go one
   way at 53 objects (16.5 measured against 14.6 predicted)
   and the other at 219 (38.0 against a capped 40.0).
   Weighting each object by its translation unit's size would remove the bias;
   `each-cost.py` already has the graph it would need.
3. **The fit is 29 commits from two branches**, both heavy on vendor churn.
   An R-only batch — 0 invalidated objects throughout — is not represented,
   and `FLOOR_MINUTES` is the constant that would move.
4. **8 GB ccache on a standard runner** should hold ~17 trees' worth of compressed
   objects; only the previous commit's are needed. Not measured on a runner.
5. **Rebalancing raises the concurrency footprint.** A 77-commit batch now asks
   for 20 runners instead of 4, for an hour. Peak concurrency is still capped by
   `max-parallel` — a large batch gains legs (67 → 79 on `main-dev`) without
   gaining slots — but it is the whole account's Actions concurrency, so other
   workflows queue behind it where they used not to.
6. **The publish path has not run against GitHub.** Its invariants are checked
   offline against a copy of the real branch
   ([`rcc-parts-test.sh`](rcc-parts-test.sh)), and the numbers in §3 come from
   there, but a local bare repository is not the real remote: HTTPS latency makes
   the collision window a second or two rather than 130 ms, and
   `--filter=blob:none` is a server capability, exercised there through
   `uploadpack.allowFilter`. The fallbacks are in place — a filtered fetch that is
   refused retries unfiltered, and a publish that cannot succeed at all is logged
   and left to the fan-in — so the failure mode is a slow leg or a late record,
   not a lost one. The first live run on a scratch `each-*` branch is what
   confirms it.
7. **The two layouts coexist between consolidations.** Records written before
   this lands live only in `runs2.ndjson`; records written after live in both.
   Readers handle it by trying the per-commit file first, and
   `rcc-consolidate.sh` removes the drift when it runs — but until it has, a
   reader that only knows about `runs2.d/` would silently miss the historical
   commits.
8. **`rcc-consolidate.sh` has only been run against a copy.** The numbers in §3
   come from consolidating a clone of the live branch, and the lease, the root
   inheritance and the log GC are all checked in `rcc-parts-test.sh` — but it
   force-pushes an orphan branch that ~950 snapshot branches and several
   workflows read, and the first real run is the one that proves the fetch
   refspecs elsewhere tolerate it. Dry run first.

---

## 8. Relation to the vendoring loop plan

This is a concrete, narrower implementation of primitive **B** in
[`VENDORING-LOOP.md` §3.2](VENDORING-LOOP.md#b-build-primitive--synchronous-sharded-matrix-ci-new-rcc-matrixyaml) —
plan, sharded matrix, `if: always()` fan-in — landed inside the existing `each-rcc`
instead of as a new `rcc-matrix.yaml`, because the selection semantics are already right there.

Two corrections to that plan fall out of implementing it:

- §4.2 attributes within-shard reuse to **incremental `make`**.
  It is **ccache**. `R CMD build` compiles from a copy of the package,
  and this package's `cleanup` deletes `src/duckdb` on the way,
  so make timestamps cannot cross a commit boundary. The hit-rate figures are unaffected —
  it is the same "only the changed unity objects recompile" effect — but the mechanism matters
  for how the leg is written (clean per commit, cache outside the workspace).
- §4.4 attributes the ~70-90 s per-commit floor to the **LTO link**.
  There is no LTO in this build: the package sets no `-flto` and R's `Makeconf`
  reports `LTO =` empty. Whatever the floor is made of, dropping LTO is not the
  lever, so `FLOOR_MINUTES` stays unmeasured rather than inheriting that
  explanation.
- §4.3 leaves the reverse-include map as future work.
  It exists now (`each-cost.py`), and it is cheap enough — 3.5 s — to run per plan.

The promote primitive (**C**) and the `*-green` branch model are no longer open:
they landed on `main` as the **series loop** (`.claude/skills/series-loop.md`)
while this branch was in flight, which is where the `<S>-green` bound above
comes from. This change is orthogonal to it — it swaps how the commits in
`<S>-green..HEAD` get built, not which ones.
