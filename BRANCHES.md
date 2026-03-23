# Branching Strategy

Version numbers are given at the time of writing (March 2026) and may be outdated by the time you read this.
The branching strategy is expected to remain stable.

## Why multiple R packages?

DuckDB releases a new minor version approximately every four months.
See <https://duckdb.org/docs/stable/dev/release_cycle> for a detailed description of the upstream release cycle.

CRAN does not allow multiple versions of the same package to coexist, so each supported release line needs its own package name (`duckdb`, `duckdb.1.4`, etc.).
LTS releases receive patch updates for one year — roughly three minor-release cycles — after which they are archived.
The `.dev` packages on r-universe mirror the corresponding bleeding-edge upstream branches and let users test upcoming releases without waiting for CRAN.

## R Package Flavors

Several packages are published, organised into three release lines:

| Package          | Install from   | Tracks                               | Description                                          |
|------------------|----------------|--------------------------------------|------------------------------------------------------|
| `duckdb`         | CRAN           | `duckdb/duckdb-r@v1.5-variegata`     | **Current stable release.**                          |
| `duckdb`         | r-universe     | `duckdb/duckdb-r@main`               | Current or upcoming release.                         |
| `duckdb.1.5`     | Does not exist |                                      | v1.5 is not an LTS version.                          |
| `duckdb.1.4`     | r-universe     | `duckdb/duckdb-r@v1.4-andium`        | **LTS — v1.4.** Receives only bug fixes.             |
| `duckdb.dev`     | r-universe     | `krlmlr/duckdb-r@main-dev`           | Bleeding-edge build of the next major/minor version. |
| `duckdb.1.5.dev` | r-universe     | `krlmlr/duckdb-r@v1.5-variegata-dev` | Bleeding-edge build on the v1.5 upstream.            |
| `duckdb.1.4.dev` | r-universe     | `krlmlr/duckdb-r@v1.4-andium-dev`    | Bleeding-edge build on the v1.4 upstream.            |

Use `duckdb` unless you need to pin to a specific minor version (LTS) or want to test unreleased functionality (`.dev`).

## Overview

Three moving parts work together to produce the published R packages:

```txt
duckdb/duckdb        krlmlr/duckdb-r         duckdb/duckdb-r       CRAN / r-universe
(upstream C++)       (CI/CD fork)            (canonical R pkg)
──────────────       ──────────────          ───────────────       ─────────────────
main            ──►  main-dev           ──►  main               ──►  duckdb (v1.6, r-universe)
                           └────►                                    duckdb.dev
v1.5-variegata  ──►  v1.5-variegata-dev ──►  v1.5-variegata     ──►  duckdb (v1.5, CRAN)
                           └────►                                    duckdb.1.5.dev
v1.4-andium     ──►  v1.4-andium-dev    ──►  v1.4-andium        ──►  duckdb.1.4 (LTS)
                           └────►                                    duckdb.1.4.dev

   │                     ^        │                ^
   │   vendor (hourly)   │        │ during release │
   │  with patches from  │        │   preparation  │
   │      patch/         │        │      only      │
   └─────────────────────┘        └────────────────┘
```

The arrow from upstream to the CI/CD fork represents automated vendoring; the arrow from the fork to the canonical repo represents the release merge. Patches from `patch/` are applied to the vendored C++ code during every vendor run (see [Patch Stack](#patch-stack) below).

## Repositories

This package lives in two GitHub repositories:

- **`duckdb/duckdb-r`** — the canonical repository. Stable and LTS branches are published to CRAN and r-universe from here.
- **`krlmlr/duckdb-r`** — a disconnected fork used exclusively for CI/CD, so that automated runs do not consume the `duckdb` organization's GitHub Actions quota. Development ("dev") branches live here.

The C++ database engine is vendored from **`duckdb/duckdb`** (referred to as *upstream*) into `krlmlr/duckdb-r`. The R glue code that wraps it lives in `duckdb/duckdb-r` and is synchronized with the dev branches.

## Branch Overview

| `duckdb` branch  | `krlmlr` dev branch  | R packages                        | Notes                         |
|------------------|----------------------|-----------------------------------|-------------------------------|
| `main`           | `main-dev`           | `duckdb.dev`                      | Source of truth for glue code |
| `v1.5-variegata` | `v1.5-variegata-dev` | `duckdb` (v1.5), `duckdb.1.5.dev` | Current release               |
| `v1.4-andium`    | `v1.4-andium-dev`    | `duckdb.1.4`, `duckdb.1.4.dev`    | LTS                           |

Stable branches (`duckdb/duckdb-r`) track released R package versions and are the source for CRAN releases and numbered r-universe releases (without the `.dev` suffix).
Dev branches (`krlmlr/duckdb-r`) track the corresponding bleeding-edge upstream branches and are published as `.dev` packages.

## Release Cycle Mapping

The upstream release cycle is documented at <https://duckdb.org/docs/stable/dev/release_cycle>.
This section summarises the parts that are relevant to the R package and describes what actions to take at each phase.
This assumes v1.5-variegata is the current release, v1.6 is in development, and v1.4-andium is current LTS; adjust branch names as needed for future cycles.
(These numbers are for illustrative purposes only; at the time of writing, the next release is expected to be v2.0.0.)

### Phase 1: Mid-Cycle (≈75% of the time)

Upstream active branches: `main`, `v1.5-variegata`, `v1.4-andium`.

This is business-as-usual. Automated vendoring runs hourly with no manual intervention required.

- Upstream patch releases (`v1.5.z`) cut from `v1.5-variegata` are picked up automatically by the corresponding `-dev` branch.
- When a patch release is tagged upstream, run the [On release](#on-release) flow for that branch.
- Forward-port glue code changes from `main` toward older branches as usual.

### Phase 2: Pre-Release

Upstream active branches: `main`, `v1.5-variegata`, `v1.6-codename` (newly created), `v1.4-andium`.

When the upstream team creates the new `v1.6-codename` branch, the R package temporarily becomes a three-branch extension:

```txt
  duckdb/duckdb branches          R package branches to create
  ──────────────────────          ────────────────────────────
  main                            (existing) krlmlr/duckdb-r@main-dev
  v1.4-andium                     (existing) krlmlr/duckdb-r@v1.4-andium-dev
  v1.5-variegata                  (existing) krlmlr/duckdb-r@v1.5-variegata-dev
  v1.6-codename  (new)  ──►       krlmlr/duckdb-r@v1.6-codename-dev  (create)
                                  duckdb/duckdb-r@v1.6-codename      (create)
```

Actions:

1. Create `v1.6-codename` in `duckdb/duckdb-r` (the future stable branch) from `main`.
2. Create `v1.6-codename-dev` in `krlmlr/duckdb-r` from `main` and configure CI to vendor from the upstream `v1.6-codename` branch.
3. Forward-port all current glue code from `main-dev` into the new dev branch as a starting point.
4. Add the new dev branch to the front of the forward-port chain:

```txt
duckdb/duckdb-r@main  →  krlmlr/duckdb-r@main-dev  →  krlmlr/duckdb-r@v1.6-codename-dev
                                                    ↘  krlmlr/duckdb-r@v1.5-variegata-dev  →  …
```

### Phase 3: Feature Freeze

Upstream active branches: `main`, `v1.5-variegata`, `v1.6-codename`

From the R package perspective, this phase is identical to Pre-Release.
Only bug fixes flow into `v1.6-codename`; new features target `main`.
No additional branch management is required.

### On new minor release (`v1.6.0`)

When upstream tags `v1.6.0`:

1. Run the [On release](#on-release) flow: merge `krlmlr/duckdb-r@v1.6-codename-dev` → `duckdb/duckdb-r@v1.6-codename`.
2. Publish the new `duckdb` CRAN package from `duckdb/duckdb-r@v1.6-codename`.
3. Decide whether `v1.5-variegata` is designated as an LTS release:
   - **If LTS**: keep its dev branch alive, register `duckdb.1.y` on r-universe, and add it to the forward-port chain.
   - **If not LTS**: stop vendoring into its dev branch and archive both branches.
4. Update the Branch Overview table and the R Package Flavors table in this document.

### On LTS expiry (one year after designation)

TBD.

## Synchronization

### Vendoring

CI/CD pipelines in `krlmlr/duckdb-r` unconditionally vendor the C++ code from the corresponding upstream branch and build the `.dev` package.
If vendoring breaks the build, it can be fixed after the fact in the same commit.
The `-dev` branches are not protected, so force-pushes are allowed to fix mistakes.

It is important that every commit in the `-dev` branches builds successfully so that the history is clean and bisectable.
For this reason, the `-dev` branches are checked commit by commit, even if multiple commits are pushed at once.

### On release

When a new version is released, the dev branch is merged into the corresponding stable branch:

```txt
krlmlr/duckdb-r@main-dev            →  duckdb/duckdb-r@main
krlmlr/duckdb-r@v1.5-variegata-dev  →  duckdb/duckdb-r@v1.5-variegata
krlmlr/duckdb-r@v1.4-andium-dev     →  duckdb/duckdb-r@v1.4-andium
```

### Ongoing

Glue code changes are forward-ported continuously from newer to older branches so that LTS branches stay up to date:

```txt
duckdb/duckdb-r@main  →  krlmlr/duckdb-r@main-dev  →  krlmlr/duckdb-r@v1.5-variegata-dev  →  krlmlr/duckdb-r@v1.4-andium-dev
```

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

If a vendor run fails because a patch no longer applies cleanly, update the patch against the new upstream code, commit it, and re-run vendoring.
