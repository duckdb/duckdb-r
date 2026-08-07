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
* **Results** — one record and, for a failure, one log per commit,
  published in two places from the same bytes:
  * in the **run** that decided the commit —
    `parts/<sha>.ndjson` and `<sha>.log` in the leg's
    `each-logs-<shard>-<attempt>` artifact (14 days),
    and the same content inline in the leg's job log,
    between that commit's `::group::<sha>` and its
    `<sha>: <state> (<n>s, exit <rc>)` line;
  * on the **`rcc2` branch** — `runs2.d/<xx>/<sha>.ndjson`
    and `logs2.d/<xx>/<sha>.log`, one file per commit, no aggregate;
    what the store keeps and for how long is
    [`store/`](/handbook/operations/ci/per-commit/store/README.md)'s.

  The store is a copy of the run's files, not a second computation,
  so a consumer may read whichever it can reach.
  A **run's conclusion is not a verdict**: a leg exits 0 whatever its commits
  did, deliberately, so that a red commit reads as a result rather than as a
  broken job.
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
Selection reads the verdict store on the `rcc2` branch instead —
CI-side, that is what "decided" means, in the planner
([`each-plan.sh`](/scripts/each-plan.sh)), in a leg's resume check,
and in the backstop, all of them through
[`rcc-decided.sh`](/scripts/rcc-decided.sh).
[`series-check.sh`](/scripts/series-check.sh) and
[`series-advance.sh`](/scripts/series-advance.sh) read the per-commit record,
so they see a verdict minutes after it happens rather than at the end of a run.
[`rcc-logs.sh`](/scripts/rcc-logs.sh) writes records to the same place.

The **series loop reads the runs first** and treats the store as its fallback
([`.claude/skills/series-loop.md`](/.claude/skills/series-loop.md), stage 2):
the store was built so that an agent with no API access could still read a
verdict and a log, and one that can read the run reads the source instead.
Nothing about the CI-side use above changes with it.
