# Per-commit build times of one landing

*What it measures:* how long each commit of a large `each-rcc` run took to build and check,
against what the planner's cost model predicted for it,
and which constants of that model fit the measured times.
Per commit: the unity objects it invalidates, whether it was the first commit of its leg (an empty ccache),
and the `duration_seconds` its record on the `rcc2` branch reports.

*When and on what:* 2026-11-22, from the records of two runs on krlmlr/duckdb-r:

* [44932694459](https://github.com/krlmlr/duckdb-r/actions/runs/44932694459),
  `each-rcc` on `main-land-dev` planned from 5405e828f0,
  822 commits in 41 legs at `max-parallel: 20`, of which 612 were built before the legs reached their deadline;
* [44932760627](https://github.com/krlmlr/duckdb-r/actions/runs/44932760627),
  its follow-up planned from a1a93d5bee, 211 commits in 20 legs,
  58 of them recorded when the data was collected, while its legs were still running.

Both runs planned with `FULL` 40, `FLOOR` 6, `OBJECT_SECONDS` 9.7 and `SETUP` 5.

*What it supports:* the constants and the fit in
[`operations/ci/per-commit/planning/`](/handbook/operations/ci/per-commit/planning/README.md).

## Files

* [`collect.sh`](collect.sh) recomputes both plans with the planner at each run's tip
  and joins them with the records, into [`data.tsv`](data.tsv):
  run, shard, position in the shard, commit, invalidated objects, and minutes (empty where the commit has no record).
  The recomputed plans match the job names of both runs shard for shard,
  in commit count and in estimate.
  The committed `data.tsv` is the snapshot the planner's constants were fitted to;
  re-running `collect.sh` picks up the records published since and changes it.
* [`jobs.tsv`](jobs.tsv) is the start and end of every leg of run 44932694459, from the Actions API.
* [`fit.R`](fit.R) fits the model, compares it with the constants before,
  and replays run 44932694459's commits through the planner and the deadline logic of
  [`each-shard.sh`](/scripts/each-shard.sh) with each set of constants;
  [`fit.md`](fit.md) is its reprex.

## Findings

Least squares over the 670 records gives `FULL` 47.7, `FLOOR` 9.3 and `OBJECT_SECONDS` 10.0;
the planner takes 48, 9.3 and 10.
The RMSE falls from 6.3 to 4.5 minutes, and the mean error from 4.1 minutes a commit to zero.
The constants before under-predict every kind of commit:
a commit with nothing much to recompile by 3 minutes, a cold build by 9.

The model's shape holds.
Cold builds do not depend on what their commit changed,
and a separate cap for wide warm commits, below the cold build, lowers the RMSE by 0.03.
The residuals are concave in the object count,
above the line at 21 to 80 objects and below it at 161 to 230,
which is what counting objects rather than their sizes predicts.

Job time outside the build loop was 2.7 to 6.9 minutes, median 5.2, on the legs that killed no commit,
so `SETUP` stays at 5.
No leg took longer than 306 minutes, against the job's `timeout-minutes: 350`:
`each-shard.sh` runs every commit under a `timeout` of what is left of the deadline,
so a slow commit cannot carry a leg past it, and the pair stays as it is.
Ten legs killed a commit at the deadline and lost 12 to 45 minutes each to it,
because the leg starts a commit whenever more time is left than its last commit took,
and a wide commit after a cheap one does not fit.

Replanned and replayed against the measured times,
the old constants reproduce the run: 41 legs, 3 of which build every commit, 615 commits built against 612 measured.
The refitted ones give 61 legs, 56 of which build every commit, and 816 of 822 commits built,
for 1.34 times the runner minutes.
That replay reuses the data the constants were fitted to, so it is the best case.

## Replicating

From a clone whose `origin` is krlmlr/duckdb-r,
`experiments/2026-11-22-each-timing-refit/collect.sh` rewrites `data.tsv` in a few seconds;
a later run of it picks up the records the follow-up has published since.
Then, from this directory, `Rscript ../../scripts/render-reprex.R fit.R fit`,
which needs `jsonlite` and `python3`.
