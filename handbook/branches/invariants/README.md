# Invariants

What every series guarantees — the numbered statements the branches are
required to satisfy — and, for each one, what would actually catch a
violation.

A series is one DuckDB minor line `L` together with its branches:
`stable` (published; `main` for the current line),
`lts` (LTS lines only), `dev`, and `dev-base`.
A series opened into the series loop carries
`-build`, `-dev`, `-green`, and `-build-base` instead.
What those refs are and how they advance is
[`branches/model/`](/handbook/branches/model/README.md).

The numbers are stable identifiers.
[`RELEASE.md`](/RELEASE.md) cites them at every step of the release state
machine that has to preserve them, so they are renamed only in both places
at once.

Read every statement as a claim about **trees, not ancestry**.
`main` is maintained as a rebuilt, linear history and shares no merge-base
with the parked `vX-codename` baselines, so "X equals Y plus a rename"
means the two working trees differ only by the rename — not that one is a
git-ancestor of the other.

**Most of these are enforced by nothing.**
Three hold mechanically because the tooling cannot easily produce anything
else — C1, G2, and the vendor counter in V3 — and a fourth, G1, is measured
and closed by a script the series loop runs on its own schedule.
The rest are conventions, kept by the loop's routine and by review.
Each entry below says which it is.

## Structural

- **S1 — Flavor isolation (`lts`).**
  `git diff stable lts` touches only flavor files:
  `DESCRIPTION`'s `Package:`, `R/duckdb-package.R`,
  the `DUCKDB_PACKAGE_NAME` macro in `src/include/rapi.hpp`, `NAMESPACE`,
  `man/*-package.Rd`, the renamed `inst/include/duckdb_*_types.hpp`,
  the README blurb, and the `library()` / `test_check()` names in `tests/`.
  Nothing under `src/duckdb/`, no glue logic in `src/*.cpp`, no `R/` logic.
  *No check diffs the two branches.*
  It holds by construction instead:
  the rename is [`scripts/flavor.patch`](/scripts/flavor.patch), and that
  patch's diff touches exactly those eight paths.
  The converse failure — a package name hard-coded somewhere the patch does
  not rewrite — is caught by
  [`scripts/flavor-package-name.R`](/scripts/flavor-package-name.R),
  which CI runs in its `rcc-smoke` job
  ([`.github/workflows/custom/after-install`](/.github/workflows/custom/after-install/action.yml))
  and which
  [`tests/testthat/test-flavor-package-name.R`](/tests/testthat/test-flavor-package-name.R)
  wraps for `testthat::test_local()`.
  The tooling itself is [`branches/flavors/`](/handbook/branches/flavors/README.md).
- **S2 — Baseline purity (`dev-base`).**
  `dev-base` is byte-identical to the *released* `stable` tree:
  `Package: duckdb`, a bare three-component version, no flavor rename.
  The rename and the version scaffolding live entirely above it, in
  `dev-base..dev`.
  *Nothing checks this*, and it describes the legacy layout only:
  a series-loop series has no `dev-base`, because its seed is flavored from
  day one ([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).
- **S3 — `dev-base` ⊑ `dev`.**
  `dev-base` is an ancestor of `dev` and only ever fast-forwards;
  `dev..dev-base` is always empty.
  *Nothing checks this* — the branch is deliberately unprotected.
  The loop's equivalent frontier is enforced:
  [`scripts/series-advance.sh`](/scripts/series-advance.sh) refuses to push
  `-green` or `-build-base` unless `git merge-base --is-ancestor` holds for
  the new position.
- **S4 — `dev` contents.**
  Every commit in `dev-base..dev` is either a `vendor:` commit or a
  forward-port equivalent to a commit on `main`.
  **Glue is never *born* on a `dev` branch.**
  The exception is the preview line tracking upstream `main`, where
  vendor-coupled glue — adaptation forced by a new upstream C++ API — is
  born on `dev` beside the vendor commit that requires it, because `main`
  does not yet carry that upstream version.
  *The check the statement implies, `git cherry main dev`, is run nowhere.*
  [`scripts/series-port.sh`](/scripts/series-port.sh) runs the opposite
  direction — what `main` has and the series lacks — which closes the gap
  rather than detecting a violation of it.
  What keeps glue off `dev` is the rule that R-side work lands on `main` and
  reaches a series by forwarding, not a gate.

## Linearity and ancestry

History is **linear going forward**.
The cost of extra rebases and CI runs is accepted in exchange for a
bisectable, merge-free active history.

- **L — No new merge commits.**
  The active region (`dev-base..dev`) and every release transition are
  linear: forward-ports are cherry-picks, releases are fast-forwards or
  rebases, and pull requests never create a merge commit.
  Deep history below the release baselines still holds roughly 170
  historical PR merges from before this policy; those are grandfathered.
  *Nothing computes this.*
  `main` is the only protected branch in `duckdb/duckdb-r`, and what its
  protection requires is repository configuration rather than anything in
  the tree.
  What can be said from the tree is that the automated paths cannot break
  it: [`.github/workflows/fledge.yaml`](/.github/workflows/fledge.yaml)
  merges its version-bump pull request with `gh pr merge --squash`, and
  `series-advance.sh` and `series-port.sh` extend `-dev` by cherry-pick.
  A merge that did land would not be reported, but it would quietly shrink
  C1's coverage: [`scripts/each-plan.sh`](/scripts/each-plan.sh) walks
  `--first-parent`, so commits reachable only through a merge's second
  parent are never built.
- **A1 — Dev descends from its release point.**
  Within a patch series, `release-content ⊑ dev-base ⊑ dev` as linear
  ancestors, where `release-content` is the released tree that `dev-base`
  equals (per **S2**).
  That point may sit a couple of commits *below* `stable`'s tip when the tip
  carries release mechanics — the CRAN merge and the post-release bump.
  `dev-base` advances only by fast-forward; `dev` grows by append and is
  force-pushed only to re-anchor onto a new release point or to drop a
  non-green commit.
  The flavor rename is the first group of commits in `dev-base..dev`.
  *Nothing checks the ancestry.*
  Under the series loop the analogous frontier is checked before every push,
  by `series-advance.sh`.
- **A2 — Flip ancestry (preview line).**
  For the next-major flip to be an atomic fast-forward, `main ⊑ main-dev`
  must hold.
  It is **not** maintained continuously: `main` (current stable) and
  `main-dev` (next major) vendor different upstream C++, so forcing ancestry
  would mean rebasing 400-odd commits on every `main` patch release for no
  benefit.
  It is established **once**, immediately before the flip, by rewinding to
  the upstream bifurcation point and replaying.
  *There is nothing to enforce continuously, by design.*
  The linearization runbook this invariant refers to does not exist as a
  document in the repository; the flip is a one-time manual operation.
- **A3 — Dev SHAs are disposable.**
  Because linearity is maintained by rebasing, `-dev` SHAs are not durable.
  Only tags and the fast-forward-only markers are stable references.
  This is acceptable — `-dev` exists solely for CI and r-universe.
  *Nothing to enforce:* it is a consequence, not an obligation.
  What consumers are told to use instead is enforced —
  `-green` only ever fast-forwards, checked by `series-advance.sh`.

### What linearity costs

| Operation | When | Cost | Mechanism |
|-----------|------|------|-----------|
| `dev` append (vendor / forward-port) | daily / per glue change | O(1) | append; cherry-pick |
| `dev-base` advance | per reviewed release | O(1) ref update | fast-forward |
| Patch re-baseline | per patch release | O(pending) replayed × per-commit CI (3–21 commits today) | rebase; the merge driver resolves the version line |
| Forward-port across the chain | per glue change | O(diff) × active lines | cherry-pick; the merge driver handles `DESCRIPTION` |
| **Major-flip linearization** | per major release | O(hundreds) — 402 pending on `main-dev` when this was measured | one-time rewind and replay, deferred rather than continuous |

The [`DESCRIPTION` merge driver](/handbook/operations/vendoring/pipeline/README.md)
is what keeps the recurring rebases cheap.
The one genuinely expensive operation — the major-flip linearization — is
paid once, by design, rather than amortized into every patch release.

## Flavor and identity

- **F1 — Name coherence.**
  Within a branch, `DESCRIPTION:Package`, `DUCKDB_PACKAGE_NAME`,
  `@useDynLib`, the `duckdb[._]L[._]types.hpp` filename, and the testthat
  names all agree, and match the branch role:
  `stable` and `dev-base` → `duckdb` (per **S2**, `dev-base` is the
  un-renamed release); `lts` → `duckdb.L`; `dev` → `duckdb.L.dev`.
  The rename is exactly what distinguishes `dev` from `dev-base`.
  *No check compares those five surfaces.*
  They agree because one patch rewrites all of them together, and because
  the `flavor-package-name.R` scan named under **S1** finds a name the patch
  missed.
- **F2 — Mechanical rename.**
  The rename is produced solely by `scripts/flavor.sh`;
  its non-name structure is identical across all series, differing only in
  the version token.
  *Nothing prevents a hand-edit* and nothing compares the rename between
  series.

## Version

- **V1 — Prefix lock.**
  `major.minor` equals `L` on every branch of the series.
  The exception is the preview line, which carries a synthetic placeholder
  prefix greater than any current release (`main-dev` is `1.5.99.…`) until
  the flip sets the real number.
  *Nothing asserts the prefix.*
  The one machine rule here is defensive:
  [`scripts/merge-version.sh`](/scripts/merge-version.sh) gates its
  component-wise maximum on an equal `major.minor.patch`, so a
  cross-line forward-port keeps *ours* and can never import a foreign
  prefix.
- **V2 — Patch ordering.**
  `stable` and `lts` share the released patch `Z`;
  `dev` and `dev-base` are at or ahead of `Z`.
  *Nothing checks this.*
- **V3 — Counters.**
  The **4th** component free-runs as the R-client dev counter *only* on the
  glue source of truth (`main`: `…9003`, `…9004`);
  on `-dev` branches it is a fixed marker (`.9000` / `.9001`).
  The **5th** component is the vendor counter, strictly monotone along
  `dev`, one bump per vendor commit.
  Componentwise within the prefix, `dev ≥ dev-base ≥ stable`.
  Regular LTS flavors never carry a fifth component.
  *The vendor counter is mechanical:*
  [`scripts/vendor-one.sh`](/scripts/vendor-one.sh) increments it by one in
  every vendor commit it writes, filling missing components with zeros, so
  monotonicity is a property of the only thing that writes it.
  On a series-loop dev branch the seed's `chore: Add fifth version
  component` commit stamps it at `.0`; elsewhere it is absent until the
  first vendor commit mints `.1`.
  The 4th component is bumped by `fledge` on `main`, daily, via
  `.github/workflows/fledge.yaml`.
  *Nothing checks the fixed-marker rule on `-dev`, or the componentwise
  ordering.*
  The counters themselves are
  [`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md).
- **V4 — Release shape.**
  A released `stable` or `lts` version is the bare three-component prefix,
  with no 4th or 5th component.
  *Nothing verifies it:* `fledge::bump_version()` sets the version at the
  tip and is trusted to.

## Source of truth, across series

- **G1 — Glue monotone down the chain.**
  At the forward-port frontier, glue, R code, tests, CI and cpp11 satisfy
  `main ⊇ newer-dev ⊇ … ⊇ older-dev`;
  older lines lag only by pending forward-ports.
  This is **S4** applied across the whole chain.
  *This is the one gap that is routinely measured.*
  `scripts/series-port.sh <series>` without `--apply` prints every commit on
  `main` that has no patch-id equivalent on `<series>-dev`, classified by
  what it touches, plus whether the tooling paths differ;
  with `--apply` it cherry-picks them and closes the residue with a single
  sync commit that takes `main`'s tooling tree verbatim.
  It runs as a stage of the series loop, so the lag is measured and closed
  on the loop's schedule — converging, not gating.
  A scheduled stale-branch workflow — running
  `git merge-base --is-ancestor main <branch>` for each active `-dev` branch
  and reporting the lag — is proposed in `BRANCHES.md` and does not exist in
  `.github/workflows/`.
- **G2 — Patch-stack derivation.**
  Each `dev`'s `patch/` equals `main`'s patch set minus the patches already
  merged into *that series'* upstream branch.
  `patch/` may therefore legitimately differ between series;
  it is never hand-authored per series beyond dropping what landed upstream.
  *Mechanical.*
  Every vendor commit re-applies the whole stack:
  `vendor-one.sh` dry-runs each `patch/*.patch` against the freshly vendored
  tree, applies the ones that still apply, and deletes the ones that do not.
  The subtraction is that deletion.
  Its limit is that `patch --dry-run` cannot tell a patch that landed
  upstream from one that merely stopped applying, and removes both — so a
  dropped patch in a vendor commit is a fact to check, not a verdict to
  trust.

## CI and green

- **C1 — Every `dev` commit is green,** so `dev` is bisectable end to end.
  *Enforced, and the only invariant with a gate of its own.*
  [`.github/workflows/each.yaml`](/.github/workflows/each.yaml) builds every
  commit in `<S>-green..HEAD` that has no verdict yet and writes one verdict
  per commit; the gates are
  [`scripts/rcc-one.sh`](/scripts/rcc-one.sh) — install, then style,
  snapshots, roxygen, a clean tree, `R CMD check`, and pkgdown.
  `series-advance.sh` then fast-forwards `<S>-green` over the unbroken
  prefix of successes and refuses to move at all when a commit in flight has
  failed.
  So the guarantee is exact up to `<S>-green`;
  the range `<S>-green..<S>-dev` is what is in flight and undecided, and
  `<S>-build` has no CI at all — `each.yaml` never matches `*-build`.
  The marker, the shards and the verdict store are
  [`operations/ci/per-commit/`](/handbook/operations/ci/per-commit/README.md).
- **C2 — `stable`, `lts`, and `dev-base` tips are green** — former green
  `dev` tips, or freshly checked re-baselines.
  *Enforced for `main`, and at release time.*
  [`.github/workflows/R-CMD-check.yaml`](/.github/workflows/R-CMD-check.yaml)
  runs on every push to `main`, on every pull request against it, on
  `cran-*` branches, and nightly;
  [`R-CMD-check-dev.yaml`](/.github/workflows/R-CMD-check-dev.yaml) adds the
  development-dependency matrix on `cran-*` pushes and on every `v*` tag.
  No workflow triggers on `v1.4-andium`, `v1.4-andium-lts` or
  `v1.5-variegata` themselves: between releases those tips are green because
  of where they came from, not because anything re-checks them.

Bisectability needs three things at once, and only one of them is C1:
a linear first-parent history (**L**), one upstream commit per vendor commit
forming a contiguous walk of the tracked upstream branch, and a green build
for every commit.
The middle one is
[`operations/vendoring/model/`](/handbook/operations/vendoring/model/README.md)'s.

## Prerelease, during STABILIZE

- **P1 — Release branches frozen.**
  Pre-release mutates only `main` (fold-back fixes) and `dev`
  (forward-ports and vendoring);
  `stable`, `lts` and `dev-base` stay at the previous release until the cut.
  A half-finished pre-release is abortable with zero rollback on the release
  branches.
- **P2 — Candidate ⊆ release.**
  The revdep-tested pinned candidate is an ancestor of the `dev` tip that
  will be cut;
  any delta added after a revdep run is reviewed, and re-checked if risky.
  What ships was tested.
- **P3 — Fold-back ordering.**
  Every fold-back fix lands on `main` before any `dev`
  (a `dev` fix lacking a `main` ancestor violates **S4**).
- **P4 — Freeze convergence.**
  At glue freeze, `git cherry main dev` is empty for *every* releasing
  series simultaneously, so all releasing lines carry identical glue.
  This is the multi-line synchronization barrier.

*None of the four is automated.*
They are steps of the release state machine, which a human drives and which
cites each of them at the step that must preserve it —
[`operations/releases/process/`](/handbook/operations/releases/process/README.md).
P4 is at least measurable with the same command G1 uses:
the barrier is `scripts/series-port.sh` reporting nothing pending, for every
releasing series at once.

## The gap

These invariants were written on the premise that most of them "can be
enforced by a dev-branch health workflow".
That workflow does not exist, and no plan in [`plan/`](/plan/README.md)
schedules it;
the nearest planned work restates the series loop's own rules as a checklist
without adding checks.
Two consequences are worth carrying:
a violation of anything but C1 surfaces only when someone looks, and the
figures quoted above — the merge counts, the pending windows, the version
numbers — are observations made when the invariants were written, not values
any check keeps current.
