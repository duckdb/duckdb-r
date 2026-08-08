#!/bin/bash
# Check what scripts/series-forward-build.sh promises, offline, against a
# synthetic repository built here -- no network, no fixtures on disk.
#
# The claims that matter are about the R-side carry (duckdb/duckdb-r#2590): the
# buffer holds the vendored tree and its glue, every fix CI demanded afterwards
# was folded into the equivalent commit on the old `-dev`, and a replay that
# reads only the buffer drops all of it. Seven things are checked.
#
#   1. A vendor commit whose `-dev` twin folded an R-side fix comes out with that
#      fix in the same commit -- not stacked above it -- carrying the twin's
#      message and a trailer naming where it came from.
#   2. A twin that folded nothing replays exactly as the buffer commit did:
#      same message, same tree, no trailer.
#   3. Glue the buffer already carries is applied once. The carry is the paths
#      the twin touched that its `-build` commit did not, so a shared file is the
#      pick's and not applied twice.
#   4. Tooling paths a twin folded in are dropped, and the drop is printed. The
#      seed is current `main`, which has the newer copy; carrying an older
#      series' workflow backwards would regress it.
#   5. A carry the new base has moved out from under stops the run with the
#      conflict in the tree, and a rerun after resolution commits it with the
#      twin's message. This is the restart path, and the half that stopped is
#      remembered -- a resume that guessed would write a vendor message over a
#      commit that carries a fix.
#   6. `--no-dev` reproduces the pre-#2590 behaviour, and a `-dev` that cannot be
#      derived or does not resolve refuses to start rather than replaying without
#      it silently.
#   7. The fifth version component still rises once per replayed commit, carry or
#      no carry.
#
# Usage:
#   scripts/series-forward-build-test.sh
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
is() { # <description> <actual> <expected>
  if [ "$2" = "$3" ]; then ok "$1"; else
    no "$1"
    echo "         actual: $2"
    echo "       expected: $3"
  fi
}
has() { # <description> <haystack> <needle>
  case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac
}
hasnt() { # <description> <haystack> <needle>
  case "$2" in *"$3"*) no "$1"; echo "     unexpected: $3" ;; *) ok "$1" ;; esac
}

# --- the fixture -----------------------------------------------------------
#
# One repository holding the shape a forward replay meets: an old buffer, an old
# `-dev` that folded fixes into the same upstream commits, and a fresh seed on a
# `main` that has moved on. The script under test runs against the repository
# that contains it, so it is copied in beside a `scripts/` of its own -- which
# also makes the tooling-path exclusion real rather than hypothetical.

R=$SCRATCH/repo
mkdir -p "$R"
cd "$R"
git init -q -b main .
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git config merge.ours-version.driver "scripts/merge-version.sh %O %A %B"
git config rerere.enabled false

mkdir -p scripts src/duckdb src/include tests/testthat/_snaps R .github/workflows
cp "$HERE/series-forward-build.sh" scripts/
cp "$HERE/merge-version.sh" scripts/ 2>/dev/null || {
  echo "Error: scripts/merge-version.sh missing; the DESCRIPTION driver needs it" >&2
  exit 1
}
chmod +x scripts/*.sh
echo 'DESCRIPTION merge=ours-version' > .gitattributes

desc() { printf 'Package: duckdb\nVersion: %s\n' "$1" > DESCRIPTION; }

desc 1.0.0.9000.0
echo 'seed glue' > src/glue.cpp
echo 'snapshot line one' > tests/testthat/_snaps/sql.md
printf 'test_that("x", {\n  expect_equal(spill(), "a")\n})\n' > tests/testthat/test-x.R
echo 'foo <- function() 1' > R/foo.R
echo 'on: push' > .github/workflows/w.yaml
git add -A
git commit -qm 'chore: seed'
git branch old-seed

# --- the old buffer: four vendor commits, one of them adapting glue ---------
vendor() { # <upstream-sha> <version> <file> [<glue-line>]
  # git tracks no empty directory, so checking out the seed removes src/duckdb.
  mkdir -p src/duckdb
  echo "vendored $1" > "src/duckdb/$3"
  [ -z "${4:-}" ] || echo "$4" > src/glue.cpp
  desc "$2"
  git add -A
  git commit -qm "vendor: Update vendored sources to duckdb/duckdb@$1"
}

vendor aaaaaaa 1.0.0.9000.1 a.cpp
vendor bbbbbbb 1.0.0.9000.2 b.cpp 'glue adapted for bbbbbbb'
vendor ccccccc 1.0.0.9000.3 c.cpp
vendor ddddddd 1.0.0.9000.4 d.cpp
git branch old-build

# --- the old -dev: the same four, with what CI demanded folded in -----------
git checkout -q -b old-dev old-seed

fold() { # <upstream-sha> <version> <file> [<glue-line>]
  vendor "$@"
}
amend() { git commit -q --amend -F- ; }

# aaaaaaa: a snapshot fold -- the archetype (claim 1)
fold aaaaaaa 1.0.0.9000.1 a.cpp
echo 'snapshot line one, corrected' > tests/testthat/_snaps/sql.md
git add -A
git log -1 --format=%B | { cat; echo 'R-side fix'; echo '----------'; echo; echo 'Snapshot corrected for the new engine output.'; } | amend

# bbbbbbb: the same glue the buffer carries, nothing more (claims 2, 3)
fold bbbbbbb 1.0.0.9000.2 b.cpp 'glue adapted for bbbbbbb'

# ccccccc: an R-code fix, folded together with a workflow edit (claim 4)
fold ccccccc 1.0.0.9000.3 c.cpp
echo 'foo <- function() 2' > R/foo.R
echo 'on: [push, workflow_dispatch]' > .github/workflows/w.yaml
git add -A
git log -1 --format=%B | { cat; echo 'R-side fix'; echo '----------'; echo; echo 'foo() returns 2 now.'; } | amend

# ddddddd: a test fix against a line the new base has since changed (claim 5)
fold ddddddd 1.0.0.9000.4 d.cpp
printf 'test_that("x", {\n  expect_equal(spill(), "b")\n})\n' > tests/testthat/test-x.R
git add -A
git log -1 --format=%B | { cat; echo 'R-side fix'; echo '----------'; echo; echo 'Spill expectation follows the engine.'; } | amend

# --- the new seed: `main` has moved on --------------------------------------
git checkout -q -b new-seed old-seed
echo 'on: [push, workflow_dispatch, schedule]' > .github/workflows/w.yaml
printf 'test_that("x", {\n  expect_equal(normalize(spill()), "a")\n})\n' > tests/testthat/test-x.R
desc 2.0.0.9000.0
git add -A
git commit -qm 'chore: main moved on'

run() { # -> stdout+stderr, never aborts the test run
  set +e
  scripts/series-forward-build.sh "$@" 2>&1
  echo "EXIT=$?"
  set -e
}

# Start a scenario from the seed, whatever the last one left behind -- a stopped
# replay leaves an unmerged index, which every later checkout would refuse.
# Detached first: never reset --hard onto a branch that is being kept.
fresh() { # <branch>
  git checkout -q --force --detach HEAD
  git reset -q --hard new-seed
  git clean -qfd
  rm -f "$(git rev-parse --git-dir)"/series-forward-*
  git checkout -q -B "$1"
}

# --- claims 1-4, 7: the replay up to the conflicting commit -----------------
echo
echo "== replay with the -dev carry"
fresh fwd
out=$(run --dev old-dev old-build old-seed)

has "stops at the commit whose carry conflicts" "$out" "Conflict carrying the R-side fix"
has "names the -dev twin in the stop"          "$out" "$(git rev-parse --short old-dev)"
has "points at the whole-set read"             "$out" "scripts/series-glue.sh"

# Three commits landed before the stop.
is "three commits replayed before the stop" \
  "$(git rev-list --count new-seed..HEAD)" 3

sha_of() { git log --format='%H %s' new-seed..HEAD | sed -n "s/^\([0-9a-f]*\) .*duckdb\/duckdb@$1.*$/\1/p"; }
A=$(sha_of aaaaaaa); B=$(sha_of bbbbbbb); C=$(sha_of ccccccc)

# 1. the snapshot fold rides in the vendor commit, with the twin's prose.
is "carried commit holds the corrected snapshot" \
  "$(git show "$A:tests/testthat/_snaps/sql.md")" 'snapshot line one, corrected'
has "carried commit keeps the R-side fix prose" "$(git log -1 --format=%B "$A")" 'Snapshot corrected'
has "carried commit names its provenance"       "$(git log -1 --format=%B "$A")" 'Carried from `old-dev`'
is "the carry is folded in, not stacked" \
  "$(git log --format=%s new-seed.."$A" | grep -c .)" 1

# 2. a twin that folded nothing is indistinguishable from the buffer commit.
hasnt "uncarried commit gets no trailer" "$(git log -1 --format=%B "$B")" 'Carried from'
is "uncarried commit keeps the vendor subject" \
  "$(git log -1 --format=%s "$B")" 'vendor: Update vendored sources to duckdb/duckdb@bbbbbbb'

# 3. glue shared by both sides is applied once, by the pick.
is "shared glue applied once" "$(git show "$B:src/glue.cpp")" 'glue adapted for bbbbbbb'
is "shared glue is not in the carry set" \
  "$(git show --format= --name-only "$B" | grep -c '^src/glue.cpp$')" 1

# 4. tooling is dropped, loudly; the R-side half of the same fold is carried.
has "reports the dropped tooling path" "$out" '.github/workflows/w.yaml'
has "says it is not carrying it"       "$out" 'not carrying tooling paths'
is "new base keeps its own workflow" \
  "$(git show "$C:.github/workflows/w.yaml")" 'on: [push, workflow_dispatch, schedule]'
is "the R-side half of that fold is carried" "$(git show "$C:R/foo.R")" 'foo <- function() 2'

# 7. the counter rises once per replayed commit, carry or no carry.
is "counter runs 1,2,3 over the three commits" \
  "$(git log --reverse --format=%H new-seed..HEAD |
       while read -r c; do git show "$c:DESCRIPTION" | sed -rn 's/^Version: //p'; done | tr '\n' ' ')" \
  '2.0.0.9000.1 2.0.0.9000.2 2.0.0.9000.3 '

# --- claim 5: the stop is a real conflict, and the rerun resumes it ---------
echo
echo "== conflict and resume"
is "the conflict is in the tree" \
  "$(git diff --name-only --diff-filter=U)" 'tests/testthat/test-x.R'
is "the vendored half of the stopped commit is staged" \
  "$(git diff --cached --name-only -- src/duckdb | tr '\n' ' ')" 'src/duckdb/d.cpp '

out=$(run --dev old-dev old-build old-seed)
has "rerunning while unresolved stops again" "$out" 'Conflict carrying the R-side fix'
is "and adds no commit" "$(git rev-list --count new-seed..HEAD)" 3

printf 'test_that("x", {\n  expect_equal(normalize(spill()), "b")\n})\n' > tests/testthat/test-x.R
git add tests/testthat/test-x.R
out=$(run --dev old-dev old-build old-seed)
has "resume commits the resolved carry"  "$out" 'resuming: committing the resolved carry'
has "and reports a finished replay"      "$out" 'DONE: replay complete'
hasnt "not a replay that had nothing to do" "$out" 'Nothing to replay'
is "four commits in total"               "$(git rev-list --count new-seed..HEAD)" 4

D=$(sha_of ddddddd)
has "the resumed commit keeps the twin's prose" "$(git log -1 --format=%B "$D")" 'Spill expectation'
has "and its provenance trailer"                "$(git log -1 --format=%B "$D")" 'Carried from `old-dev`'
is "and the resolution"       "$(git show "$D:tests/testthat/test-x.R" | sed -n 2p)" '  expect_equal(normalize(spill()), "b")'
is "and the counter"          "$(git show "$D:DESCRIPTION" | sed -rn 's/^Version: //p')" '2.0.0.9000.4'
is "no state file survives a finished replay" \
  "$(ls "$(git rev-parse --git-dir)" | grep -c series-forward || true)" 0

# --- claim 6: --no-dev, and refusing rather than guessing -------------------
echo
echo "== --no-dev and the refusals"
fresh fwd2
out=$(run --no-dev old-build old-seed)
has "--no-dev finishes"            "$out" 'DONE: 4 vendor commit(s) replayed'
has "--no-dev says what it skipped" "$out" 'no -dev consulted'
is "--no-dev carries nothing" \
  "$(git show "$(sha_of aaaaaaa):tests/testthat/_snaps/sql.md")" 'snapshot line one'

fresh fwd3
out=$(run old-build old-seed)
has "derives old-dev from old-build" "$out" 'indexed 4 vendor commit(s) on old-dev'

fresh fwd4
out=$(run --dev no-such-ref old-build old-seed)
has "refuses an unresolvable --dev"  "$out" 'Error: no-such-ref is not a commit'
has "and says why it matters"        "$out" 'drops every one of them silently'
is  "and replays nothing"            "$(git rev-list --count new-seed..HEAD)" 0

fresh fwd5
out=$(run old-dev old-seed)
has "refuses when -dev cannot be derived" "$out" 'cannot derive the -dev ref'
is  "and replays nothing"                 "$(git rev-list --count new-seed..HEAD)" 0

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
