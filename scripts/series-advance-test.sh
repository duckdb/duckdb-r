#!/bin/bash
# Check stage 5's carry of the base series' test-side fixes, offline, against a
# synthetic remote and clone built here -- no network, no fixtures on disk.
#
# The split this rests on is how far a fix was demanded (duckdb/duckdb-r#2594):
# `-build` holds what the code needs to **compile**, because that is what the
# vendor gate checks, and `-dev` holds everything CI asked for after that --
# including glue, which is why the carry is a difference and not an allow-list.
# A forward series inherits only the first when its buffer is replayed. Ten
# things are checked.
#
#   1. A buffered commit whose base `-dev` twin folded a test-side fix is minted
#      with that fix in the same commit -- not stacked above it -- carrying the
#      twin's message and a trailer naming where it came from.
#   2. Glue the twin has beyond its `-build` commit is carried, because the
#      buffer already compiles and anything on top of it was demanded by
#      something later than the compiler -- and it is reported, because glue
#      missing from the base buffer is drift that wants mirroring there.
#   3. Glue the buffer already carries is applied once, by the pick. That is
#      what taking the difference buys over replaying the twin wholesale.
#   4. The buffer's own strand is never carried: `src/duckdb/` and `patch/`,
#      which a forward regenerates from its own patches.
#   5. What vendoring regenerates is never carried -- `R/version.R`,
#      `src/include/sources.mk` -- since it differs between any two runs of the
#      same upstream SHA and is noise, not a fix.
#   6. A series with no base to mine -- not a forward, or a forward whose base
#      is gone after cutover -- behaves exactly as it did before this existed,
#      and a chunk with no carry still moves the ref rather than replaying.
#   7. A conflicting carry stops the run with the conflict in a worktree that is
#      kept, writes no ref, and names both commits.
#   8. `--continue` finishes the resolved commit with the twin's message and
#      completes the rest of the chunk.
#   9. Starting a second run while one is stopped refuses rather than replaying
#      over the resolution; `--abort` discards it and writes no ref.
#  10. The fifth version component still rises once per vendor commit, carry or
#      no carry.
#
# Usage:
#   scripts/series-advance-test.sh
#
# Environment variables:
#   KEEP - if non-empty, do not delete the scratch directory

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SCRATCH=$(mktemp -d)
[ -n "${KEEP:-}" ] || trap 'rm -rf "$SCRATCH"' EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac; }
hasnt() { case "$2" in *"$3"*) no "$1"; echo "     unexpected: $3" ;; *) ok "$1" ;; esac; }

# --- the fixture -----------------------------------------------------------
#
# A bare remote plus a clone, because stage 5 reads `origin/*` and pushes. The
# shape is one base series that has been through repair -- so its `-dev` carries
# folds its `-build` never saw -- and a forward series whose buffer was replayed
# out of that `-build` and therefore has none of them.
#
# The verdict store is stubbed on an `rcc2` branch: stage 5 refuses to extend
# over a `failure`, and reads `missing` for anything absent, which is what a
# freshly pushed commit looks like.

REMOTE=$SCRATCH/remote.git
WORK=$SCRATCH/work
git init -q --bare -b main "$REMOTE"

git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$REMOTE"

mkdir -p scripts src/duckdb src/include tests/testthat/_snaps R patch
cp "$HERE/series-advance.sh" "$HERE/setup-git.sh" "$HERE/merge-version.sh" scripts/
chmod +x scripts/*.sh
echo 'DESCRIPTION merge=ours-version' > .gitattributes

desc() { printf 'Package: duckdb\nVersion: %s\n' "$1" > DESCRIPTION; }
verfile() { echo "duckdb_version <- \"$1\"" > R/version.R; }

desc 1.0.0.9000.0
verfile seed
echo 'seed glue' > src/glue.cpp
echo 'snapshot one' > tests/testthat/_snaps/sql.md
echo 'snapshot types' > tests/testthat/_snaps/types.md
echo 'foo <- function() 1' > R/foo.R
mkdir -p src/duckdb
echo 'vendored at the seed' > src/duckdb/seed.cpp
echo 'generated sources list' > src/include/sources.mk
git add -A
git commit -qm 'vendor: Update vendored sources to duckdb/duckdb@0000000'
git branch base-seed

# The seed carries a vendor commit because a real one does: a forward's seed is
# a flavored `main`, whose history is vendor commits. `vendored_sha` walks past
# a `-dev` that has none of its own and lands there, which is how stage 5 finds
# the anchor on a forward series' first extension.

# --- the base series' buffer: compile-side only -----------------------------
bvendor() { # <sha> <version> <file> [<glue>]
  mkdir -p src/duckdb
  echo "vendored $1" > "src/duckdb/$3"
  [ -z "${4:-}" ] || echo "$4" > src/glue.cpp
  desc "$2"; verfile "build-$1"
  echo "generated sources list for $1" > src/include/sources.mk
  git add -A
  git commit -qm "vendor: Update vendored sources to duckdb/duckdb@$1"
}

bvendor aaaaaaa 1.0.0.9000.1 a.cpp
bvendor bbbbbbb 1.0.0.9000.2 b.cpp 'glue adapted for bbbbbbb'
bvendor ccccccc 1.0.0.9000.3 c.cpp
bvendor ddddddd 1.0.0.9000.4 d.cpp
bvendor eeeeeee 1.0.0.9000.5 e.cpp
git branch base-build

# --- the base series' -dev: the same, with what CI demanded folded in -------
git checkout -q -b base-dev base-seed
amend() { git add -A; git log -1 --format=%B | { cat; echo; echo "$1"; } | git commit -q --amend -F-; }

# aaaaaaa: a snapshot fold -- the archetype (claim 1).
bvendor aaaaaaa 1.0.0.9000.1 a.cpp
echo 'snapshot one, corrected' > tests/testthat/_snaps/sql.md
amend 'Snapshot corrected for the new engine output.'

# bbbbbbb: the buffer's own glue, unchanged (claim 3), plus a second glue file
# the tests demanded (claim 2), the buffer's strand (claim 4) and the
# regenerated bookkeeping (claim 5).
bvendor bbbbbbb 1.0.0.9000.2 b.cpp 'glue adapted for bbbbbbb'
echo 'rapi fix the tests demanded' > src/rapi.cpp
echo 'patched' > patch/0001-fix.patch
echo 'in-place patch effect' >> src/duckdb/b.cpp
echo 'generated sources list, per dev' > src/include/sources.mk
verfile 'dev-bbbbbbb'
amend 'Glue fix a test demanded, plus bookkeeping that is not a fix.'

# ccccccc: nothing folded at all.
bvendor ccccccc 1.0.0.9000.3 c.cpp

# ddddddd: an R-code fix (claim 1, second shape).
bvendor ddddddd 1.0.0.9000.4 d.cpp
echo 'foo <- function() 2' > R/foo.R
amend 'foo() returns 2 now.'

# eeeeeee: a snapshot the forward series has since changed for itself (claim 5).
bvendor eeeeeee 1.0.0.9000.5 e.cpp
echo 'snapshot types, per the base' > tests/testthat/_snaps/types.md
amend 'Types snapshot follows the engine.'

git branch base-green base-dev
git branch base-build-base base-build

# --- the forward series -----------------------------------------------------
# Its buffer is the base buffer's content -- compile side only -- and its -dev
# starts at the seed with one commit of its own R side, so the last carry
# conflicts.
git checkout -q -b base-fwd-build base-build
git checkout -q -b base-fwd-dev base-seed
echo 'snapshot types, per the forward' > tests/testthat/_snaps/types.md
git add -A
git commit -qm 'test: the forward series has its own types snapshot'
git branch base-fwd-green base-fwd-dev
git branch base-fwd-build-base base-fwd-build

# --- a series with no forward and no base to mine (claim 4) -----------------
git checkout -q -b solo-dev base-seed
git branch solo-green solo-dev
git checkout -q -b solo-build base-seed
bvendor fff1111 1.0.0.9000.1 f.cpp
bvendor fff2222 1.0.0.9000.2 g.cpp
git branch solo-build-base base-seed

# The store stub: stage 5 refuses over a `failure` and reads `missing` for
# anything absent, which is what a freshly pushed commit looks like.
git checkout -q --orphan rcc2
git rm -rqf .
git commit -q --allow-empty -m 'chore: empty store'

git checkout -q main
git push -q origin main base-seed base-build base-dev base-green base-build-base \
  base-fwd-build base-fwd-dev base-fwd-green base-fwd-build-base \
  solo-build solo-dev solo-green solo-build-base rcc2
git fetch -q origin

run() { set +e; scripts/series-advance.sh "$@" 2>&1; echo "EXIT=$?"; set -e; }
at() { # <series> <upstream sha> -> the -dev commit vendoring it
  git log --format='%H %s' "origin/$1-green..origin/$1-dev" | grep -m1 "duckdb@$2" | cut -d' ' -f1
}
wat() { # <upstream sha> -> the same, inside the kept worktree
  git -C "$WT" log --format='%H %s' | grep -m1 "duckdb@$1" | cut -d' ' -f1
}

# --- claims 1-3, 5, 8: extend the forward series ----------------------------
echo
echo "== extending base-fwd from its buffer, mining base-dev"
out=$(run base-fwd)

has "reports how many carry a fix" "$out" 'carry a fix from origin/base-dev'
has "stops on the conflicting carry" "$out" 'conflicted'
has "names the twin it came from"    "$out" 'carrying the test-side fix from'
has "names the stage-5 resume"       "$out" 'series-advance.sh base-fwd --continue'
has "says no ref was written"        "$out" 'No ref was written.'

git fetch -q origin
is "nothing was pushed" \
  "$(git rev-list --count origin/base-fwd-green..origin/base-fwd-dev)" 0

WT=$(awk '{print $1}' .git/series-advance-base-fwd)
is "the worktree is kept"    "$([ -d "$WT" ] && echo yes)" yes
is "with the conflict in it" "$(git -C "$WT" diff --name-only --diff-filter=U)" 'tests/testthat/_snaps/types.md'
# The pick lands and the carry conflicts on top of it, so the fifth commit
# exists and is waiting for its amend -- which is why the resume knows to
# finish it as a carry rather than as a pick.
is "five commits made, the last awaiting its carry" \
  "$(git -C "$WT" rev-list --count origin/base-fwd-dev..HEAD)" 5
is "and the stopped half is recorded as the carry" \
  "$(awk '{print $4}' .git/series-advance-base-fwd)" carry

# 1. the fold rode in, in the commit that needed it, not stacked above it.
A=$(wat aaaaaaa)
is "carried commit holds the corrected snapshot" \
  "$(git -C "$WT" show "$A:tests/testthat/_snaps/sql.md")" 'snapshot one, corrected'
has "and keeps the twin's prose" "$(git -C "$WT" log -1 --format=%B "$A")" 'Snapshot corrected'
has "and names its provenance"   "$(git -C "$WT" log -1 --format=%B "$A")" 'Carried from `origin/base-dev`'
is "the carry is folded in, not stacked" \
  "$(git -C "$WT" rev-list --count "origin/base-fwd-dev..$A")" 1

D=$(wat ddddddd)
is "the R-code fix is carried too" "$(git -C "$WT" show "$D:R/foo.R")" 'foo <- function() 2'

# 2. glue beyond the buffer's carries, and is reported as drift.
B=$(wat bbbbbbb)
is "glue the tests demanded is carried" \
  "$(git -C "$WT" show "$B:src/rapi.cpp")" 'rapi fix the tests demanded'
has "and the drift is reported"       "$out" 'carry glue the base buffer does not have'
has "naming where to mirror it"       "$out" 'mirror it onto base-build'
has "and the path"                    "$out" 'src/rapi.cpp'

# 3. glue the buffer already has is the pick's, applied once.
is "shared glue applied once" \
  "$(git -C "$WT" show "$B:src/glue.cpp")" 'glue adapted for bbbbbbb'
is "and is not in the carry set" \
  "$(git -C "$WT" show --format= --name-only "$B" | grep -c '^src/glue.cpp$')" 1

# 4, 5. the buffer's strand and the regenerated bookkeeping stay behind.
is "no patch/ is carried" \
  "$(git -C "$WT" show --format= --name-only "$B" | grep -c '^patch/' || true)" 0
is "the in-place src/duckdb repair is not carried" \
  "$(git -C "$WT" show "$B:src/duckdb/b.cpp")" 'vendored bbbbbbb'
is "R/version.R stays the buffer's" \
  "$(git -C "$WT" show "$B:R/version.R")" 'duckdb_version <- "build-bbbbbbb"'
is "src/include/sources.mk stays the buffer's" \
  "$(git -C "$WT" show "$B:src/include/sources.mk")" 'generated sources list for bbbbbbb'

# 8. the counter rises once per vendor commit.
is "counter runs 1..5 over the commits made so far" \
  "$(git -C "$WT" log --reverse --format=%H origin/base-fwd-dev..HEAD |
       while read -r c; do git -C "$WT" show "$c:DESCRIPTION" | sed -n 's/^Version: //p'; done | tr '\n' ' ')" \
  '1.0.0.9000.1 1.0.0.9000.2 1.0.0.9000.3 1.0.0.9000.4 1.0.0.9000.5 '

# --- claim 7: a second run refuses --------------------------------------------
echo
echo "== refusing to start beside a stopped replay"
out=$(run base-fwd)
has "refuses a fresh run"      "$out" 'has a stopped replay'
has "and points at both exits" "$out" '--continue, or discard it with --abort'
git fetch -q origin
is "still nothing pushed" "$(git rev-list --count origin/base-fwd-green..origin/base-fwd-dev)" 0

out=$(run base-fwd --continue)
has "and --continue on an unresolved tree stops again" "$out" 'conflicted'

# --- claim 7, second half: --abort discards a stopped replay ------------------
echo
echo "== --abort discards it"
out=$(run base-fwd --abort)
has "abort says what it did"    "$out" 'stopped replay discarded; no ref was written'
is "the worktree is gone"       "$([ -d "$WT" ] && echo yes || echo no)" no
is "and the state file with it" "$(ls .git | grep -c series-advance || true)" 0
git fetch -q origin
is "and still nothing pushed" "$(git rev-list --count origin/base-fwd-green..origin/base-fwd-dev)" 0

# Aborting leaves the work to be done, so the next run reaches the same stop.
out=$(run base-fwd)
has "the next run stops at the same place" "$out" 'conflicted'
WT=$(awk '{print $1}' .git/series-advance-base-fwd)

# --- claim 6: resolve and continue --------------------------------------------
echo
echo "== resolving and continuing"
echo 'forward types snapshot, updated for the engine' > "$WT/tests/testthat/_snaps/types.md"
git -C "$WT" add tests/testthat/_snaps/types.md
out=$(run base-fwd --continue)
has "resumes at the stopped commit" "$out" 'resuming at'
has "and pushes the extended dev"   "$out" 'dev ->'

git fetch -q origin
is "all five buffered commits are now on dev" \
  "$(git rev-list --count origin/base-fwd-green..origin/base-fwd-dev)" 5
E=$(at base-fwd eeeeeee)
is "the resolved commit keeps the resolution" \
  "$(git show "$E:tests/testthat/_snaps/types.md")" 'forward types snapshot, updated for the engine'
has "and takes the twin's message" "$(git log -1 --format=%B "$E")" 'Types snapshot follows the engine'
has "with the provenance trailer"  "$(git log -1 --format=%B "$E")" 'Carried from `origin/base-dev`'
is "no state file survives"        "$(ls .git | grep -c series-advance || true)" 0
is "the kept worktree is gone"     "$([ -d "$WT" ] && echo yes || echo no)" no

is "nothing to abort once finished" "$(run base-fwd --abort)" "base-fwd: nothing to abort
EXIT=0"

# --- claim 4: a series with no base to mine -----------------------------------
echo
echo "== a series with no base series to mine"
out=$(run solo)
hasnt "says nothing about carrying" "$out" 'carry a fix from'
has   "and moves the ref"           "$out" 'dev ->'
git fetch -q origin
is "the dev tip is a buffer commit verbatim, not a replay" \
  "$(git rev-parse origin/solo-dev)" "$(git rev-parse origin/solo-build)"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
