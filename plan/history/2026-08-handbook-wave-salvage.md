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

## Findings

* **`make format-check` aborts instead of reporting when `cmake-format`
  is absent.**
  [`scripts/format.py`](/scripts/format.py) sends `src/CMakeLists.txt`
  through `cmake-format`, which ships separately from `clang-format`;
  without it the run dies with a `FileNotFoundError` before it reaches a
  verdict on any file, rather than reporting a difference.
  Run, not inferred.
  *Proof:* `scripts/format.py`, the `format-*` targets in
  [`Makefile`](/Makefile).
  *Leaf:* [`architecture/glue/`](/handbook/architecture/glue/README.md).
  *From:* [#2484](https://github.com/duckdb/duckdb-r/pull/2484).

* **The vendor scripts' default clone layout is two levels, not one.**
  Both scripts `cd` to the package root first and then default
  `upstream_basedir` to `../../../duckdb`,
  so the package clone has to sit *two* directories deeper than the
  upstream clone — upstream at `~/git/duckdb` pairs with a package clone
  at `~/git/R/duckdb/duckdb-r`, and the layout `README.md` describes
  resolves to a path that does not exist.
  Any other layout works by passing the upstream path as the positional
  argument.
  *Proof:* [`scripts/vendor.sh`](/scripts/vendor.sh),
  [`scripts/vendor-one.sh`](/scripts/vendor-one.sh);
  the wrong statement is in [`README.md`](/README.md).
  *Leaf:* [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).
  *From:* [#2477](https://github.com/duckdb/duckdb-r/pull/2477).

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
  *Proof:* `src/include/deps.mk`.
  *Leaf:* [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md),
  or [`build/source-build/`](/handbook/build/source-build/README.md),
  which already owns the `.dd` files.
  *From:* [#2477](https://github.com/duckdb/duckdb-r/pull/2477).

* **`BASE_SCAN_DEPTH` does not reach the series scripts.**
  The variable is honoured by the two vendor scripts only.
  [`scripts/series-advance.sh`](/scripts/series-advance.sh) and
  [`scripts/series-check.sh`](/scripts/series-check.sh)
  hard-code the same depth and read no such variable,
  so a branch that stacks enough non-vendoring commits under
  `src/duckdb/` to need the bound raised needs both of them changed too.
  *Proof:* those two scripts, against
  [`scripts/vendor-one.sh`](/scripts/vendor-one.sh).
  *Leaf:* [`operations/vendoring/troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md).
  *From:* [#2472](https://github.com/duckdb/duckdb-r/pull/2472).

* **An empty `Files:` list from the glue gate is a local setup problem,
  not a broken glue.**
  When it prints
  `Error: could not derive glue compile flags (R CMD SHLIB -n)`
  alongside an empty file list, the flags could not be derived at all.
  Deriving them needs `src/Makevars.rstrtmgr`, which only `./configure`
  writes; the gate runs `./configure` itself when the file is missing,
  so reaching this message means that failed.
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
  [#2488](https://github.com/duckdb/duckdb-r/issues/2488).
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
  *Proof:* that header.
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
  *Proof:* `R/storage.R` and its generated `man/` page.
  *Leaf:* [`architecture/r-layer/`](/handbook/architecture/r-layer/README.md),
  which states the rule but not this failure mode.
  *From:* [#2480](https://github.com/duckdb/duckdb-r/pull/2480).

* **The flavor-name guard fires in exactly one place.**
  `tests/testthat/test-flavor-package-name.R` can only ever skip under
  `R CMD check`: [`.Rbuildignore`](/.Rbuildignore) excludes `scripts$`,
  so neither
  [`scripts/flavor-package-name.R`](/scripts/flavor-package-name.R)
  nor the [`scripts/flavor.patch`](/scripts/flavor.patch) allowlist it
  reads is present in a built tarball.
  The `custom/after-install` CI step running the scan against a plain
  checkout is the guard; delete it and nothing is left,
  while the test keeps passing by skipping.
  *Proof:* `.Rbuildignore`, that test file, and
  [`.github/workflows/custom/after-install/action.yml`](/.github/workflows/custom/after-install/action.yml).
  *Leaf:* [`testing/guards/`](/handbook/testing/guards/README.md).
  *From:* [#2467](https://github.com/duckdb/duckdb-r/pull/2467).

* **CI turns the installed-size check off.**
  [`.github/workflows/custom/before-install/action.yml`](/.github/workflows/custom/before-install/action.yml)
  exports `_R_CHECK_PKG_SIZES_=FALSE`,
  so the standing package-size NOTE cannot fail a matrix run —
  and neither can a size regression.
  The NOTE is seen at submission time and nowhere earlier.
  *Proof:* that action file.
  *Leaf:* [`operations/releases/cran/`](/handbook/operations/releases/cran/README.md).
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
  [`branches/invariants/`](/handbook/branches/invariants/README.md)
  says most invariants are enforced by nothing and defers the
  per-statement notes to `BRANCHES.md`, which does not carry them.
  The wave derived them against the scripts:
  the only continuous mechanical checks are
  [`scripts/series-advance.sh`](/scripts/series-advance.sh)'s
  `git merge-base --is-ancestor` gate before it pushes `-green` or
  `-build-base`, and the vendor counter the pipeline bumps.
  The structural and flavor invariants hold *by construction* — the
  rename is one patch, so its diff is the surface — and the linearity
  and dev-baseline invariants are checked by nothing at all.
  Worth re-deriving rather than trusting, but the shape held.
  *Proof:* `scripts/series-advance.sh`, `scripts/series-check.sh`,
  [`scripts/flavor.patch`](/scripts/flavor.patch).
  *Leaf:* [`branches/invariants/`](/handbook/branches/invariants/README.md).
  *From:* [#2478](https://github.com/duckdb/duckdb-r/pull/2478).

## Defects the wave found that `main` still has

Each is a thing to fix, not a thing to write down;
they are listed here so closing the wave does not lose them.
[#2489](https://github.com/duckdb/duckdb-r/issues/2489)
(the vendored tree is not byte-reproducible across clones, because
`DUCKDB_SOURCE_ID` is an abbreviated commit id sized by the clone) and
[#2490](https://github.com/duckdb/duckdb-r/issues/2490)
(regeneration rewrites every file unconditionally, invalidating git's
stat cache) already have issues and are not repeated.

* **`README.md` states the wrong vendoring clone layout.**
  It says the `duckdb-r` clone must be one level deeper than the
  `duckdb` clone, and gives `R/duckdb-r` beside `duckdb` as the example.
  The scripts default to `../../../duckdb` from the package root, which
  makes that example resolve outside both clones — see the finding
  above.
  Either the sentence or the default is wrong; the scripts are what
  runs.

* **The flavor rename misses the README blurb.**
  [`scripts/flavor.patch`](/scripts/flavor.patch) writes
  "This package contains the LTS version 1.3 of DuckDB" into
  `README.md`, and
  [`scripts/flavor.sh`](/scripts/flavor.sh) rewrites the flavor suffix
  with a substitution that requires a `.` or `_` immediately before the
  `1`.
  In that sentence the `1.3` is preceded by a space, so it is never
  rewritten, and every flavored branch's README announces version 1.3
  whatever it actually carries — visible on the published `duckdb.1.4`.
  The rest of the rename is unaffected.

* **`scripts/flavor.sh` requires `gsed`.**
  It invokes `gsed` directly, so on a system where GNU sed is simply
  `sed` — most Linux — the script fails unless a `gsed` is on `PATH`.

* **`BRANCHES.md` cites a runbook that does not exist.**
  The major-flip linearization invariant defers to "the linearization
  runbook"; no such document is in the repository.
  A reader following the citation finds nothing.

* **`plan/done/PLAN-storage-locations.md` still marks unshipped work
  `[x]`.**
  Its header already corrects two of them — the
  `duckdb_extension_storage()` / `duckdb_secret_storage()` setters and
  the `?duckdb_storage_config` page.
  A third is not corrected: the Phase 2 `.duckdb-r-keep` marker scheme
  and the writability probe of the installed library directory.
  Neither appears in `R/` or `NAMESPACE`, and the extension cache is
  never placed in the package library.

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
