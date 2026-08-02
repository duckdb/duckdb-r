# Troubleshooting

When a vendoring run goes red:
how to tell the failure modes apart, what causes each one, and what it needs.
The repair procedures themselves are playbooks the series loop runs
([`series-loop/`](/handbook/operations/vendoring/series-loop/README.md));
what follows is how to reach the right one.

## Where to look first

[`scripts/series-check.sh`](/scripts/series-check.sh) is the read-only diagnosis.
For every series it walks `<S>-green..<S>-dev`,
looks each commit up in the harvest on branch `rcc`,
and prints one verdict —
`ADVANCE`, `WAIT`, `RETRY <sha>`, `REPAIR <sha>`, or `IDLE` —
beside the in-flight and buffered counts.
It takes no arguments, discovers the series from the refs,
and changes nothing, so it is always safe to run first.

The harvest it reads lives on the orphan branch `rcc`:
one record per commit at `runs2.d/<xx>/<sha>.ndjson`,
a failing commit's whole log at `logs2/<sha>.log`,
and `runs2.ndjson` holding the same records concatenated
for commits that predate the per-commit layout.
A matrix leg publishes its record within seconds of deciding a commit,
and `rcc-logs.yaml` sweeps every 30 minutes for whatever a leg could not publish.
The record is what decides whether a commit counts as judged;
the `rcc` commit status is a display surface on the commit list.
The store's shape and its writers belong to
[`ci/per-commit/`](/handbook/operations/ci/per-commit/README.md).

Three commands answer "what is vendored here, and when did it last move":

```bash
grep duckdb_version R/version.R            # the DuckDB version string
git log -1 --grep="^vendor:" --format=%s   # the upstream commit it came from
git log --oneline --grep="^vendor:" -10    # the last ten vendor commits
```

## The script refuses to start

Both [`vendor.sh`](/scripts/vendor.sh) and
[`vendor-one.sh`](/scripts/vendor-one.sh) abort with
`Error: working directory not clean` before touching anything:
`git status --porcelain` must be empty.
Commit or stash first.
A dirty *upstream* clone is only a warning.
`vendor-one.sh` additionally refuses unless the working directory
is the root of its own git worktree.

## The base scan comes up empty

```
Error: no duckdb/duckdb@ subject among the newest N src/duckdb commit(s)
```

Both scripts recover where the branch stands in upstream history
by scanning back over recent commits that touched `src/duckdb/`
and taking the first `duckdb/duckdb@<sha>` they find in a subject.
The pathspec narrows the walk and the subject decides,
so patch-stack fixes — which edit the vendored tree in place and carry no
upstream SHA — are looked past, twenty commits deep by default.

Coming up empty is not an answer, and neither script guesses.
An empty base makes the enumeration read `..<HEAD>`,
whose missing left side git resolves to the upstream clone's `HEAD` —
a range nobody chose, silently vendoring the wrong span —
so both refuse and name the bound they hit.

Two causes, with different fixes:

* **A vendor subject was reworded or squashed away.**
  The subject line is the only record of the base,
  so restore a well-formed `vendor: … duckdb/duckdb@<sha>` subject;
  its exact format is
  [`pipeline/`](/handbook/operations/vendoring/pipeline/README.md)'s.
* **The branch genuinely stacks more than twenty non-vendoring commits
  under `src/duckdb/`.**
  Raise `BASE_SCAN_DEPTH`.
  The message says the scan hit its bound only when it actually did,
  so its absence points at the first cause instead.
  The same bound is written into `series-advance.sh` and `series-check.sh`
  as a literal twenty, so a branch that needs a raise here needs them changed too.

## The glue gate stops the walk

`vendor-one.sh` syntax-checks the R glue against the freshly vendored headers
after each commit it makes, and stops at the first failure with exit status 3:

```
=== GLUE BROKEN by <sha> (upstream <commit>) ===
Files: ...
```

The gate runs *after* the commit, so the breaking vendor commit is already at
`HEAD`, and the upstream clone is kept rather than removed
so the walk can resume once the glue is fixed.
The failing files are also left in `/tmp/vendor-one-glue-failures.txt`.

The check is `g++ -fsyntax-only` over `src/*.cpp`, four files at a time,
with the compile flags derived from `R CMD SHLIB -n` so they match the local setup.
It costs about twenty seconds, links nothing and starts no R session,
which is what makes it affordable once per commit.
Nearly every upstream break is a C++ API change the glue has to follow,
and the gate catches it here rather than fifteen minutes into a build.

Fix the glue in `src/*.cpp` and `src/include/`, never in `src/duckdb/`,
run `clang-format`, amend into `HEAD` appending an `R-side fix` section
that names the upstream change and what was adapted, then rerun the script.
The fix has to land *in* the vendor commit that needs it:
a follow-up leaves a commit that never built in the history forever
([`branches/invariants/`](/handbook/branches/invariants/README.md)).
The full procedure — including what to do when no glue fix can help
because the vendored tree is broken at that commit — is stage 1 of the
series loop.

One misreading is worth guarding against.
An empty `Files:` list next to
`Error: could not derive glue compile flags (R CMD SHLIB -n)`
means the flags could not be derived, not that every glue file is broken.
Deriving them needs `src/Makevars.rstrtmgr`, which only `./configure` writes;
the gate runs `./configure` itself when the file is missing,
so this is a broken local setup rather than an upstream change.
`--no-check-glue` turns the gate off.

## A patch disappeared from `patch/`

That is by design.
Each vendor run applies every `patch/*.patch` in order,
and a patch whose dry run no longer applies is deleted —
`Removing patch <file>` in the log — with the deletion committed
as part of the vendor commit.
The assumption is that the fix landed upstream.

Verify that assumption rather than trusting it.
If the patch is still needed, restore it and rebase it against the new sources.
The patch stack's lifecycle is
[`pipeline/`](/handbook/operations/vendoring/pipeline/README.md)'s,
and its rules are [Patch Stack](/BRANCHES.md#patch-stack) in `BRANCHES.md`.

## A commit on `-dev` is red

`series-check.sh` names the oldest failure and classifies it
from what its harvested log contains.
`RETRY` means nothing in the commit caused it;
`REPAIR` means the commit has to change.

| in the log | what it is | where it goes |
|---|---|---|
| `Updating snapshots: '…'` | engine output drifted | [`testing/snapshots/`](/handbook/testing/snapshots/README.md) |
| `Error ('test-….R:N:M')` | a real test failure | fix at origin, fold into the commit |
| `Changes detected in workflow_dispatch build` | style or roxygen drift | fix at origin, fold into the commit |
| a refused or reset connection while the tests passed | infrastructure | rerun the commit |
| `exceeded its …s budget -- presumed stuck` | a gate ran out of time | not a flake; rerunning buys the same kill |

Never classify by the absence of a marker:
`Job is waiting for a hosted runner` appears in every log and means nothing.

Repair the oldest failure first — later reds usually inherit it.
Snapshot drift after a vendor commit is the class most often mistaken for a
regression: an engine whose error wording or type list changed makes the
recorded output stale rather than wrong, and the corrected files are already
published on the `snapshot-<sha>-rcc-smoke-null` branch the snapshots gate wrote.
When to accept and when accepting hides a regression is
[`testing/snapshots/`](/handbook/testing/snapshots/README.md)'s call.

A build failure straight after vendoring is almost always a DuckDB C++ API
change: adapt the glue and fold the fix into the vendor commit that broke.
If the R-specific build configuration is at fault instead,
`rconfigure.py` is what changes.
Folding, replaying the tail, and force-pushing `<S>-dev` is stage 2 of the
series loop.

## A commit has no verdict at all

Missing is not failed, and `series-check.sh` says `WAIT` rather than `REPAIR`.
Rule out the cheap explanations from what git can see before doing anything:
the harvest may be stale — compare the age of the `rcc` branch tip against its
thirty-minute schedule — and the run may simply be queued behind a large push.

Only then is the run presumed lost.
The series loop's rule is twelve hours, and its recovery is the
`retry-<S>-dev` ref, which re-judges one commit on its own SHA
instead of amending it and re-minting every descendant.

Nothing schedules a replan.
`each.yaml` fires on push, `workflow_dispatch` and `workflow_call`,
so after a leg dies its undecided commits wait for someone to push to the branch
or dispatch the workflow.
Shards, budgets and what a dead leg leaves behind are
[`ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)'s.

## Diffs that are not changes

`src/*.dd` files that change on every build are spurious;
revert them with `git checkout -- src/*.dd`.
They should only change when a `.cpp` file gains or loses a *local* `#include`,
because `src/include/deps.mk` filters everything under `duckdb/`
out of the recorded dependencies.

Two vendorings of the same upstream commit from different clones
differ in one line of `src/function/table/version/pragma_version.cpp`
and nowhere else;
[`pipeline/`](/handbook/operations/vendoring/pipeline/README.md) explains why,
and why nothing downstream breaks.

## Re-vendoring from scratch

When a tree has to be rebuilt from a known upstream state
rather than repaired commit by commit:

```bash
git clone https://github.com/duckdb/duckdb.git /tmp/duckdb-vendor
git -C /tmp/duckdb-vendor checkout v1.4-andium   # the series' upstream branch
scripts/vendor.sh /tmp/duckdb-vendor
R CMD INSTALL .
```

This produces exactly one vendor commit, at that upstream branch's `HEAD`.
It is a seed, not a catch-up.
A single commit that carries a series forward over however many upstream
commits it skipped breaks the one-commit-per-upstream-commit rule,
and `git bisect` across it answers nothing
([`model/`](/handbook/operations/vendoring/model/README.md)).
Use it to seed a new line or to inspect a tree,
and let `vendor-one.sh` walk a series forward.

## Limits

Two stores still answer "has this commit been judged".
Selection and the loop both read the record on `rcc`,
but the `rcc` commit status is written per commit and shown on the commit list,
and a `pending` status left behind by a leg that died reads like work in
progress when it is not.
Nothing decides from it: a commit without a *record* is undecided
and gets replanned, so the status is safe to disbelieve.
Collapsing the two into one is finding F1 of
[`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md);
[`meta/plans/`](/handbook/meta/plans/README.md) tracks what is live.

`scripts/vendor-gate.sh`, which turned a window of `rcc` statuses into one
`green`/`red`/`stale`/`undecided` verdict for the daily vendoring run,
was retired with the rest of the legacy dispatch path.
`series-check.sh` is what replaced it, and its verdicts are the ones above.
