# Branching Strategy

*Handbook: [`branches/`](/handbook/branches/README.md) —
its leaves state the current model, flavors, and invariants,
and are absorbing this file section by section;
where the two disagree, the leaf is right.*

Version numbers are given at the time of writing (March 2026) and may be outdated by the time you read this.
The branching strategy is expected to remain stable.

What is left here is the branch model in detail and the
**[series invariants](#series-invariants)**, which the handbook still
defers to.  The flavors, the repositories, the release cycle, the
synchronization, and the version counters have been absorbed;
the headings below say where.

## Package Components

The R package is a **monorepo without submodules**, combining several components in a single repository.
This design accommodates R development conventions (`R CMD build`, CRAN compliance) and preserves the requirement
to avoid hard runtime dependencies other than DBI.

The seven components are:

1. **DuckDB core** (`src/duckdb/`): the vendored C++ database engine.
   It is tracked from upstream branches of `duckdb/duckdb`:
   `main` (bleeding edge / dev), `v1.5-variegata` (current patch series), `v1.4-andium` (LTS).
   Never modify this directory directly — use the `patch/` mechanism instead.

2. **Flavor** (`DESCRIPTION`, `R/duckdb-package.R`, `NAMESPACE`, `README.md`, `src/include/rapi.hpp`,
   `inst/include/duckdb_types.hpp`, `tests/testthat.R`, `man/duckdb-package.Rd`): the published package
   name variant (`duckdb`, `duckdb.1.4`, `duckdb.1.4.dev`, …).
   Managed via `scripts/flavor.patch` and `scripts/flavor.sh`; also covers the `@useDynLib` directive and
   the `DUCKDB_PACKAGE_NAME` C++ macro.
   `scripts/flavor-package-name.R` guards the boundary: it fails as soon as the package name is hard-coded —
   as a namespace qualifier or as a quoted string — in code or docs anywhere the patch does not rewrite it.
   Code asks for the name at run time with `get_package_name()` instead, and docs do not namespace-qualify
   our own objects. CI runs the scan from `.github/workflows/custom/after-install`;
   `tests/testthat/test-flavor-package-name.R` wraps it for `testthat::test_local()` and skips under
   `R CMD check`, which works from a tarball that carries neither the sources nor `scripts/`.

3. **Glue code** (`src/*.cpp`, `src/include/`): the C++ bridge between R and the DuckDB C++ API.
   Glue code may change when DuckDB's C++ API shifts, so it is updated together with vendoring commits.

4. **R code and tests** (`R/`, `tests/`, some interfaces also reflected in `src/*.cpp`): the native R
   interface — DBI implementation, connection handling, result processing, and the full testsuite.

5. **CI/CD infrastructure** (`.github/workflows/`, `scripts/`): build, test, and release automation.

6. **cpp11** (`inst/include/cpp11/`, `inst/include/cpp11.hpp`): vendored from
   [`krlmlr/cpp11`](https://github.com/krlmlr/cpp11), which is a patch stack on top of
   [`r-lib/cpp11`](https://github.com/r-lib/cpp11).

7. **R core** (indirect): the R API itself constrains what the glue code may safely do; changes
   in R (e.g. `r-devel` ABI shifts) affect the package indirectly and may require R or glue code updates.

### Directory tree

```
duckdb-r/
├── R/                              # R code — DBI interface, connection, results  [4]
├── tests/
│   └── testthat/                   # R unit tests (~40 files)                     [4]
├── src/
│   ├── *.cpp                       # Glue code — R ↔ DuckDB C++ bridge            [3]
│   ├── *.dd                        # Local-header dependency tracking (keep in VCS)[3]
│   ├── include/
│   │   └── rapi.hpp                # Defines DUCKDB_PACKAGE_NAME (flavor)         [2,3]
│   └── duckdb/                     # Vendored DuckDB C++ core (≈1700 .cpp, ≈1400 .h) [1]
│       ├── src/                    # DuckDB source files
│       ├── third_party/            # DuckDB bundled third-party libs
│       └── extension/              # Extension loaders
├── inst/
│   └── include/
│       ├── cpp11/                  # Vendored cpp11 headers (krlmlr/cpp11)         [6]
│       ├── cpp11.hpp               # cpp11 single-header entry point               [6]
│       └── duckdb_types.hpp        # Public C++ types exposed to downstream R pkgs [3]
├── patch/                          # R-specific patches applied to src/duckdb/     [1]
│   ├── 0001-….patch
│   └── …
├── scripts/                        # Build and maintenance scripts                 [5]
│   ├── vendor.sh                   # Manual vendoring from local DuckDB clone
│   ├── vendor-one.sh               # Commit-by-commit vendoring (series loop)
│   ├── flavor.sh                   # Apply flavor rename to a branch
│   ├── flavor.patch                # Patch template for flavor rename              [2]
│   ├── each-plan.sh                # Plan cost-balanced shards of unbuilt commits
│   ├── each-shard.sh               # Build one shard: many commits, one job
│   ├── each-cost.py                # Unity objects a commit invalidates
│   ├── rcc-one.sh                  # The per-commit rcc gate
│   ├── each-harvest.sh             # Reconcile shard results onto the rcc branch
│   ├── rcc-part-push.sh            # Publish one commit's result from its leg
│   ├── rcc-decided.sh              # Commits the rcc branch has a verdict for
│   ├── rcc-merge.sh                # Bring runs2.ndjson level with the records
│   ├── rcc-consolidate.sh          # Manual: GC old logs, squash the rcc branch
│   └── VENDORING.md                # Supplementary vendoring notes (→ see §Vendoring)
├── .github/
│   └── workflows/
│       ├── each.yaml               # Per-commit rcc, as a sharded matrix           [5]
│       ├── sync.yaml               # Fast-forward krlmlr/main from duckdb/main     [5]
│       ├── fledge.yaml             # Automated version-bump PRs                    [5]
│       └── R-CMD-check*.yaml       # Package check workflows                       [5]
├── DESCRIPTION                     # Package metadata — name + version = flavor    [2]
└── NAMESPACE                       # R namespace (regenerated by roxygen2)
```

Numbers in `[brackets]` refer to the component list above.

### Component interaction diagram

```
  r-lib/cpp11
      │  patches maintained in krlmlr/cpp11
      ▼
  inst/include/cpp11/   ◄─────────────────────────────────────────────────────────────┐
                                                                                      │ vendored [6]
  duckdb/duckdb (upstream C++)   ←── R core evolves independently (indirect) [7]      │
      │                                                                               │
      │  vendor.sh / vendor-one.sh  (routine-driven; see the series loop)             │
      │  patch/ applied on top                                                        │
      ▼                                                                               │
  src/duckdb/   ← R-ready vendored C++  [1]                                           │
      │                                                                               │
      │  compiled together with                                                       │
      ▼                                                                               │
  src/*.cpp  (glue code)  [3]  ◄── src/include/rapi.hpp (DUCKDB_PACKAGE_NAME) [2,3]   │
      │                                       ▲                                       │
      │                                       │ flavor.sh / flavor.patch              │
      │                              DESCRIPTION · Package: duckdb.x.y [2]            │
      │                                                                               │
      │  compiled and linked against cpp11 ◄──────────────────────────────────────────┘
      ▼
  libduckdb*.so / duckdb*.dll
      │  loaded by R via .registration = TRUE
      ▼
  R/ (DBI interface)  [4]  ◄──  tests/testthat/  [4]
      │
      └──►  Published R package (CRAN / r-universe)

  ─────────────────────────────────────────────────────────────────────────────────
  CI/CD infrastructure [5]:   series routine → each.yaml → R-CMD-check → fledge.yaml
  ─────────────────────────────────────────────────────────────────────────────────
```

## Why multiple R packages, and which exist

Absorbed into
[`branches/flavors/`](/handbook/branches/flavors/README.md):
CRAN carries one version of one name at a time, so a release line that
must stay installable beside the current one needs its own name.
The leaf carries the live table of flavors and the ref each publishes from.

## Overview

Three moving parts work together to produce the published R packages:

```txt
duckdb/duckdb        krlmlr/duckdb-r         duckdb/duckdb-r       CRAN / r-universe
(upstream C++)       (CI/CD fork)            (canonical R pkg)
──────────────       ──────────────          ───────────────       ─────────────────
main            ──►  main-dev           ──►  main               ──►  duckdb (r-universe)
                     main-dev-base                                   duckdb.dev
v1.5-variegata  ──►  v1.5-variegata-dev ──►  main               ──►  duckdb (CRAN)
                     v1.5-variegata-dev-base                         duckdb.1.5.dev (r-universe)
v1.4-andium     ──►  v1.4-andium-dev    ──►  v1.4-andium        ──►  duckdb.1.4 (r-universe)
                     v1.4-andium-dev-base    v1.4-andium-lts         duckdb.1.4.dev (r-universe)

   │              ^        ^       │                ^
   │  vendor      │        │       │ during release │
   │  (daily)     │        │       │  preparation   │
   │  + patches   │        │       │     only       │
   │  from patch/ │        │       └────────────────┘
   └──────────────┘        │
                    sync.yaml (hourly FF of krlmlr/main from duckdb/main)
```

The arrow from upstream to the CI/CD fork represents automated vendoring; the arrow from the fork to the canonical repo represents the release merge. Patches from `patch/` are applied to the vendored C++ code during every vendor run (see [Patch Stack](#patch-stack) below).

## Repositories

Absorbed into
[`branches/model/`](/handbook/branches/model/README.md):
`duckdb/duckdb-r` is canonical, `krlmlr/duckdb-r` is the CI/CD fork,
and the engine is vendored from `duckdb/duckdb` into the fork.

## Branch Overview

Each supported DuckDB minor version has a **series of four branches** organised into two repos.
The table below shows the complete set at the time of writing.
The `dev`/`dev-base` pair is the legacy vendoring layout;
as each series is reseeded into the series loop
(see [`operations/vendoring/`](/handbook/operations/vendoring/README.md) below),
that pair gives way to the loop's four refs —
`<S>-build`, `<S>-dev`, `<S>-green`, `<S>-build-base`.

| Branch                    | Repo              | `Package:`       | Purpose                                                    |
|---------------------------|-------------------|------------------|------------------------------------------------------------|
| `main`                    | `duckdb/duckdb-r` | `duckdb`         | Source of truth for glue code, R code, tests, CI/CD, cpp11 |
| `main-dev`                | `krlmlr/duckdb-r` | `duckdb`         | Vendored dev (upstream `main`); published as `duckdb.dev`  |
| `main-dev-base`           | `krlmlr/duckdb-r` | `duckdb`         | Stable base for `main-dev`; marks the last reviewed point  |
| `v1.5-variegata`          | `duckdb/duckdb-r` | `duckdb`         | Stable baseline for current release                        |
| `v1.5-variegata-lts`      |                   |                  | Does not exist, v1.5 is not an LTS                         |
| `v1.5-variegata-dev`      | `krlmlr/duckdb-r` | `duckdb.1.5.dev` | Bleeding edge on v1.5 upstream                             |
| `v1.5-variegata-dev-base` | `krlmlr/duckdb-r` | `duckdb.1.5.dev` | Stable base for `v1.5-variegata-dev`                       |
| `v1.4-andium`             | `duckdb/duckdb-r` | `duckdb`         | Stable baseline for LTS release                            |
| `v1.4-andium-lts`         | `duckdb/duckdb-r` | `duckdb.1.4`     | `v1.4-andium` + one rename commit; published to r-universe |
| `v1.4-andium-dev`         | `krlmlr/duckdb-r` | `duckdb.1.4.dev` | Bleeding edge on v1.4 upstream                             |
| `v1.4-andium-dev-base`    | `krlmlr/duckdb-r` | `duckdb.1.4.dev` | Stable base for `v1.4-andium-dev`                          |

### Branch series structure

Within each minor version, the four branches form a linear stack, illustrated here for v1.4:

```
duckdb/duckdb-r                         krlmlr/duckdb-r
───────────────                         ───────────────

v1.4-andium  ────────────────────────────────────►
 │  Package: duckdb                              │
 │  Baseline: glue code + vendored C++           │
 │                                               ▼
 │                                      v1.4-andium-dev-base
 │                                      Package: duckdb.1.4.dev
 │                                      v1.4-andium + rename + version suffix
 │                                               │
 │                                               │  vendor commits land here first
 │                                               ▼
 ▼                                      v1.4-andium-dev          ← bleeding edge
v1.4-andium-lts                         Package: duckdb.1.4.dev
 Package: duckdb.1.4                    Always a descendant of dev-base
 v1.4-andium + one rename commit
 Published to r-universe
```

The pending changes between `dev-base` and `dev` can be inspected at any time:

```
https://github.com/krlmlr/duckdb-r/compare/v1.4-andium-dev-base...v1.4-andium-dev
```

The same structure applies to v1.5 and to `main`/`main-dev`/`main-dev-base`.
The `-lts`-suffixed branch only exists when the minor version is designated an LTS release.

Stable branches (`duckdb/duckdb-r`) track released R package versions and are the source for CRAN
releases and numbered r-universe releases (without the `.dev` suffix).
Dev branches (`krlmlr/duckdb-r`) track the corresponding bleeding-edge upstream branches and are
published as `.dev` packages.

## Source of Truth

`main` in `duckdb/duckdb-r` is the **source of truth** for four of the seven components:

| Component                | Source of truth                   | Notes                                             |
|--------------------------|-----------------------------------|---------------------------------------------------|
| DuckDB core              | `duckdb/duckdb` upstream          | Vendored independently into each branch           |
| Flavor                   | Per-branch (via `flavor.sh`)      | Applied mechanically on top of the baseline       |
| **Glue code**            | **`main`**                        | Forward-ported to all `-andium` / `-dev` branches |
| **R code and tests**     | **`main`**                        | Forward-ported to all `-andium` / `-dev` branches |
| **CI/CD infrastructure** | **`main`**                        | Forward-ported to all `-andium` / `-dev` branches |
| **cpp11**                | **`main`**                        | Forward-ported to all `-andium` / `-dev` branches |
| R core                   | External (`r-devel`, CRAN policy) | Monitored; fixes land in `main` first             |

### Keeping derived branches in sync with main

The forward-port order for non-vendor commits is always from newer to older:

```
duckdb/duckdb-r@main ─────────────────────────────►
        │                                         │
        ▼                                         ▼
krlmlr/duckdb-r@main-dev                duckdb/duckdb-r@v1.4-andium
        │
        ▼
krlmlr/duckdb-r@v1.5-variegata-dev
        │
        ▼
krlmlr/duckdb-r@v1.4-andium-dev
```

Never port in reverse. Proposed patterns to keep this consistent:

1. **PR-per-branch**: After any non-vendor commit merges to `main`, open a PR for each active
   `-dev` branch. `sync.yaml` already handles `krlmlr/main` automatically; the remaining branches
   require a manual or script-assisted step.

2. **`scripts/sync-to-derived.sh`** *(proposed — see §Tooling)*: A script that identifies commits
   in `main` not yet reachable from a given `-dev` branch and prints the `git cherry-pick` commands
   needed to bring it up to date.

3. **Stale-branch CI check** *(proposed — see §Tooling)*: A scheduled workflow that computes
   `git merge-base --is-ancestor main <branch>` for each active `-dev` branch and posts a status
   summary to flag forward-porting debt early.

4. **Mandatory merge-base label**: PRs to any `-dev` branch that target glue-code or R-code files
   are labeled `needs-forward-port` automatically by a label action, reminding maintainers to
   propagate the change toward `main` before the next release.

## Series Invariants

A **series** is one DuckDB minor line `L` together with its branches: `stable`
(published; `main` for the current line), `lts` (LTS lines only), `dev`, and
`dev-base`. The following invariants hold across all branches of a series. Each
is phrased to be **checkable** — most can be enforced by a dev-branch health
workflow — and each is referenced by name from the release FSM in
[`operations/releases/process/`](/handbook/operations/releases/process/README.md), which must preserve them at every step.

State relationships as **tree diffs**, not ancestry: `main` is maintained as a
rebuilt/linear history and shares no merge-base with the parked `vX-codename`
baselines, so any invariant phrased as "X equals Y plus a rename" means *the
working trees differ only by the rename*, not that one is a git-ancestor of the
other.

### Structural

- **S1 — Flavor isolation (`lts`).** `git diff stable lts` touches only flavor
  files (`DESCRIPTION:Package`, `R/duckdb-package.R`, `src/include/rapi.hpp`
  macro, `NAMESPACE`, `man/*-package.Rd`, the renamed
  `inst/include/duckdb_*_types.hpp`, the README blurb, and the `library()` /
  `test_check()` names in `tests/`). Nothing under `src/duckdb/`, no glue logic
  in `src/*.cpp`, no `R/` logic.
- **S2 — Baseline purity (`dev-base`).** `dev-base` is byte-identical to the
  *released* `stable` tree: `Package: duckdb`, bare three-component version, **no
  flavor rename**. The `flavor.sh` rename and the version scaffolding live entirely
  *above* it, in `dev-base..dev`. (Confirmed: `v1.5-variegata-dev-base` reads
  `duckdb 1.5.4`, `v1.4-andium-dev-base` reads `duckdb 1.4.5`.)
  This invariant describes the legacy `dev-base` layout;
  a series-loop series has no `dev-base` —
  its seed is flavored from day one,
  per the bootstrap rule in `.claude/skills/series-loop.md`.
- **S3 — `dev-base` ⊑ `dev`.** `dev-base` is an ancestor of `dev` and only ever
  fast-forwards; `dev..dev-base` is always empty.
- **S4 — `dev` contents.** Every commit in `dev-base..dev` is either a `vendor:`
  commit or a forward-port equivalent to a commit on `main` (`git cherry main
  dev` shows no unmatched non-vendor `+`). **Glue is never *born* on a `dev`
  branch.** *Exception:* on the preview line (tracking upstream `main`),
  vendor-coupled glue — adaptation forced by a new upstream C++ API — is born on
  `dev` alongside the vendor commit that requires it, because `main` does not yet
  carry that upstream version.

### Linearity and ancestry

History is **linear going forward** — the cost of extra rebases and CI runs is
accepted in exchange for a bisectable, merge-free active history.

- **L — No new merge commits.** The active region (`dev-base..dev`) and every
  release transition are linear: forward-ports are `cherry-pick`s, releases are
  fast-forwards or rebases, and PRs never create a merge commit (use "Rebase and
  merge", or a fast-forward push). Deep history below the release baselines still
  contains ~170 historical PR merges from before this policy; those are
  grandfathered. *(Currently nearly satisfied: `main-dev` adds 0 merges over 402
  commits, `v1.4-andium-dev` 0 over 3 — but `v1.5-variegata-dev` carries 1 stray
  merge in its 21-commit window that should be rebased out, and the 1.5.4 release
  landed on `main` via a merge commit, which this policy replaces with FF/rebase.)*
- **A1 — Dev descends from its release point.** Within a patch series,
  `release-content ⊑ dev-base ⊑ dev` as linear ancestors, where `release-content`
  is the released tree (which `dev-base` equals, per **S2**) — this may sit a
  couple of commits *below* `stable`'s tip when that tip carries release mechanics
  (the CRAN merge + post-release bump). `dev-base` advances only by fast-forward;
  `dev` grows by append and is rewritten (force-push) only to re-anchor onto a new
  release point or to drop a non-green commit. The `flavor.sh` rename is the first
  group of commits in `dev-base..dev`. *(Confirmed: `dev-base ⊑ dev` everywhere
  (pending 402 / 21 / 3, nothing behind); `v1.4-andium`'s release ⊑ `dev`. For
  1.5, `dev-base` is anchored at the release content `main~2`, two commits below
  `main`'s current tip.)*
- **A2 — Flip ancestry (preview line).** For the next-major flip to be an atomic
  fast-forward, `main ⊑ main-dev` must hold. This is **not** maintained
  continuously: `main` (current stable) and `main-dev` (next major) vendor
  different upstream C++, so forcing ancestry would mean rebasing 400+ commits on
  every `main` patch release for no benefit. Instead it is **established once**,
  immediately before the flip, by the linearization runbook (rewind to the
  upstream bifurcation point, then replay).
- **A3 — Dev SHAs are disposable.** Because linearity is maintained by rebasing,
  `-dev` SHAs are not durable; only tags (releases) and the fast-forward-only
  `dev-base` marker are stable references. This is acceptable — `-dev` exists
  solely for CI and r-universe.

#### Cost of maintaining linear ancestry

| Operation | When | Cost | Mechanism |
|-----------|------|------|-----------|
| `dev` append (vendor / forward-port) | daily / per glue change | O(1) | append; cherry-pick |
| `dev-base` advance | per reviewed release | O(1) ref update | fast-forward |
| Patch re-baseline | per patch release | O(pending) replayed × per-commit CI (small: 3–21 today) | rebase; merge driver auto-resolves the version |
| Forward-port across the chain | per glue change | O(diff) × active lines | cherry-pick; merge driver handles `DESCRIPTION` |
| **Major-flip linearization** | per major release | O(hundreds) — 402 pending on `main-dev` today | one-time rewind + replay (deferred, not continuous) |

The merge driver is what keeps the recurring rebases (patch re-baseline,
forward-port) cheap; the one genuinely expensive operation — the major-flip
linearization — is paid once, by design, rather than amortized into every patch
release.

### Flavor / identity

- **F1 — Name coherence.** Within a branch, `DESCRIPTION:Package`,
  `DUCKDB_PACKAGE_NAME`, `@useDynLib`, the `duckdb[._]L[._]types.hpp` filename,
  and the testthat names all agree and match the branch role: `stable` and
  `dev-base` → `duckdb` (per **S2**, `dev-base` is the un-renamed release);
  `lts` → `duckdb.L`; `dev` → `duckdb.L.dev`. The rename is exactly what
  distinguishes `dev` from `dev-base`.
- **F2 — Mechanical rename.** The rename is produced solely by `scripts/flavor.sh`;
  its non-name structure is identical across all series, differing only in the
  version token.

### Version

- **V1 — Prefix lock.** `major.minor` equals `L` on every branch of the series.
  *Exception:* the preview line carries a synthetic placeholder prefix greater
  than any current release (`main-dev` is `1.5.99.…`) until the flip sets the
  real number (e.g. `2.0.0`).
- **V2 — Patch ordering.** `stable` and `lts` share the released patch `Z`;
  `dev`/`dev-base` are at or ahead of `Z`.
- **V3 — Counters.** The **4th** component free-runs as the R-client dev counter
  *only* on the glue source of truth (`main`: `…9003`, `…9004`); on `-dev`
  branches it is a fixed marker (`.9000` / `.9001`). The **5th** component is the
  vendor counter, strictly monotone along `dev` (one bump per vendor commit).
  On a series-loop dev branch the seed's `chore: Add fifth version component`
  commit stamps it at `.0`;
  elsewhere it is absent until the first vendor commit mints `.1` —
  e.g. `v1.4-andium-dev` at `1.4.5.9000` has no vendor commits yet.
  Regular LTS flavors never carry a fifth component.
  Componentwise within the prefix, `dev ≥ dev-base ≥ stable`.
- **V4 — Release shape.** A released `stable`/`lts` version is the bare
  three-component prefix (no 4th/5th component).

### Source of truth (cross-series)

- **G1 — Glue monotone down the chain.** At the forward-port frontier,
  glue/R/tests/CI/cpp11 satisfy `main ⊇ newer-dev ⊇ … ⊇ older-dev`; older lines
  lag only by pending forward-ports. (S4 applied across the whole chain.)
- **G2 — Patch-stack derivation.** Each `dev`'s `patch/` equals `main`'s patch
  set minus the patches already merged into *that series'* upstream branch.
  `patch/` may therefore legitimately differ between series; it is never
  hand-authored per series beyond dropping patches that landed upstream.

### CI / green

- **C1 — Every `dev` commit is green** (`each.yaml`), so `dev` is bisectable
  end to end.
- **C2 — `stable`, `lts`, and `dev-base` tips are green** (former green `dev`
  tips or freshly checked re-baselines).

### Prerelease (during STABILIZE)

- **P1 — Release branches frozen.** Pre-release mutates only `main` (fold-back
  fixes) and `dev` (forward-ports + vendor); `stable`, `lts`, and `dev-base`
  stay at the previous release until CUT. A half-finished pre-release is
  abortable with zero rollback on the release branches.
- **P2 — Candidate ⊆ release.** The revdep-tested pinned candidate is an ancestor
  of the `dev` tip that will be cut; any delta added after a revdep run is
  reviewed (and re-checked if risky). What ships was tested.
- **P3 — Fold-back ordering.** Every fold-back fix lands on `main` before any
  `dev` (a `dev` fix lacking a `main` ancestor violates S4).
- **P4 — Freeze convergence (barrier).** At GLUE FREEZE, `git cherry main dev` is
  empty for *every* releasing series simultaneously, so all releasing lines share
  identical glue. This is the multi-line synchronization invariant.

## Release cycle mapping

Superseded by
[`operations/releases/process/`](/handbook/operations/releases/process/README.md),
which models the same cycle as a state machine — clusters, gates, and
what each phase must leave standing — without illustrative branch names
that go stale.

## Synchronization

Absorbed: the refs and how far each may move are
[`branches/model/`](/handbook/branches/model/README.md)'s,
the routine that moves them is
[`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)'s,
the per-commit checking is
[`operations/ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)'s,
and bringing a release onto its branch is
[`operations/releases/process/`](/handbook/operations/releases/process/README.md)'s.

## Patch Stack

The upstream C++ code in `src/duckdb/` may be updated to suit the needs of the R package, but not all updates are relevant or appropriate.
R-specific fixes are maintained as an ordered series of git-format patches under `patch/`.
Every vendor run re-applies the full stack on top of the freshly vendored sources.

```txt
  duckdb/duckdb (upstream)
        │
        │  vendor.sh / vendor-one.sh
        ▼
  src/duckdb/   ← raw vendored C++ sources
        │
        │  apply patch/0001-...patch
        │  apply patch/0002-...patch
        │  apply patch/0003-...patch
        │  ...
        ▼
  src/duckdb/   ← R-ready C++ sources (committed to branch)
```

Patches are numbered to define their application order.
Gaps in the numbering are normal — they indicate patches that were previously removed because the fix was accepted upstream.

When a patch is no longer needed (because the fix was merged upstream), delete the file. Do not renumber the remaining patches. When adding a new patch, assign it the next available number and send the same change as a pull request to `duckdb/duckdb` so it can be retired eventually.

A **forward-port** is the one kind of patch that needs no pull request: it carries a fix upstream has already merged, back onto the commits vendored before it.
It retires itself, and it is the escalation, not the default — a red vendor commit whose *next* commit fixes it is folded into that one instead ([troubleshooting](/handbook/operations/vendoring/troubleshooting/)).

If a vendor run fails because a patch no longer applies cleanly, update the patch against the new upstream code, commit it, and re-run vendoring.

## Version numbering

Absorbed into
[`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md),
including the merge driver, the prefix gate, and what a forward rebuild
renumbers.

## Tooling

### Existing tooling

| Script / Workflow               | Purpose                                                                                                    |
|---------------------------------|------------------------------------------------------------------------------------------------------------|
| `scripts/vendor.sh`             | Local manual vendoring from a cloned upstream repo                                                         |
| `scripts/vendor-one.sh`         | Commit-by-commit vendoring (called by the series-loop routine)                                             |
| `scripts/flavor.sh <flavor>`    | Applies the flavor rename (updates `flavor.patch`, then applies it and re-runs `cpp11::cpp_register()`)    |
| `scripts/flavor.patch`          | Patch template used by `flavor.sh`; contains `1.4` as placeholder version (replaced by `flavor.sh`)        |
| `scripts/each-plan.sh`          | Selects the commits without a build status and partitions them into contiguous, cost-balanced shards       |
| `scripts/each-cost.py`          | Counts the unity objects a commit invalidates, from the include graph, without building                    |
| `scripts/each-shard.sh`         | Builds one shard: many commits in one job and one workspace, writing the `rcc` status per commit           |
| `scripts/rcc-one.sh`            | The per-commit gate (style, snapshots, roxygen, clean tree, `R CMD check`, pkgdown), as a script           |
| `scripts/each-harvest.sh`       | Fan-in onto the orphan `rcc` branch: reconciles whatever the legs could not publish themselves              |
| `scripts/rcc-part-push.sh`      | Publishes one commit's record and log to the `rcc` branch from the leg that decided it, conflict-free       |
| `scripts/rcc-decided.sh`        | Lists the commits the `rcc` branch holds a verdict for; the single source work selection reads                |
| `scripts/rcc-merge.sh`          | Brings `runs2.ndjson` level with the per-commit records in `runs2.d/`: appends the missing, replaces the stale |
| `scripts/rcc-consolidate.sh`    | Manual: makes the two record layouts agree, drops logs past their retention, squashes `rcc` to two commits   |
| `scripts/merge-version.sh`      | Git merge driver for `DESCRIPTION`: combines the 4th/5th version counters, gated on an equal prefix         |
| `scripts/setup-git.sh`          | Registers the merge driver in `.git/config`, enables `rerere`, pins `rebase.backend=merge` (run per clone)  |
| `.github/workflows/sync.yaml`   | Hourly fast-forward of `krlmlr/main` from `duckdb/main`                                                    |
| `.github/workflows/each.yaml`   | Builds every statusless commit on push to `*-dev` branches, as a sharded matrix (see [`operations/ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)) |
| `.github/workflows/rcc-consolidate.yaml` | Manual (`workflow_dispatch`) consolidation of the `rcc` branch; dry run by default                 |
| `.github/workflows/fledge.yaml` | Daily version-bump PRs via `fledge`                                                                        |

### Proposed tooling

The following scripts would fill gaps in the current workflow.
They do not yet exist; this section documents the intent so they can be implemented incrementally.

**`scripts/sync-to-derived.sh <source-branch> <target-branch>`**

Computes the set of commits in `<source-branch>` not yet reachable from `<target-branch>`,
filters out vendor commits (matching `^vendor:`), and prints the `git cherry-pick` commands
needed to bring the target up to date.
Optionally opens a draft PR via `gh pr create --draft`.
Automates the forward-porting step for glue code and R code changes.

**`scripts/promote-dev.sh <series>`** (e.g., `promote-dev.sh v1.4-andium`)

Fast-forwards `<series>-dev-base` to match `<series>-dev` in `krlmlr/duckdb-r`.
Serves as Step 4 of the patch-release process; makes the comparison URL empty once a release is confirmed clean.

```bash
# Example:
scripts/promote-dev.sh v1.4-andium
# → git push krlmlr refs/heads/v1.4-andium-dev:refs/heads/v1.4-andium-dev-base
```

**`scripts/release-lts.sh <series> <version>`** (e.g., `release-lts.sh v1.4-andium 1.4.5`)

Orchestrates Steps 4–9 of the patch-release process for an LTS series:
promotes dev-base, opens a merge PR to the stable branch, bumps the version,
rebases the `-lts` branch, tags, and prints a CRAN submission checklist.

**Stale-branch CI check** (`.github/workflows/stale-branches.yaml`)

A scheduled workflow (e.g., daily) that runs `git merge-base --is-ancestor main <branch>` for each
active `-dev` branch and posts a GitHub Actions summary.
Alerts maintainers via a failing step when forward-porting is overdue by more than a configurable
number of commits or days.
