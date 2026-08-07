# The legs

The three jobs, the scripts behind them,
what one leg does with its workspace, and what a lost leg costs.
How its commits were chosen is
[`selection/`](/handbook/operations/ci/per-commit/selection/README.md)'s;
how they were packed into shards is
[`planning/`](/handbook/operations/ci/per-commit/planning/README.md)'s.

One run is three jobs:

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
       → publish record + log to the `rcc2` branch   ← seconds after the verdict
     ... stops at its own deadline and defers the rest

harvest (1 job, if: always())
  └─ fill in records and logs for commits whose leg never got to publish
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
* [`scripts/rcc-lib.sh`](/scripts/rcc-lib.sh) —
  the store: its paths, its clone helpers, its retention and its squash.
* [`scripts/rcc-publish.sh`](/scripts/rcc-publish.sh) —
  the one writer: stage files, push them, retry on the ref race.
* [`scripts/rcc-decided.sh`](/scripts/rcc-decided.sh) —
  the other direction: which commits the store has decided.
* [`scripts/rcc-consolidate.sh`](/scripts/rcc-consolidate.sh) —
  manual: drop what has aged out, squash the branch.
* [`scripts/rcc-cutover.sh`](/scripts/rcc-cutover.sh) —
  one-shot: build `rcc2` from what the old `rcc` branch held.
* [`scripts/each-harvest.sh`](/scripts/each-harvest.sh) —
  fan-in: reconcile what the legs could not publish.
* [`scripts/rcc-run-fields.jq`](/scripts/rcc-run-fields.jq) —
  the run-object projection all three writers share.
* [`scripts/rcc-store-test.sh`](/scripts/rcc-store-test.sh) —
  offline checks for the store's invariants,
  and the source of the concurrency measurements below.

## Why reuse works even though every commit starts from a clean tree

The leg does `git checkout --force` and `git clean -qfdx` before each commit,
so object files do not survive — and they would not anyway:
`R CMD check` compiles from the copy `R CMD build` makes,
and this package's `cleanup` script tars `src/duckdb` away.
Incremental `make` cannot cross a commit boundary here.

What does survive is **ccache**, which is content-addressed
and lives outside the workspace for the whole job.
A typical adjacent vendor commit recompiles about five of the unity objects —
roughly 98% hits, measured in
[`experiments/2026-03-vendor-build-cost/`](/experiments/2026-03-vendor-build-cost/README.md).
Cleaning the workspace also means every commit's verdict is identical to one
from a fresh checkout, which is what keeps the semantics honest.

## All four cores, and no within-job parallelism

`install/action.yml` derives `-j` from `parallel::detectCores()`,
because the compile phase dominates a build:
measured on a 4-core box, 8 vendored unity objects with ccache disabled,
70.8 s at `-j2` against 43.1 s at `-j4` — 1.64×, at identical user time.

Gates run serially, and that works well enough.
The tree-mutating chain is serial by construction —
`style` → `snapshots` → `roxygen`, with `clean` observing their union —
so the optimisation potential in overlapping the rest looks limited.

The legs run on **`ubuntu-26.04`**, the image `rcc-smoke` uses.
That is a parity requirement, not housekeeping: the gate exists to reproduce
`rcc-smoke`'s verdict, and a verdict that depends on the runner image is not a
reproduction.

The environments match, with minor differences that do not affect the result:
the leg does not use `custom/after-install`, whose capped ccache and
tree-keyed archive are per-commit constructs a multi-commit job cannot use,
and keeps one 8 GB local cache instead.

The gate runs as a script rather than a reusable workflow or a composite action:
`uses:` is a job-level key and a workflow cannot loop over a composite action,
so a shell loop ([`rcc-one.sh`](/scripts/rcc-one.sh))
is the simplest construct that runs the same gate N times in one job.

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
The planner's artifact carries `overwrite: true` and the leg's is
named per attempt, so "Re-run all jobs" collides on neither.
The fan-in is guarded on the planner having succeeded,
so it does not reconcile a run that never built.

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
