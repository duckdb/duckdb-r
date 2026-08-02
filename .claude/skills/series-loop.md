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

**The subject is what decides, never the path.**
`src/duckdb/` is not a proxy for "vendored here":
the patch stack is applied to the vendored tree in place,
so every CRAN and compiler-warning fix lands under `src/duckdb/`
carrying no upstream SHA —
89 such commits on `main` today.
A pathspec narrows the walk and nothing more;
a reader of this state looks *past* such commits,
and `vendored_sha()` does so 20 deep —
far more than a series stacks above its buffer,
and bounded so the walk ends by itself.
Reading the newest commit that merely *touched* the directory
answers with a commit that vendored nothing,
which is how `scripts/series-advance.sh` came to refuse
branches that had vendored perfectly well.
Should 20 ever not be enough, the helper says so on stderr
rather than answering wrongly; raise it then.

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

Set up first, then work through the stages in order;
each stage is skippable when it has nothing to do, the setup is not.
Three scripts carry the mechanical parts:
`scripts/series-check.sh`
(read-only — walks every series, classifies from the harvest,
prints one verdict each:
ADVANCE / WAIT / RETRY `<sha>` / REPAIR `<sha>` / IDLE,
plus a CUTOVER line for a forward series that has caught up —
a suggestion for a human, stage 6),
`scripts/series-advance.sh <S>`
(stages 3 and 5 — fast-forwards `-green`,
moves `-build-base` by vendored-SHA match,
extends `-dev` by ≤ 100;
refuses on any failure or non-fast-forward),
and `scripts/series-port.sh <S>`
(stage 4 — brings `<S>-dev` level with `main`:
cherry-picks plus a tooling sync).
Judgement — repairs, review, vendoring — stays here.

### 0. Setup

**Every branch, whole history, with tags.**
A firing reads across all of them, and a narrowed clone fails quietly
rather than loudly:

```sh
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  git fetch --unshallow origin
fi
git fetch --prune --tags origin
```

`--depth` implies `--single-branch`, and a checkout made that way
sees no `*-build` refs at all —
so a firing on one enumerates zero series
and reports a clean pass over nothing.
Depth costs more subtly:
`vendored_sha()` walks 20 subjects deep,
`series-port.sh` needs a merge base with `main`
and patch-ids to dedupe against,
stage 3 asks whether green is an ancestor of dev,
and every one of those meets the graft boundary
and answers wrong or refuses.
Tags are not optional either:
`vendor-one.sh` reads `git describe --tags` for the version it stamps.

**Read the open PRs, and use judgement about them.**
List the ones touching `.github/`, `scripts/` or `.claude/` —
the paths stage 4 ports —
and read the ones that change vendoring logic:
`vendor-one.sh`, the `series-*` scripts, `each*`, `rcc*`, these skills.
Earlier firings opened them, and an open PR is tooling
the series does **not** have:
stage 4 ports what `main` carries,
and `main` carries only what merged.

So each one is context for this firing, not an instruction to it.
A PR that documents a bug says a workaround is still to be paid,
and saves re-diagnosing from scratch what a previous firing wrote up.
A PR that is *changing* a behaviour says something else:
what looks like a fresh bug may be the thing already being fixed,
and repairing against the old behaviour wastes the repair.
Neither is a reason to wait for review,
and none of them is applied early —
the series gets a tooling change when it merges and stage 4 ports it,
never before.

### 1. Vendor onto `<S>-build`

Run **`main`'s copy of the script**, against the buffer worktree:

```sh
VENDOR_REPO=<S>-build-worktree \
  <main-checkout>/scripts/vendor-one.sh --commits 100 <upstream-clone>
```

This stage is the one place the port stage cannot reach.
Stage 4 brings `.github/`, `scripts/` and `.claude/` on `<S>-dev`
level with `main` every firing,
but `-build` carries no ports by design —
its tooling refreshes only at a forward,
so a buffer opened last month vendors with last month's script.
Invoking `main`'s copy closes that
without teaching CI to read another branch's tree:
it is a script the routine runs, not a cross-branch reference.

Only the script comes from `main`.
Everything it invokes by relative path —
`scripts/rconfigure.py`, `patch/*.patch`, `./configure` —
stays the buffer's,
because those are coupled to the vendored tree
they generate and patch.

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
into the next one, when that repairs it —
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
(see [`EACH.md`](/scripts/EACH.md) §3),
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

Before diagnosing anything twice,
check the open PRs read during setup:
a failure an earlier firing already wrote up
is one to work around, not to re-derive.

Classify each `failure` by what its log (`logs2/<sha>.log`) **contains**:

| evidence | meaning | action |
|---|---|---|
| `Updating snapshots: '…'` | engine output drifted, or a flavor-dependent snapshot | fold the corrected files from `snapshot-<sha>-rcc-smoke-null` |
| `Error ('test-….R:N:M')` | real test failure | fix test/R code at origin |
| the cause is in `src/duckdb/` itself and the next upstream commit fixes it | upstream was transiently broken | fold the pair into one; if the next one is red too, forward-port (below) |
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

**A transiently broken upstream commit is folded into the next one,
when the next one fixes it.**
Squash the adjacent pair, and only that pair.
Keep the newer commit's `vendor: … duckdb/duckdb@<sha>` subject —
the subject is machine-readable state and must name the tree it carries —
and record the folded SHA and subject in the body,
marked as not passing on its own.
Keep any `R-side fix` sections from both.
The gap this leaves in the fifth component is fine:
the counter orders, it does not count.
Mirror the fold in `<S>-build` (force-push; it carries no CI).

**Forward-port only when the next commit is red too** —
the build stays red for at least one commit that has to remain,
and there is no adjacent green tree to squash into.
Then re-root the fixing diff into `patch/00NN-*.patch`,
fold that into the breaking vendor commit
with an `R-side fix` section,
and let it retire itself:
every vendor run deletes a patch that no longer applies,
so the commit reaching upstream's fix drops it as part of itself.

Both treatments, and how to choose, are spelt out in
[`handbook/operations/vendoring/troubleshooting/`](/handbook/operations/vendoring/troubleshooting/).

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

### 4. Port from `main`

The goal is identity, not curation:
after this stage,
`.github/`, `scripts/` and `.claude/` on `<S>-dev`
are byte-identical to `main`'s.
CI reads workflows and scripts from the branch it checks,
so this is what puts a fix into effect —
never park a tooling change to wait for a forward.

```sh
scripts/series-port.sh <S>                  # list candidates + identity check
scripts/series-port.sh <S> --apply          # cherry-pick all, sync, push
scripts/series-port.sh <S> --apply <sha>…   # a chosen subset instead
```

The script lists **every** commit `main` has that the series lacks,
oldest first,
classified TOOLING / MIXED / OTHER / VENDOR by what it touches,
and applies all but VENDOR by default.
A MIXED or OTHER commit is a *forward-port*
in `BRANCHES.md`'s sense (invariant S4):
`-dev` has always been vendor commits
plus cherry-picks of `main` commits,
and the port merely batches what used to be manual —
judged by CI like every `-dev` commit.
Picks are whole commits, never split:
a wholesale pick matches its `main` commit by patch-id,
so the next rebase skips it silently,
while a tooling-only half of a MIXED commit would replay —
at best to empty, at worst to a conflict —
and could sever a coupled change
(a script from the test that exercises it),
minting a commit whose message describes more than it contains.
VENDOR commits are listed and never auto-picked:
`main`'s engine is not this series' engine,
and the series' own vendoring owns that strand.
**The subject is what decides one, never the path** —
the same rule as everywhere else in this skill.
The patch stack is applied to the vendored tree in place,
so CRAN and compiler-warning fixes land under `src/duckdb/`
carrying no upstream SHA;
excluding them by path made exactly those fixes wait for a forward,
which is the one thing the port exists to end.
They are ordinary commits, ported like any other.
Port volume threatens nothing either:
the readers of the strand — `vendored_sha()` in stage 5,
the base scan in `vendor-one.sh` — look *past* such commits by subject,
bounded, and say so on stderr when the bound is exhausted,
so a ported commit is invisible to them whatever it touched.
After the picks the script closes whatever tooling delta remains
with one sync commit taking `main`'s tooling tree verbatim,
so the identity goal holds even where history diverged
(adaptations folded into vendor commits during repair,
picks dropped as empty).
In steady state the residue is empty and no sync commit is created.
When one appears, read its diff —
it is the residue the commit walk could not explain —
and treat anything it reverts that the series genuinely needs
as a finding for `main`:
make it conditional there;
a series never keeps its own fork of the tooling.

What stays judgement:

- a conflict stops the sequence in place —
  resolve it in the kept worktree toward `main`'s intent,
  keeping the series' flavor where the two meet
  (`Package:`, `@useDynLib`, `DUCKDB_PACKAGE_NAME`
  keep the series' name),
  `cherry-pick --continue` through the rest, push,
  and rerun the script to finish
  (reruns are exact:
  clean picks dedupe by patch-id,
  resolved ones by their `cherry picked from` trailer);
- an OTHER commit that cannot work against this series' engine —
  apply an explicit subset without it,
  fix it on `main` (a guard, a runtime seam),
  and port the fixed commit instead;
- a series with a live forward counterpart is being replaced —
  port only what its remaining verification needs.

Ported and sync commits are ordinary `-dev` commits:
green per commit like everything else,
vendoring nothing —
the consumption anchor of stage 5 reads vendor subjects
and does not see them —
and transient:
a forward's seed already carries their content
and the replay leaves them behind (`series-forward.md`);
a rebase drops patch-id equivalents,
and a sync commit whose delta `main` absorbed
rebases to empty and is dropped the same way (`series-rebase.md`).

### 5. Extend `<S>-dev`

Append the next ≤ 100 commits from `<S>-build` and push,
**whether or not the commits already in flight have reported**.
A commit that has not been judged yet is not a reason to hold the buffer:
the budget is 100 and the buffer is rarely near it,
so waiting for a full CI cycle before topping it up
costs a cycle per firing and buys nothing —
`each.yaml` plans every commit in `<S>-green..tip` without a status,
so a longer tip is simply more work planned in the same pass.

A **known failure** does stop the stage.
Once a commit in `<S>-green..<S>-dev` has reported `failure`,
stage 2 is going to fold a fix into it and replay everything above,
so anything appended now is work minted only to be re-minted.
Extend on pending, never on red.
While `-dev` sits on `-build`'s line this is a plain ref move;
after a repair it is a replay of the buffer commits
onto the repaired tip —
which is where the version counter is lost:
the `ours-version` merge driver keeps green's `Version:`
through every replayed commit,
so **restamp the fifth component before pushing**
(invariant below) —
`series-advance.sh` does both,
anchoring on the `-build` commit equivalent to
`-dev`'s newest **vendor** commit.
Not its tip: `-dev` also carries commits that vendor nothing —
tooling cherry-picked from `main`,
the adaptations folded in during repair,
and the patch-stack fixes that edit `src/duckdb/` in place
without vendoring anything —
and the anchor is about how much of the buffer has been consumed,
which only vendor commits record.
Exception: a series with a **live** forward counterpart
(`<S>-fwd-build` exists and is not cutover litter)
is being replaced —
verify and promote it, but do not extend it.
`each.yaml` triggers one `rcc` run per new commit;
`rcc-logs.yaml` harvests results to branch `rcc` every 30 minutes,
which is below build time (~35 min).

### 6. Suggest a cutover — never perform one

A forward series that has caught up is **reported, not swapped**.
When `<S>-fwd-green` vendors the upstream commit `<S>-green` vendors,
`series-check.sh` says so beside that series' verdict,
and the firing carries the line into its summary:

```sh
scripts/series-cutover.sh <S> origin <upstream-clone>
```

That is the whole stage.
The routine does not run the script,
and does not swap the four refs by hand instead.

Cutover is the one move that retires a lineage consumers are reading.
Everything else the loop does is bounded and recoverable:
a bad repair is repaired again,
a wrong extension is replayed,
and `-green` only ever moves forward over commits CI called green.
The swap moves a serving green *sideways*
— the single sanctioned non-fast-forward of one (`series-forward.md`) —
and it deletes the counterpart that would let it be undone.
Its coverage gate is also the one gate the loop cannot fully evaluate:
the ancestry check needs an upstream clone,
and degrades to a warning without one,
so an unattended firing would be authorizing the swap on a warning.
Verification is mechanical, so the loop owns it;
deciding that r-universe should build a different lineage today
is not, so a human owns that.

The script enforces its own half:
it refuses to run without a terminal
and takes the series name as confirmation,
so a firing that tries anyway achieves nothing.
Treat that refusal as the answer, not as an obstacle to route around.

### 7. Open a PR for whatever the tooling got wrong

A firing that had to work around a bug in the tooling
owes `main` a PR before it ends.
Not a fix to this firing — a fix to the next one.

**Check what the setup read.**
If an open PR already covers the cause,
**add this firing's evidence to it** rather than opening a second:
two PRs for one cause split the review
and neither one carries the whole case.
If it has been open across several firings, say so in the report —
§5's health signal is workarounds per month,
and a fix waiting for review is a workaround that keeps being paid.
Never merge one yourself to get past it.

**Work around by hand first, then write the PR.**
A fix that the current firing depends on
is a fix nobody can review calmly:
it has to merge now, it merges unreviewed,
and the firing that needed it is over before anyone reads it.
So: unstick the series by hand, finish the firing,
and open a PR that prevents the workaround being needed again.
If the workaround cannot be done by hand,
say so in the report and stop —
that is a finding, not a licence to self-merge.

**One PR per cause, small, against `main`.**
`main` is the source of truth for `.github/`, `scripts/` and `.claude/`;
a series never keeps its own fork of the tooling.
Two bugs in one firing are two PRs,
because they will be reviewed —
and merged, or not — independently.
Link the failing firing as evidence:
the run, the commit, the log line that shows the behaviour.
A reviewer should be able to see the bug happen
without reproducing it.

**The fix reaches the series by itself.**
Once merged, stage 4 ports it into every `-dev` branch
on the next firing.
Nothing has to be carried anywhere by hand,
and nothing waits for a forward —
which is the whole reason the port stage exists.

**What is not a tooling PR.**
A red commit whose cause is the vendored tree,
a flake that a retry settles,
a snapshot that drifted because the engine changed:
those are stage 2 repairs.
The test is whether the *same firing done again* would hit it —
a bug in a script or a workflow would,
an upstream commit that did not build would not.

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
  plus an `R-side fix` section when the glue was adapted in that commit,
  or a transient `patch/` entry was folded in to repair the tree.
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
- Cutover is manual.
  The loop reports that a forward series has caught up
  and prints the command; it never runs it,
  and never swaps the refs by another route.
  Every other ref move in this skill is the routine's to make.
- A base is advanced on completed, successful runs —
  never on absence of a failure.
- Fixes are folded into the commit that needs them,
  never stacked on top:
  every commit of `<S>-dev` must remain independently green
  so the chain stays bisectable.
- **Every vendor commit raises the fifth version component.**
  `DESCRIPTION:Version` must be strictly greater
  than its parent's on every commit that vendors,
  on `-build` and on `-dev` alike.
  The counter is what orders the series —
  r-universe installs by version,
  and a run of commits sharing one version
  is a run r-universe cannot tell apart.
  Gaps are fine; repeats are not.

  The merge driver does not currently deliver this.
  `ours-version` exists so a replay does not conflict
  on the `Version:` line at every single commit,
  and it keeps *our* side — which on a replay onto `<S>-green`
  is green's version, for the whole chain.
  A 40-commit `main-dev` came out of the 2026-08-02 firing
  reading `1.5.99.9003.1039` from end to end.
  Until the driver is fixed,
  **restamp the counter after any replay**
  and before pushing `-dev`:
  walk the new commits oldest first
  and reapply one bump per vendor commit
  from the parent's value.
  Check it, do not assume it —
  a replay that silently froze the counter
  looks exactly like one that did not.
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
