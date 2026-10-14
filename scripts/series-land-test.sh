#!/bin/bash
# Check the landing of a series on `main`, offline, against a synthetic fork,
# canonical repository and clone built here -- no network, no fixtures on disk.
#
# The claim scripts/series-land.sh makes is that `<L>-land-dev` is `main` plus
# the series' vendor commits and nothing else, and that its tip is the package
# the series' rc strand holds. Ten things are checked.
#
#   1. Without --push the build writes no ref, and says what it would write.
#   2. Only vendor commits land, on `main` itself, unflavored.
#   3. Each is stamped with the series' prefix and a counter of its own.
#   4. A first pick whose old parent vendors another engine than `main` takes
#      the vendored strand whole, and the glue and test fix it folded with it.
#      A later pick that conflicts with what `main` changed stops the build,
#      which resumes on a rerun without skipping a version number.
#   5. A tooling sync the base cannot reverse-apply is placed by its subject
#      rather than stranding the run, and a port `main` carries is not replayed.
#   6. The tree check explains what the landing takes from `main` by
#      construction -- `NEWS.md` and the READMEs -- and nothing else, and the
#      counter reproduces the series' version, so `DESCRIPTION` agrees.
#   7. --push writes `<L>-land-dev` and `<L>-land-green` at the base together.
#   8. A rebuild from the same inputs mints the same SHAs, and the conflict
#      resolved once is resolved again by rerere without stopping.
#   9. --status advances green over the commits the store passed, names the
#      first one it has not, and prints the fast-forward once every one passed.
#  10. A `main` that moved stops a kept build, and a rebuild on it that the
#      series has not ported is refused before anything is pushed.
#
# Usage:
#   scripts/series-land-test.sh
#
# Environment variables:
#   KEEP - if non-empty, do not delete the scratch directory

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SCRATCH=$(mktemp -d)
[ -n "${KEEP:-}" ] || trap 'rm -rf "$SCRATCH"' EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"
export TMPDIR=$SCRATCH

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac; }
hasnt() { case "$2" in *"$3"*) no "$1"; echo "     unexpected: $3" ;; *) ok "$1" ;; esac; }

# --- the fixture -----------------------------------------------------------
#
# `main` at a base B, a series seeded on B the way series-forward seeds one, and
# `main` moving on from B: it vendors a newer engine of its own line, takes an
# R-side fix and two tooling changes, and bumps its version. The series ports
# the fix and syncs the tooling twice, and vendors three commits of its own line.

FORK=$SCRATCH/fork.git
CANON=$SCRATCH/canonical.git
WORK=$SCRATCH/work
git init -q --bare -b main "$FORK"
git init -q --bare -b main "$CANON"

git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$FORK"
git remote add upstream "$CANON"

mkdir -p scripts R src/duckdb/src/function/table/version tests/testthat
for s in series-land.sh series-forward-build.sh series-rc.sh setup-git.sh merge-version.sh; do
  cp "$HERE/$s" scripts/
done
chmod +x scripts/*.sh
echo 'DESCRIPTION merge=ours-version' > .gitattributes
scripts/setup-git.sh >/dev/null

desc() { printf 'Package: %s\nVersion: %s\n' "$1" "$2" > DESCRIPTION; }
engine() { # <id> <R version>
  echo "engine $1" > src/duckdb/engine.cpp
  echo "#define DUCKDB_SOURCE_ID \"$1\"" > src/duckdb/src/function/table/version/pragma_version.cpp
  echo "duckdb_version <- \"$2\"" > R/version.R
}
commit() { git add -A; git commit -qm "$1"; }

desc duckdb 1.5.5.9000
engine aaaa111 1.5.5
echo 'rename duckdb.1.3 duckdb_1_3' > scripts/flavor.patch
echo 'tool v1' > scripts/tool.sh
echo 'pkg <- "duckdb"' > R/package.R
echo 'foo <- function() 1' > R/foo.R
echo 'glue 1' > src/glue.cpp
echo 'test 1' > tests/testthat/test-foo.R
printf 'a\nb\nc\n' > tests/testthat/test-bar.R
echo '# duckdb 1.5.5.9000' > NEWS.md
echo 'readme at the base' > README.md
commit 'vendor: Update vendored sources to duckdb/duckdb@aaaa111 (#1)'
B=$(git rev-parse HEAD)

# `main` moves on.
engine aaaa112 1.5.6
commit 'vendor: Update vendored sources to duckdb/duckdb@aaaa112 (#2)'
echo 'foo <- function() 2' > R/foo.R
commit 'fix: An R-side fix on main (#3)'
P=$(git rev-parse HEAD)
printf 'a\nb main\nc\n' > tests/testthat/test-bar.R
commit 'test: A test main adjusted (#9)'
Q=$(git rev-parse HEAD)
echo 'tool v2' > scripts/tool.sh
commit 'ci: A tooling change (#4)'
echo 'tool v3' > scripts/tool.sh
commit 'ci: Another tooling change (#5)'
desc duckdb 1.5.6.9001
echo '# duckdb 1.5.6.9001' > NEWS.md
commit 'fledge: Bump version to 1.5.6.9001 (#6)'
echo 'readme on main' > README.md
commit 'docs: The README main renders today (#7)'
M=$(git rev-parse HEAD)
git push -q upstream main
git push -q origin main

# The series: three seed commits on B, as flavor.sh and series-forward write them.
git checkout -q -b s "$B"
echo 'rename duckdb.2.0.dev duckdb_2_0_dev' > scripts/flavor.patch
commit 'chore: Update flavor patch to duckdb.2.0.dev'
echo 'pkg <- "duckdb.2.0.dev"' > R/package.R
desc duckdb.2.0.dev 1.5.5.9000
commit 'chore: Update version to 2.0.dev'
desc duckdb.2.0.dev 1.99.99.9000.0
commit 'chore: Add fifth version component'

engine bbbb222 1.99.99-dev1
echo 'glue 2, adapted to bbbb222' > src/glue.cpp
echo 'test 2, as bbbb222 answers' > tests/testthat/test-foo.R
desc duckdb.2.0.dev 1.99.99.9000.1
commit 'vendor: Update vendored sources to duckdb/duckdb@bbbb222'
git cherry-pick -x "$P" >/dev/null
echo 'tool v2' > scripts/tool.sh
commit 'chore(series): Sync tooling with main'
engine cccc333 1.99.99-dev2
printf 'a\nb v2\nc\n' > tests/testthat/test-bar.R
desc duckdb.2.0.dev 1.99.99.9000.2
commit 'vendor: Update vendored sources to duckdb/duckdb@cccc333'
# The port of `main`'s test change meets the line cccc333 adapted, and is
# resolved by hand, as stage 4 resolves one.
git cherry-pick -x "$Q" >/dev/null 2>&1 || true
printf 'a\nb v2 main\nc\n' > tests/testthat/test-bar.R
git add tests/testthat/test-bar.R
GIT_EDITOR=true git cherry-pick --continue >/dev/null
echo 'tool v3' > scripts/tool.sh
commit 'chore(series): Sync tooling with main'
engine dddd444 1.99.99-dev3
echo 'test 3, as dddd444 answers' > tests/testthat/test-foo.R
desc duckdb.2.0.dev 1.99.99.9000.3
commit 'vendor: Update vendored sources to duckdb/duckdb@dddd444'
git push -q origin s:refs/heads/v2.0-x-fwd-dev
git checkout -q main

scripts/series-rc.sh v2.0-x-fwd --push >/dev/null 2>&1
git fetch -q origin
RC=$(git rev-parse origin/v2.0-x-fwd-rc-dev)

# The resolution the port above recorded would answer the landing's conflict
# too, since rerere matches the hunk whichever side it is on; a clone that never
# saw it is the case to check first.
rm -rf "$(git rev-parse --git-common-dir)/rr-cache"

# --- 1: a build without --push ------------------------------------------------

echo "== a build stops on a conflict, and resumes"
out=$(scripts/series-land.sh v2.0-x-fwd --no-check-glue 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
is "the build stops" "$st" 1
has "on the pick that meets main's change" "$out" "Conflict at"
has "and keeps the build" "$out" "the build stopped and is kept"
read -r WT _ < "$(git rev-parse --git-dir)/series-land-v2.0-x"
printf 'a\nb v2 main\nc\n' > "$WT/tests/testthat/test-bar.R"
git -C "$WT" add tests/testthat/test-bar.R

echo
echo "== a build without --push writes no ref"
out=$(scripts/series-land.sh v2.0-x-fwd --no-check-glue 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "it reports the landing" "$out" "3 vendor commits on main $(git rev-parse --short "$M")"
has "and that it was not pushed" "$out" "Not pushed; --push writes v2.0-x-land-dev"
is "no land-dev on the fork" "$(git ls-remote origin refs/heads/v2.0-x-land-dev | wc -l)" 0

TIP=$(git -C "$WT" rev-parse HEAD)

# --- 2, 3, 4, 5: what landed ------------------------------------------------

echo
echo "== only vendor commits land, on main, unflavored, counted"
is "the first landing commit stands on main" "$(git rev-parse "$TIP~3")" "$M"
is "every commit above main vendors" \
  "$(git log --format=%s "$M..$TIP" | grep -vc '^vendor:' || true)" 0
is "the subjects are the series' own, oldest first" \
  "$(git log --reverse --format=%s "$M..$TIP" | sed 's/.*@//' | tr '\n' ' ')" \
  "bbbb222 cccc333 dddd444 "
is "the versions count this chain" \
  "$(for c in $(git rev-list --reverse "$M..$TIP"); do
       git show "$c:DESCRIPTION" | sed -n 's/^Version: //p'; done | tr '\n' ' ')" \
  "1.99.99.9000.1 1.99.99.9000.2 1.99.99.9000.3 "
is "the package is main's name" "$(git show "$TIP:DESCRIPTION" | sed -n 's/^Package: //p')" duckdb
is "and so is the R code the flavor renames" "$(git show "$TIP:R/package.R")" 'pkg <- "duckdb"'

FIRST=$(git rev-parse "$TIP~2")
is "the rewind took the strand whole" "$(git show "$FIRST:src/duckdb/engine.cpp")" "engine bbbb222"
is "R/version.R with it" "$(git show "$FIRST:R/version.R")" 'duckdb_version <- "1.99.99-dev1"'
is "and the glue it folded" "$(git show "$FIRST:src/glue.cpp")" "glue 2, adapted to bbbb222"
is "and the test fix" "$(git show "$FIRST:tests/testthat/test-foo.R")" "test 2, as bbbb222 answers"
is "main's R-side fix is there from the start" "$(git show "$FIRST:R/foo.R")" 'foo <- function() 2'
is "and main's tooling" "$(git show "$FIRST:scripts/tool.sh")" "tool v3"

# --- 6: the tree check ------------------------------------------------------

echo
echo "== the tip is the package the rc strand holds"
has "NEWS.md is main's" "$out" "NEWS.md"
has "the README is main's" "$out" "README.md"
is "the tip carries the series' version" "$(git show "$TIP:DESCRIPTION" | sed -n 's/^Version: //p')" \
  "$(git show "$RC:DESCRIPTION" | sed -n 's/^Version: //p')"
hasnt "so DESCRIPTION is no difference at all" "$out" "DESCRIPTION"
hasnt "nothing is unexplained" "$out" "UNEXPLAINED"
is "the trees agree everywhere else" \
  "$(git diff --name-only "$TIP" "$RC" -- . ':(exclude)NEWS.md' ':(exclude)README.md' ':(exclude)DESCRIPTION')" ""

# --- 7: --push --------------------------------------------------------------

echo
echo "== --push writes both refs"
out=$(scripts/series-land.sh v2.0-x-fwd --no-check-glue --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
git fetch -q origin
is "land-dev is the tip" "$(git rev-parse origin/v2.0-x-land-dev)" "$TIP"
is "land-green is main" "$(git rev-parse origin/v2.0-x-land-green)" "$M"

# --- 8: a rebuild mints the same SHAs ---------------------------------------

echo
echo "== a rebuild from the same inputs is the same chain"
scripts/series-land.sh v2.0-x-fwd --abort >/dev/null
out=$(scripts/series-land.sh v2.0-x-fwd --no-check-glue --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "rerere resolved the conflict" "$out" "rerere resolved that stop; continuing"
has "nothing to push" "$out" "v2.0-x-land-dev: already on origin"

# --- 9: --status ------------------------------------------------------------

echo
echo "== --status moves green over what passed"
C1=$(git rev-parse "$TIP~2")
C2=$(git rev-parse "$TIP~1")
git checkout -q --orphan rcc2
git rm -rqf .
rec() { # <sha> <state>
  mkdir -p "runs2.d/${1:0:2}"
  printf '{"commit":"%s","status":{"context":"rcc","state":"%s"}}\n' "$1" "$2" \
    > "runs2.d/${1:0:2}/$1.ndjson"
}
rec "$C1" success
rec "$C2" success
commit 'chore: store stub'
git push -q origin rcc2
git checkout -q main

out=$(scripts/series-land.sh v2.0-x-fwd --status --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "it counts what passed" "$out" "2 of 3 commits above v2.0-x-land-green passed"
has "and names the first that has not" "$out" "first not passed: $(git rev-parse --short "$TIP") (missing)"
git fetch -q origin
is "green moved over the two" "$(git rev-parse origin/v2.0-x-land-green)" "$C2"
hasnt "it is not ready" "$out" "READY"

git checkout -q rcc2
rec "$TIP" success
commit 'chore: store stub, the tip'
git push -q origin rcc2
git checkout -q main
out=$(scripts/series-land.sh v2.0-x-fwd --status --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "every commit passed" "$out" "READY: every commit has passed"
has "and it prints the fast-forward" "$out" "git push upstream $TIP:refs/heads/main"

# --- 10: main moves ---------------------------------------------------------

echo
echo "== a main that moved is not landed on blindly"
git checkout -q main
echo 'foo <- function() 3' > R/foo.R
commit 'fix: A fix the series never ported (#8)'
git push -q upstream main
out=$(scripts/series-land.sh v2.0-x-fwd --no-check-glue 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
is "the kept build refuses" "$st" 1
has "and says main moved" "$out" "Error: main moved from $(git rev-parse --short "$M")"

scripts/series-land.sh v2.0-x-fwd --abort >/dev/null
out=$(scripts/series-land.sh v2.0-x-fwd --no-check-glue --push 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
is "a rebuild the series does not match fails" "$st" 1
has "it names the path" "$out" "R/foo.R"
has "and refuses to push" "$out" "DIVERGED"
git fetch -q origin
is "land-dev is where it was" "$(git rev-parse origin/v2.0-x-land-dev)" "$TIP"

scripts/series-land.sh v2.0-x-fwd --abort >/dev/null

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
