# Salvage from the closed handbook wave

*A record, not a leaf.*
Twenty-nine pull requests written against a stub handbook were closed
unmerged in August 2026, superseded by the MVP tree
([#2493](https://github.com/duckdb/duckdb-r/pull/2493),
[#2495](https://github.com/duckdb/duckdb-r/pull/2495),
[#2504](https://github.com/duckdb/duckdb-r/pull/2504)).
Each topic is owned today by its leaf under
[`handbook/`](/handbook/README.md) —
walk down from the root to find it —
and where a finding below and a leaf disagree, the leaf is right.
This file exists so the verified findings those branches carried,
and that no leaf states yet, are not lost with the branches.

Every entry names the file that proves the claim,
the leaf that would own it, and the pull request it came from.
Nothing here is written for a reader who needs the fact today;
it is written for whoever deepens that leaf next,
who should re-verify before writing —
the claims were checked in August 2026 and nothing keeps them current.
The bar applied was
[`meta/authoring/`](/handbook/meta/authoring/README.md)'s ladder,
so most of the wave's prose is not here at all;
what it excluded is listed at the end.

**This record changed its mind once, and says so.**
Its first version sorted the survivors into findings worth writing and a
short tail of defects.
`meta/authoring/` then gained the discussion that precedes the ladder —
is a behaviour that looks wrong actually desirable, or a mere
limitation, and for a limitation, is it cheaper to document or to
remove? — and every survivor was walked through it again, against the
code.
Where the fix is one to three lines with obvious consequences, it is
cheaper than the paragraph, so the entry became an issue and nothing
else.
Where the fix is larger, the behaviour is a limitation for as long as
that takes: it stays deepening material, and carries the issue so the
leaf writes it as provisional.
That reweighing moved two entries out of the findings and into the issue
tracker alone, and moved two more out of the record entirely, because a
leaf or a merged fix now states them better.
The defects listed below are links rather than paragraphs for a separate
reason: an issue can be closed, and this directory is for things that
never move again.

## Deepening material

* **A local commit-by-commit replay must delete `src/*.o` between
  commits, or it means nothing.**
  The `%.dd: %.d` rule in
  [`src/include/deps.mk`](/src/include/deps.mk)
  filters every path under `duckdb/` out of the recorded dependencies,
  so no glue object depends on a vendored engine header.
  After a vendor run `make` therefore does not recompile the glue:
  an upstream API break goes unnoticed
  and the package is linked from objects built against a different
  engine.
  A fresh CI checkout never hits this, which is why it bites only
  locally.
  The filtering is deliberate and the file says why —
  the dependency lists would otherwise carry the whole vendored tree —
  and the pipeline catches the API break by other means,
  compiling the glue against the fresh headers after each commit.
  So the caveat is an operator's, not a bug's.
  *Proof:* `src/include/deps.mk`, and the glue gate in
  [`scripts/vendor-one.sh`](/scripts/vendor-one.sh).
  *Leaf:* [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md),
  or [`build/source-build/`](/handbook/build/source-build/README.md),
  which already owns the `.dd` files.
  *From:* [#2477](https://github.com/duckdb/duckdb-r/pull/2477).

* **An empty `Files:` list from the glue gate is a local setup problem,
  not a broken glue.**
  When it prints
  `Error: could not derive glue compile flags (R CMD SHLIB -n)`
  alongside an empty file list, the flags could not be derived at all.
  Deriving them needs `src/Makevars.rstrtmgr`, which only `./configure`
  writes; the gate runs `./configure` itself when the file is missing,
  so reaching this message means that failed.
  The script has the right answer and discards it — `glue_compiles()`
  returns a distinct 2, and the caller's `!` collapses it into the
  `GLUE BROKEN` path — but recovering it means restructuring an error
  path in a script that pushes commits and exits with documented codes,
  which is not a change a reviewer approves at a glance.
  So this stays a limitation the leaf states while
  [#2513](https://github.com/duckdb/duckdb-r/issues/2513) is open,
  and the trigger and the action are what a reader needs:
  an empty list means the setup, not the glue.
  *Proof:* [`scripts/vendor-one.sh`](/scripts/vendor-one.sh),
  the glue-flag block.
  *Leaf:* [`operations/vendoring/troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md).
  *From:* [#2472](https://github.com/duckdb/duckdb-r/pull/2472).

* **The version merge driver's prefix gate silently declines to
  renumber across a patch release.**
  [`scripts/merge-version.sh`](/scripts/merge-version.sh)
  combines counters only when both sides share a `major.minor.patch`
  prefix, and otherwise keeps ours verbatim.
  The script header states the gate; what it does not state is the
  consequence for a rebase — a series at `1.5.4.9005.N` rebased onto a
  `1.5.5.9000` base leaves every commit at the base version instead of
  producing a rising vendor counter, which then has to be re-applied by
  hand, one commit at a time, as part of the rebase.
  Whether the larger version would be the better answer is
  [#2488](https://github.com/duckdb/duckdb-r/issues/2488),
  which is the boundary the prose carries:
  the gate is deliberate, and the open question is which answer is
  right, not whether the script is broken.
  *Proof:* `scripts/merge-version.sh`.
  *Leaf:* [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).
  *From:* [#2477](https://github.com/duckdb/duckdb-r/pull/2477).

* **`-DDUCKDB_R_BUILD` has exactly one effect on the vendored tree.**
  It replaces the `atomic` next pointer in `SegmentNode` with a plain
  pointer, in
  `src/duckdb/src/include/duckdb/storage/table/segment_tree.hpp`
  (two `#ifndef DUCKDB_R_BUILD` blocks, the member and its `Next()`
  accessor).
  That is the whole of what the define does,
  which makes it the one flag whose name suggests more than it delivers.
  The two blocks are upstream's own, not this repository's:
  nothing under `patch/` mentions the define,
  so it is an accommodation upstream offers and the Makevars opt into.
  *Proof:* that header, and the absence of the define from `patch/`.
  *Leaf:* [`architecture/engine/`](/handbook/architecture/engine/README.md).
  *From:* [#2466](https://github.com/duckdb/duckdb-r/pull/2466).

* **The ALTREP materialization budget stops a runaway query rather than
  truncating it.**
  `AltrepRelationWrapper::Materialize()` converts the cell budget to a
  row budget, pushes a `LimitRelation` of the budget *plus one* row, and
  raises if that extra row comes back — so an over-budget relation
  fails, and a caller never receives a silently shortened frame.
  The same path temporarily doubles `max_expression_depth`, because
  deeply nested relation trees otherwise hit the engine's own limit
  ([#101](https://github.com/duckdb/duckdb-r/issues/101)).
  *Proof:* [`src/reltoaltrep.cpp`](/src/reltoaltrep.cpp).
  *Leaf:* [`architecture/glue/`](/handbook/architecture/glue/README.md),
  which already flags the budget for deepening.
  *From:* [#2484](https://github.com/duckdb/duckdb-r/pull/2484).

* **One hard-coded package qualifier de-evaluates every inline chunk in
  its roxygen block.**
  roxygen2 evaluates inline chunks in the package's own namespace, and
  an unresolvable reference does not raise: the chunk *and its
  neighbours in the same block* are emitted verbatim as `\verb{r ...}`.
  A single qualified reference in [`R/storage.R`](/R/storage.R) also
  took out the `lifecycle::badge()` chunk beside it.
  The regenerated `.Rd` then differs from the committed one and CI fails
  at the `roxygenize` step, before anything is compiled —
  which is why the failure reads as unrelated to the edit that caused
  it.
  The instance is gone from `main`, and the CI step is the guard that
  keeps it gone, so what a leaf owes is the trigger and the action —
  never write the package name into an inline chunk, and read a
  `roxygenize` failure as an unresolvable reference — not the anatomy.
  *Proof:* `R/storage.R` and its generated `man/` page.
  *Leaf:* [`architecture/r-layer/`](/handbook/architecture/r-layer/README.md),
  which states the rule but not this failure mode.
  *From:* [#2480](https://github.com/duckdb/duckdb-r/pull/2480).

* **CI turns the installed-size check off, because it treats every NOTE
  as an error.**
  [`.github/workflows/custom/before-install/action.yml`](/.github/workflows/custom/before-install/action.yml)
  exports `_R_CHECK_PKG_SIZES_=FALSE`.
  The check action runs `r-lib/actions/check-r-package` with
  `error-on: "note"` unless `RCMDCHECK_ERROR_ON` overrides it, so
  without that export the standing package-size NOTE would fail every
  matrix run — the suppression is what makes a strict error level
  usable at all.
  The cost is that a size regression cannot fail a run either, and the
  NOTE is seen at submission time and nowhere earlier.
  *Proof:* that action file, and
  [`.github/workflows/check/action.yml`](/.github/workflows/check/action.yml).
  *Leaf:* [`operations/releases/cran/`](/handbook/operations/releases/cran/README.md),
  which already names the known package-size NOTE as the one blocker
  it tolerates.
  *From:* [#2474](https://github.com/duckdb/duckdb-r/pull/2474).

* **`-j4` is safe on a 16 GB runner, and there is no second parallelism
  knob.**
  Peak RSS was measured at about 834 MB per vendored unity object, so
  four compiles in flight fit with room to spare.
  Nothing else in the build oversubscribes: the package requests no
  `-flto`, R's `Makeconf` reports `LTO =` empty, and `DESCRIPTION`
  carries no `Config/testthat/parallel`, so the suite runs serially.
  A measurement taken in August 2026, on a four-core container;
  the three negatives are checkable at any time.
  *Proof:* [`DESCRIPTION`](/DESCRIPTION), `R CMD config`,
  [`src/Makevars`](/src/Makevars).
  *Leaf:* [`operations/ci/per-commit/legs/`](/handbook/operations/ci/per-commit/legs/README.md).
  *From:* [#2485](https://github.com/duckdb/duckdb-r/pull/2485).

* **The per-invariant enforcement audit.**
  The wave derived, against the scripts, what would actually catch a
  violation: the only continuous mechanical checks are
  [`scripts/series-advance.sh`](/scripts/series-advance.sh)'s
  `git merge-base --is-ancestor` gate before it pushes `-green` or
  `-build-base`, and the vendor counter the pipeline bumps.
  The structural and flavor invariants hold *by construction* — the
  rename is one patch, so its diff is the surface — and the linearity
  and dev-baseline invariants are checked by nothing at all.
  Worth re-deriving rather than trusting, but the shape held.
  That the leaf has nowhere to absorb this from is a defect of its own,
  [#2516](https://github.com/duckdb/duckdb-r/issues/2516).
  *Proof:* `scripts/series-advance.sh`,
  [`scripts/series-check.sh`](/scripts/series-check.sh),
  [`scripts/flavor.patch`](/scripts/flavor.patch).
  *Leaf:* [`branches/invariants/`](/handbook/branches/invariants/README.md).
  *From:* [#2478](https://github.com/duckdb/duckdb-r/pull/2478).

## Defects, filed as issues

Each is a thing to fix rather than a thing to write down, because the
fix is small enough to be cheaper than the paragraph:
a filed defect whose fix is *not* glance-sized is a limitation
meanwhile, and appears above instead, with its issue linked —
[#2513](https://github.com/duckdb/duckdb-r/issues/2513) is the one such
case here.
They are links rather than paragraphs because a defect belongs where it
can be closed, and this directory cannot close anything.

Filed from this reweighing:

* [#2511](https://github.com/duckdb/duckdb-r/issues/2511) —
  `make format-check` dies with a `FileNotFoundError` when
  `cmake-format` is absent, and formats generated CMake files it should
  not touch. The two tracked CMake files are real: they exist to emit
  `compile_commands.json` for clangd, and stay. The fix is deleting the
  CMake handling from `scripts/format.py`.
* [#2512](https://github.com/duckdb/duckdb-r/issues/2512) —
  `BASE_SCAN_DEPTH` raises the base-scan bound in the two vendor
  scripts and not in the two series scripts that hard-code the same
  twenty, which `scripts/VENDORING.md` states the other way round.
  The fix reads the variable in place of the literal, with the same
  default, so it changes nothing until someone sets it.
* [#2519](https://github.com/duckdb/duckdb-r/issues/2519) —
  `plan/done/PLAN-storage-locations.md` still marks the Phase 2
  `.duckdb-r-keep` marker scheme and the library writability probe
  `[x]`, though neither reached `R/` or `NAMESPACE`.

The flavor rename, one file, three wrong statements in the README it
produces — the fix is one change, and a check in
`scripts/flavor-package-name.R` would cover all three:

* [#2517](https://github.com/duckdb/duckdb-r/issues/2517) —
  `## Installation from GitHub` still says
  `pak::pak("duckdb/duckdb-r")`, which installs the mainline package
  rather than the flavor whose README the reader is on.
  Whether a flavor is installable from GitHub at all, and with which
  ref, is
  [`branches/flavors/`](/handbook/branches/flavors/README.md)'s
  question.
* [#2514](https://github.com/duckdb/duckdb-r/issues/2514) —
  the blurb announces LTS version 1.3 on every flavor, because the
  substitution requires a `.` or `_` before the version and that one is
  preceded by a space.
* [#2518](https://github.com/duckdb/duckdb-r/issues/2518) —
  the `# duckdb` H1 sits above every hunk in `scripts/flavor.patch`, so
  every flavor is titled as the mainline package.

`#2517` and `#2518` were surfaced by
[#2510](https://github.com/duckdb/duckdb-r/pull/2510) rather than by the
wave, and are recorded here because they belong beside `#2514`.

Elsewhere in the same scripts, and in the branch documentation:

* [#2515](https://github.com/duckdb/duckdb-r/issues/2515) —
  `scripts/flavor.sh` invokes `gsed`, so it fails wherever GNU sed is
  `sed`.
* [#2516](https://github.com/duckdb/duckdb-r/issues/2516) —
  `BRANCHES.md` is cited twice for content it does not carry: a
  linearization runbook that is not in the repository, and the
  per-invariant enforcement notes the invariants leaf defers to it for.

Already filed when the wave closed, and not repeated here:
[#2489](https://github.com/duckdb/duckdb-r/issues/2489)
(the vendored tree is not byte-reproducible across clones, because
`DUCKDB_SOURCE_ID` is an abbreviated commit id sized by the clone) and
[#2490](https://github.com/duckdb/duckdb-r/issues/2490)
(regeneration rewrites every file unconditionally, invalidating git's
stat cache).

## What the ladder excluded

Recorded so the same material is not salvaged again from the branch
diffs, which remain readable on the closed pull requests.

* **Enumerations an artifact already is** — per-translation-unit
  responsibility tables for `src/`, the `.Rbuildignore` inclusion and
  exclusion lists, roster tables of skip helpers, test files, workflow
  files, patch files, and script exit codes.
  The file is the list.
* **Restatements of a script's own header.**
  Several branches copied out reasoning that
  [`scripts/setup-git.sh`](/scripts/setup-git.sh),
  [`scripts/merge-version.sh`](/scripts/merge-version.sh),
  [`scripts/rconfigure.py`](/scripts/rconfigure.py) and
  `tests/testthat/helper-skip.R` already carry inline.
  The reweighing added one: that the flavor-name guard can only ever
  skip under `R CMD check`, because `.Rbuildignore` excludes `scripts$`
  and a tarball therefore has neither the scan nor the allowlist it
  reads, is stated in almost those words by the header of
  `tests/testthat/test-flavor-package-name.R` *and* by the comment on
  the `custom/after-install` step that runs the scan against the
  checkout — and
  [`testing/guards/`](/handbook/testing/guards/README.md)
  already states the operative half, that CI runs the scan against a
  plain checkout and the test wraps it for the suite.
* **Reference-page material.**
  Storage resolution order, dbplyr translation coverage, and the
  connect-time message's throttling all belong to `?duckdb_storage` and
  the roxygen sources, which ship to readers who do not have this tree.
* **Counts and snapshots that an ordinary commit invalidates** —
  file counts under `src/duckdb/`, object counts, and version strings
  quoted as status rather than as dated examples.
* **History and rejected alternatives** — retired scripts, what a
  document used to say, why a design was abandoned.
  That is git's and the issues'.
* **Facts a newer leaf states better.**
  The wedged `pending` status is the clearest case: the wave's finding
  was that `PENDING_TTL_HOURS` survives only in a plan document and in a
  comment about the heuristic that was removed, so a `pending` status
  can be disbelieved.
  [`operations/ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)
  now states the operative fact directly — the status is a display
  artifact, selection reads records, and a commit without a record is
  undecided — which is the durable form of the same thing.
  The reweighing added the vendor scripts' clone layout, which this
  record carried twice, once as a finding and once as a defect:
  [#2506](https://github.com/duckdb/duckdb-r/pull/2506) fixed the
  `README.md` sentence that contradicted the scripts, and
  [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)
  now owns where the upstream repository is looked for.
