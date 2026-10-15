#!/bin/bash
# Check the generations of a line, offline, against a synthetic fork, canonical
# repository and clone built here: no network, no fixtures on disk.
#
# The claim is that a line's generations are named, served, compared, published
# and pruned by the rules scripts/series-lib.sh states, and that a cutover
# moves no ref. Seven things are checked.
#
#   1. The names: a line, `-fwd` as generation 0, `-v001` and up; each
#      generation's base is the one below it; the next generation of a line
#      whose `-fwd` stands for `v000` is `v001`; the published generation is
#      read from `main`'s declaration.
#   2. series-check.sh serves the two newest generations and the published one,
#      reads the rest as FROZEN, and names a cutover for a generation whose
#      green covers the published one's, as a pull request to prepare.
#   3. series-converge.sh compares a generation with the one it was built from,
#      and a line's first refs with their first generation.
#   4. series-advance.sh mines a generation's base, the one below it, for the
#      fix a buffer commit lacks.
#   5. series-cutover.sh prepares the two pull requests and the review, says
#      whether the canonical repository carries the green yet, writes
#      `publishes_from` with --apply, and moves no ref; it refuses a line's
#      first refs and reports an already published generation.
#   6. series-prune.sh offers a frozen generation older than the published one
#      with the commands that retire it, archive first, and nothing else; it
#      runs none of them.
#   7. series-alpha.sh and series-land.sh read a generation's line.
#
# Usage:
#   scripts/series-generations-test.sh
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
# A line `v9.9-x` with its first refs and three generations, `-fwd` (0), `-v001`
# and `-v002`, each a seed on `main` plus vendor commits, the newer ones
# vendoring further. `main` declares the flavor as publishing from the first
# refs' green. A canonical repository holds `main` and no green yet; an archive
# remote is there for the prune commands to name.

FORK=$SCRATCH/fork.git
CANON=$SCRATCH/canonical.git
ARCHIVE=$SCRATCH/archive.git
WORK=$SCRATCH/work
for r in "$FORK" "$CANON" "$ARCHIVE"; do git init -q --bare -b main "$r"; done

git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$FORK"
git remote add upstream "$CANON"
git remote add archive "$ARCHIVE"

mkdir -p scripts R src/duckdb tests/testthat/_snaps
for s in series-lib.sh series-check.sh series-converge.sh series-cutover.sh series-prune.sh \
  series-advance.sh series-alpha.sh series-land.sh series-tests.sh setup-git.sh merge-version.sh; do
  cp "$HERE/$s" scripts/
done
chmod +x scripts/*.sh
echo 'DESCRIPTION merge=ours-version' > .gitattributes
scripts/setup-git.sh >/dev/null

desc() { printf 'Package: duckdb.9.9.dev\nVersion: %s\n' "$1" > DESCRIPTION; }
declare_published() { # <green ref>
  cat > scripts/series.yaml <<EOF
flavors:
  - flavor: duckdb.9.9.dev
    kind: dev
    upstream: v9.9-x
    series: v9.9-x
    releases_from: main
    publishes_from: $1
    repo: duckdb/duckdb-r
    badges: [r-universe]
EOF
}
commit() { git add -A; git commit -qm "$1"; }

desc 1.0.0.9000
echo 'engine 0' > src/duckdb/engine.cpp
echo 'duckdb_version <- "0.0.0"' > R/version.R
echo 'foo <- function() 1' > R/foo.R
echo 'glue 0' > src/glue.cpp
echo 'snapshot one' > tests/testthat/_snaps/sql.md
declare_published v9.9-x-green
commit 'vendor: Update vendored sources to duckdb/duckdb@0000000 (#1)'
MAIN=$(git rev-parse HEAD)
git push -q origin main
git push -q upstream main

# One generation: a seed on main, then vendor commits up to <n> of the list,
# with a fix folded into the -dev twin of the second where the generation is
# `v001`, so a `v002` buffer commit for that SHA has something to mine.
shas=(aaaa111 bbbb222 cccc333 dddd444 eeee555)
generation() { # <series> <how many vendor commits on -dev> <how many on -build>
  local s=$1 ndev=$2 nbuild=$3 i sha
  git checkout -q --detach "$MAIN"
  desc 1.0.0.9000.0
  commit 'chore: Add fifth version component'
  local seed; seed=$(git rev-parse HEAD)
  for ((i = 0; i < nbuild; i++)); do
    sha=${shas[i]}
    echo "engine $sha" > src/duckdb/engine.cpp
    echo "glue $sha" > src/glue.cpp
    desc "1.0.0.9000.$((i + 1))"
    commit "vendor: Update vendored sources to duckdb/duckdb@$sha"
  done
  git branch -f "$s-build" HEAD
  git checkout -q --detach "$seed"
  for ((i = 0; i < ndev; i++)); do
    sha=${shas[i]}
    echo "engine $sha" > src/duckdb/engine.cpp
    echo "glue $sha" > src/glue.cpp
    [ "$s $sha" != "v9.9-x-v001 bbbb222" ] || echo 'snapshot one, corrected on v001' > tests/testthat/_snaps/sql.md
    desc "1.0.0.9000.$((i + 1))"
    commit "vendor: Update vendored sources to duckdb/duckdb@$sha"
  done
  git branch -f "$s-dev" HEAD
  git branch -f "$s-green" HEAD
  git branch -f "$s-build-base" "$s-build"
}
generation v9.9-x 1 1
generation v9.9-x-fwd 2 2
generation v9.9-x-v001 3 3
generation v9.9-x-v002 1 2
git branch -f v9.9-x-v001-rc-dev v9.9-x-v001-dev
git branch -f v9.9-x-fwd-rc-dev v9.9-x-fwd-dev

# The store stub, empty: every commit reads `missing`.
git checkout -q --orphan rcc2
git rm -rqf .
echo stub > README
commit 'chore: store stub'

git checkout -q main
git push -q origin rcc2 \
  v9.9-x-build v9.9-x-dev v9.9-x-green v9.9-x-build-base \
  v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base v9.9-x-fwd-rc-dev \
  v9.9-x-v001-build v9.9-x-v001-dev v9.9-x-v001-green v9.9-x-v001-build-base v9.9-x-v001-rc-dev \
  v9.9-x-v002-build v9.9-x-v002-dev v9.9-x-v002-green v9.9-x-v002-build-base
git fetch -q origin
git fetch -q upstream

run() { set +e; "$@" 2>&1; echo "EXIT=$?"; set -e; }
heads() { git ls-remote --heads "$1" | sort; }

# shellcheck source=series-lib.sh
. scripts/series-lib.sh

echo "=== 1. the names"
is "a line's first refs are the line" "$(series_line v9.9-x)" v9.9-x
is "-fwd belongs to its line" "$(series_line v9.9-x-fwd)" v9.9-x
is "and so does -v012" "$(series_line v9.9-x-v012)" v9.9-x
is "the first refs have no generation" "$(series_gen v9.9-x)" ""
is "-fwd is generation 0" "$(series_gen v9.9-x-fwd)" 0
is "-v012 is generation 12" "$(series_gen v9.9-x-v012)" 12
is "the base of -fwd is the line" "$(series_base v9.9-x-fwd origin)" v9.9-x
is "the base of v001 is -fwd, standing for v000" "$(series_base v9.9-x-v001 origin)" v9.9-x-fwd
is "the base of v002 is v001" "$(series_base v9.9-x-v002 origin)" v9.9-x-v001
is "the first refs have no base" "$(series_base v9.9-x origin)" ""
is "generation 0 is spelled -fwd while nothing spells v000" "$(series_gen_name v9.9-x 0 origin)" v9.9-x-fwd
is "generation 3 is spelled v003" "$(series_gen_name v9.9-x 3 origin)" v9.9-x-v003
is "the generations, newest first, the line last" \
  "$(series_generations v9.9-x origin | tr '\n' ' ')" "v9.9-x-v002 v9.9-x-v001 v9.9-x-fwd v9.9-x "
is "the newest is v002" "$(series_newest v9.9-x origin)" v9.9-x-v002
is "the next is v003" "$(series_next v9.9-x origin)" v9.9-x-v003
is "a line with -fwd alone takes v001 next" "$(git branch -f other-fwd-dev main >/dev/null; git push -q origin other-fwd-dev; git fetch -q origin; series_next other origin)" other-v001
is "a line with nothing takes v000 next" "$(series_next nothing origin)" nothing-v000
is "the published generation is read from main's declaration" "$(series_published upstream/main v9.9-x)" v9.9-x
is "the two newest are served" "$(series_served v9.9-x-v001 origin v9.9-x && echo yes)" yes
is "the published one is served however old" "$(series_served v9.9-x origin v9.9-x && echo yes)" yes
is "and generation 0 is not" "$(series_served v9.9-x-fwd origin v9.9-x || echo no)" no

echo
echo "=== 2. series-check.sh serves two generations and the published one"
out=$(run scripts/series-check.sh)
[ -z "${KEEP:-}" ] || echo "$out"
has "the run finishes" "$out" "EXIT=0"
has "generation 0 is frozen" "$out" "=== v9.9-x-fwd: FROZEN — generation 0 of v9.9-x"
has "naming what is served" "$out" "the loop serves v9.9-x-v002 v9.9-x-v001 and the published v9.9-x"
has "v001 gets a verdict" "$out" "=== v9.9-x-v001:"
has "v002 gets a verdict" "$out" "=== v9.9-x-v002:"
has "the first refs get a verdict" "$out" "=== v9.9-x:"
has "v002 covers the published green" "$out" "CUTOVER  v9.9-x-v002 covers v9.9-x's green"
has "as a pull request to prepare" "$out" "scripts/series-cutover.sh v9.9-x-v002 --remote origin"
hasnt "the frozen generation is not offered" "$out" "CUTOVER  v9.9-x-fwd"
hasnt "nor is the published one" "$out" "CUTOVER  v9.9-x covers"

echo
echo "=== 3. series-converge.sh compares a generation with its base"
out=$(run scripts/series-converge.sh v9.9-x-v002)
[ -z "${KEEP:-}" ] || echo "$out"
has "the header names the generation" "$out" "=== v9.9-x-v002"
has "its base is v001" "$out" "v9.9-x-v001-dev"
has "and itself" "$out" "v9.9-x-v002-dev"
out=$(run scripts/series-converge.sh v9.9-x)
has "the first refs compare with -fwd" "$out" "v9.9-x-fwd-dev"
has "and themselves" "$out" "v9.9-x-dev "

echo
echo "=== 4. series-advance.sh mines the generation below"
out=$(run scripts/series-advance.sh v9.9-x-v002 --canonical '')
[ -z "${KEEP:-}" ] || echo "$out"
has "the chunk completes" "$out" "EXIT=0"
has "the base mined is v001" "$out" "carry a fix from origin/v9.9-x-v001-dev"
git fetch -q origin
is "the fix v001 folded reached v002" \
  "$(git show origin/v9.9-x-v002-dev:tests/testthat/_snaps/sql.md)" 'snapshot one, corrected on v001'

echo
echo "=== 5. series-cutover.sh prepares the pull requests and moves no ref"
before_fork=$(heads origin); before_canon=$(heads upstream)
OUT=$SCRATCH/cutover
out=$(run scripts/series-cutover.sh v9.9-x --out "$OUT")
has "a line's first refs are refused" "$out" "EXIT=2"
has "saying what to name" "$out" "name the generation to publish"
out=$(run scripts/series-cutover.sh v9.9-x-v002 --out "$OUT")
[ -z "${KEEP:-}" ] || echo "$out"
has "the run finishes" "$out" "EXIT=0"
has "it names the flavor and both generations" "$out" "=== cutover of duckdb.9.9.dev: v9.9-x -> v9.9-x-v002"
has "coverage is not verified without a clone" "$out" "no upstream clone given, coverage not verified"
has "the convergence read is printed" "$out" "=== v9.9-x-v002"
has "the canonical copy is missing, and the plain push is printed" "$out" "v9.9-x-v002-green is not in upstream yet"
has "with the command" "$out" "git push upstream $(git rev-parse origin/v9.9-x-v002-green):refs/heads/v9.9-x-v002-green"
has "the review stat names the glue" "$out" "src/glue.cpp"
hasnt "and not the engine" "$out" "src/duckdb/engine.cpp"
has "the two pull requests are named" "$out" "1. duckdb/duckdb.r-universe.dev: $OUT/packages.json.change"
has "the universe change names the new green" "$(cat "$OUT/packages.json.change")" \
  '{"package": "duckdb.9.9.dev", "url": "https://github.com/duckdb/duckdb-r", "branch": "v9.9-x-v002-green"}'
has "and the old one" "$(cat "$OUT/packages.json.change")" '"branch": "v9.9-x-green"}'
has "the declaration change names the new green" "$(cat "$OUT/series.yaml.change")" "publishes_from: v9.9-x-v002-green"
is "the review diff is written" "$([ -s "$OUT/review.diff" ] && echo yes)" yes
has "and says no ref moved" "$out" "No ref was moved."
is "the fork's refs are untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
hasnt "series.yaml is untouched without --apply" "$(cat scripts/series.yaml)" "v9.9-x-v002-green"
out=$(run scripts/series-cutover.sh v9.9-x-v002 --out "$OUT" --apply)
has "--apply rewrites the declaration" "$(cat scripts/series.yaml)" "publishes_from: v9.9-x-v002-green"
has "and says so" "$out" "applied: scripts/series.yaml now publishes duckdb.9.9.dev from v9.9-x-v002-green"
is "and still moves no ref" "$(heads origin)" "$before_fork"
git checkout -q scripts/series.yaml
git push -q upstream origin/v9.9-x-v002-green:refs/heads/v9.9-x-v002-green
out=$(run scripts/series-cutover.sh v9.9-x-v002 --out "$OUT")
has "once mirrored, the canonical copy reads level" "$out" "v9.9-x-v002-green is at $(git rev-parse --short origin/v9.9-x-v002-green) in upstream, level with the fork"

echo
echo "=== 6. series-prune.sh offers what is frozen and older than the published generation"
out=$(run scripts/series-prune.sh v9.9-x-v002)
has "a generation is refused" "$out" "EXIT=2"
out=$(run scripts/series-prune.sh v9.9-x)
[ -z "${KEEP:-}" ] || echo "$out"
has "the run finishes" "$out" "EXIT=0"
has "the published one is named" "$out" "v9.9-x                       $(git rev-parse --short origin/v9.9-x-green)  served, published by duckdb.9.9.dev"
has "generation 0 is frozen but newer than the published one" "$out" "v9.9-x-fwd                   $(git rev-parse --short origin/v9.9-x-fwd-green)  frozen, newer than the published generation"
has "so nothing is offered" "$out" "Nothing to prune."
# main publishes from v002 now, as the cutover's pull request would make it.
declare_published v9.9-x-v002-green
commit 'chore(series): Publish duckdb.9.9.dev from v9.9-x-v002-green'
git push -q upstream main
before_fork=$(heads origin); before_canon=$(heads upstream); before_archive=$(heads archive)
out=$(run scripts/series-prune.sh v9.9-x)
[ -z "${KEEP:-}" ] || echo "$out"
has "v002 is published now" "$out" "v9.9-x-v002                  $(git rev-parse --short origin/v9.9-x-v002-green)  served, published by duckdb.9.9.dev"
has "v001 is served, the second newest" "$out" "v9.9-x-v001                  $(git rev-parse --short origin/v9.9-x-v001-green)  served"
has "generation 0 may go" "$out" "v9.9-x-fwd                   $(git rev-parse --short origin/v9.9-x-fwd-green)  frozen, older than the published generation: may be pruned"
has "and so may the first refs" "$out" "v9.9-x                       $(git rev-parse --short origin/v9.9-x-green)  frozen, older than the published generation: may be pruned"
has "the checks a human makes are named" "$out" "no landing is being built from a listed generation"
has "the archive push comes first" "$out" "git push archive refs/remotes/origin/v9.9-x-fwd-build:refs/heads/v9.9-x-fwd-build refs/remotes/origin/v9.9-x-fwd-dev:refs/heads/v9.9-x-fwd-dev refs/remotes/origin/v9.9-x-fwd-green:refs/heads/v9.9-x-fwd-green refs/remotes/origin/v9.9-x-fwd-build-base:refs/heads/v9.9-x-fwd-build-base refs/remotes/origin/v9.9-x-fwd-rc-dev:refs/heads/v9.9-x-fwd-rc-dev"
has "then the deletion, rc strand included" "$out" "git push --delete origin v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base v9.9-x-fwd-rc-dev"
has "the first refs' deletion too" "$out" "git push --delete origin v9.9-x-build v9.9-x-dev v9.9-x-green v9.9-x-build-base"
hasnt "v001's refs are not offered" "$out" "--delete origin v9.9-x-v001"
hasnt "nor v002's" "$out" "--delete origin v9.9-x-v002"
hasnt "no canonical copy of the frozen greens exists to delete" "$out" "git push --delete upstream"
has "and nothing was run" "$out" "Nothing above was run."
is "the fork's refs are untouched" "$(heads origin)" "$before_fork"
is "the canonical repository's too" "$(heads upstream)" "$before_canon"
is "and the archive took nothing" "$(heads archive)" "$before_archive"

echo
echo "=== 7. a generation's line is read where a script needs it"
out=$(run scripts/series-alpha.sh v9.9-x-v002)
has "series-alpha.sh reads the line's upstream branch" "$out" "v9.9-x"
hasnt "and not the generation's name as a branch" "$out" "release/v9.9-x-v002/"
out=$(run scripts/series-land.sh v9.9-x-v002 --status)
has "series-land.sh names the landing after the line" "$out" "v9.9-x-land-dev does not exist on origin"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
