# Snapshots

How the suite records expected output as snapshot files,
and how a changed snapshot is accepted —
deliberately, because accepting one asserts that the new output is correct.

## What a snapshot records

Snapshot expectations are testthat's.
`expect_snapshot()` calls are spread over `tests/testthat/`,
and the text they captured lives in `tests/testthat/_snaps/<file>.md` —
one Markdown file per test file,
one section per test, holding the code and its printed output.
Running them is running the suite
([`testing/suite/`](/handbook/testing/suite/README.md));
whether they run at all under CRAN's rules is
[`testing/guards/`](/handbook/testing/guards/README.md).

Much of the recorded text comes from the engine rather than from R:
error messages and the position they point at, type names,
`EXPLAIN` plans, the storage summary.
A snapshot therefore drifts whenever a vendored DuckDB changes its output,
which is why snapshot repair is a routine part of vendoring
([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).

The one thing a snapshot must not record is the package's own name.
Every flavor but the mainline one ships under a different name
([`branches/flavors/`](/handbook/branches/flavors/README.md)),
and anything derived from `get_package_name()` carries that name into
the output it produces —
the session storage home most visibly.
`scripts/lts.patch` deliberately does not rewrite `tests/testthat/_snaps/`,
so a file recorded on one flavor could never match another.
`tests/testthat/helper-snapshot.R` normalises at capture time instead:
pass `transform = transform_package_name` to any expectation
whose output can contain the package name,
and every flavor records the same text.

## Accepting a changed snapshot

Every route ends in `testthat::snapshot_accept()`,
which promotes the output of the last run to be the recorded one.
They differ in who reads the diff, and when.

**By hand.**
Run the failing test, call `testthat::snapshot_accept("<name>")`,
run it again to confirm it holds.

**In CI.**
`.github/workflows/update-snapshots/` is a composite action
wired into the R-CMD-check jobs
([`operations/ci/workflows/`](/handbook/operations/ci/workflows/README.md)).
It greps `tests/testthat/test-*.R` for the literal string `snapshot`,
runs `testthat::test_local()` over just those files
with `TESTTHAT_PARALLEL=FALSE`,
and if any of them failed *or warned*
calls `testthat::snapshot_accept()` with no argument —
accepting all of them at once.
Where the result goes depends on the event.
Outside a pull request it opens a pull request
from `snapshot-<base>-<job>-<matrix>`
carrying nothing but `tests/testthat/_snaps`,
and then fails the job on purpose,
so a red build is what announces the drift.
On a pull request it opens nothing:
the accepted files stay in the working tree
for the later `commit` step,
which pushes them onto the branch,
or — for a pull request from a fork —
uploads them as a patch artifact and fails.
A custom build opts out by setting `SKIP_UPDATE_SNAPSHOTS=true`.
Per-commit builds mirror the same step
and publish the accepted files as a `snapshot-<sha>-rcc-smoke-null` branch
([`operations/ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)).

**For one commit deep in a series.**
`scripts/snapshot-accept.sh <commit-ish> <snapshot-name>...`
is the fallback when no `snapshot-<sha>-rcc-smoke-null` branch exists,
or when its diff does not survive review.
It checks the commit out detached —
a probe must never move a branch ref —
wipes `src/` with `git clean -fdx`,
because a stale object for a source that upstream has since folded
into a unity file links as a duplicate-symbol error,
installs, runs the suite,
accepts each named snapshot,
and re-runs to confirm the accepted files hold.
It leaves them under `tests/testthat/_snaps/` in the working tree
and prints them;
folding them into the offending commit is the caller's job.

## When accepting is right, and when it hides a regression

Accepting is right when the diff reads as the change that caused it.
A vendored engine commit that reworded an error,
moved a reported error position,
renamed a type, or changed a plan's layout
should show up in `_snaps/` as exactly that and nothing more.
Folding the accepted files into the commit that changed the behaviour
then keeps the history honest:
the commit that moved the output is the commit that carries
the new expectation.
Accepting is accepting new behaviour as correct,
so it deserves the same scrutiny as a code review.

Accepting hides a regression when:

* **A snapshot file, or a section of one, disappears.**
  Recorded output is only dropped when its test stopped running —
  a skip that now fires, an error raised before the expectation,
  a helper that no longer loads.
  That is a failure in its own right,
  and accepting it deletes the evidence.
* **The diff is wider than its cause.**
  A change to one operator that moves snapshots
  of tests it has no business touching
  is a signal to find out why, not to record it.
* **Output turned into an error, or an error lost its detail.**
  A message that keeps its class but drops its position or its context
  is a regression wearing the shape of a rewording.
* **Nothing explains it.**
  Output that moved with no engine change behind it
  is an R-layer change nobody made on purpose.
* **The text differs only by the package name.**
  That is a missing `transform = transform_package_name`,
  not drift;
  accepting it records a file that is wrong on every other flavor.
* **The output is not deterministic.**
  A one-shot warning fires for whichever test reaches it first,
  so its snapshot depends on test order,
  and accepting simply freezes one run's ordering.
  The repair is to make the output stable —
  by excluding the case, or by pinning the order —
  not to re-record it after every reshuffle.

CI's blanket accept is a diff producer, not a verdict.
It accepts everything that failed or warned,
real failures included,
and then fails the build precisely so that a person reads the result.
A `snapshot-…` pull request is never merged unread.
If the diff is surprising in any way, do not fold it blind:
rebuild locally with `scripts/snapshot-accept.sh` and compare.
When a reviewed fold may skip the local pass
is the series loop's call
([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md));
reading snapshot drift out of a red run is
[`operations/vendoring/troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md).
