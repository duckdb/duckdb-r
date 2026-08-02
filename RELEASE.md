# R Package Release Process

*Handbook: [`operations/releases/process/`](/handbook/operations/releases/process/README.md).*

The release process is modelled as a finite state machine: four clusters
(TRACK, STABILIZE, CUT, RESET), the states inside them, the gate that leaves each
one, multi-line coordination, and failure and rollback. All of that now lives in
the handbook at
[`operations/releases/process/`](/handbook/operations/releases/process/README.md).
It remains the operational companion to [`BRANCHES.md`](BRANCHES.md), which
defines the branch model, the package flavors, and the **[series
invariants](BRANCHES.md#series-invariants)** the process must preserve at every
step.

The sections below have not moved yet; each is bound for a handbook leaf of its
own.

## STABILIZE — pre-release (≈ T−14 → tag)

Moved to
[`operations/releases/process/`](/handbook/operations/releases/process/README.md),
apart from the reverse-dependency runs.

### 0.2 / 0.4 Reverse-dependency checks

Run against the `.dev` build at the pinned commit. The first pass is early enough
to act on; the second (≈ T−7) is the go/no-go gate.

```r
remotes::install_github("r-lib/revdepcheck") # once
revdepcheck::revdep_check(num_workers = 8, env = c(MAKEVARS = "-j8"))
```

CRAN policy requires contacting affected maintainers **well beforehand**, which is
the entire reason this happens before the tag rather than after.

## CUT — release execution

Moved to
[`operations/releases/process/`](/handbook/operations/releases/process/README.md),
apart from the version bump and the CRAN submission.

### 4 MERGED — the version bump

The package version is **not** derived from the git tag — set it explicitly so
`DESCRIPTION` matches the upstream tag:

```r
fledge::bump_version("X.Y.Z")
```

### 5 PUBLISHED — CRAN submission

For the **current** line (the CRAN `duckdb` package), submit the source tarball at
<https://cran.r-project.org/submit.html>. The maintainer (currently Hannes)
confirms the upload, after which CRAN's automated checks run. CRAN acceptance is
**asynchronous** — it can take days and overlaps RESET and the next TRACK. If CRAN
rejects, fix on `stable` and re-enter CUT as a follow-up patch. LTS lines publish
to r-universe only and have no CRAN tail.

## RESET — re-baseline

Moved to
[`operations/releases/process/`](/handbook/operations/releases/process/README.md),
apart from the version handling.

The glue source of truth (`main`) separately moves to its ongoing development
version (4th component, e.g. `X.Y.Z.9000`) via `fledge`; the `dev` branches then
resume bumping the 5th (vendor) component from the new baseline.
