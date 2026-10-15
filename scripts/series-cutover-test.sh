#!/bin/bash
# Check a cutover, offline, against a synthetic fork, canonical repository and
# clone built here: no network, no fixtures on disk, and a `gh` that records
# what it is asked instead of reaching GitHub.
#
# The claim is that scripts/series-cutover.sh keeps every lineage the swap
# replaces as the head of a closed pull request, swaps the four refs atomically,
# moves the canonical copy of green, deletes what the forward leaves behind in
# both repositories, and refuses to move anything when it cannot archive; and
# that scripts/series-prune.sh offers only cutover litter, and runs nothing.
# Six things are checked.
#
#   1. Without a terminal the cutover refuses before fetching anything, and
#      names --prepare.
#   2. --prepare prints the gates, the convergence read, the package on both
#      sides, the review stat with the engine excluded, the archive plan and the
#      cleanup plan, writes the review diff, and moves nothing.
#   3. A cutover whose archive fails swaps nothing; one against a remote that
#      is not on GitHub refuses too, unless --no-archive.
#   4. The cutover, confirmed on a terminal: four archive pull requests opened
#      as drafts and closed (-dev, -build and the vendor strand in
#      the fork, green's copy in the canonical repository), the four refs and
#      the vendor strand swapped to the forward's tips, the canonical green
#      forced to the new one, and the forward's refs, its vendor strand, its rc
#      strand, its retry ledger and its canonical copy deleted.
#   5. series-check.sh ignores what a refused deletion leaves as cutover litter.
#   6. series-prune.sh lists that litter with the commands that remove it and
#      runs none of them; it offers nothing of a live forward.
#   7. series-advance.sh mirrors a forward's green into the canonical repository
#      under a lease, so a rebase that reset it does not stop the firing, and
#      a base green plainly, so a divergence there does.
#
# Usage:
#   scripts/series-cutover-test.sh
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
# A series `v9.9-x` seeded on an older `main`, two vendor commits deep, and its
# forward seeded on the current `main`, three deep: the forward covers the
# series. Both have a green at their tip, a buffer one commit ahead of green on
# the series, an rc strand, a retry ledger and a vendor strand on the forward.
# The canonical repository holds `main` and both greens, as the loop's
# mirroring leaves them.

FORK=$SCRATCH/fork.git
CANON=$SCRATCH/canonical.git
WORK=$SCRATCH/work
BIN=$SCRATCH/bin
for r in "$FORK" "$CANON"; do git init -q --bare -b main "$r"; done

# The `gh` stand-in: every call appended to a log, a pull request number for a
# POST, the number back for a PATCH, an existing pull request for a GET where
# $GH_EXISTING names one as `<head>:<number>`, and a failure on demand.
mkdir -p "$BIN"
cat > "$BIN/gh" <<'EOF'
#!/bin/bash
echo "$*" >> "$GH_LOG"
[ -z "${GH_FAIL:-}" ] || { echo "gh: refused" >&2; exit 1; }
case " $* " in
  *" -X POST "*) n=$(( $(grep -c -- '-X POST' "$GH_LOG") + 100 )); echo "$n" ;;
  *" -X PATCH "*) sed -n 's#.*/pulls/\([0-9]*\) .*#\1#p' <<<"$*" ;;
  *" -X GET "*) case " $* " in *" head=test:${GH_EXISTING%%:*} "*) echo "${GH_EXISTING#*:}" ;; esac ;;
esac
EOF
chmod +x "$BIN/gh"
export GH_LOG=$SCRATCH/gh.log
export SERIES_GH=$BIN/gh
: > "$GH_LOG"

git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$FORK"
git remote add upstream "$CANON"
git config remote.origin.github test/fork
git config remote.upstream.github test/canonical

mkdir -p scripts R src/duckdb tests/testthat
for s in series-cutover.sh series-converge.sh series-prune.sh series-check.sh series-advance.sh \
  series-tests.sh setup-git.sh merge-version.sh; do
  cp "$HERE/$s" scripts/
done
chmod +x scripts/*.sh
echo 'DESCRIPTION merge=ours-version' > .gitattributes
scripts/setup-git.sh >/dev/null

desc() { printf 'Package: duckdb.9.9.dev\nVersion: %s\n' "$1" > DESCRIPTION; }
commit() { git add -A; git commit -qm "$1"; }

desc 1.0.0.9000
echo 'engine 0' > src/duckdb/engine.cpp
echo 'duckdb_version <- "0.0.0"' > R/version.R
echo 'foo <- function() 1' > R/foo.R
echo 'glue 0' > src/glue.cpp
echo 'test_that("one", expect_true(TRUE))' > tests/testthat/test-one.R
cat > scripts/series.yaml <<'EOF'
flavors:
  - flavor: duckdb.9.9.dev
    kind: dev
    upstream: v9.9-x
    series: v9.9-x
    releases_from: main
    publishes_from: v9.9-x-green
    repo: duckdb/duckdb-r
    badges: [r-universe]
EOF
commit 'vendor: Update vendored sources to duckdb/duckdb@0000000 (#1)'
OLD_MAIN=$(git rev-parse HEAD)
echo 'bar <- function() 2' > R/bar.R
commit 'feat: Add bar()'
MAIN=$(git rev-parse HEAD)
git push -q origin main
git push -q upstream main

shas=(aaaa111 bbbb222 cccc333 dddd444)
series() { # <series> <seed> <vendor commits on -dev> <on -build> <fourth component>
  local s=$1 seed=$2 ndev=$3 nbuild=$4 v=$5 i sha
  git checkout -q --detach "$seed"
  desc "1.0.0.$v.0"
  commit 'chore: Add fifth version component'
  local top; top=$(git rev-parse HEAD)
  for ((i = 0; i < nbuild; i++)); do
    sha=${shas[i]}
    echo "engine $sha" > src/duckdb/engine.cpp
    echo "glue $sha" > src/glue.cpp
    desc "1.0.0.$v.$((i + 1))"
    commit "vendor: Update vendored sources to duckdb/duckdb@$sha"
  done
  git branch -f "$s-build" HEAD
  git checkout -q --detach "$top"
  for ((i = 0; i < ndev; i++)); do
    sha=${shas[i]}
    echo "engine $sha" > src/duckdb/engine.cpp
    echo "glue $sha" > src/glue.cpp
    desc "1.0.0.$v.$((i + 1))"
    commit "vendor: Update vendored sources to duckdb/duckdb@$sha"
  done
  git branch -f "$s-dev" HEAD
  git branch -f "$s-green" HEAD
  git branch -f "$s-build-base" "$s-build~$((nbuild - ndev))"
}
series v9.9-x "$OLD_MAIN" 2 3 9000
series v9.9-x-fwd "$MAIN" 3 3 9001
git branch -f v9.9-x-fwd-rc-dev v9.9-x-fwd-dev
git branch -f retry-v9.9-x-fwd-dev v9.9-x-fwd-dev
git branch -f v9.9-x-vendor v9.9-x-build~1
git branch -f v9.9-x-fwd-vendor v9.9-x-fwd-build~1

# The store stub, empty: every commit reads `missing`.
git checkout -q --orphan rcc2
git rm -rqf .
echo stub > README
commit 'chore: store stub'

git checkout -q main
git push -q origin rcc2 \
  v9.9-x-build v9.9-x-dev v9.9-x-green v9.9-x-build-base v9.9-x-vendor \
  v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base \
  v9.9-x-fwd-rc-dev retry-v9.9-x-fwd-dev v9.9-x-fwd-vendor
git push -q upstream v9.9-x-green v9.9-x-fwd-green
git fetch -q origin
git fetch -q upstream

run() { set +e; "$@" 2>&1; echo "EXIT=$?"; set -e; }
heads() { git ls-remote --heads "$1" | sort; }
# The cutover on a terminal: `script` lends it a pty, and the confirmation is
# typed into it.
tty_run() { # <args...> -> output and EXIT=
  set +e
  printf 'v9.9-x\n' | script -qec "$(printf '%q ' "$@")" /dev/null 2>&1 | tr -d '\r'
  echo "EXIT=${PIPESTATUS[1]}"
  set -e
}

OLD_DEV=$(git rev-parse origin/v9.9-x-dev)
OLD_BUILD=$(git rev-parse origin/v9.9-x-build)
OLD_GREEN=$(git rev-parse origin/v9.9-x-green)
NEW_DEV=$(git rev-parse origin/v9.9-x-fwd-dev)
NEW_BUILD=$(git rev-parse origin/v9.9-x-fwd-build)
NEW_GREEN=$(git rev-parse origin/v9.9-x-fwd-green)
NEW_BB=$(git rev-parse origin/v9.9-x-fwd-build-base)
NEW_VENDOR=$(git rev-parse v9.9-x-fwd-vendor)

echo "=== 1. without a terminal the cutover refuses, and names --prepare"
before_fork=$(heads origin); before_canon=$(heads upstream)
out=$(run scripts/series-cutover.sh v9.9-x </dev/null)
has "it refuses" "$out" "EXIT=1"
has "as a manual operation" "$out" "cutover is a manual operation"
has "naming the read-only mode" "$out" "--prepare runs the gates and the review alone"
is "and moved nothing" "$(heads origin)" "$before_fork"

echo
echo "=== 2. --prepare prints the gates, the review and the plan, and moves nothing"
OUT=$SCRATCH/prepare
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT")
[ -z "${KEEP:-}" ] || echo "$out"
has "the run finishes" "$out" "EXIT=0"
has "old green named" "$out" "old green vendors: bbbb222"
has "new green named" "$out" "new green vendors: cccc333"
has "coverage not verified without a clone" "$out" "no upstream clone given, coverage gate not verified"
has "the convergence read is printed" "$out" "=== v9.9-x"
has "the package on both sides" "$out" "package: duckdb.9.9.dev"
has "the four refs with their versions" "$out" "v9.9-x-green               ${OLD_GREEN:0:7} 1.0.0.9000.2     ->  ${NEW_GREEN:0:7} 1.0.0.9001.3"
has "the review names the glue" "$out" "src/glue.cpp"
hasnt "and not the engine" "$out" "src/duckdb/engine.cpp"
has "the archive plan names -dev in the fork" "$out" "v9.9-x-dev -> v9.9-x-fwd-dev in test/fork"
has "and -build" "$out" "v9.9-x-build -> v9.9-x-fwd-build in test/fork"
hasnt "but not green, which is on -dev" "$out" "v9.9-x-green -> v9.9-x-fwd-green in test/fork"
hasnt "nor build-base, which is on -build" "$out" "v9.9-x-build-base ->"
has "and the vendor strand against the forward's" "$out" "v9.9-x-vendor -> v9.9-x-fwd-vendor in test/fork"
has "and green's copy in the canonical repository" "$out" "v9.9-x-green -> v9.9-x-fwd-green in test/canonical"
has "the cleanup names the forward's refs and strands" "$out" \
  "deleted after the swap: v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base v9.9-x-fwd-vendor v9.9-x-fwd-rc-dev retry-v9.9-x-fwd-dev on origin"
has "and the canonical copy" "$out" "v9.9-x-fwd-green on upstream"
has "and says nothing happened" "$out" "Prepared; nothing was opened, pushed or deleted."
is "the review diff is written" "$([ -s "$OUT/review.diff" ] && echo yes)" yes
hasnt "without the version bookkeeping" "$(cat "$OUT/review.stat")" "DESCRIPTION"
has "with the forward's R side" "$(cat "$OUT/review.diff")" "+glue cccc333"
is "the fork's refs are untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
is "and gh was not called" "$(wc -l < "$GH_LOG")" 0

echo
echo "=== 3. a cutover that cannot archive swaps nothing"
out=$(GH_FAIL=1 tty_run scripts/series-cutover.sh v9.9-x --out "$OUT")
[ -z "${KEEP:-}" ] || echo "$out"
has "the archive fails" "$out" "could not open the archive pull request for v9.9-x-dev in test/fork"
has "and the run stops" "$out" "EXIT=1"
is "with the fork's refs untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
: > "$GH_LOG"
git config --unset remote.origin.github
out=$(tty_run scripts/series-cutover.sh v9.9-x --out "$OUT")
has "a remote that is not on GitHub is refused" "$out" "origin is not a GitHub remote, so v9.9-x-dev cannot be archived there"
has "naming the override" "$out" "pass --no-archive"
has "and the run stops" "$out" "EXIT=1"
is "with the fork's refs untouched" "$(heads origin)" "$before_fork"
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --no-archive)
has "--no-archive says what it costs" "$out" "archive pull requests: skipped (--no-archive); the replaced history is reachable from nothing"
git config remote.origin.github test/fork
: > "$GH_LOG"

echo
echo "=== 4. the cutover: archive, swap, mirror, delete"
# A rerun after a swap that failed: -build was archived the first time, as #99.
out=$(GH_EXISTING=v9.9-x-build:99 tty_run scripts/series-cutover.sh v9.9-x --out "$OUT")
[ -z "${KEEP:-}" ] || echo "$out"
has "the run finishes" "$out" "EXIT=0"
has "the series is replaced" "$out" "Series v9.9-x replaced by its forward counterpart."
has "-dev archived in the fork" "$out" "archived v9.9-x-dev as test/fork#101 (closed; its head is refs/pull/101/head there)"
has "-build was archived already, and is not archived twice" "$out" "already archived v9.9-x-build as test/fork#99 (its head is refs/pull/99/head there)"
has "the vendor strand archived in the fork" "$out" "archived v9.9-x-vendor as test/fork#102"
has "green's copy archived in the canonical repository" "$out" "archived v9.9-x-green as test/canonical#103"
has "the canonical green moved" "$out" "canonical v9.9-x-green -> ${NEW_GREEN:0:7}"
has "the strands are to be re-cut" "$out" "scripts/series-rc.sh v9.9-x --push"
has "the fork's universe entry is named" "$out" "The fork's universe still names v9.9-x-fwd-green"
log=$(cat "$GH_LOG")
has "each archive is looked up first, closed, by head" "$log" "api -X GET repos/test/fork/pulls -f state=closed -f head=test:v9.9-x-dev -f per_page=20"
has "the -dev pull request is a draft from -dev against -fwd-dev" "$log" \
  "api -X POST repos/test/fork/pulls -f title=chore(series): Archive v9.9-x-dev before its cutover -f head=v9.9-x-dev -f base=v9.9-x-fwd-dev -F draft=true -f body=Archive of \`v9.9-x-dev\` as it stood before the cutover of \`v9.9-x\` on"
has "naming the tip it keeps" "$log" "$OLD_DEV"
has "and is closed" "$log" "api -X PATCH repos/test/fork/pulls/101 -f state=closed"
hasnt "the -build pull request is not opened again" "$log" "-f head=v9.9-x-build -f base=v9.9-x-fwd-build -F draft=true"
has "the vendor strand's pull request" "$log" "-f head=v9.9-x-vendor -f base=v9.9-x-fwd-vendor -F draft=true"
has "the canonical green's pull request" "$log" "api -X POST repos/test/canonical/pulls -f title=chore(series): Archive v9.9-x-green before its cutover -f head=v9.9-x-green -f base=v9.9-x-fwd-green"
is "four lookups, three pull requests opened and closed, nothing else" "$(grep -c -- "-X " "$GH_LOG")" 10
is "-dev is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-dev | cut -f1)" "$NEW_DEV"
is "-build is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-build | cut -f1)" "$NEW_BUILD"
is "-green is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"
is "-build-base is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-build-base | cut -f1)" "$NEW_BB"
is "-vendor is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-vendor | cut -f1)" "$NEW_VENDOR"
is "the forward's refs, its vendor strand, its rc strand and its ledger are gone" "$(git ls-remote origin 'refs/heads/*fwd*' | wc -l)" 0
is "the canonical green is the forward's" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"
is "and the canonical copy of the forward's green is gone" "$(git ls-remote upstream refs/heads/v9.9-x-fwd-green | wc -l)" 0
is "the old -dev is still an object in the fork" "$(git -C "$FORK" cat-file -t "$OLD_DEV")" commit
is "and so is the old -build" "$(git -C "$FORK" cat-file -t "$OLD_BUILD")" commit

echo
echo "=== 5. series-check.sh ignores cutover litter"
# A refused deletion leaves the forward's refs at the series' tips; and an
# older cutover left its rc strand behind.
git push -q origin "$NEW_GREEN:refs/heads/v9.9-x-fwd-green" "$NEW_DEV:refs/heads/v9.9-x-fwd-dev" \
  "$NEW_BUILD:refs/heads/v9.9-x-fwd-build" "$NEW_DEV:refs/heads/v9.9-x-fwd-rc-dev" "$NEW_BUILD~1:refs/heads/v9.9-x-fwd-vendor"
git push -q upstream "$NEW_GREEN:refs/heads/v9.9-x-fwd-green"
git fetch -q origin
out=$(run scripts/series-check.sh --canonical '')
[ -z "${KEEP:-}" ] || echo "$out"
has "the forward is litter" "$out" "v9.9-x-fwd: green is an ancestor of v9.9-x's — cutover litter, ignoring"
has "and the series gets a verdict" "$out" "=== v9.9-x:"

echo
echo "=== 6. series-prune.sh lists the litter and runs nothing"
before_fork=$(heads origin); before_canon=$(heads upstream)
out=$(run scripts/series-prune.sh v9.9-x-fwd)
has "a forward's name is refused" "$out" "EXIT=2"
has "naming the series" "$out" "name the series it forwards, v9.9-x"
out=$(run scripts/series-prune.sh v9.9-x)
[ -z "${KEEP:-}" ] || echo "$out"
has "the run finishes" "$out" "EXIT=0"
has "the forward reads as swapped in" "$out" "v9.9-x-fwd-green ${NEW_GREEN:0:7} is an ancestor of v9.9-x-green: the forward was swapped in"
has "the litter is listed" "$out" "cutover litter:"
has "the rc strand among it" "$out" "  v9.9-x-fwd-rc-dev"
has "and the canonical copy" "$out" "  v9.9-x-fwd-green on upstream"
has "the vendor strand among it too" "$out" "  v9.9-x-fwd-vendor"
has "the deletion in the fork" "$out" "git push --delete origin v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-vendor v9.9-x-fwd-rc-dev"
has "and in the canonical repository" "$out" "git push --delete upstream v9.9-x-fwd-green"
has "and nothing was run" "$out" "Nothing above was run."
is "the fork's refs are untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
# A live forward: its green is no ancestor of the series'.
git checkout -q --detach "$MAIN"
echo 'engine dddd444' > src/duckdb/engine.cpp
desc 1.0.0.9002.1
commit 'vendor: Update vendored sources to duckdb/duckdb@dddd444'
git push -q -f origin HEAD:refs/heads/v9.9-x-fwd-green HEAD:refs/heads/v9.9-x-fwd-dev
git checkout -q main
out=$(run scripts/series-prune.sh v9.9-x)
has "a live forward is not litter" "$out" "is not an ancestor of v9.9-x-green: the forward is live"
has "and nothing is offered" "$out" "Nothing to prune."

echo
echo "=== 7. series-advance.sh mirrors a forward's green under a lease, a base green plainly"
# The live forward's green was reset in 6, as a rebase resets one, and the
# canonical copy still holds the pre-reset green.
RESET=$(git rev-parse origin/v9.9-x-fwd-green)
git push -q origin "$NEW_BUILD:refs/heads/v9.9-x-fwd-build-base"
out=$(run scripts/series-advance.sh v9.9-x-fwd --chunk 0)
[ -z "${KEEP:-}" ] || echo "$out"
has "the reset green is mirrored" "$out" "green mirrored to upstream"
is "and the canonical copy is the reset one" "$(git ls-remote upstream refs/heads/v9.9-x-fwd-green | cut -f1)" "$RESET"
git push -q -f upstream "$OLD_GREEN:refs/heads/v9.9-x-green"
out=$(run scripts/series-advance.sh v9.9-x --chunk 0)
[ -z "${KEEP:-}" ] || echo "$out"
has "a base green that would not fast-forward stops the firing" "$out" "v9.9-x-green would not fast-forward in upstream"
has "with an error" "$out" "EXIT=1"
is "and the canonical copy is untouched" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$OLD_GREEN"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
