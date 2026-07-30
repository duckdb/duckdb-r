# The series loop: vendor, promote, repair

One routine drives **all** series:
each firing enumerates every series and every existing forward (`-fwd`)
counterpart and serves each in turn.
`<S>` is a series prefix — `main`, `v1.5-variegata`, `v1.4-andium`,
`main-fwd`, and every future series.
Retrofit of the earlier `rcc-smoke-fix` / `advance-green-dev` skills,
which repaired by forking `broken-<sha>-dev` branches
and were never made to work;
this loop repairs in place and was proven on the `main` rewind
(~1000 commits from the v1.5 fork point to the upstream tip).

## The four branches of a series

| ref | who writes it | what it is |
|---|---|---|
| `<S>-build` | the routine, unconditionally | Every upstream first-parent commit vendored one-to-one, glue compiling at every commit. **No CI runs here** (`each.yaml` never matches `*-build`). The buffer. |
| `<S>-dev` | the routine, force-push | `<S>-build` commits, consumed up to 100 at a time, with test/R/patch adaptations folded in as CI demands. What CI builds, commit by commit. |
| `<S>-green` | the routine, fast-forward only | The newest commit such that every commit in `<S>-green..it` has a `success` run. What r-universe should build from. |
| `<S>-build-base` | the routine | The `<S>-build` commit equivalent to `<S>-green` (same vendored upstream SHA). Marks how much of the buffer has been consumed and verified. |

Equivalence between `-build` and `-dev` commits is by the
`duckdb/duckdb@<sha>` reference in the commit subject —
the subject is machine-readable state,
which is also how `vendor-one.sh` finds its base.

**A series is discovered, not configured**:
each firing lists `refs/heads/*-build`,
and every `<X>-build` with a sibling `<X>-dev` is a series it serves —
base and forward (`<S>-fwd-*`, see `series-forward.md`) alike,
in one pass over all of them.
Ignore a forward series
whose green is an ancestor of its base series' green;
that is cutover litter pending deletion
(the base moves on after cutover, so equality cannot be the test).

**All four refs exist from day one, equal, and green contains the flavor
change.**
A new series is bootstrapped with all four refs at the **same commit** —
the seed tip, "after flavoring", before any vendor commit:

    <S>-green = <S>-build-base = <S>-build = <S>-dev

Stage 1 then populates `-build`;
the other three advance as the loop consumes and verifies.
Whatever consumes `-green` must build the series' *flavored* package,
so the seed contains the flavor pair, never just the unflavored base,
topped by a separate `chore: Add fifth version component` commit
stamping the `.0` — the vendor counter's zero,
so every commit on the series is orderable by version.
The fifth component belongs to dev branches only:
`flavor.sh` never stamps it,
and regular LTS flavors keep their four-component version.
There is never a "no green yet" state:
every walk below is bounded by `<S>-green`, from the first firing on.

## One firing

Work through these in order;
each stage is skippable when it has nothing to do.
Two scripts carry the mechanical parts:
`scripts/series-check.sh`
(read-only — walks every series, classifies from the harvest,
prints one verdict each:
ADVANCE / WAIT / RETRY `<sha>` / REPAIR `<sha>` / IDLE)
and `scripts/series-advance.sh <S>`
(stages 3–4 — fast-forwards `-green`,
moves `-build-base` by vendored-SHA match,
extends `-dev` by ≤ 100;
refuses on any failure or non-fast-forward).
Judgement — repairs, review, vendoring — stays here.

### 1. Vendor onto `<S>-build`

```sh
scripts/vendor-one.sh --commits 100 <upstream-clone>
```

The script gates itself:
after each vendored commit it syntax-checks the glue
against the freshly vendored headers
(~20 s, flags derived from `R CMD SHLIB -n`, no link, no R session)
and **stops at the first failure**
with the breaking vendor commit at HEAD and the upstream clone kept.
Then:

1. fix the glue — `src/*.cpp`, `src/include/`, not `src/duckdb/`;
2. `clang-format -i src/*.{c,cc,cpp,h,hpp}` — CI fails any diff;
3. amend into HEAD, appending an `R-side fix` section
   naming the upstream change and what was adapted;
4. rerun the script to finish the budget.

If no glue fix can help
because the vendored tree itself is broken at that commit,
vendor on and fold the broken commit
into the upstream commit that repairs it —
the fold rule in stage 2;
the broken tree never stands alone on the chain.

Push `<S>-build` unconditionally —
red never blocks the buffer, that is the point of it.
Tests, R code and patches are `-dev`'s concern;
do not edit `src/duckdb/` by hand in this stage.

### 2. Repair the oldest `<S>-dev` failure

Read the harvest on branch `rcc`
for every commit in `<S>-green..<S>-dev` —
`runs2.d/<xx>/<sha>.ndjson` per commit,
or `runs2.ndjson`, which holds the same records concatenated.
That range is the loop's whole world:
nothing at or before `<S>-green` is ever re-examined.
A commit **missing** from the harvest has not completed —
wait, do not guess.
`each.yaml`'s legs publish a record within seconds of deciding a commit
(see [`EACH.md`](../../scripts/EACH.md) §3),
so missing now means undecided, not merely uncollected.

If a commit is still missing after **12 hours**, presume its run lost —
but only after trying hard to rule that out from what git can see:
the harvest may be stale
(check the age of the `rcc` branch tip against its 30-minute schedule),
and the run may simply be queued
(runner throughput is roughly 35–40 commits per hour,
so a long tail behind a large push is normal).
Review whatever CI state is reachable before concluding loss.
Only then self-heal:
push `retry-<S>-dev` at the first commit with missing state
(*Rerun one commit*, below).
A missing status needs nothing forced —
the commit is planned by the ordinary rule —
and `<S>-dev` is not touched at all,
so no descendant is re-minted and no verified run is discarded.
Never amend a commit that has a record;
that discards a verified result —
and a rerun no longer needs the amend.

Classify each `failure` by what its log (`logs2/<sha>.log`) **contains**:

| evidence | meaning | action |
|---|---|---|
| `Updating snapshots: '…'` | engine output drifted, or a flavor-dependent snapshot | fold the corrected files from `snapshot-<sha>-rcc-smoke-null` |
| `Error ('test-….R:N:M')` | real test failure | fix test/R code at origin |
| the cause is in `src/duckdb/` itself and a later vendor commit fixes it | upstream was transiently broken | fold the vendor commits into one (below) |
| `Changes detected in workflow_dispatch build` | style / roxygen drift | fix formatting at origin |
| a gate reached out and was refused — `cannot open URL`, `SSL connect error`, a refused or reset connection — while the tests themselves passed | infra, not the tree | rerun the commit: `retry-<S>-dev` (below) |
| none of the above and no test phase | cancelled or infra | rerun the commit: `retry-<S>-dev` (below) |

Never classify by absence of a marker:
`"Job is waiting for a hosted runner"` appears in every log
and means nothing.

Repair the **oldest** failure first — later reds usually inherit it.
Fold the fix into the offending commit
(extend its message with what was adapted: tests, R code, patches),
replay the tail, force-push `<S>-dev`.
If other failures have a demonstrably different cause,
they may be fixed in the same pass;
otherwise let CI re-judge the tail.

**A transiently broken upstream commit is folded away, not fixed.**
When the failure's cause lies in the vendored tree itself —
upstream did not build or pass at that commit —
and a later vendor commit (usually the next) repairs it,
there is nothing to adapt on the R side:
fold the failing vendor commit into the one that fixes it,
so the broken tree never stands alone on the chain.
One commit remains, carrying the newer commit's tree
(the gap this leaves in the fifth version component is fine —
the counter orders, it does not count)
and a **carefully reconstructed message**:
keep the newer commit's `vendor: … duckdb/duckdb@<sha>` subject,
because the subject is machine-readable state
and must name the tree's actual upstream commit;
move the folded commit's upstream SHA and subject into the body,
marked as folded because it does not pass on its own;
keep any `R-side fix` sections from both.
If upstream stayed broken for a span,
the whole span folds into the commit that repairs it.
Mirror the fold in `<S>-build` (force-push; it carries no CI),
so the buffer never again offers the broken commit
and `-build`/`-dev` equivalence by vendored SHA stays intact.
Paid for on the rewind chain:
a transient upstream build failure had to be squashed into its follow-up.

Before force-pushing a repair,
**build and check it locally** at the repaired commit
with `scripts/rcc-one.sh` (#59) —
the per-commit gate extracted from CI's `rcc-smoke`,
so the local verdict is CI's verdict, not an approximation of it.
Run the full gate when time allows,
or the stages the repair touches when it does not;
`git clean -fdx -- src/` first either way.
(Until #59 is available:
`R CMD INSTALL` plus `testthat::test_local()`.)
A CI round trip costs ~35 minutes plus queue and harvest;
a local pass costs ~10.
One local pass that catches a bad repair saves a full cycle,
and a repair that was not run locally is a guess.
The exception is a reviewed snapshot fold
whose diff matches the upstream change exactly —
that class has been verified end to end
and may go straight to CI.

**On a forward series, mine the base series before deriving anything.**
The base `<S>-dev` (for `<S>-fwd`) once verified the same upstream commits:
find the equivalent commit by its vendored `duckdb/duckdb@<sha>` subject,
and the amendments folded there —
tests, R code, patches;
the delta between that `-dev` commit and its `-build` equivalent —
are proven fixes.
Carrying them over beats rederiving them,
and their commit-message trailers say what they were for.
Mining is what *forwarding* costs, and only forwarding:
a forward series rebased onto a newer mainline
(`series-rebase.md`) leaves nothing to mine,
because its repairs are still commits on `-fwd-dev`.
CI still judges the result like any other repair.

For snapshot drift,
CI has already computed the corrected files
and pushed them to `snapshot-<sha>-rcc-smoke-null` —
a commit on top of the failing one
carrying the new `tests/testthat/_snaps/*.md`.
Fetch, **review the diff carefully**, and fold.
The diff must read as the engine change the vendor commit describes;
accepting it is accepting new behaviour as correct,
so it deserves the same scrutiny as a code review.
A **deleted** snapshot file is a bad sign —
a snapshot only disappears when its test stopped running,
which is its own failure.
If the diff is surprising in any way, do not fold blind:
build locally and run the checks —
`scripts/snapshot-accept.sh <commit> <name>…`
does build → test → accept → re-test
and leaves the corrected files in the working tree.
CI's files were once verified byte-identical
to a local build-and-accept,
so the shortcut is sound for diffs
that look exactly like the upstream change —
the review is what earns it.
The branches are per-run;
read the one for the sha being repaired.

### 3. Advance `<S>-green` and `<S>-build-base`

Fast-forward `<S>-green` to the newest `<S>-dev` commit
such that every commit in `<S>-green..<that commit>` has a `success` run.
The range bounds the walk:
everything at or before `<S>-green` is trusted —
verified by this loop,
or accepted as the series' seed on day one —
and is never re-examined.
Move `<S>-build-base` to the `<S>-build` commit
with the same vendored upstream SHA
(day one: the seed tip, before any vendor commit is consumed).
Fast-forward only —
if `-green` cannot fast-forward, something rewrote verified history;
stop and say so.

### 4. Extend `<S>-dev`

If everything between `<S>-green` and the `<S>-dev` tip is green
(or the tip equals `-green`),
append the next ≤ 100 commits from `<S>-build` and push.
While `-dev` sits on `-build`'s line this is a plain ref move;
after a repair it is a replay of the buffer commits
onto the repaired tip —
`series-advance.sh` does both,
anchoring on the `-build` commit equivalent to the `-dev` tip.
Exception: a series with a **live** forward counterpart
(`<S>-fwd-build` exists and is not cutover litter)
is being replaced —
verify and promote it, but do not extend it.
`each.yaml` triggers one `rcc` run per new commit;
`rcc-logs.yaml` harvests results to branch `rcc` every 30 minutes,
which is below build time (~35 min).

## Rerun one commit: `retry-<S>-dev`

Some runs fail for reasons the commit had no part in:
a CDN that refused the TLS handshake in the `pkgdown` gate,
a leg cancelled mid-flight, a runner that never reported.
The tree is fine and the verdict is wrong,
so the commit needs judging again, not repairing.

Amending does rerun it —
the fresh committer timestamp alone mints a new SHA,
and `each.yaml` schedules runs for commits without a status —
but it re-mints every descendant with it.
The `pkgdown` flake this was written for sat 22 green commits
below the `main-fwd-dev` tip:
amending would have thrown away 22 verified builds to reprint one.

So ask for that one commit to be judged again, beside the series:

```sh
git push --force-with-lease origin \
  "<the failing commit>:refs/heads/retry-<S>-dev"
```

One ref, no rewrite; `<S>-dev` does not move
and the chain the loop walks never learns anything happened.
`-dev` is what `each.yaml` triggers on,
and the name is the series' own branch with a prefix,
which is the whole trick:
`each-plan.sh` strips `retry-` and anchors the scan on `<S>-green`,
so the bound comes from the ref
that already marks how far the series is trusted.
The retry branch needs no ref of its own for it.
The rerun writes a fresh `rcc` status on the **same SHA**.

**The tip is what is being asked about.**
Only it is replanned in spite of its verdict;
the rest of `<S>-green..tip` keeps the ordinary
build-it-if-it-has-no-status rule,
so a run lost further down the range comes back in the same pass.
A retry branch naming a series with no green plans nothing at all:
without the anchor the scan falls back to
first-parent history since `SINCE`,
which reaches past the seed into `main`,
where no commit carries an `rcc` status —
14 of them, for the failure this was written for,
every one queued as a build.

**The branch is the ledger, and nothing deletes it.**
`retry-<S>-dev` already **on this commit** means
it has had its one rerun and failed again:
the failure is not transient, whatever the log looks like.
Classify it from the new log and repair it for real.
Pointing anywhere else, it is a spent retry of an earlier commit
and says nothing about this one — force-update it and rerun.
`series-check.sh` reads the ledger the same way:
the failure a retry branch sits on is REPAIR, never RETRY.
One ref per series, so it records the retry in flight,
not the history of them.

The verdict reaches the loop the ordinary way.
A commit's record lives twice on `rcc` —
`runs2.d/<xx>/<sha>.ndjson`, which the leg publishes within seconds,
and a line in `runs2.ndjson`, which `rcc-merge.sh` keeps level with it.
Readers take the per-commit record first,
so `each-harvest.sh` and the leg both *replace* it rather than appending;
that is the one case where a decided commit legitimately changes state.

**Deleting a record by hand means deleting both.**
Dropping only the line from `runs2.ndjson` does nothing:
readers still find the record, and the next `rcc-merge.sh`
re-appends the line from the part that is still there.
To drop a commit's result, remove
`runs2.d/<xx>/<sha>.ndjson`, its line in `runs2.ndjson`,
and `logs2/<sha>.log`;
then the scheduled backstop re-derives all of it from the fresh status.

**Both mechanisms live in the tree at the commit under retry.**
`each.yaml` and its scripts are read from the retried ref, not from `main`,
so a series whose commits predate them retries by hand:
push the branch, dispatch `each-rcc` on `retry-<S>-dev`
with `force=true` and `max-commits=1`,
and drop the stale record from `rcc` once the rerun is green —
both copies of it, per above.
A rebase onto a newer mainline (`series-rebase.md`)
is what carries the automatic path into a forward series.

## Commit-message contract

- `-build`: the vendor message as `vendor-one.sh` writes it,
  plus an `R-side fix` section when the glue was adapted in that commit.
- `-dev`: the same message,
  extended with any test / R code / patch adaptations
  folded in during repair.

## Traps, all paid for once already

- **Clean every build product between local builds** —
  `git clean -fdx -- src/`.
  A stale object for a source upstream folded into a unity file
  links as a duplicate-symbol error,
  and `.so`, `Makevars.duckdb` and dependency files
  go stale the same way.
  `git clean` never touches tracked files,
  so uncommitted *edits* survive —
  but an uncommitted *new* file under `src/` would be deleted;
  commit or stage it first.
- **clang-format must be clean.**
  The per-commit runs are `workflow_dispatch`;
  `.github/workflows/commit/action.yml` turns any diff
  from the style, roxygenize or snapshot steps into `exit 1`.
  One unsorted `#include` once turned 858 commits red;
  no local build shows it.
- **Never `git reset --hard` while HEAD is on a branch you keep** —
  detach first.
  A probe once truncated the working branch to its own position.
- **Restore whole directories, not touched files**,
  when replaying over a base that owns them
  (`.github` in particular).

## Invariants

- `<S>-green` and `<S>-build-base` move forward only.
- A base is advanced on completed, successful runs —
  never on absence of a failure.
- Fixes are folded into the commit that needs them,
  never stacked on top:
  every commit of `<S>-dev` must remain independently green
  so the chain stays bisectable.
- Git alone is sufficient in principle:
  even a rerun is one pushed ref —
  `retry-<S>-dev`, which asks for one commit to be judged again
  without rewriting anything —
  and `each.yaml` schedules runs
  for any commit in `<S>-green..tip` without a status.
  When richer tools are available
  (CI log retrieval, the Actions API),
  use them — they shorten diagnosis —
  but never depend on them.
