# The contract

What every consumer of `each.yaml` can rely on:
what gets a verdict, what marker is written, and where the results land.
How the to-do list is computed is
[`selection/`](/handbook/operations/ci/per-commit/selection/README.md)'s.

* **Commits considered** — `<S>-green..HEAD` on a series branch,
  else first-parent history since `SINCE`; undecided ones only.
* **Marker written** — a commit status, context `rcc`,
  `pending` before a commit and `success`/`failure` after it,
  written by the leg.
* **Re-trigger a commit** — give it a new SHA and force-push;
  the record is keyed by SHA, so a rewritten commit has none.
  To re-judge one on the SHA it already has, push a `retry-<S>-dev`
  branch at it; to replan a whole range, dispatch with `force`.
* **Results** — on the `rcc` branch:
  `runs2.d/<xx>/<sha>.ndjson` for a new record,
  `runs2.ndjson` for the aggregate it is merged into,
  `logs2/<sha>.log` for the log.
  A reader takes the per-commit file and falls back to the aggregate;
  the two are made to agree by
  [`store/`](/handbook/operations/ci/per-commit/store/README.md#consolidation),
  which is a manual operation.
* **Gate applied per commit** — style, snapshots, roxygen, clean tree,
  `R CMD check`, pkgdown. The *order* is the contract;
  the list is `rcc-one.sh`'s `ALL_GATES`.
  The copy that runs is the **commit's own**, not the branch tip's:
  the leg resets the workspace before each commit, and the gate it then
  invokes is the one that commit carries.
  So a change to the gate binds the commits at or after it and no others,
  and a range replayed from before one is judged without it.
* **Accepted snapshots** — pushed as `snapshot-<sha>-rcc-smoke-null`.
* **Triggers** — push to `each-*` / `*-dev`, `workflow_dispatch`,
  `workflow_call`.

The snapshot branches are load-bearing, so `rcc-one.sh` reproduces them
rather than just leaving the accepted snapshots in the tree.
The name is a **frozen literal** — the full SHA between two constants,
one real branch name for the shape of it:

```
snapshot-0019bff821c63ce478d9046aa925d104df1f71a0-rcc-smoke-null
```

Upstream derives that tail from its job name and its empty matrix.
Here the job is `build` and a matrix exists, so the tail is *kept*
rather than derived: deriving it would rename every future branch
and orphan every existing one.
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
