# DuckDB R Package Vendoring

This document covers the mechanics of vendoring:
what the scripts do, which invariants a dev branch must satisfy, how a new dev line is started,
and how to troubleshoot a failing run.
For the branch strategy, the complete list of active branches, and the release process, see
[BRANCHES.md](/BRANCHES.md), which is the authoritative source.
For the historical design notes that led to the series loop,
see [history/vendoring-loop.md](/plan/history/vendoring-loop.md)
(superseded by `.claude/skills/series-loop.md`).

## What is Vendoring?

Vendoring is the practice of including a copy of external dependencies directly in your source code repository.
The duckdb-r package vendors (includes a complete copy of) the DuckDB C++ core library in the `src/duckdb/` directory.

## Why Vendor DuckDB?

- **Self-contained builds**: The R package can be built without requiring users to have DuckDB installed separately
- **Version compatibility**: Ensures the R bindings work with a specific, tested version of the DuckDB core
- **CRAN compliance**: Meets CRAN requirements for packages to be self-contained
- **Reproducible builds**: Eliminates dependency on external DuckDB installations

## Active Dev Branches

All series are vendored by a single scheduled Claude routine — the **series
loop** (`.claude/skills/series-loop.md`) — into each series' `-build` branch,
and consumed from there into `-dev` (see `BRANCHES.md` for the full branch
list):

| Dev branch           | Vendors from upstream |
|----------------------|-----------------------|
| `v1.4-andium-dev`    | `v1.4-andium`         |
| `v1.5-variegata-dev` | `v1.5-variegata`      |
| `main-dev`           | `main`                |

To add a series, create its refs (see `.claude/skills/series-open.md`)
**and** update this table;
the one routine discovers the series from its refs.

## Dev Branch Invariants

Everything below exists to keep four properties true for every dev branch.
They are what makes the history useful rather than merely present.

1. **Linear.**
   First-parent history only, no merge commits.
   A merge lands a batch of changes as a single step whose components were never built individually.
2. **One upstream commit per vendor commit.**
   Each vendor commit corresponds to exactly one upstream commit on the tracked branch,
   and the vendored SHAs form a **contiguous first-parent walk** of that upstream branch —
   no gaps, no jumps, no going backwards.
3. **Green per commit.**
   Every commit builds and passes the testsuite on its own.
   That is what `each.yaml` verifies, and what makes `git bisect` meaningful.
   If a vendor commit needs an R-side fix to build, the fix is folded **into that commit**,
   never added as a follow-up — a follow-up leaves a red commit in the history forever.
4. **Auditable R-side delta.**
   Vendor commits touch only the mechanical path set
   (`src/duckdb/`, `R/version.R`, `src/include/sources.mk`, `DESCRIPTION`).
   Anything else in a vendor commit is a folded glue fix,
   and must be reviewable as a path-filtered diff (see [history/vendoring-loop.md](/plan/history/vendoring-loop.md) §3.4).

Invariant 2 is the one that is easy to lose.
It is violated the moment a dev branch is re-pointed at a different upstream branch
without re-basing its vendored history — see
[Starting a new dev line](#starting-a-new-dev-line-the-fork-point-rule).

## The Vendoring Scripts

The scripts, and what a run does step by step: [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).

## Version Counters and the Merge Driver

The merge driver, its wiring, and its prefix gate: [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).

## Automated Vendoring

Vendoring is driven by the routine described in
`.claude/skills/series-loop.md`: `scripts/vendor-one.sh` appends upstream
commits to `<series>-build` with a glue-only compile gate, and the routine
consumes them into `<series>-dev` at most 100 at a time, gated on the per-commit
`rcc` results harvested to branch `rcc`. There is no vendoring workflow; CI's
role is building each `-dev` commit (`each.yaml`) and recording results
(`rcc-logs.yaml`, every 30 minutes).

**Tooling is authored on `main` and ported by the loop.**
CI reads workflows and scripts from the branch it checks,
so a tooling fix takes effect for a series
once it sits on `<S>-dev`.
Porting is a stage of the series loop with an identity goal —
after it, `.github/`, `scripts/`, and `.claude/` on `<S>-dev`
are byte-identical to `main`'s:
a helper script cherry-picks everything `main` has gained
and closes the residue with one sync commit,
and the routine judges conflicts
(`scripts/series-port.sh`,
stage 4 of `.claude/skills/series-loop.md`;
the wider simplification is
[`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md)).
The next forward retires the ported commits,
whose content the new seed already carries.

`scripts/vendor-gate.sh` has been retired with the rest of the legacy dispatch
path ([`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md), D4).
It turned the `rcc` commit-status of a branch tip and the five commits before it
into one verdict for the daily vendoring run:

| Gate decision | Meaning                                                        | Action                                                                                                                    |
|---------------|----------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| `green`       | some commit in the window is `rcc=success`                     | rewind to the youngest green commit (re-applying any non-vendored commits above it), then vendor at most 100 commits on top |
| `red`         | no green in the window, but a failure/error                    | fail loudly — the breakage must be repaired before vendoring continues                                                    |
| `stale`       | no green/red, and a commit has had no `rcc` result for over 6h | fail loudly — CI never decided; investigate                                                                               |
| `undecided`   | no green/red, results still pending and younger than 6h        | succeed and do nothing; re-check tomorrow                                                                                 |

After a successful advance, `.github/workflows/each.yaml` (`scripts/each-plan.sh`)
builds every commit that does not yet have a build status,
which is what keeps invariant 3 checkable.
It groups them into contiguous shards balanced by predicted build cost
and gives each shard one job that walks its commits in a single workspace;
the per-commit `rcc` status is written exactly as before.
See [`EACH.md`](EACH.md).

The `stale`/`undecided` split keeps the loop patient with commits that are
legitimately still building,
while surfacing a genuinely stuck pipeline instead of waiting on it forever.

**Non-vendored commits are never overwritten.**
A vendor commit only regenerates `src/duckdb/` (plus the version bump),
so vendoring can re-create it from upstream at any time.
A *non-vendored* commit cannot be regenerated,
and the series loop never discards one:
`-green` only ever fast-forwards,
and repairs rewrite only the unverified range `-green..-dev`.
R-side work does not land on `-dev` directly at all —
it lands on `main`
and reaches a series by forwarding (`.claude/skills/series-forward.md`),
which rebuilds the series beside the old one
instead of rewriting it.

## Manual Vendoring

Vendoring by hand, and the local commit-by-commit loop: [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).

## Starting a New Dev Line: the Fork-Point Rule

When upstream cuts a release branch (say `v2.0-<codename>` off `main`),
the R package gains a new dev line.
The tempting shortcut — point an existing dev branch at the new upstream branch
and let `vendor-one.sh` catch up — silently breaks invariant 2,
because the branch's recorded base is a commit on the *old* upstream line.

What happens then is worth spelling out, because it happened to `main-dev`:

* `main-dev` was created from the v1.5-era package (vendoring the released `v1.5.0` tree)
  and re-pointed at upstream `main`.
* `vendor-one.sh` enumerated `<v1.5 base>..main`,
  whose oldest entries are the commits `main` accumulated
  **after the fork point but before the release**.
  So the first mainline vendor commit moved the vendored sources *backwards* in time —
  from released `v1.5.0` to a `main` commit two weeks older —
  while simultaneously skipping ahead:
  it landed 101 first-parent commits past the fork point in a single step.
* Those ~100 upstream commits were never built against the R glue,
  and a `git bisect` across that one commit answers nothing.

The rule that avoids this:

> **A new dev line starts with a vendor commit at the fork point of the two upstream branches,
> and walks forward from there, one upstream commit at a time.**

The fork point is the newest commit on the **first-parent chain of both** upstream branches.
It is not `git merge-base`:
upstream merges the release branch back into `main`,
which drags the merge base forward to just after the most recent release.

```bash
cd ~/duckdb
git rev-list --first-parent origin/main          > /tmp/main-fp
git rev-list --first-parent origin/v2.0-codename > /tmp/rel-fp
# newest commit present in both chains:
awk 'NR==FNR{a[$0];next} $0 in a{print; exit}' /tmp/main-fp /tmp/rel-fp
```

Day one of a new cycle then looks like this
(the series bootstrap — the fifth-component commit
and the four refs created equal at the seed tip — is
`.claude/skills/series-open.md`'s job;
this list is the sources-and-glue side it drives):

1. Create the new dev branch from the current package `main`
   (glue code, R code, CI — the [source of truth](/BRANCHES.md#source-of-truth)),
   and apply its flavor with `scripts/flavor.sh`,
   as the **first** commits of the branch —
   the rename touches the shared-object name and every `.Call()` entry point,
   so applying it later invalidates every build below it.

   `flavor.sh` has three prerequisites it does not check:
   GNU sed under the name `gsed` (present on macOS via Homebrew, absent on a plain Linux box),
   and the `cpp11` and `decor` R packages, needed for the `cpp11::cpp_register()` step.
   It commits the first of its two commits *before* reaching that step,
   so a missing prerequisite leaves the branch with a half-applied flavor;
   finish by hand with `cpp11::cpp_register()` and a second commit,
   and check that `src/cpp11.cpp` really carries the renamed `_duckdb_<flavor>_*` entry points.
2. Seed it with **one** vendor commit at the fork point:
   check the upstream clone out at that commit and run `scripts/vendor.sh`.
3. Rewind the R side as far as the fork-point engine requires,
   and fold it into the seed commit — that commit has to build and test green like any other.
   The package `main` tracks the *released* series,
   so it may already assume engine behaviour that the fork-point engine does not have.
   Three kinds of rewind come up, in rising order of bluntness:
   * **glue code** that calls an API introduced after the fork
     (take the hunk from the package state that matches this engine —
     the `vX.Y.0` tag, or the preceding LTS series);
   * **snapshots** that record engine output — error message wording, `test_all_types()` columns —
     which are simply older here;
   * **whole test files** added later for a feature this engine does not have yet.
     Deleting one is legitimate, but say so in the commit message,
     so the deletion can be undone at the vendor commit where the feature appears.

   Keep each rewind as small as the compiler and the testsuite demand.
   Reverting a whole file to its old state also reverts R-side improvements
   that have nothing to do with the engine.
4. Check the upstream clone out at the branch tip
   and walk forward with the
   [commit-by-commit loop](/handbook/operations/vendoring/pipeline/README.md).

Step 3 is only needed for the line that *rewinds*,
i.e. the mainline whose fork point predates the current release.
A dev line for a freshly cut release branch forks from `main`
at a point the package already builds against, so it needs no rewind.

## Understanding Vendor Commits

The vendor commit message, and why its subject is machine-readable state: [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).

## Troubleshooting

### Vendoring stopped working

1. **Check the harvest**: read `runs2.d/<xx>/<sha>.ndjson` and `logs2/` on branch
   `rcc` — `runs2.ndjson` accumulates the same records in one file
   (`scripts/series-check.sh` prints a per-series verdict, reading whichever of
   the two holds the commit).
2. **Gate says `red` or `stale`**: a commit near the tip is failing `rcc`, or never got a result.
   Repair the failing commit first (see the skills in `.claude/skills/`);
   vendoring resumes on its own once a green base is back in the window.
3. **Clean working directory**: both scripts abort on any uncommitted change.
4. **The base is unparseable**: if the recent commits touching `src/duckdb/`
   no longer carry a `duckdb/duckdb@<sha>` subject (e.g. after a manual squash),
   the script has no base and tries to vendor from the beginning of time.
   Restore a well-formed vendor subject.

### Manual recovery

```bash
# 1. Clone fresh DuckDB repository
git clone https://github.com/duckdb/duckdb.git /tmp/duckdb-vendor

# 2. Checkout target branch
cd /tmp/duckdb-vendor
git checkout v1.4-andium   # adjust to target series

# 3. Run manual vendor
cd /path/to/duckdb-r
scripts/vendor.sh /tmp/duckdb-vendor

# 4. Test build
R CMD INSTALL .
```

### Common issues

**Issue**: `Error: working directory not clean`
**Solution**: Commit or stash all changes before vendoring.

**Issue**: A patch disappeared from `patch/`
**Solution**: That is by design, and both vendor scripts only do it
when the patch reverses cleanly against the regenerated tree —
its change is already there, so it landed upstream.
A patch that neither applies nor reverses stops the run instead (exit 4).
See [the patch stack](/handbook/operations/vendoring/pipeline/README.md).

**Issue**: Build failures after vendoring
**Solution**: Usually a DuckDB C++ API change;
adapt the glue code in `src/*.cpp` / `src/include/` and fold the fix into the vendor commit.
If the R-specific build configuration is at fault, update `scripts/rconfigure.py`.

**Issue**: `src/*.dd` files change on every build
**Solution**: Spurious — revert with `git checkout -- src/*.dd`.
They should only change when a `.cpp` file gains or loses a local `#include`.

## Monitoring Vendoring

### Ahead/behind badges

Two ranges tell a human how far a series is,
and both stay clean linear counts by construction
(`-green` is always an ancestor of `-dev`,
and `-build-base` of `-build` —
the display ref `-build-base` exists for exactly this;
no script ever reads it back):

* **in flight** — pushed to CI, not yet trusted: `<S>-green..<S>-dev`
* **buffered** — vendored, not yet consumed: `<S>-build-base..<S>-build`

shields.io renders these from the public repo,
showing how many commits `head` is ahead of `base`:

```text
https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=<S>-green&head=<S>-dev&label=in%20flight
https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=<S>-build-base&head=<S>-build&label=buffered
```

The live table is the `Flavors` section of [`README.md`](/README.md) —
one row per flavor, these two badges
plus an *ahead* badge against the branch the series releases from,
and version badges for the CRAN and LTS rows.
`.claude/skills/series-open.md` documents its upkeep,
including the constraint that every ref a badge names
must live in `krlmlr/duckdb-r`:
shields.io compares within a single repository,
so release branches are mirrored into the fork and kept fresh.
Link a badge to the matching compare URL —
`https://github.com/krlmlr/duckdb-r/compare/<base>...<head>` —
which is the drill-down.
An upstream-lag badge ("how far behind `duckdb/duckdb` itself")
is not expressible this way — the comparison would cross repositories.

### GitHub Actions

- The routine reports each firing; branch `rcc` holds the harvested
  per-commit results (`runs2.d/<xx>/<sha>.ndjson`, `logs2/<sha>.log`, and
  `runs2.ndjson`), published within seconds of each commit being decided
- Check for `rcc` statuses on the individual commits of each `-dev` branch

### Commit history

Look for recent vendor commits:

```bash
git log --oneline --grep="^vendor:" -10
```

### Version tracking

Check what DuckDB version is currently vendored:

```bash
grep duckdb_version R/version.R            # DuckDB version string
git log -1 --grep="^vendor:" --format=%s   # upstream commit it came from
```

## Files and Directories

What each file in `scripts/` is for: the generated index, [`README.md`](README.md). What the pipeline generates and consumes: [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).

## Development Guidelines

Working with vendored code, and the patch-stack lifecycle: [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).

## Release Considerations

Which branch is released, and when, is governed by
[Release Cycle Mapping](/BRANCHES.md#release-cycle-mapping) in `BRANCHES.md`.
In short: CRAN releases come from the stable branches in `duckdb/duckdb-r`,
the `.dev` packages on r-universe are built from the dev branches in `krlmlr/duckdb-r`,
and the version in `DESCRIPTION` must match the upstream tag at release time.

---

This vendoring system ensures that the duckdb-r package stays synchronized with DuckDB development
while maintaining stability for end users.
