# DuckDB R Package Vendoring

*Handbook: [`operations/vendoring/`](/handbook/operations/vendoring/README.md) —
its leaves state the model, the pipeline, the loop, and the
troubleshooting map; where the two disagree, the leaf is right.*

What is left here is what those leaves do not carry yet:
driving the scripts by hand, and creating a patch.
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
(the replay [`series-open`](/.claude/skills/series-open/SKILL.md) drives when it splits a new line).
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

