# Snapshots

What the recorded snapshot output asserts,
and how a changed snapshot is accepted — deliberately,
because accepting one asserts the new output is correct.

`expect_snapshot()` output lives in
`tests/testthat/_snaps/<file>.md`, one file per test file.
Much of the recorded text is the *engine's* —
error messages and positions, type names, `EXPLAIN` plans —
so snapshots drift whenever a vendored DuckDB changes its output,
and snapshot repair is a routine part of vendoring
([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).

A snapshot must never record the package's own name:
[`scripts/flavor.patch`](/scripts/flavor.patch) does not rewrite
`_snaps/`, so one recorded file has to serve every flavor.
Pass `transform = transform_package_name`
(`tests/testthat/helper-snapshot.R`) to any expectation whose
output can carry the name.

**A skip in a snapshot file goes inside `test_that()`.**
testthat rewrites `_snaps/<file>.md` from the snapshots the run actually
took, and restores a skipped one only when the skip is recorded against a
named test.
A skip at the top of the file aborts before any test starts,
so nothing is recorded, every snapshot in the file counts as unused,
and the whole `.md` is deleted —
which the `update-snapshots` action then publishes as a deletion
proposed by whichever platform skipped.
Put `skip_on_os()` and friends in each `test_that()` body instead;
a file-level skip is safe only in a file that takes no snapshots.

**Accepting a changed snapshot.**
Every route ends in `testthat::snapshot_accept()`:

* **By hand** — run the failing test, accept the named snapshot,
  run again to confirm it holds.
* **In CI** — the `update-snapshots` composite action re-runs the
  snapshot tests and publishes the accepted files:
  as a `snapshot-*` pull request (then fails the job so red
  announces the drift), onto the PR branch, or —
  per-commit — as a `snapshot-<sha>-rcc-smoke-null` branch
  ([`ci/per-commit/contract/`](/handbook/operations/ci/per-commit/contract/README.md)).
* **For one commit deep in a series** —
  [`scripts/snapshot-accept.sh`](/scripts/snapshot-accept.sh);
  its header is the procedure.

Accepting is right when the diff reads as the change that caused it,
and the accepted files are folded into the commit
that changed the behaviour — so the commit that moved the output carries the
new expectation.
A diff that does not read that way is a regression being hidden.

*To deepen: absorb the repair procedure from
`scripts/snapshot-accept.sh`'s header.*
