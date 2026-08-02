# The pipeline

The machinery that turns one upstream DuckDB commit into one vendor commit:
the two vendoring scripts,
what `rconfigure.py` regenerates,
the lifecycle of the patch stack,
and the `DESCRIPTION` merge driver
that keeps the version counters mergeable across vendor commits.
Why the engine is vendored at all,
and the one-commit-per-upstream-commit invariant,
are [`model/`](/handbook/operations/vendoring/model/README.md)'s;
the routine that runs these scripts on a schedule
is [`series-loop/`](/handbook/operations/vendoring/series-loop/README.md)'s;
a run that comes back red
is [`troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md)'s.

## The two scripts

[`scripts/vendor.sh`](/scripts/vendor.sh) and
[`scripts/vendor-one.sh`](/scripts/vendor-one.sh)
both regenerate `src/duckdb/` from scratch, re-apply the patch stack, and commit.
They differ in how they choose *which* upstream commit to vendor,
and in what they do afterwards.

| | `vendor.sh` | `vendor-one.sh` |
|---|---|---|
| Chooses | the upstream clone's `HEAD`, whatever it is | the next unvendored upstream commit, oldest first |
| Bumps the package version | no | yes, the fifth component |
| Checks the glue afterwards | no | yes, unless `--no-check-glue` |
| Typical use | one-off and manual, and to seed a new series | the series loop, and any commit-by-commit walk |

Shared behaviour, in the order it happens:

1. **Locate the upstream clone.**
   The positional argument is the source repository, default `../../../duckdb`.
   Unless it is already called `duckdb`,
   it is cloned into `./duckdb` in the package root, which is `.gitignore`d.
   `vendor-one.sh` reuses an existing `./duckdb` and `git fetch`es it;
   `vendor.sh` always clones, so a leftover `./duckdb` makes it fail.
   Both remove the clone when a run finishes —
   except when `vendor-one.sh`'s glue gate fails,
   where it is deliberately kept for the repair.
2. **Refuse to run on a dirty tree.**
   `git status --porcelain` must be empty.
   A dirty *upstream* clone is only a warning.
3. **Find the base.**
   The newest `duckdb/duckdb@<sha>` in the subject
   of the last 20 commits that touched `src/duckdb/`.
   The pathspec narrows the walk and the subject decides:
   patch-stack fixes edit the vendored tree in place and carry no upstream SHA,
   so the scan looks past them.
   `BASE_SCAN_DEPTH` raises the bound.
   Coming up empty is not an answer —
   both scripts refuse and name the bound they hit,
   because an empty base leaves a range with a missing left side
   that git resolves to the clone's `HEAD`, which nobody chose.
4. **Enumerate candidates** (`vendor-one.sh` only):
   `git log --first-parent --reverse <base>..<HEAD of clone>`.
   An upstream PR merge is therefore one candidate,
   and a commit reachable only through a second parent is never vendored on its own.
5. **Regenerate and patch.**
   Check the candidate out, `rm -rf src/duckdb`,
   run `rconfigure.py` against the clone,
   then apply the patch stack.
6. **Decide whether the candidate is worth a commit.**
   If `git describe --tags` resolves to an exact tag, it always is:
   the subject gains a `(tag vX.Y.Z)` marker, and `vendor-one.sh` stops after committing.
   Otherwise the regenerated tree must differ in **more than one** file under `src/duckdb/`.
   One file always differs —
   `src/duckdb/src/function/table/version/pragma_version.cpp`
   carries the `DUCKDB_SOURCE_ID` of every commit —
   so "more than one" is the test for a real change.
   Upstream commits that touch only tests, CI, docs, or other clients
   produce no vendor commit; the walk moves on to the next candidate.
7. **Bump the version** (`vendor-one.sh` only):
   the fifth component of `Version:` is incremented,
   missing components padded with zeroes
   (`1.5.4.9005` → `1.5.4.9005.1`, `1.2.3` → `1.2.3.0.1`),
   so every vendor commit is installable as a distinct version on r-universe.
8. **Commit** `git add .` with the message below.
9. **Gate the glue** (`vendor-one.sh` only):
   syntax-check every `src/*.cpp` against the freshly vendored headers,
   four at a time, with `g++ -fsyntax-only`
   and the flags a dry `R CMD SHLIB -n` prints
   (so they always match the local setup; `./configure` runs first if needed).
   It costs about 20 seconds, needs no link and no R session,
   and catches every upstream API change the glue has to follow.
   On failure the script exits 3
   with the breaking commit at `HEAD` and the failing files
   in `/tmp/vendor-one-glue-failures.txt`:
   fix the glue and amend, do not add a follow-up commit.

`vendor-one.sh --commits N` repeats steps 3–9 up to `N` times —
the series loop passes 100 —
stopping early on a tag or when no candidate remains.
Its `VENDOR_REPO` variable names the checkout to vendor *into*,
which must be the root of a worktree;
that is what lets the loop run `main`'s copy of the script against a series' buffer.
Only the script itself comes from `main` that way:
everything it invokes by relative path —
`scripts/rconfigure.py`, `patch/*.patch`, `./configure` —
stays the target tree's,
because those are coupled to the tree they generate and patch.

## What `rconfigure.py` regenerates

[`scripts/rconfigure.py`](/scripts/rconfigure.py) is where the vendored tree comes from.
It imports `package_build` from the *upstream clone's* own `scripts/`,
so upstream's packaging decides which sources are emitted;
`DUCKDB_PATH` points it at the clone.
It writes five committed things:

* `src/duckdb/` — the engine sources for the package,
  amalgamated into per-directory unity chunks
  wherever upstream's own `CMakeLists.txt` says `add_library_unity`,
  with `parquet` and `core_functions` linked in
  (`DUCKDB_R_EXTENSIONS` adds more — a build knob,
  see [`build/configuration/`](/handbook/build/configuration/README.md));
* `src/include/sources.mk` — the object list the build compiles;
* `R/version.R` — the vendored DuckDB version string,
  parsed out of `pragma_version.cpp` with its `v` prefix stripped;
* `src/Makevars` and `src/Makevars.win` — the include and link flags,
  filled into `src/Makevars.in`.

All five carry a "do not edit by hand" header, and all five are regenerated wholesale.
Two consequences are worth knowing before reading a diff:

**The tree is not byte-reproducible across clones.**
`DUCKDB_SOURCE_ID` is an *abbreviated* commit id,
and git auto-sizes that abbreviation from the number of objects in the clone it runs in.
The same upstream commit vendors as `7300522cf0` from one clone and `7300522cf07` from another,
and a single branch can contain both lengths at different points of its history.
Nothing downstream breaks —
`configure` compares only the first ten characters
when it checks a prebuilt library against the vendored headers —
but a diff between two vendorings of one upstream commit
shows this line even when everything else is identical.
Pin `core.abbrev` in the upstream clone if an exact match matters.

**Regeneration costs about twice what it needs to.**
All ~3550 vendored files are rewritten unconditionally,
including the ones whose content did not change,
which invalidates git's stat cache;
both the "more than one changed file" test and the `git add` then re-hash the whole tree.
Measured: `git status` over the vendored tree costs 1.06 s right after every file is touched
and 0.017 s when the index is still valid,
at two full passes per candidate — including candidates that are skipped —
which is the bulk of the ~4.9 s a vendor commit takes on four cores.
Writing only the files that actually differ would roughly halve it,
in CI as well as locally.
That is one of the items in
[`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md),
which carries the intent for this pipeline.

Two smaller facts about the script:
it drops the bundled jemalloc tree from the source list,
because the R package never defines `DUCKDB_ENABLE_JEMALLOC`
and upstream's packaging started emitting sources that neither compile nor link without it;
and `DUCKDB_BUILD_UNITY` is read from the environment,
parsed as an integer and rejected — with a message, and a non-zero exit —
when it is not a positive one;
unset or empty keeps the long-standing default of 20.
It reaches upstream's `build_package()` as its `unity_count` argument,
and there it currently does nothing:
upstream has accepted that argument without using it since well before v1.0.0,
because the grouping is decided per directory by `add_library_unity`.
So setting the knob is now honoured all the way to the call and no further —
which is what it should do, and worth knowing before reaching for it.
When `DUCKDB_R_BINDIR`, `DUCKDB_R_CFLAGS` and `DUCKDB_R_LIBS` are all set,
the script writes `src/Makevars` for a system-library build and exits
without touching the vendored tree at all.
That branch is reachable but stale:
it still fills a `{{ SOURCES }}` placeholder that `src/Makevars.in` no longer has,
so the generated `Makevars` keeps its `include include/sources.mk`
and would compile the whole vendored tree anyway.
The working route to a prebuilt library is `DUCKDB_R_USE_SYSTEM_LIB`,
which `configure` handles instead;
both belong to [`build/fast-paths/`](/handbook/build/fast-paths/README.md).

## The patch stack

Not every upstream source is right for the R package as it stands.
The R-specific fixes are kept as an ordered series of patches in
[`patch/`](/patch/),
and every vendor run re-applies the whole stack on top of the freshly regenerated tree,
in file-name order, with `patch -p1 --forward` after a dry run.
Numbers define the order; gaps in the numbering are normal
and mark patches that were retired.

The lifecycle has four moves:

* **Adding one.**
  Edit `src/duckdb/`, capture the diff as `patch/00NN-my-fix.patch` with the next free number,
  then check it applies against a clean tree:

  ```bash
  git diff > patch/00NN-my-fix.patch
  git checkout -- src/duckdb/
  patch -p1 < patch/00NN-my-fix.patch
  ```

  Send the same change to `duckdb/duckdb` as a pull request,
  so the patch can eventually be retired.
* **Dropping one.**
  When the fix lands upstream, delete the file. Never renumber the rest.
  Both scripts also drop it for you, and correctly:
  a patch that no longer applies forward but *reverses* cleanly
  is already present in the regenerated tree,
  which is exactly what "the fix landed upstream" looks like.
  The deletion becomes part of that vendor commit.
* **Breaking one.**
  A patch that neither applies forward nor reverses cleanly is a different case:
  its change is not in the tree and cannot be re-applied,
  because the code around it moved.
  Both scripts stop, exit 4, and name the patch,
  leaving the regenerated sources uncommitted in the working tree
  and the upstream clone in place.
  Rebase the patch against those sources — keep it outside the tree,
  `git checkout -- .`, put it back, and rerun —
  and delete it only after confirming its change is genuinely upstream.
  Rerunning `vendor.sh` also means clearing `./duckdb` first, or passing it,
  because that script always clones.
  One caution:
  a run that used to limp past a broken patch now halts, which is the point,
  but it does mean a series loop can stop where it previously did not.

Never edit `src/duckdb/` directly in a way you want to keep.
The next run regenerates the directory from scratch, and the edit is gone.
Which patches a given series carries is a series property, not a pipeline one —
each series' stack is `main`'s minus what already landed in *that* series' upstream branch,
stated as an invariant in
[`branches/invariants/`](/handbook/branches/invariants/README.md).

## The vendor commit

Both scripts write the same message:

```text
vendor: Update vendored sources to duckdb/duckdb@<commit_hash>

Date: <author date of the upstream commit>

<subjects of the upstream first-parent commits since the previous base>
```

with `(tag v1.x.x)` inserted after `sources` when the commit is an exact tag,
and `#N` in the collected subjects rewritten to a full
`https://redirect.github.com/duckdb/duckdb/pull/N` link.

The subject line is machine-readable state, not decoration.
It is the only record of where a branch stands in upstream history:
the base scan in step 3 parses it, and so do the series scripts and the repair playbooks.
Do not reword it,
and do not squash vendor commits together without keeping the newest SHA in the subject.

## The `DESCRIPTION` merge driver

The package version carries two counters that advance on different strands —
the fourth component on the R-client strand,
the fifth on the vendor strands, once per vendor commit (step 7 above).
What the counters mean and who sets them is
[`releases/versioning/`](/handbook/operations/releases/versioning/README.md)'s;
what keeps them from halting every rebase is here.

Because each strand owns one counter and freezes the other,
a merge or forward-port between them conflicts on the `Version:` line of *every* commit.
[`scripts/merge-version.sh`](/scripts/merge-version.sh) is a git merge driver
that resolves that one line by taking the component-wise maximum of the two sides.
The ownership split makes the maximum do the right thing without either side knowing about the other:
it keeps the fourth component from the R-client strand and the fifth from the vendor strand.
Every other line of `DESCRIPTION` still goes through a normal three-way merge,
so a genuine concurrent edit — two branches touching `Imports:`, say — still surfaces as a conflict.
If either side has no `Version:` line at all, the driver falls back to a plain three-way merge.

**The prefix gate.**
The driver combines counters only when the `major.minor.patch` prefix of both sides is equal;
otherwise it keeps *ours* verbatim and never inherits a foreign prefix.
That is a safety rail for cross-release forward-ports, such as 1.5.x onto the 1.4.x LTS.
It also means the driver does **not** renumber a dev branch when the base moves to a new patch release:
rebasing a series from `1.5.4.9005.N` onto a `1.5.5.9000` base
leaves every commit at the base version rather than producing `1.5.5.9000.1`, `…2`, `…3`,
and the vendor counter has to be re-applied explicitly, one commit at a time, as part of the rebase.
The gate is doing its job here, but this is the one case
where it silently does less than a reader might assume.

**Wiring it up** takes two things.
The `DESCRIPTION merge=ours-version` attribute lives in `.gitattributes` and is committed;
the *name → command* mapping cannot live in a versioned file, so it is not.
[`scripts/setup-git.sh`](/scripts/setup-git.sh) installs the mapping into `.git/config`,
enables `rerere` so a genuine resolution survives repeated rebases,
and pins `rebase.backend=merge` —
the patch/`am` backend bypasses merge drivers entirely, so a rebase would ignore the driver.
Run it once per clone,
and as the first step of any CI job that rebases, cherry-picks, or merges in this repository.

## Vendoring by hand

The scripts expect the upstream clone one level *above* the package clone —
`~/duckdb` next to `~/R/duckdb-r` is the layout the defaults assume.
For a single upstream state, check the clone out at the commit you want and run `vendor.sh`,
which vendors whatever `HEAD` is:

```bash
cd ~/duckdb && git checkout <branch-or-commit>
cd ~/R/duckdb-r && scripts/vendor.sh ../../../duckdb
R CMD INSTALL .
```

To replay a stretch of upstream history the way CI does,
check the clone out at the **last** commit you want vendored, so the walk terminates by itself,
and drive `vendor-one.sh` one commit at a time:

```bash
export MAKEFLAGS=-j$(nproc) NOT_CRAN=true DUCKDB_R_RUN_TESTS=true

while scripts/vendor-one.sh ../../../duckdb --commits 1; do
  rm -f src/*.o                                # see below — mandatory
  R CMD INSTALL . --no-byte-compile || break   # repair, then `git commit --amend`
  R -q -e 'testthat::test_local()'       || break
done
```

`rm -f src/*.o` is not an optimisation; without it the loop means nothing.
The `src/*.dd` dependency files deliberately record only local `include/` headers —
`src/include/deps.mk` filters out everything under `duckdb/` —
so `make` does not know that the glue objects depend on the vendored engine headers.
The glue is then never recompiled after vendoring:
API breakages go unnoticed,
and the package is linked from objects built against a different engine.
A fresh CI checkout does not have this problem, which is why it only bites locally.

Three things make the loop affordable.
**ccache**: adjacent vendor commits change a median of two `.cpp` files and no headers,
so a warm cache turns a cold build of ~15 minutes into a couple of minutes.
**Failing fast**: `OBJECTS = $(GLUE) $(SOURCES)` puts the 15 glue files first,
so a glue compile error surfaces within a minute
instead of after the engine has been rebuilt.
**Skipping the engine when it did not change**:
with the objects in place, a commit touching two `.cpp` files costs those two plus the relink.

Measured on a four-core container replaying 81 vendor commits of upstream `main`:
about 4 s to vendor and 30 s to run the testsuite per commit,
against ~50 minutes for the initial cold build of a new engine tree.
Build time is strongly **bimodal**, and the split is what to plan around —
a median of 56 s with 57 % of commits under two minutes, but a maximum of 754 s,
because a commit touching a widely-included header
invalidates a large share of the ~345 unity objects at once.
The mix depends on which branch is replayed:
a release branch is cheaper than a mainline window in active pre-release development,
so plan bulk replays off the pessimistic figure.

When a commit breaks, fix the glue and `git commit --amend`,
so the fix lands *in* the vendor commit that needs it and the history stays bisectable;
then continue the loop.
Never run `R CMD build` in a working tree you still need:
the `cleanup` script runs `git clean -fdx src` and packs `src/duckdb/` into `src/duckdb.tar.xz`.

## Limits

* **A walk that vendors nothing can leave the tree dirty.**
  When no candidate qualifies, `vendor-one.sh` restores `src/duckdb/` and stops,
  but `rconfigure.py` has already rewritten `R/version.R` and the generated `Makevars`
  for the last candidate it tried.
  On a dev branch the version string changes with almost every upstream commit,
  so this is the common case, and the *next* run then refuses on the dirty tree.
  `git checkout -- .` before rerunning. `vendor.sh` restores `R/version.R` as well.
* **There is no vendoring workflow.**
  Nothing under `.github/workflows/` runs these scripts;
  vendoring is driven by the routine, and CI's role is to build the commits it produces
  ([`ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)).
* **The pipeline vendors DuckDB, and one other thing.**
  [`scripts/vendor-rfuns.sh`](/scripts/vendor-rfuns.sh)
  copies the `rfuns` extension sources from a `duckdb-rfuns` checkout into `src/`,
  one commit per import.
  It shares the base-scan idea but nothing else:
  no patch stack, no version bump, no glue gate, and no routine drives it.
* **Seeding a new series is not a plain vendor run.**
  A new dev line has to start at the fork point of the two upstream branches,
  which is not `git merge-base`,
  and the R side has to be rewound to what that engine supports.
  That procedure belongs to
  [`series-loop/`](/handbook/operations/vendoring/series-loop/README.md).
