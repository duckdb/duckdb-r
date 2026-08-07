# DuckDB R Package Vendoring

*Handbook: [`operations/vendoring/`](/handbook/operations/vendoring/README.md) —
its leaves state the model, the pipeline, the loop, and the
troubleshooting map; where the two disagree, the leaf is right.*

What is left here is what those leaves do not carry yet:
driving the scripts by hand, creating a patch, two properties of the
regenerated tree, starting a new dev line, the vendor commit format,
recovering a broken run, and the badges.
Every heading below is a candidate for absorption,
and this file goes away when the last one lands.
For the branch model and the series invariants see
[BRANCHES.md](/BRANCHES.md);
for the design notes behind the series loop see
[superseded/vendoring-loop.md](/plan/superseded/vendoring-loop.md).

What this file used to carry, and where each part lives now:

* what vendoring is, why, and the invariants every `-dev` branch keeps —
  [`vendoring/model/`](/handbook/operations/vendoring/model/README.md)
* which series exist —
  [`branches/model/`](/handbook/branches/model/README.md),
  and the published flavors
  [`branches/flavors/`](/handbook/branches/flavors/README.md)
* what the two vendor scripts share — the dirty-tree refusal, the base
  scan, the more-than-one-file rule, the version bump, what
  `rconfigure.py` regenerates, and the patch stack —
  [`vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)
* the version counters and the merge driver —
  [`releases/versioning/`](/handbook/operations/releases/versioning/README.md)
* the automated loop —
  [`vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)
* the failure classes and what each needs —
  [`vendoring/troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md)
* release considerations —
  [`releases/process/`](/handbook/operations/releases/process/README.md)
* what each script in this directory does —
  [`scripts/README.md`](README.md), the generated index of this directory

## Driving the scripts by hand

[`vendor.sh`](vendor.sh) vendors the upstream clone's `HEAD` as it stands,
so check the clone out at the exact commit you want before running it;
[`vendor-one.sh`](vendor-one.sh) walks forward instead, one unvendored
upstream first-parent commit at a time.
What the two share is
[`pipeline/`](/handbook/operations/vendoring/pipeline/README.md)'s.
Three things an operator needs beyond what it states:

* **Where the upstream clone goes.**
  The positional argument is the source repository, and where each
  script looks when it is omitted is
  [`pipeline/`](/handbook/operations/vendoring/pipeline/README.md)'s.
  Unless it is already called `duckdb`, it is cloned into `./duckdb` in
  the package root — which is `.gitignore`d — and that clone is `rm -rf`ed
  when the script exits.
  In CI `actions/checkout` creates it there instead.
* **How far `vendor-one.sh` goes.**
  `--commits N` repeats the walk up to `N` times (the routine uses 100),
  stopping early when no candidates remain — or at a tag:
  a candidate that `git describe --tags` resolves exactly is always
  vendored, its subject gets a `(tag vX.Y.Z)` marker, and the run ends
  there.
* **How deep the base scan looks.**
  Twenty commits, the same bound `vendored_sha()` uses in
  [`series-advance.sh`](series-advance.sh); `BASE_SCAN_DEPTH` raises it.

### Local setup

```bash
# A clone structure the default reaches, three levels up:
# ~/git/
#   duckdb/              # Upstream DuckDB repository
#   R/
#     duckdb/
#       duckdb-r/        # This repository

# Update DuckDB to desired branch/commit
cd ~/git/duckdb
git checkout desired_branch_or_commit

# Run vendoring; any other layout passes the path instead
cd ~/git/R/duckdb/duckdb-r
scripts/vendor.sh

# Build and test
R CMD INSTALL .
```

### Creating a patch

The stack's rules — application order, numbering, when a patch retires —
are [Patch Stack](/BRANCHES.md#patch-stack).
Producing one is a diff against the freshly regenerated tree:

```bash
# 1. Make changes to src/duckdb/
# 2. Generate patch
git diff > patch/00NN-my-fix.patch
# 3. Test that patch applies cleanly
git checkout -- src/duckdb/
patch -p1 < patch/00NN-my-fix.patch
```

### Commit-by-commit vendoring, verified locally

This is the local equivalent of what CI does,
and the loop to use when replaying a long stretch of upstream history
(see [Starting a new dev line](#starting-a-new-dev-line-the-fork-point-rule)).
Check the upstream clone out at the **last** commit you want vendored,
so that the walk terminates by itself:

```bash
export MAKEFLAGS=-j$(nproc) NOT_CRAN=true DUCKDB_R_RUN_TESTS=true

while scripts/vendor-one.sh --commits 1; do
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
Appendix A of [superseded/vendoring-loop.md](/plan/superseded/vendoring-loop.md) measured a release branch,
where 66 % of commits touch no header at all,
whereas a mainline window in active pre-release development
runs closer to a 57/43 split — plan bulk replays off the pessimistic figure.

When a commit breaks, fix the glue and `git commit --amend`
so the fix lands *in* the vendor commit, then continue the loop.
Never run `R CMD build` in a working tree you still need:
the `cleanup` script runs `git clean -fdx src` and packs `src/duckdb/` into `src/duckdb.tar.xz`.

## Two properties of the regenerated tree

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

**Regeneration costs about twice what it needs to.**
`rconfigure.py` rewrites all ~3550 vendored files unconditionally,
including the ~3548 whose content did not change.
That invalidates git's stat cache,
so both the more-than-one-file test and the `git add` that follows
re-hash the entire tree.
Measured: `git status` over the vendored tree costs **1.06 s** right after every file is touched
and **0.017 s** when the index is still valid.
At two full passes per *candidate* — including candidates that are skipped
because they changed nothing vendorable — this is the bulk of the per-commit cost
(measured end to end: ~4.9 s per vendor commit on 4 cores).
Writing only files whose content actually differs would roughly halve it,
in CI as well as locally.

## Starting a New Dev Line: the Fork-Point Rule

When upstream cuts a release branch (say `v2.0-<codename>` off `main`),
the R package gains a new dev line.
The tempting shortcut — point an existing dev branch at the new upstream branch
and let `vendor-one.sh` catch up — silently breaks the one-upstream-commit-per-vendor-commit
invariant, because the branch's recorded base is a commit on the *old* upstream line.

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

   `flavor.sh` needs GNU sed, and the `cpp11` and `decor` R packages for its
   `cpp11::cpp_register()` step — the `cpp11` being `krlmlr/cpp11`
   ([`handbook/architecture/glue/`](/handbook/architecture/glue/README.md)).
   On macOS, GNU sed means `gsed`, from Homebrew.
   A missing or wrong one costs a rerun and nothing else:
   the script refuses a dirty tree, prepares the whole rename before it
   commits anything, and restores the tree if it cannot finish.
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

The failure classes and what each needs are
[`vendoring/troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md)'s.
Two things that leaf does not carry:

**Rebuilding the upstream clone from scratch**, when a broken or
half-updated clone is the suspect:

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

**`src/*.dd` files changing on every build** is spurious —
revert with `git checkout -- src/*.dd`.
They should only change when a `.cpp` file gains or loses a local `#include`.

## Monitoring Vendoring

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
