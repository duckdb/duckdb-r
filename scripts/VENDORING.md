# DuckDB R Package Vendoring

*Handbook: [`operations/vendoring/`](/handbook/operations/vendoring/README.md) —
its leaves state the model, the pipeline, the loop, and the
troubleshooting map, and are absorbing this file section by
section; where the two disagree, the leaf is right.*

What is left here is the hands-on mechanics:
what each script does and how to drive it by hand,
how a new dev line is started, and how to work a failing run.
The model, the invariants, the loop, and the version counters have been
absorbed into the handbook; the headings below say where.
For the branch strategy, the complete list of active branches, and the release process, see
[BRANCHES.md](/BRANCHES.md), which is the authoritative source.
For the historical design notes that led to the series loop,
see [history/vendoring-loop.md](/plan/history/vendoring-loop.md)
(superseded by `.claude/skills/series-loop.md`).

## What vendoring is, and why

`src/duckdb/` is a complete copy of the DuckDB C++ core, kept in this
repository instead of resolved at build time.
Absorbed into
[`operations/vendoring/model/`](/handbook/operations/vendoring/model/README.md),
which states the reasons and the invariants every `-dev` branch keeps.

## Which series exist

A series is *discovered from its refs*, not listed here.
Absorbed into
[`branches/model/`](/handbook/branches/model/README.md);
the published flavors are
[`branches/flavors/`](/handbook/branches/flavors/README.md)'s.

## Dev branch invariants

Absorbed into
[`operations/vendoring/model/`](/handbook/operations/vendoring/model/README.md).

## The Vendoring Scripts

Both scripts regenerate `src/duckdb/` from scratch
(`rm -rf src/duckdb`, then `DUCKDB_PATH=<clone> python3 scripts/rconfigure.py`),
re-apply the patch stack, and commit.
They differ only in how they choose *which* upstream commit to vendor.

| Script                  | Chooses                                             | Bumps version | Typical use                                                        |
|-------------------------|-----------------------------------------------------|---------------|--------------------------------------------------------------------|
| `scripts/vendor.sh`     | the upstream clone's `HEAD`, whatever it is          | no            | one-off / manual, and to **seed** a new dev line at the fork point  |
| `scripts/vendor-one.sh` | the next unvendored upstream commit(s), oldest first | yes           | the series loop, and any commit-by-commit walk                      |

Shared behaviour, in the order it happens:

1. **Locate the upstream clone.**
   The positional argument is the source repository (default `../../../duckdb`).
   Unless it is already called `duckdb`, it is cloned into `./duckdb` in the package root
   (which is `.gitignore`d), and that clone is `rm -rf`ed when the script exits.
   In CI the clone is created by `actions/checkout` into `./duckdb` instead.
2. **Refuse to run on a dirty tree.**
   `git status --porcelain` must be empty.
3. **Find the base.**
   The last `duckdb/duckdb@<sha>` mentioned in the subject of a recent commit that touched `src/duckdb/`.
   The pathspec narrows the walk, the subject decides:
   patch-stack fixes edit the vendored tree in place and carry no upstream SHA,
   so the scan looks past them — 20 commits deep, the same bound `vendored_sha()` uses
   in [`series-advance.sh`](series-advance.sh), and `BASE_SCAN_DEPTH` raises it.
   Coming up empty is not an answer: both scripts refuse and say which bound they hit,
   because an empty base turns the enumeration below into a range nobody chose.
   This is the *only* record of where the branch stands in upstream history:
   it is parsed out of the commit message, so vendor commit subjects must keep their exact format.
4. **Enumerate candidates** (`vendor-one.sh` only):
   `git log --first-parent --reverse <base>..<HEAD of clone>`.
   Upstream PR merges therefore count as one commit each,
   and commits reachable only through a second parent are never vendored on their own.
5. **Regenerate and patch.**
   For each candidate, check it out, regenerate `src/duckdb/`,
   then apply every `patch/*.patch` in order.
   **A patch that no longer applies is deleted**, and the deletion becomes part of the vendor commit —
   see [Patch Stack](/BRANCHES.md#patch-stack).
6. **Decide whether the commit is worth vendoring.**
   * If `git describe --tags <commit>` resolves to an exact tag (a release), it is **always** vendored,
     the subject gets a `(tag vX.Y.Z)` marker, and `vendor-one.sh` stops afterwards.
   * Otherwise the regenerated tree must differ in **more than one** file under `src/duckdb/`.
     One file always differs —
     `src/function/table/version/pragma_version.cpp` carries the `DUCKDB_SOURCE_ID` of every commit —
     so "more than one" is the test for a real change.
     Upstream commits that only touch tests, CI, docs, or other clients produce no vendor commit;
     the walk skips forward to the next candidate that does.
7. **Bump the package version** (`vendor-one.sh` only):
   the fifth component of `Version:` in `DESCRIPTION` is incremented
   (`1.5.4.9005` → `1.5.4.9005.1` → `…9005.2`),
   so every vendor commit is installable as a distinct version on r-universe.
8. **Commit** with the message described in [Understanding Vendor Commits](#understanding-vendor-commits).

`vendor-one.sh --commits N` repeats steps 3–8 up to `N` times (the routine uses 100),
stopping early on a tag or when no candidates remain.

### Two properties of the regenerated tree

**It is not byte-reproducible across clones.**
`src/function/table/version/pragma_version.cpp` records `DUCKDB_SOURCE_ID`
as an *abbreviated* commit id,
and git auto-sizes that abbreviation from the number of objects in the clone it runs in.
The same upstream commit therefore vendors as `7300522cf0` from one clone
and `7300522cf07` from another,
and `main-dev` contains both lengths at different points in its own history.
Nothing downstream breaks —
`configure` and `scripts/install-libduckdb.sh` both substring-match the id —
but a diff between two vendorings of the same upstream commit
will show this one line even when everything else is identical.
Pin `core.abbrev` in the upstream clone if an exact match matters.

**Step 5 costs about twice what it needs to.**
`rconfigure.py` rewrites all ~3550 vendored files unconditionally,
including the ~3548 whose content did not change.
That invalidates git's stat cache,
so both the "> 1 changed file" test in step 6 and the `git add` in step 8
re-hash the entire tree.
Measured: `git status` over the vendored tree costs **1.06 s** right after every file is touched
and **0.017 s** when the index is still valid.
At two full passes per *candidate* — including candidates that are skipped
because they changed nothing vendorable — this is the bulk of the per-commit cost
(measured end to end: ~4.9 s per vendor commit on 4 cores).
Writing only files whose content actually differs would roughly halve it,
in CI as well as locally.

## Version counters and the merge driver

Absorbed into
[`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md),
including the prefix gate and what it declines to renumber.

## Automated vendoring

Absorbed into
[`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md).
The `scripts/vendor-gate.sh` decision table that stood here documented a
script that has since been retired, and is gone with it.

## Manual Vendoring

### Local development setup

```bash
# Ensure your clone structure:
# ~/
#   duckdb/          # Upstream DuckDB repository
#   R/
#     duckdb-r/      # This repository

# Update DuckDB to desired branch/commit
cd ~/duckdb
git checkout desired_branch_or_commit

# Run vendoring
cd ~/R/duckdb-r
scripts/vendor.sh ../../../duckdb

# Build and test
R CMD INSTALL .
```

`vendor.sh` vendors the upstream clone's current `HEAD`,
so check the clone out at the exact commit you want before running it.

### Commit-by-commit vendoring, verified locally

This is the local equivalent of what CI does,
and the loop to use when replaying a long stretch of upstream history
(see [Starting a new dev line](#starting-a-new-dev-line-the-fork-point-rule)).
Check the upstream clone out at the **last** commit you want vendored,
so that the walk terminates by itself:

```bash
export MAKEFLAGS=-j$(nproc) NOT_CRAN=true DUCKDB_R_RUN_TESTS=true

while scripts/vendor-one.sh ../../../duckdb --commits 1; do
  rm -f src/*.o                                # see below — mandatory
  R CMD INSTALL . --no-byte-compile || break   # repair, then `git commit --amend`
  R -q -e 'testthat::test_local()'       || break
done
```

`rm -f src/*.o` is not an optimisation, it is required for the loop to mean anything.
The `src/*.dd` dependency files deliberately record only local `include/` headers
(`src/include/deps.mk` filters out everything under `duckdb/`),
so `make` does not know that the glue objects depend on the vendored engine headers.
Without the `rm`, the glue is never recompiled after vendoring:
API breakages go unnoticed and the package is linked from objects
built against a different engine.
A fresh CI checkout does not have this problem, which is why it only bites locally.

Three things make this affordable:

* **ccache.**
  Adjacent vendor commits change a median of two `.cpp` files and no headers,
  so a warm ccache turns a ~15 minute cold build into a couple of minutes;
  wide-header commits are the exception, not the rule
  (measured in [`experiments/2026-03-vendor-build-cost/`](/experiments/2026-03-vendor-build-cost/README.md)).
  Point R at it via `~/.R/Makevars` (`CXX = ccache g++`, …)
  and give it a cache large enough to hold several trees (`ccache --max-size=20G`).
  Note that ccache reads `$CCACHE_DIR/ccache.conf` (i.e. `~/.ccache/ccache.conf`)
  in preference to `~/.config/ccache/ccache.conf` once the legacy directory exists —
  a `--set-config` that lands in the wrong file silently keeps the 5 GB default.
* **Failing fast.**
  Most breakages are glue-code compile errors,
  and `OBJECTS = $(GLUE) $(SOURCES)` puts the ~15 glue files first,
  so they fail within a minute rather than after the engine has been rebuilt.
  To check the glue alone, without building anything, compile it with `-fsyntax-only`
  using the flags `R CMD INSTALL` prints.
* **Skipping the engine when it did not change.**
  With the objects already in place, a vendor commit that touches two `.cpp` files
  costs only those two plus the glue relink.

Measured on a 4-core container (R 4.5.3, ccache 4.9.1, `-O2` without `-g`, no LTO),
replaying 81 vendor commits of upstream `main` one at a time:
about 4 s to vendor and 30 s to run the testsuite, against ~50 minutes
for the initial cold build of a new engine tree.
Build time is strongly **bimodal**, and the split is what to plan around:

| | median | min | max | share under 2 min | total |
|---|---|---|---|---|---|
| 81 commits, fork point → 102 upstream first-parent commits later | 56 s | 15 s | 754 s | 46/80 (57 %) | ~5 h |

The cheap mode is a commit that changes only `.cpp` files;
the expensive mode is a commit touching a widely-included header,
which invalidates a large share of the ~345 unity objects at once.
Note that the mix depends on *which* branch is being replayed:
Appendix A of [history/vendoring-loop.md](/plan/history/vendoring-loop.md) measured a release branch,
where 66 % of commits touch no header at all,
whereas a mainline window in active pre-release development
runs closer to a 57/43 split — plan bulk replays off the pessimistic figure.

When a commit breaks, fix the glue and `git commit --amend`
so the fix lands *in* the vendor commit (invariant 3), then continue the loop.
Never run `R CMD build` in a working tree you still need:
the `cleanup` script runs `git clean -fdx src` and packs `src/duckdb/` into `src/duckdb.tar.xz`.

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
   [commit-by-commit loop](#commit-by-commit-vendoring-verified-locally).

Step 3 is only needed for the line that *rewinds*,
i.e. the mainline whose fork point predates the current release.
A dev line for a freshly cut release branch forks from `main`
at a point the package already builds against, so it needs no rewind.

## Understanding Vendor Commits

Vendor commits follow a specific format:

```text
vendor: Update vendored sources to duckdb/duckdb@<commit_hash>

Date: <author date of the upstream commit>

<subjects of the upstream first-parent commits since the previously vendored commit>
```

For tagged releases:

```text
vendor: Update vendored sources (tag v1.x.x) to duckdb/duckdb@<commit_hash>
```

The subject line is machine-readable state:
`vendor-one.sh`, `series-advance.sh`, `series-port.sh` and the repair skills
all recover "where is this branch in upstream history"
by parsing `duckdb/duckdb@<sha>` out of it.
Do not reword it, and do not squash vendor commits together
without keeping the newest SHA in the subject.

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

**Issue**: A patch silently disappeared from `patch/`
**Solution**: That is by design —
a patch that no longer applies is deleted by the vendor run,
on the assumption that the fix landed upstream.
Verify that assumption; if the patch is still needed, restore and rebase it against the new sources.
See [Patch Stack](/BRANCHES.md#patch-stack).

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

### Key vendoring files

- `scripts/vendor.sh` - Manual vendoring of one specific upstream state
- `scripts/vendor-one.sh` - Commit-by-commit vendoring (used by the series loop)
- `scripts/each-plan.sh` - Selects commits with no verdict on the `rcc` branch and shards them by predicted build cost
- `scripts/each-cost.py` - Counts the unity objects a commit invalidates, from the include graph
- `scripts/each-shard.sh` - Builds one shard of commits in a single job
- `scripts/rcc-one.sh` - The per-commit `rcc` gate
- `scripts/each-harvest.sh` - Folds the shards' results onto the orphan `rcc` branch
- `scripts/rcc-part-push.sh` - Publishes one commit's result to the `rcc` branch from the leg that decided it
- `scripts/rcc-decided.sh` - Lists the commits the `rcc` branch has a verdict for; what work selection reads (see [`per-commit builds`](/handbook/operations/ci/per-commit/README.md))
- `scripts/rcc-merge.sh` - Brings `runs2.ndjson` level with the records in `runs2.d/`
- `scripts/rcc-consolidate.sh` - Manual: makes the layouts agree, GCs logs older than a month, squashes the `rcc` branch
- `scripts/rconfigure.py` - Regenerates `src/duckdb/`, `src/include/sources.mk`, `R/version.R`
- `scripts/setup-git.sh` - Registers the `DESCRIPTION` merge driver, `rerere`, and `rebase.backend=merge`
- `scripts/merge-version.sh` - The merge driver itself (see [Version counters and the merge driver](#version-counters-and-the-merge-driver))
- `.github/workflows/each.yaml` - Per-commit CI as a sharded matrix (see [`per-commit builds`](/handbook/operations/ci/per-commit/README.md))
- `patch/*.patch` - R-specific patches applied to vendored code
  (see [Patch Stack](/BRANCHES.md#patch-stack))

### Vendored content

- `src/duckdb/` - Complete DuckDB C++ source code (DO NOT modify directly)
- `R/version.R` - The vendored **DuckDB** version, generated by `rconfigure.py`
- `src/include/sources.mk` - Object list for the package build, generated by `rconfigure.py`

### Generated content

- `./duckdb/` - Temporary clone of the DuckDB repository, removed when the script exits

## Development Guidelines

### When working with vendored code

1. **Never modify `src/duckdb/` directly** - changes will be overwritten by the next vendor run
2. **Use patches**: create `.patch` files in `patch/` for necessary changes,
   and send the same change upstream so the patch can be retired
3. **Update `rconfigure.py`**: for R-specific build configuration changes
4. **Keep the fix in the commit that needs it**:
   an R-side fix for a vendored API change belongs in the vendor commit that introduced the break,
   so the history stays bisectable

### Creating patches

```bash
# 1. Make changes to src/duckdb/
# 2. Generate patch
git diff > patch/00NN-my-fix.patch
# 3. Test that patch applies cleanly
git checkout -- src/duckdb/
patch -p1 < patch/00NN-my-fix.patch
```

## Release considerations

Absorbed into
[`operations/releases/process/`](/handbook/operations/releases/process/README.md).
