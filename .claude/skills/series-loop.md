# The series loop: vendor, promote, repair

*Handbook: [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md) —
what this routine is, and when it runs.*

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
| `<S>-build-base` | the routine, force-push | The `<S>-build` commit equivalent to `<S>-green` (same vendored upstream SHA). Marks how much of the buffer has been consumed and verified. A marker with no consumer, recomputed every stage 3. |

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
Five scripts carry the mechanical parts:
`scripts/series-check.sh`
(read-only — walks every series, classifies from the `rcc2` store,
which is stage 2's fallback source, not its first one;
prints one verdict each:
ADVANCE / WAIT / RETRY `<sha>` / REPAIR `<sha>` / IDLE,
plus a CUTOVER line for a forward series that has caught up —
a suggestion for a human, stage 6),
`scripts/series-advance.sh <S>`
(stages 3 and 5 — fast-forwards `-green`,
sets `-build-base` to the vendored-SHA match,
extends `-dev` by ≤ 100;
refuses on any failure, and on a `-green` that would not fast-forward),
`scripts/series-port.sh <S>`
(stage 4 — brings `<S>-dev` level with `main`:
cherry-picks plus a tooling sync),
`scripts/r-universe-check.sh`
(read-only — what r-universe made of every published green, stage 3),
and `scripts/series-glue.sh <S>`
(read-only — every R-side glue adaptation a series carries, in one read;
what stage 2 mines and what a forward replays).
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

**Establish how this firing reads results, once.**
Verdicts and logs come from the `each-rcc` runs that produced them (stage 2),
which needs Actions read access to the repository those runs live in.
Probe it here rather than per commit:
list the most recent `each-rcc` runs.
If that answers, the firing is on the run path for every stage below.
If it does not — no such access from this session at all —
the firing falls back to the `rcc2` store,
which still works, inside its 30-day window,
but is now an **emergency route** rather than a warm copy:
`rcc-logs.yaml` is dispatch-only,
so a firing that needs the store complete has to ask for it
and read the answer on a later pass (below).
Record which one served: the store exists to work around a log access
problem that may have passed, and retiring it waits on firings
that report they never had to open it.

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

**The handbook owns the code; this skill owns ref motion.**
Any change to code, tests or patches is bound by
[`handbook/`](/handbook/README.md)'s page for that area,
which this skill neither repeats nor overrides.
Read the page before changing anything it owns.

### 1. Vendor onto `<S>-build`

Run **`main`'s copy of the script**, against the buffer worktree:

```sh
git -C <upstream-clone> checkout --detach origin/<upstream branch of S>
VENDOR_REPO=<S>-build-worktree \
  <main-checkout>/scripts/vendor-one.sh --commits 100 <upstream-clone>
```

**The clone's HEAD is what picks the line to vendor**, so check it out first.
The script reads it as the walk's right-hand side and nothing else names one;
a clone left wherever the last session parked it
vendors that branch onto this series' buffer.
`main`, `v1.5-variegata` and `v1.4-andium` each track
the `duckdb/duckdb` branch of the same name (`BRANCHES.md`).
The script refuses when the buffer's last vendored commit
is off the clone HEAD's first-parent line,
which is the shape a wrong ref takes;
treat that refusal as the answer and check out the right branch.

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

Every commit in `<S>-green..<S>-dev` was decided by an `each-rcc` leg,
and **the leg's own run is where its result is read**.
That range is the loop's whole world:
nothing at or before `<S>-green` is ever re-examined.

#### Read the results from the runs that produced them

List the `each-rcc` runs on `<S>-dev` and on `retry-<S>-dev`,
newest first, back to when `<S>-green` last moved,
and take each run's `each-logs-<shard>-<attempt>` artifacts —
one per leg, holding, for the commits that leg decided,
exactly what the `rcc2` store holds for them, in the same bytes.
Unzipped:

```
index.ndjson         one line per commit that leg decided
parts/<sha>.ndjson   the record, published as runs2.d/<xx>/<sha>.ndjson
<sha>.log            the log, published as logs2.d/<xx>/<sha>.log
```

`each-shard.sh` writes those files and then *copies* the last two onto the
branch, so the two sources cannot disagree about a verdict —
they differ in reach and in latency, never in content.
Where a commit appears in more than one run —
a retry, a re-run of a leg that died —
the **higher run id wins**, the same rule the store applies to its copy
([`store/`](/handbook/operations/ci/per-commit/store/README.md)).

Fetch through whatever Actions access the firing has:
the GitHub tools (list the workflow's runs, list a run's artifacts,
ask for an artifact's download URL, then `curl` and `unzip` it),
or `gh run download` where a `gh` exists.
Unzip to disk and grep there.
A leg's artifact is tens of megabytes of build output,
and nothing below needs any of it in context:
what a firing reads is one state per commit,
and the tail of the one log it is about to classify.

Artifacts keep for **14 days**, far longer than a commit normally waits
between being pushed and being repaired.
Past that the leg's **job log** carries the same content
inline — `::group::<sha>` opens the commit's section,
its log is printed inside, and `<sha>: <state> (<n>s, exit <rc>)` closes it —
and GitHub keeps job logs far longer than either the artifact
or the store's 30-day window.
Which shard holds which commit is the run's `each-plan` artifact (7 days),
or the group markers themselves.

Two deliberate behaviours mislead a reader who skips them.
A leg **exits 0 even when commits failed** —
a red commit is a result, not a broken leg —
so a run's `conclusion` says nothing about any commit in it,
and asking that run only for its *failed* jobs answers with the jobs that
broke, which are the ones a red commit is not in.
Take the shard jobs, all of them.
And a leg that resumed skips what a previous attempt decided
(`already decided, skipping`), so its artifact covers only what it rebuilt;
the older attempt's artifact is still there, named per attempt, and still counts.

#### When a run cannot be read, consult the store

That is what it is for:
`scripts/series-check.sh`, or `git show origin/rcc2:runs2.d/<xx>/<sha>.ndjson`
with `logs2.d/<xx>/<sha>.log` beside it.
Three cases reach for it —
the firing has no Actions access to the repository the runs live in,
the deciding run has aged out,
or the run is there and its results are not
(a leg that died before it uploaded anything).
Nothing else in this stage changes; the bytes are the same either way.

**The store is an emergency route, and it is not kept warm.**
One writer is still automatic, and it covers almost all of it:
a leg publishes its own verdict seconds after deciding a commit.
Everything else has been retired in the loop's direction of travel —
the per-run fan-in, which reconciled onto the branch
whatever a leg could not publish,
and the periodic sweep, `rcc-logs.yaml` ticking every 30 minutes.
Both were copying what a firing now reads at the source.
So the gap left for the dispatch is the leg that never published:
a run cancelled whole, or a push that failed.

Reaching that gap means asking for the sweep —
through whatever Actions access the firing has,
the same routes stage 2 already reads runs through:
the GitHub tools' run-a-workflow call on `rcc-logs.yaml` at `main`,
or `gh workflow run rcc-logs.yaml --ref main` where a `gh` exists,
or the *Run workflow* button.
A firing with no Actions access at all cannot dispatch it either,
and is reading a copy nobody is refreshing —
which is worth saying plainly in the report rather than working around.

**Dispatch it and move on.** A run takes 2–13 minutes,
and nothing in the firing is worth blocking on it:
finish the stages that do not depend on the missing record,
say in the report that the sweep was dispatched and what it was for,
and let the next firing read the result.
A record that is still absent on that next pass,
after a sweep that completed, is a real absence and not a stale copy —
which is the one question the old schedule could never answer.

`series-check.sh` reads the store and only the store.
Its ref geometry — in flight, buffered, the retry ledger, a ready cutover —
does not depend on where verdicts come from, so run it every firing;
but where its verdict and a run disagree, the run is right,
because the store is the copy.
A store that stopped being written would make the script confidently wrong,
which is a stage 7 PR — teach it the run route — never a repair on the series.

#### A commit with no verdict

It has not been judged: wait, do not guess.
The run list says which kind of waiting it is:

* a run on the branch is queued or in progress — it is coming;
  throughput is roughly 35–40 commits per hour,
  so a long tail behind a large push is normal;
* a completed run planned it but its leg deferred it at the leg deadline,
  or could not check it out — the ordinary rule replans it on the next push;
* no run covers it at all — nothing was ever triggered;
  push, or dispatch `each-rcc` on the branch.

The store answers this one badly, which is worth the run list even on a firing
whose verdicts came from the store:
an absent record can equally mean a queued run, a lost one,
or a sweep that was never dispatched —
and with `rcc-logs.yaml` off its schedule the last of those is the common case,
not the rare one. The run list separates them; the store's tip cannot.

Only when none of those explains it,
and the run that should have decided it finished hours ago saying nothing
about it, presume that run lost.
**12 hours** is the outer bound on being patient, not a licence to skip the
question. Only then self-heal:
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

Classify each `failure` by what the commit's log **contains** —
`<sha>.log` in the leg's artifact, that commit's `::group::` section in the
leg's job log, or `logs2.d/<xx>/<sha>.log` on the store, whichever the firing
is reading; they are the same bytes:

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
A CI round trip costs ~35 minutes plus queue;
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

**Stage 5 now carries the test-side half by itself**
(duckdb/duckdb-r#2594),
so what reaches this stage is what it could not:
a carry that conflicted and was resolved by hand,
and the compile-side half it deliberately leaves alone.
A commit that already carries a `Carried from` trailer
has the base series' fix in it,
so a red on that commit is something else —
check the trailer before mining anything.

**Read the whole set before carrying any one of it across.**
`scripts/series-glue.sh <S>` prints every glue adaptation the series holds,
oldest first, with the upstream SHA each answered
and the `R-side fix` prose each left behind,
and closes with the files ranked by how often they were adapted.
One lookup answers a narrower question than the situation asks:
upstream moves the same call site repeatedly,
each move is a separate commit here,
and only the last version of that glue survives the range.
Match on the failure in front of you alone
and the fix carried over is an intermediate one —
already superseded, further down the very range it was read from.
The ranked file list is the cheapest read of where that is about to happen.
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

### 3. Advance the frontier, and read what r-universe made of the last one

Fast-forward `<S>-green` to the newest `<S>-dev` commit
such that every commit in `<S>-green..<that commit>` has a `success` run.
The range bounds the walk:
everything at or before `<S>-green` is trusted —
verified by this loop,
or accepted as the series' seed on day one —
and is never re-examined.
`-green` is fast-forward only —
if it cannot fast-forward, something rewrote verified history;
stop and say so.
Set `<S>-build-base` to the `<S>-build` commit
with the same vendored upstream SHA
(day one: the seed tip, before any vendor commit is consumed),
force-pushing where the match is not a fast-forward.

**`-build-base` lands on vendor commits only, so it lags.**
The match is by vendored SHA,
and a `-build` commit that vendors nothing carries none —
the `patch/` entries stage 3 commits onto the buffer, in particular.
So a buffer ending in such commits leaves `-build-base` below them
even when green already has their content,
and the *buffered* badge (`-build-base..-build`) overstates by that much:
9 rather than 6 on `main`, 2026-08-04.
It is display-only and self-correcting —
the next verified vendor commit moves the ref past the whole run —
so nudging it onto the newest `-build` commit green demonstrably contains
is a legitimate manual move, not a repair.

**`-build-base` is the one ref of the four that is not fast-forward only.**
It is a marker, not a promise:
nothing consumes it, the match is recomputed from scratch every stage 3,
and where the ref sits today tells the next firing nothing
it does not re-derive.
So the stage **sets** it rather than advancing it,
force-pushing when the match is not a fast-forward,
and the cost of being wrong is one display column
until the next stage 3 recomputes it.
The other three carry their guarantees unchanged:
`-green` fast-forwards only,
`-build` and `-dev` are rewritten only by this loop,
by the rules above.

A ref found off the buffer's line is therefore not a puzzle to solve.
It happened once, on `v1.4-andium`, 2026-08-06:
an auto-update commit landed on `-build` and on `-build-base`
31 seconds apart and left the two siblings,
which the stage then refused as a rewind of verified history.
Set the ref and move on;
diagnosing what wrote it is worth doing only if it recurs.

Do not teach the match to guess:
a patch-id scan finds only the commits
whose content reached `-dev` unsplit,
which on `main` that day was one of three.

#### What r-universe made of it

`<S>-green` is a ref with a consumer,
and that consumer builds it on platforms this loop never sees.
The `rcc` gate is Linux on one R version;
r-universe builds Windows on x86_64 and arm64,
macOS on x86_64 and arm64, and wasm,
against R-devel, release and oldrel,
and runs `R CMD check` on each.
So a series can be green at every commit
and still publish a package that does not compile —
and no `each-rcc` run, on any platform it covers, would ever say so.
This is the read that closes that gap:

```sh
scripts/r-universe-check.sh            # every package, per target, reds only
scripts/r-universe-check.sh --log <id> # the log behind one of them
```

It prints, per package, the version and the commit built —
naming the local ref when this clone knows it,
which is how a red is attributed to a series —
then one line per target that is not OK, with the log URL.
Three access facts it exists to encapsulate, each paid for once:
the `/builds` dashboard answers 403 to some fetchers
while `https://<universe>.r-universe.dev` answers a plain curl;
the build logs live in the GitHub repository `r-universe/<universe>`,
which this project cannot be granted,
but `/api/actions/logs/<job-id>` serves them complete and anonymously;
and `/api/packages` alone **cannot** answer the question,
because its `_binaries` array is one row per artifact —
a target whose build failed outright leaves no row,
and the row from the last version that did build stays,
wearing that older version.
Read as current state it reports success
for a target that has been failing for a fortnight.
The script reads the version-scoped check table for verdicts
and `_binaries` only to say how stale the published binary has become.

Results always describe the **previous** green:
a universe build takes about an hour and starts when the ref moves,
so a firing reads the consequence of an earlier firing's push.
That is why this is a read and never a gate —
nothing here holds stage 3's fast-forward.
The mainline `duckdb` package is built from `duckdb/duckdb-r`, not a series:
a red there is upstream's, and reaches this repository as a PR to `main`.

**A platform DuckDB publishes no extensions for is not a finding.**
The extension install test downloads,
so wherever the repository has no build for this platform
it fails with an HTTP 404 —
about DuckDB's release coverage, not about the commit green points at,
and not something this repository can move.
Which platforms are covered is DuckDB's list and it changes,
so check the current one before spending a diagnosis:
`handbook/usage/extensions/README.md` links it,
and holds whatever the standing gap is.
As of 2026-08 that is `windows-devel-arm64` and `windows-release-arm64`
on every package (duckdb/duckdb-r#2425) —
read past those two and judge the rest of the table.
Only what the list explains:
every other red is a finding until shown otherwise.

**Never undo a push to green.**
A red here is a red on a commit the gate called green,
and the reflex — rewind `-green` to before it — is wrong twice over:
`-green` moves forward only (the invariant below),
and the ref serves a package,
so rewinding publishes an older one
and throws away every verified commit above it
to escape a failure on a platform the gate never covered.
Green stays. The finding travels forward.

**State the finding in the commit message on `-dev`.**
An r-universe failure has no per-commit record anywhere —
not in an `each-rcc` run, not in the store — and no commit of its own;
it lives in a job log that ages out,
in a universe that rebuilds over it.
So write it where the series keeps its memory:
the message of the `-dev` commit that carries the fix,
in an `R-side fix` section like any other adaptation,
naming the target, the verdict and what the log said.
`scripts/series-glue.sh` and the mining step of stage 2 read those messages,
so a forward picks the finding up
instead of rediscovering it from a build that has long since scrolled off.
When there is no fix to carry — an hour budget r-universe overran,
an extension repository with nothing published for a platform —
write it anyway, on the next `-dev` commit the stage produces:
a finding with no repair is still the thing
that stops the next firing diagnosing it from scratch.

**What a fix may be is the handbook's rule, not this skill's.**
A compiler-warning fix is bound by
[`architecture/glue/`](/handbook/architecture/glue/README.md),
which owns the tree's position on suppression;
read it before writing one.
The shapes listed below are shapes, never permission.

**A `patch/` entry is a prototype of an upstream change**,
filed as a pull request and retired when upstream takes it
([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).
So write it as the diff you would send to `duckdb/duckdb`,
and keep the vendored code free of commentary about us:
the reasoning goes in the commit message,
which the patch header carries upstream with it.

**A fix must cost Linux nothing.**
The only gate that will judge it is Linux on one R version,
so a change that helps Windows or macOS is unverifiable where it runs,
and a change that *hurts* Linux is the one outcome that gate does catch —
late, after a replay of everything above it.
Prefer changes that are inert where the gate can see them:
a `patch/` entry whose whole diff sits inside `#if defined(_WIN32)`,
a test skip keyed on a runtime value the engine itself reports,
a cast or an initialization that states an intent the code already has.
Anything broader waits for evidence,
and a local reproduction is evidence:
the compiler a warning names is usually installed here.
Reproduce it, fix it, confirm the diagnostic is gone,
then compile the same translation unit under `g++ -Wall`
and confirm the output is unchanged —
which is what costs-Linux-nothing means as a check
rather than as a claim.
A fix carrying both halves does not wait for r-universe;
the next universe build confirms it in passing.

**Say which flags a reproduction needed.**
The gate compiles with `R CMD config CXXFLAGS`, which is `-g -O2`,
so a `-Wall` diagnostic is invisible to it
and to any local build that does not add the flag by hand.
Adding it is how another platform's warning is reproduced;
recording it is what stops the result reading as the gate's view.

**A fix belongs where its code lives, which is not always `main`.**
A fix that is not series-specific belongs on `main`,
where stage 4 spreads it to every series by itself —
but a `patch/` entry is only portable when the tree it patches is.
`main` carries the engine `main` has vendored,
and a series buffer runs ahead of it,
so a patch written against the newer engine
applies in neither direction on `main`'s tree —
`vendor-one.sh`'s `PATCH BROKEN` exit.
Landing it there breaks the next vendor run
instead of helping any series.
Check that the code exists on `main` before routing a fix through it;
where it does not, the fix is series-specific by engine version,
belongs on `<S>-dev` and `<S>-build`,
and reaches `main` when `main`'s engine reaches the code.

**A `patch/` entry has to reach the buffer too.**
Stage 4 ports `main` onto `<S>-dev` and stops there;
`<S>-build` carries no ports by design (stage 1).
But `vendor-one.sh` applies the **buffer's** `patch/*.patch`
to each tree it regenerates,
so a patch that only ever landed on `-dev`
is absent the next time the buffer vendors,
and the commit that reaches `-dev` from it
arrives broken again on exactly the platform the patch was for.
Commit it onto `<S>-build` as well, in the same firing.

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
classified TOOLING / MIXED / OTHER / VENDOR / VERSION by what it touches,
and applies all but VENDOR and VERSION by default.
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

VERSION commits are listed and never auto-picked either:
`main`'s R-client counter is not this series'.
A `-dev` version says which release line the series was seeded from
and how far its own vendoring has run,
and what `main` is at today is read from `main`
([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
Here the **content** decides, not the subject:
the commit moves `Version:` and carries nothing but release paperwork,
so a bump under a subject other than `fledge:` is held back too,
and a bump riding on real content is not —
that one is a forward-port that happens to bump,
ported whole like any other,
because a pick is never half a commit.

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

**A frozen series takes no ports by default.**
A series seeded from a release branch keeps the R code it was seeded with —
glue, tests, docs and version alike —
so `main`'s development line,
which belongs to another engine's R side,
is not a backlog it is behind on.
`scripts/series-port.sh` reads that off the lineage under the seed
and skips the walk for such a series,
so the sync commit is their whole default port
and their tooling still follows `main`:
a frozen R side is not a frozen CI,
and the identity goal above holds for every series either way.
Run the script for a frozen series like any other;
the default needs no judgement.

**Frozen is not untouchable.**
A change the r-universe build genuinely needs still lands —
a `configure` fix, whatever keeps the flavor green —
and stage 2 reaches for it the same way it mines a base series:
if the red has already been fixed on `main`,
port that commit rather than rederive it.
Name it, one commit at a time:

```sh
scripts/series-port.sh <S> --list            # walk a frozen series anyway
scripts/series-port.sh <S> --apply <sha>…    # take the ones the build needs
```

Explicit SHAs are never second-guessed,
on a frozen series or any other.
What the freeze buys is that nobody has to read
the whole development line every firing
to find the two commits that matter.
The bar is what the build needs, not what `main` happens to have:
a fix that only tidies R code the series is content with
is not a reason to move the series off its seed.

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

**On a forward series, the base's fixes are folded in here.**
`<S>-fwd-build` was replayed out of `<S>-build`,
which holds what the code needs to **compile** —
that being what the vendor gate checks at every commit —
and nothing of what CI demanded after that.
Those live on the base `<S>-dev`,
folded into the commit for the same upstream SHA,
and without this every one of them would be rediscovered
as a red commit costing a repair
and a replay of everything above it.
So as each buffer commit is consumed,
`series-advance.sh` looks its base twin up by vendored SHA
and folds into the same commit
whatever that twin touched and its own `-build` commit did not,
with the twin's message and a `Carried from` trailer.

**The carry is a difference, not a list of directories,
and `src/` is not compile-only territory.**
The buffer already compiles,
so glue the `-dev` twin has *on top* of it
was demanded by something later than the compiler —
a test, a check, a platform r-universe reached and the gate never did —
and holding it back would strand exactly the fixes this exists to move.
The difference is also what stops the glue the buffer already carries
from being applied twice.
Two kinds stay behind, neither of them a judgement about the fix:
the buffer's own strand — `src/duckdb/` and `patch/`,
since a forward regenerates the tree from its own patches —
and what vendoring regenerates:
`R/version.R`, `src/include/sources.mk`, the Makevars, the logos,
which differ between any two vendor runs of the same SHA
and are noise wearing the shape of a fix.

Carried glue is **named as it goes**.
Glue the base `<S>-dev` has and the base `<S>-build` lacks
is buffer drift: a fix folded during a repair
and never mirrored onto the buffer,
so the next tree regenerated there still wants it.
The carry unblocks the forward; mirroring it onto `<S>-build`
is the repair the line is asking for.

**A conflicting carry stops the stage, and it is meant to.**
The commit is picked and the fix will not apply,
because this series has moved the code out from under it —
which is judgement, and guessing costs a wrong commit
on a chain CI is about to judge.
The worktree is kept with the conflict in it, no ref is written, and:

```sh
cd <the worktree it names>          # resolve, then git add
scripts/series-advance.sh <S> --continue     # or --abort to discard
```

`--continue` finishes that commit with the twin's message
and completes the rest of the chunk;
`--abort` throws the worktree away and leaves every ref untouched,
so the next firing simply reaches the same stop.
Starting a fresh run beside a stopped one is refused,
because it would replay over a resolution somebody made.
The push triggers one `each-rcc` run for the commits it added,
and every verdict that run reaches is readable from it
as soon as the leg has written it —
there is nothing to wait for a harvest for.
The store's own writer (the leg's publish;
`rcc-logs.yaml` only when dispatched)
just fills the fallback copy behind it.

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

The verdict reaches the loop the ordinary way — from the rerun's own run.
That run is on `retry-<S>-dev`, so its results name that branch
and carry a higher run id than the run that first judged the commit,
which is what tells the two apart while both exist.
The pre-retry `failure` does not disappear when the retry is pushed:
it stays the newest result for that SHA until the rerun reports,
and repairing on it amends a commit that is about to go green.
The store applies the same newest-run-wins rule to its copy,
so the leg *replaces* a record rather than appending —
the one case where a decided commit legitimately changes state.

**Dropping a result by hand is a store-side operation**,
and only concerns a firing that is reading the store:
remove `runs2.d/<xx>/<sha>.ndjson` and `logs2.d/<xx>/<sha>.log`,
then dispatch `rcc-logs.yaml` to re-derive both from the fresh status,
provided the commit is still inside the store's 30-day window.
The removal alone no longer does anything:
nothing sweeps on a schedule to notice the gap,
so a deletion left unaccompanied is a record simply gone.
A run's own results are immutable;
there a newer run is the only thing that supersedes an older one.

**Both mechanisms live in the tree at the commit under retry.**
`each.yaml` and its scripts are read from the retried ref, not from `main`,
so a series whose commits predate them retries by hand:
push the branch, dispatch `each-rcc` on `retry-<S>-dev`
with `force=true` and `max-commits=1`,
and — on the store path only — drop the stale record once the rerun is green,
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

- `<S>-green` moves forward only.
  `<S>-build-base` does not: it is a marker with no consumer,
  recomputed from the vendored-SHA match every stage 3,
  and set — force-pushed where it has to be — rather than advanced.
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

  A replay does not deliver it while `-dev` and `-build`
  carry different `major.minor.patch` prefixes:
  the merge driver's gate then keeps our side verbatim
  and the counter freezes for the whole chain
  ([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
  `main` is in that state.
  So after any replay, **restamp before pushing `-dev`**:
  walk the new commits oldest first
  and bump once per vendor commit from the parent's value.
  [`scripts/series-advance.sh`](/scripts/series-advance.sh) does that
  and then asserts it;
  a replay done by hand is checked the same way,
  because one that silently froze the counter
  looks exactly like one that did not.
- **Every ref move is git alone.**
  Even a rerun is one pushed ref —
  `retry-<S>-dev`, which asks for one commit to be judged again
  without rewriting anything —
  and `each.yaml` plans runs
  for any commit in `<S>-green..tip` that has no verdict.
  Nothing a firing *writes* needs an API.
- **What a firing reads comes from the runs, and falls back to git.**
  The `each-rcc` run that decided a commit is the source of its verdict
  and its log; the `rcc2` store is a copy, reachable with git alone,
  for a firing that cannot read the runs.
  Neither source may be *required*: a firing that has only one of them
  still finishes, and says in its report which one it had.
  The fallback is an emergency route and is not kept warm:
  `rcc-logs.yaml` is dispatched, never scheduled,
  so a firing that needs the copy complete asks for it
  and reads the answer on a later pass — it never blocks on one.
