# Operating it

The knobs, reading a failure without opening the log,
and what happens in each failure mode.

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
| Gates to run | — | `EACH_GATES` | `rcc-one.sh`'s `ALL_GATES` |

Most of these defaults are the workflow's, set in
[`each.yaml`](/.github/workflows/each.yaml);
the summary tail and the gate list default in the scripts that read them
instead.
The scripts carry their own fallbacks for a direct invocation too,
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

## Reading a failure without opening the log

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

## Failure modes and what happens

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
