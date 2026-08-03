# Planning

How a list of undecided commits becomes a matrix of shards:
the cost model, the two partition passes,
and the GitHub Actions limits the result has to fit inside.

## The cost model

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

## Pass 1: the fewest legs

Shards must be **contiguous** — that is what makes consecutive checkouts cheap —
so this is not bin packing.
Partitioning a sequence into the fewest contiguous parts under a fixed budget
is solved exactly by a single greedy left-to-right pass, in O(n).

Balancing by predicted time rather than commit count is what isolates expensive
commits: on a thousand-commit `main-dev` backlog the greedy pass emits legs of
7 to 27 commits, a 3.9× spread in count,
to hold them all under one deadline.

## Pass 2: the shortest wall clock

The greedy pass minimises **legs**, which is close enough to minimising
runner-minutes to serve as the cost baseline.
It is a poor answer for wall clock at every size, and for a small batch it is
the *worst* answer.
The default leg deadline is 300 minutes, a leg's first commit pays the
cold build and every cheap commit after it ~6,
so 45 commits take two legs — and the branch tip waits five hours for a
verdict that 20 legs would have delivered in fifty minutes.
This is the common case, not the corner case:
a series-loop batch is capped at the chunk the loop consumes per firing
([`vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md))
and is usually far smaller.

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

## Numbering, and the order they are queued in

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

## Which commit invalidates how many unity files

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

## Scale

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

*To deepen: weight each unity object by its translation unit's size —
`each-cost.py` already has the graph — and refit against an R-only batch,
which the current fit does not cover.*
