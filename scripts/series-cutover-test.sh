#!/bin/bash
# Check a cutover, offline, against a synthetic fork, canonical repository and
# clone built here: no network, no fixtures on disk, and a `gh` that records
# what it is asked instead of reaching GitHub.
#
# The claim is that scripts/series-cutover.sh swaps only on a confirmation
# that names the series, and under --confirm the state it was decided on, keeps
# every lineage the swap replaces as the head of a closed pull request, swaps
# the four refs atomically, moves the canonical copy of green, deletes what the
# forward leaves behind in both repositories, prints the archive pull requests
# and an undo that works, refuses to move anything when it cannot archive, or
# under --confirm on anything a terminal run leaves to the operator, and lists
# what a refused deletion leaves, keeping a forward ref that moved meanwhile;
# and that scripts/series-prune.sh offers only cutover litter, and runs
# nothing. Seventeen things are checked.
#
#   1. Without a terminal and without --confirm the cutover refuses before
#      fetching anything, and names --confirm and --prepare.
#   2. A --confirm that names another series, names no SHA or one of another
#      shape, or comes with --prepare or --no-archive is a usage error, exit 2,
#      and nothing is opened or moved.
#   3. --prepare prints the gates, the convergence read, the package on both
#      sides, the review stat with the engine excluded, the archive plan, the
#      cleanup plan, what --confirm would refuse on, the SHA to decide on and
#      the command for a terminal with the run's options, writes the review
#      diff, and moves nothing.
#   4. A cutover whose archive fails swaps nothing, on a terminal and with
#      --confirm alike; one that would archive in a remote not on GitHub, the
#      fork or the canonical repository, or without a gh, refuses too, before
#      any pull request, unless --no-archive. Under --confirm, a forward green
#      not at the SHA it names, or moved since --prepare, refuses, and so does
#      each warning a terminal run prints: coverage not verified, for want of a
#      clone or of a vendored SHA on the old green, a canonical remote that does
#      not exist or cannot be read, a divergence, a convergence read that
#      stopped, a renamed package, a version that keeps or goes back, and
#      versions not compared; each before anything is opened or moved.
#   5. The cutover, confirmed on a terminal: four archive pull requests opened
#      as drafts and closed (-dev, -build and the vendor strand in
#      the fork, green's copy in the canonical repository), the four refs and
#      the vendor strand swapped to the forward's tips, the canonical green
#      forced to the new one, and the forward's refs, its vendor strand, its rc
#      strand, its retry ledger and its canonical copy deleted. The archive pull
#      requests are listed with their URLs, and the undo is printed.
#   6. That undo, run in a fresh clone, puts the old lineage back in both
#      repositories and the forward's refs beside it.
#   7. The cutover with --confirm and no terminal, against remotes that refuse
#      deletions alone, as a cloud session's git proxy does: archived, swapped
#      and the canonical green moved, the forward's refs listed as litter, and
#      exit 9, read back correctly from a listing thousands of branches long.
#   8. The canonical copy of green: with --canonical '' there is none, and the
#      run exits 0; a --canonical naming no remote, or one that cannot be read,
#      leaves it neither archived nor moved, and the forward's copy there not
#      deleted, exit 9, with no lease on a tip the run did not read; and one
#      that moves under the run is printed with a push leased on where it is
#      now, which works.
#   9. The cutover with --confirm, against remotes that refuse deletions, and a
#      canonical repository that refuses to move green: archived and swapped
#      all the same, every ref left behind listed with the one command that
#      finishes it, and exit 9.
#  10. series-check.sh ignores what a refused deletion leaves as cutover litter.
#  11. series-prune.sh lists that litter with the commands that remove it and
#      runs none of them; it offers nothing of a live forward.
#  12. series-advance.sh mirrors a forward's green into the canonical repository
#      under a lease, so a rebase that reset it does not stop the firing, and
#      a base green plainly, so a divergence there does.
#  13. A forward ref that moves while the run archives, in the fork or in the
#      canonical repository, is kept and shown with what moved, not deleted,
#      and the run exits 9; the undo it prints leaves that ref out, and works.
#  14. On a terminal, a divergence is printed, and the swap follows the
#      confirmation.
#  15. A ref deleted since an earlier fetch, in the fork or the canonical
#      repository, is neither archived against nor deleted nor undone.
#  16. A canonical forward green that lags the fork's is undone to its own tip.
#  17. A refused deletion whose remote cannot be read back is reported as in a
#      state the run does not know, not as moved, with the line that reads
#      each ref, and the run exits 9.
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
# $GH_EXISTING names one as `<head>:<number>`, and a failure on demand. A POST
# keeps the head as `refs/pull/<n>/head`, as GitHub does, in the repository
# $GH_REPOS maps the slug to.
mkdir -p "$BIN"
cat > "$BIN/gh" <<'EOF'
#!/bin/bash
echo "$*" >> "$GH_LOG"
[ -z "${GH_FAIL:-}" ] || { echo "gh: refused" >&2; exit 1; }
case " $* " in
  *" -X POST "*)
    n=$(( $(grep -c -- '-X POST' "$GH_LOG") + 100 ))
    slug=$(sed -n 's#.* repos/\([^/]*/[^/]*\)/pulls .*#\1#p' <<<" $* ")
    head=$(sed -n 's#.* -f head=\([^ ]*\) .*#\1#p' <<<" $* ")
    for m in $GH_REPOS; do
      [ "${m%%=*}" != "$slug" ] || git -C "${m#*=}" update-ref "refs/pull/$n/head" "refs/heads/$head"
    done
    echo "$n" ;;
  *" -X PATCH "*) sed -n 's#.*/pulls/\([0-9]*\) .*#\1#p' <<<"$*" ;;
  *" -X GET "*) case " $* " in *" head=test:${GH_EXISTING%%:*} "*) echo "${GH_EXISTING#*:}" ;; esac ;;
esac
EOF
chmod +x "$BIN/gh"
export GH_LOG=$SCRATCH/gh.log
export SERIES_GH=$BIN/gh
export GH_REPOS="test/fork=$FORK test/canonical=$CANON"
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
  series-tests.sh setup-git.sh merge-version.sh series-config.sh series-lib.sh vendor-lib.sh; do
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

# The upstream clone the coverage gate reads: four commits in a line, whose
# short SHAs the vendor commits below name.
UP=$SCRATCH/duckdb
git init -q -b main "$UP"
shas=()
for i in 1 2 3 4; do
  git -C "$UP" -c user.name=Test -c user.email=test@example.invalid -c commit.gpgsign=false \
    commit -q --allow-empty -m "upstream $i"
  shas+=("$(git -C "$UP" rev-parse --short=7 HEAD)")
done
# Both series carry the same glue and R code, the base one by a port of `main`,
# so that they converge: what --confirm swaps on.
series() { # <series> <seed> <vendor commits on -dev> <on -build> <fourth component>
  local s=$1 seed=$2 ndev=$3 nbuild=$4 v=$5 i sha
  git checkout -q --detach "$seed"
  desc "1.0.0.$v.0"
  echo 'glue series' > src/glue.cpp
  echo 'bar <- function() 2' > R/bar.R
  commit 'chore: Add fifth version component'
  local top; top=$(git rev-parse HEAD)
  for ((i = 0; i < nbuild; i++)); do
    sha=${shas[i]}
    echo "engine $sha" > src/duckdb/engine.cpp
    desc "1.0.0.$v.$((i + 1))"
    commit "vendor: Update vendored sources to duckdb/duckdb@$sha"
  done
  git branch -f "$s-build" HEAD
  git checkout -q --detach "$top"
  for ((i = 0; i < ndev; i++)); do
    sha=${shas[i]}
    echo "engine $sha" > src/duckdb/engine.cpp
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
OLD_BB=$(git rev-parse origin/v9.9-x-build-base)
OLD_VENDOR=$(git rev-parse origin/v9.9-x-vendor)
NEW_DEV=$(git rev-parse origin/v9.9-x-fwd-dev)
NEW_BUILD=$(git rev-parse origin/v9.9-x-fwd-build)
NEW_GREEN=$(git rev-parse origin/v9.9-x-fwd-green)
NEW_BB=$(git rev-parse origin/v9.9-x-fwd-build-base)
NEW_VENDOR=$(git rev-parse v9.9-x-fwd-vendor)
# What --prepare prints to decide on, and --confirm names.
SHA=${NEW_GREEN:0:12}

# Back to the series and its forward as the fixture built them, in both
# repositories: what a test that moved a ref, or a cutover, undoes. The forward's
# rc strand and ledger are not put back, as the undo does not put them back.
restore() {
  git push -q -f origin "$OLD_DEV:refs/heads/v9.9-x-dev" "$OLD_BUILD:refs/heads/v9.9-x-build" \
    "$OLD_GREEN:refs/heads/v9.9-x-green" "$OLD_BB:refs/heads/v9.9-x-build-base" \
    "$OLD_VENDOR:refs/heads/v9.9-x-vendor" "$NEW_DEV:refs/heads/v9.9-x-fwd-dev" \
    "$NEW_BUILD:refs/heads/v9.9-x-fwd-build" "$NEW_GREEN:refs/heads/v9.9-x-fwd-green" \
    "$NEW_BB:refs/heads/v9.9-x-fwd-build-base" "$NEW_VENDOR:refs/heads/v9.9-x-fwd-vendor"
  git push -q -f upstream "$OLD_GREEN:refs/heads/v9.9-x-green" "$NEW_GREEN:refs/heads/v9.9-x-fwd-green"
  git fetch -q --prune origin
  git fetch -q --prune upstream
  : > "$GH_LOG"
}
# A commit on top of <base> that writes <file> with <content>, pushed to <refs>
# in the fork: a forward or a series that moved, for a refusal to read.
move_to() { # <base> <file> <content> <ref>...
  local base=$1 file=$2 content=$3 r c
  shift 3
  git checkout -q --detach "$base"
  printf '%s\n' "$content" > "$file"
  commit "fix: change $file"
  c=$(git rev-parse HEAD)
  git checkout -q main
  for r in "$@"; do git push -q -f origin "$c:refs/heads/$r"; done
  git fetch -q origin
  echo "$c"
}

echo "=== 1. without a terminal and without --confirm the cutover refuses, and names both ways on"
before_fork=$(heads origin); before_canon=$(heads upstream)
out=$(run scripts/series-cutover.sh v9.9-x </dev/null)
has "it refuses" "$out" "EXIT=1"
has "for want of a confirmation" "$out" "a cutover swaps only on a confirmation that names the series"
has "naming --confirm" "$out" "pass --confirm <series>@<sha> once a maintainer has decided"
has "and that the loop never gives one" "$out" "it never confirms one"
has "naming the read-only mode" "$out" "--prepare runs the gates and the review alone"
is "and moved nothing" "$(heads origin)" "$before_fork"

echo
echo "=== 2. a --confirm that does not name the series and a SHA is a usage error, and moves nothing"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-y@$SHA" </dev/null)
has "another series is refused" "$out" "EXIT=2"
has "naming both" "$out" "--confirm names 'v9.9-y', but the series to cut over is 'v9.9-x'; nothing was moved."
out=$(run scripts/series-cutover.sh v9.9-x --confirm '' </dev/null)
has "an empty one too" "$out" "EXIT=2"
out=$(run scripts/series-cutover.sh v9.9-x --confirm </dev/null)
has "and a missing one" "$out" "EXIT=2"
has "with the usage" "$out" "[--prepare | --confirm <series>@<sha>]"
out=$(run scripts/series-cutover.sh v9.9-x --confirm v9.9-x </dev/null)
has "the series without a SHA is refused" "$out" "EXIT=2"
has "naming what it takes" "$out" "--confirm takes v9.9-x@<sha>, the tip of v9.9-x-fwd-green that --prepare printed,"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@${NEW_GREEN:0:11}" </dev/null)
has "a SHA shorter than 12 digits is refused" "$out" "EXIT=2"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@${NEW_GREEN}0" </dev/null)
has "and one longer than 40" "$out" "EXIT=2"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@not-a-sha-at-all" </dev/null)
has "and one that is not hex" "$out" "EXIT=2"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$(tr a-f A-F <<<"$SHA")" </dev/null)
has "and one in capitals" "$out" "EXIT=2"
out=$(run scripts/series-cutover.sh v9.9-x --prepare --confirm "v9.9-x@$SHA" </dev/null)
has "beside --prepare it is refused" "$out" "EXIT=2"
has "as a contradiction" "$out" "--prepare moves nothing and --confirm swaps; pass one of them."
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --no-archive </dev/null)
has "beside --no-archive it is refused" "$out" "EXIT=2"
has "as a swap that keeps nothing" "$out" "--no-archive would keep the replaced history nowhere"
is "the fork's refs are untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
is "and gh was not called" "$(wc -l < "$GH_LOG")" 0

echo
echo "=== 3. --prepare prints the gates, the review and the plan, and moves nothing"
OUT=$SCRATCH/prepare
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT")
[ -z "${KEEP:-}" ] || echo "$out"
has "the run finishes" "$out" "EXIT=0"
has "old green named" "$out" "old green vendors: ${shas[1]}"
has "new green named" "$out" "new green vendors: ${shas[2]}"
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
has "the read converges" "$out" "CONVERGED"
has "what --confirm would refuse on is listed" "$out" \
  "--confirm would refuse on what this run warned about, which a terminal run leaves to the operator:"
has "the coverage not verified among it" "$out" "  coverage: no upstream clone given"
has "and says nothing happened" "$out" "Prepared; nothing was opened, pushed or deleted. The state to decide on:"
has "the SHA to decide on, in full" "$out" "  v9.9-x-fwd-green at $NEW_GREEN"
has "and the command for a terminal" "$out" "  scripts/series-cutover.sh v9.9-x --remote origin --canonical upstream"
hasnt "but no command line that confirms" "$out" "--confirm v9.9-x"
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP")
has "with a clone, coverage is verified" "$out" "EXIT=0"
hasnt "and --confirm would refuse on nothing" "$out" "--confirm would refuse on"
has "the clone is in the command for a terminal" "$out" "--canonical upstream --upstream $(printf '%q' "$UP")"
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --canonical '' --no-archive)
has "and so is every other option the run was given" "$out" \
  "  scripts/series-cutover.sh v9.9-x --remote origin --canonical '' --out $(printf '%q' "$OUT") --no-archive"
hasnt "--prepare aside" "$(grep -F 'scripts/series-cutover.sh v9.9-x' <<<"$out")" "--prepare"
is "the review diff is written" "$([ -s "$OUT/review.diff" ] && echo yes)" yes
hasnt "without the version bookkeeping" "$(cat "$OUT/review.stat")" "DESCRIPTION"
has "with the forward's R side" "$(cat "$OUT/review.diff")" "+glue series"
is "the fork's refs are untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
is "and gh was not called" "$(wc -l < "$GH_LOG")" 0

echo
echo "=== 4. a cutover that cannot archive, or under --confirm meets a warning or another state, swaps nothing"
out=$(GH_FAIL=1 tty_run scripts/series-cutover.sh v9.9-x --out "$OUT")
[ -z "${KEEP:-}" ] || echo "$out"
has "the archive fails" "$out" "could not open the archive pull request for v9.9-x-dev in test/fork"
has "and the run stops" "$out" "EXIT=1"
is "with the fork's refs untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
out=$(GH_FAIL=1 run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --upstream "$UP" --out "$OUT" </dev/null)
[ -z "${KEEP:-}" ] || echo "$out"
has "with --confirm the archive is still tried first" "$out" "confirmed by --confirm v9.9-x@$SHA, the tip of v9.9-x-fwd-green."
has "and fails the same way" "$out" "could not open the archive pull request for v9.9-x-dev in test/fork"
has "and the run stops" "$out" "EXIT=1"
hasnt "before the swap" "$out" "replaced by its forward counterpart"
is "with the fork's refs untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
: > "$GH_LOG"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --out "$OUT" </dev/null)
[ -z "${KEEP:-}" ] || echo "$out"
has "--confirm without a clone refuses at the coverage gate" "$out" \
  "no upstream clone given, so the coverage gate cannot be verified, and --confirm"
has "naming the option" "$out" "pass --upstream <path>. Nothing was moved."
has "and the run stops" "$out" "EXIT=1"
hasnt "where a terminal run only warns" "$out" "coverage gate not verified"
is "before any archive" "$(wc -l < "$GH_LOG")" 0
is "with the fork's refs untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
: > "$GH_LOG"
git config --unset remote.origin.github
out=$(tty_run scripts/series-cutover.sh v9.9-x --out "$OUT")
has "a remote that is not on GitHub is refused" "$out" "origin is not a GitHub remote, so v9.9-x-dev cannot be archived there"
has "naming the override" "$out" "On a terminal, --no-archive swaps without the archive."
has "and the run stops" "$out" "EXIT=1"
hasnt "before the confirmation is asked for" "$out" "Type the series name to confirm"
is "with the fork's refs untouched" "$(heads origin)" "$before_fork"
is "and gh was not called" "$(wc -l < "$GH_LOG")" 0
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --no-archive)
has "--no-archive says what it costs" "$out" "archive pull requests: skipped (--no-archive); the replaced history is reachable from nothing"
git config remote.origin.github test/fork
: > "$GH_LOG"

# Under --confirm: each refusal below comes before anything is opened or moved.
untouched() { # <what>
  is "$1: before any archive" "$(wc -l < "$GH_LOG")" 0
  is "$1: with the fork's refs untouched" "$(heads origin)" "$before_fork"
  is "$1: and the canonical repository's" "$(heads upstream)" "$before_canon"
}
confirm() { run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@${1:-$SHA}" --upstream "$UP" --out "$OUT" "${@:2}" </dev/null; }
out=$(confirm "${OLD_GREEN:0:12}")
[ -z "${KEEP:-}" ] || echo "$out"
has "a SHA that is not the forward green's is refused" "$out" \
  "v9.9-x-fwd-green is at $NEW_GREEN on origin, not at the ${OLD_GREEN:0:12} that --confirm names."
has "and the run stops" "$out" "EXIT=1"
untouched "a SHA not the forward green's"
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP")
decided=$(sed -n 's/^  v9.9-x-fwd-green at //p' <<<"$out")
is "--prepare names the tip to decide on" "$decided" "$NEW_GREEN"
moved=$(move_to "$NEW_GREEN" R/foo.R 'foo <- function() 3' v9.9-x-fwd-green)
out=$(confirm "$decided")
[ -z "${KEEP:-}" ] || echo "$out"
has "a forward green that moved after --prepare is refused" "$out" \
  "v9.9-x-fwd-green is at $moved on origin, not at the $NEW_GREEN that --confirm names."
has "with the decision sent back" "$out" "The forward moved after the state the decision was taken on"
has "and the run stops" "$out" "EXIT=1"
is "before any archive" "$(wc -l < "$GH_LOG")" 0
restore
out=$(confirm "$SHA" --canonical nosuch)
[ -z "${KEEP:-}" ] || echo "$out"
has "a --canonical naming no remote is refused" "$out" \
  "there is no remote 'nosuch', so the canonical copy of v9.9-x-green would be neither archived"
has "naming the way to say there is none" "$out" "or pass --canonical '' where there is no canonical repository. Nothing was moved."
has "and the run stops" "$out" "EXIT=1"
untouched "no canonical remote"
# A commit on the old green that touches the engine without vendoring: one
# commit deep, the scan finds no vendored SHA on it.
move_to "$OLD_GREEN" src/duckdb/engine.cpp 'engine patched' v9.9-x-green v9.9-x-dev >/dev/null
out=$(BASE_SCAN_DEPTH=1 run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP")
[ -z "${KEEP:-}" ] || echo "$out"
has "an old green with no vendored SHA to read warns on --prepare" "$out" \
  "Warning: no vendored SHA could be read on v9.9-x-green, coverage gate not verified"
has "and is what --confirm would refuse on" "$out" "  coverage: no vendored SHA read on v9.9-x-green"
out=$(BASE_SCAN_DEPTH=1 confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "under --confirm it refuses" "$out" "no vendored SHA could be read on v9.9-x-green, so the coverage gate cannot be verified,"
has "and the run stops" "$out" "EXIT=1"
is "before any archive" "$(wc -l < "$GH_LOG")" 0
restore
# A fix on the series' -dev that the forward does not carry.
move_to "$OLD_DEV" R/foo.R 'foo <- function() 3' v9.9-x-dev >/dev/null
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "a divergence is printed" "$out" "DIVERGED: 1 path(s) the forwarding does not explain."
has "and refused under --confirm" "$out" "--confirm swaps with nobody to weigh a warning, and this run printed these:"
has "naming it" "$out" "  convergence: paths the forwarding does not explain"
has "and the run stops" "$out" "EXIT=1"
is "before any archive" "$(wc -l < "$GH_LOG")" 0
restore
move_to "$NEW_DEV" DESCRIPTION "$(printf 'Package: duckdb.other\nVersion: 1.0.0.9001.4')" v9.9-x-fwd-dev >/dev/null
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "a renamed package is printed" "$out" "package: duckdb.9.9.dev -> duckdb.other"
has "and refused under --confirm" "$out" "  package: renamed from duckdb.9.9.dev to duckdb.other"
has "and the run stops" "$out" "EXIT=1"
is "before any archive" "$(wc -l < "$GH_LOG")" 0
restore
kept=$(move_to "$NEW_GREEN" DESCRIPTION "$(printf 'Package: duckdb.9.9.dev\nVersion: 1.0.0.9000.2')" v9.9-x-fwd-dev v9.9-x-fwd-green)
out=$(confirm "$kept")
[ -z "${KEEP:-}" ] || echo "$out"
has "a version kept is printed" "$out" "Warning: v9.9-x-green keeps version 1.0.0.9000.2 across the swap."
has "and refused under --confirm, for -dev" "$out" "  version: v9.9-x-dev keeps 1.0.0.9000.2"
has "and for -green" "$out" "  version: v9.9-x-green keeps 1.0.0.9000.2"
has "and the run stops" "$out" "EXIT=1"
is "before any archive" "$(wc -l < "$GH_LOG")" 0
restore
back=$(move_to "$NEW_GREEN" DESCRIPTION "$(printf 'Package: duckdb.9.9.dev\nVersion: 1.0.0.9000.1')" v9.9-x-fwd-dev v9.9-x-fwd-green)
out=$(confirm "$back")
[ -z "${KEEP:-}" ] || echo "$out"
has "a version going back is printed" "$out" "Warning: v9.9-x-green would go from 1.0.0.9000.2 back to 1.0.0.9000.1."
has "and refused under --confirm" "$out" "  version: v9.9-x-green goes from 1.0.0.9000.2 back to 1.0.0.9000.1"
has "and the run stops" "$out" "EXIT=1"
is "before any archive" "$(wc -l < "$GH_LOG")" 0
restore
# A `sort` that is not GNU's, and no `gsort`: the versions are not compared.
mkdir -p "$SCRATCH/nognu"
cat > "$SCRATCH/nognu/sort" <<'SORT'
#!/bin/bash
[ "${1:-}" != --version ] || { echo "sort (not GNU)"; exit 0; }
exec "$REAL_SORT" "$@"
SORT
chmod +x "$SCRATCH/nognu/sort"
out=$(REAL_SORT=$(command -v sort) PATH=$SCRATCH/nognu:$PATH confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "versions not compared are printed" "$out" "Note: no GNU sort here, so the versions above were not compared."
has "and refused under --confirm" "$out" "  version: not compared, for want of GNU sort"
has "and the run stops" "$out" "EXIT=1"
untouched "versions not compared"
# A canonical remote that exists and cannot be read, whose tracking refs an
# earlier fetch left: nothing is planned on them.
git remote add broken "$SCRATCH/does-not-exist.git"
git config remote.broken.github test/canonical
for b in main v9.9-x-green v9.9-x-fwd-green; do git update-ref "refs/remotes/broken/$b" "refs/remotes/upstream/$b"; done
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP" --canonical broken)
[ -z "${KEEP:-}" ] || echo "$out"
has "a canonical remote that cannot be read warns on --prepare" "$out" \
  "Warning: could not read broken (above), so the canonical copy of v9.9-x-green would be neither"
has "and is what --confirm would refuse on" "$out" "  canonical: could not read broken"
hasnt "nothing is archived on the copy an earlier fetch left" "$out" "v9.9-x-green -> v9.9-x-fwd-green in test/canonical"
hasnt "nor deleted" "$out" "v9.9-x-fwd-green on broken"
out=$(confirm "$SHA" --canonical broken)
[ -z "${KEEP:-}" ] || echo "$out"
has "under --confirm it refuses" "$out" "--confirm swaps with nobody to weigh a warning, and this run printed these:"
has "naming it" "$out" "  canonical: could not read broken"
has "and the run stops" "$out" "EXIT=1"
untouched "a canonical remote that cannot be read"
# A plan that archives in a remote naming no repository refuses before the
# first pull request, here the canonical one's after the fork's; so does a
# missing gh.
git config --unset remote.upstream.github
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP")
[ -z "${KEEP:-}" ] || echo "$out"
has "--prepare names the canonical remote as not on GitHub" "$out" "v9.9-x-green -> v9.9-x-fwd-green in upstream, which is not a GitHub remote"
has "and says the swap would refuse on it" "$out" \
  "the swap would refuse, on a terminal too, as the archive cannot be opened; --no-archive is the terminal's override:"
has "naming the setting" "$out" \
  "  upstream is not a GitHub remote, so v9.9-x-green cannot be archived there; set 'git config remote.upstream.github <owner>/<repo>'"
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "under --confirm it refuses" "$out" "Error: the swap archives what it replaces first, and this run cannot:"
has "naming the remote" "$out" "  upstream is not a GitHub remote, so v9.9-x-green cannot be archived there"
has "and the run stops" "$out" "EXIT=1"
untouched "a canonical remote not on GitHub, under --confirm"
out=$(tty_run scripts/series-cutover.sh v9.9-x --out "$OUT" --upstream "$UP")
has "on a terminal it refuses too" "$out" "  upstream is not a GitHub remote, so v9.9-x-green cannot be archived there"
hasnt "before the confirmation is asked for" "$out" "Type the series name to confirm"
untouched "a canonical remote not on GitHub, on a terminal"
git config remote.upstream.github test/canonical
out=$(SERIES_GH=$SCRATCH/no-such-gh confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "a gh that is not installed refuses" "$out" "  $SCRATCH/no-such-gh is not installed, so nothing can be archived"
has "and the run stops" "$out" "EXIT=1"
untouched "a gh that is not installed"
# The convergence read that stops for another reason than a divergence.
printf '#!/bin/bash\necho "converge: could not read the store" >&2\nexit 3\n' > scripts/series-converge.sh
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP")
[ -z "${KEEP:-}" ] || echo "$out"
has "a convergence read that stopped is printed" "$out" "the convergence read stopped with status 3 although v9.9-x-dev exists;"
has "and is what --confirm would refuse on" "$out" "  convergence: the read stopped with status 3"
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "under --confirm it refuses" "$out" "--confirm swaps with nobody to weigh a warning, and this run printed these:"
has "naming it" "$out" "  convergence: the read stopped with status 3"
has "and the run stops" "$out" "EXIT=1"
untouched "a convergence read that stopped"
cp "$HERE/series-converge.sh" scripts/series-converge.sh

echo
echo "=== 5. the cutover: archive, swap, mirror, delete"
# A rerun after a swap that failed: -build was archived the first time, as #99.
git -C "$FORK" update-ref refs/pull/99/head "$OLD_BUILD"
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
has "each archive pull request is printed with its URL" "$out" \
  "archived v9.9-x-dev as test/fork#101 (closed; its head is refs/pull/101/head there): https://github.com/test/fork/pull/101"
has "and listed after the swap, to be quoted" "$out" "  v9.9-x-dev: test/fork#101 https://github.com/test/fork/pull/101"
has "the one archived by the first run among them" "$out" "  v9.9-x-build: test/fork#99 https://github.com/test/fork/pull/99"
has "the vendor strand's" "$out" "  v9.9-x-vendor: test/fork#102 https://github.com/test/fork/pull/102"
has "and the canonical green's" "$out" "  v9.9-x-green: test/canonical#103 https://github.com/test/canonical/pull/103"
has "the undo fetches the fork's archive heads" "$out" "  git fetch origin refs/pull/101/head refs/pull/99/head refs/pull/102/head"
has "and the canonical one's" "$out" "  git fetch upstream refs/pull/103/head"
has "with one atomic push there too" "$out" \
  "  git push --atomic --force-with-lease=refs/heads/v9.9-x-green:$NEW_GREEN upstream $OLD_GREEN:refs/heads/v9.9-x-green $NEW_GREEN:refs/heads/v9.9-x-fwd-green"
has "and leases the fork's refs on the forward's tips" "$out" "--force-with-lease=refs/heads/v9.9-x-green:$NEW_GREEN"
hasnt "nothing is left behind" "$out" "SWAPPED, LEFT BEHIND"

echo
echo "=== 6. the undo the cutover printed puts the old lineage back, from a fresh clone"
undo=$(awk '/^undo, while nothing has moved since/ { f = 1; next } f && /^$/ { f = 0 } f && /^  git / { sub(/^  /, ""); print }' <<<"$out")
[ -z "${KEEP:-}" ] || echo "$undo"
is "a fetch and a push for each repository" "$(grep -c . <<<"$undo")" 4
# --no-local, so the clone holds what the fork's branches reach and nothing more.
git clone -q --no-local "$FORK" "$SCRATCH/undo"
git -C "$SCRATCH/undo" remote add upstream "$CANON"
is "a fresh clone does not have the old -dev" "$(git -C "$SCRATCH/undo" cat-file -t "$OLD_DEV" 2>/dev/null || echo missing)" missing
out=$(cd "$SCRATCH/undo" && run bash -ec "$undo")
[ -z "${KEEP:-}" ] || echo "$out"
has "the undo runs" "$out" "EXIT=0"
is "-dev is the old one" "$(git ls-remote origin refs/heads/v9.9-x-dev | cut -f1)" "$OLD_DEV"
is "-build too" "$(git ls-remote origin refs/heads/v9.9-x-build | cut -f1)" "$OLD_BUILD"
is "-green too" "$(git ls-remote origin refs/heads/v9.9-x-green | cut -f1)" "$OLD_GREEN"
is "-build-base too" "$(git ls-remote origin refs/heads/v9.9-x-build-base | cut -f1)" "$OLD_BB"
is "-vendor too" "$(git ls-remote origin refs/heads/v9.9-x-vendor | cut -f1)" "$OLD_VENDOR"
is "the forward's -dev is back" "$(git ls-remote origin refs/heads/v9.9-x-fwd-dev | cut -f1)" "$NEW_DEV"
is "and its green" "$(git ls-remote origin refs/heads/v9.9-x-fwd-green | cut -f1)" "$NEW_GREEN"
is "and its vendor strand" "$(git ls-remote origin refs/heads/v9.9-x-fwd-vendor | cut -f1)" "$NEW_VENDOR"
is "the canonical green is the old one" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$OLD_GREEN"
is "and the forward's copy there is back" "$(git ls-remote upstream refs/heads/v9.9-x-fwd-green | cut -f1)" "$NEW_GREEN"

echo
echo "=== 7. --confirm without a terminal, against remotes that refuse deletions alone"
restore
git -C "$FORK" config receive.denyDeletes true
git -C "$CANON" config receive.denyDeletes true
# Enough branches after the forward's, in the listing the run reads back, that
# a reader stopping at the first match would end the one before it by SIGPIPE.
for i in $(seq -w 1 4000); do echo "create refs/heads/zz-pad-$i $MAIN"; done | git -C "$FORK" update-ref --stdin
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --upstream "$UP" --out "$OUT" </dev/null)
[ -z "${KEEP:-}" ] || echo "$out"
has "the series is replaced" "$out" "Series v9.9-x replaced by its forward counterpart."
is "-green is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"
is "the canonical green is moved" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"
hasnt "and not left behind" "$out" "is still on the pre-cutover lineage"
has "the canonical undo is one atomic push" "$out" \
  "  git push --atomic --force-with-lease=refs/heads/v9.9-x-green:$NEW_GREEN upstream $OLD_GREEN:refs/heads/v9.9-x-green $NEW_GREEN:refs/heads/v9.9-x-fwd-green"
has "the litter in the fork is named" "$out" \
  "  cutover litter in origin, which loses nothing when deleted: v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base v9.9-x-fwd-vendor"
has "and in the canonical repository" "$out" "  cutover litter in upstream, which loses nothing when deleted: v9.9-x-fwd-green"
is "the last line says the swap stands" "$(grep -v '^EXIT=' <<<"$out" | tail -n 1)" \
  "SWAPPED, LEFT BEHIND: v9.9-x is cut over; run the lines above, or hand them to a maintainer."
has "and a refused deletion alone is exit 9" "$out" "EXIT=9"
git -C "$FORK" config --unset receive.denyDeletes
git -C "$CANON" config --unset receive.denyDeletes
git -C "$FORK" for-each-ref --format='delete %(refname)' 'refs/heads/zz-pad-*' | git -C "$FORK" update-ref --stdin

echo
echo "=== 8. the canonical copy of green: none, no remote, or moved under the run"
restore
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --upstream "$UP" --out "$OUT" --canonical '' </dev/null)
[ -z "${KEEP:-}" ] || echo "$out"
has "with --canonical '' the cutover runs" "$out" "Series v9.9-x replaced by its forward counterpart."
hasnt "with nothing left behind" "$out" "SWAPPED, LEFT BEHIND"
has "and exits 0" "$out" "EXIT=0"
is "no archive is opened in the canonical repository" "$(grep -c 'repos/test/canonical' "$GH_LOG" || true)" 0
is "and its green is untouched" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$OLD_GREEN"
restore
out=$(tty_run scripts/series-cutover.sh v9.9-x --upstream "$UP" --out "$OUT" --canonical nosuch)
[ -z "${KEEP:-}" ] || echo "$out"
has "a --canonical naming no remote warns on a terminal" "$out" \
  "Warning: there is no remote 'nosuch', so the canonical copy of v9.9-x-green will be neither archived"
has "the cutover runs" "$out" "Series v9.9-x replaced by its forward counterpart."
has "the canonical green is left behind" "$out" \
  "  v9.9-x-green in the canonical repository was neither archived nor moved, as no remote here is called"
has "with the push that moves it once its tip is read" "$out" \
  "    git push --force-with-lease=refs/heads/v9.9-x-green:<the tip it holds> nosuch $NEW_GREEN:refs/heads/v9.9-x-green"
has "the forward's copy there is left behind too" "$out" \
  "  Nor was the forward's copy there, v9.9-x-fwd-green, deleted, where it holds one."
has "with the deletion it is owed once its tip is read" "$out" \
  "    git push --force-with-lease=refs/heads/v9.9-x-fwd-green:<the tip it holds> nosuch :refs/heads/v9.9-x-fwd-green"
has "and exit 9" "$out" "EXIT=9"
is "no archive is opened in the canonical repository" "$(grep -c 'repos/test/canonical' "$GH_LOG" || true)" 0
is "and its green is untouched" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$OLD_GREEN"
restore
# The remote from 4 that cannot be read, its stale tracking refs still there.
out=$(tty_run scripts/series-cutover.sh v9.9-x --upstream "$UP" --out "$OUT" --canonical broken)
[ -z "${KEEP:-}" ] || echo "$out"
has "a canonical remote that cannot be read warns on a terminal" "$out" "Warning: could not read broken (above)"
has "the cutover runs" "$out" "Series v9.9-x replaced by its forward counterpart."
has "the canonical green is left behind, as not read" "$out" \
  "  v9.9-x-green in the canonical repository was neither archived nor moved, as broken could not be read;"
has "with the move it is owed once its tip is read" "$out" \
  "    git push --force-with-lease=refs/heads/v9.9-x-green:<the tip it holds> broken $NEW_GREEN:refs/heads/v9.9-x-green"
hasnt "and no lease on a tip it never read" "$out" "--force-with-lease=refs/heads/v9.9-x-green: "
hasnt "nor on the one an earlier fetch left" "$out" "--force-with-lease=refs/heads/v9.9-x-green:$OLD_GREEN broken"
has "the forward's copy there is left behind too" "$out" \
  "  Nor was the forward's copy there, v9.9-x-fwd-green, deleted, where it holds one."
has "with the deletion it is owed once its tip is read" "$out" \
  "    git push --force-with-lease=refs/heads/v9.9-x-fwd-green:<the tip it holds> broken :refs/heads/v9.9-x-fwd-green"
has "and exit 9" "$out" "EXIT=9"
is "no archive is opened in the canonical repository" "$(grep -c 'repos/test/canonical' "$GH_LOG" || true)" 0
git remote remove broken
restore
# The loop's mirror moves the canonical green while the run archives: this
# `gh` does that on the first pull request it opens.
cat > "$BIN/gh-moves" <<'GH'
#!/bin/bash
case " $* " in
  *" -X POST "*) [ -e "$MOVED" ] || { touch "$MOVED"; git -C "$CANON_DIR" update-ref refs/heads/v9.9-x-green "$MOVE_TO"; } ;;
esac
exec "$REAL_GH" "$@"
GH
chmod +x "$BIN/gh-moves"
out=$(MOVED=$SCRATCH/moved CANON_DIR=$CANON MOVE_TO=$MAIN REAL_GH=$BIN/gh SERIES_GH=$BIN/gh-moves \
  run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --upstream "$UP" --out "$OUT" </dev/null)
[ -z "${KEEP:-}" ] || echo "$out"
has "a canonical green that moved under the run is left behind" "$out" \
  "  v9.9-x-green in upstream is still on the pre-cutover lineage, which r-universe publishes; move it:"
has "named as moved" "$out" "  It is at $MAIN now, not at the $OLD_GREEN this run read and archived;"
move=(git push "--force-with-lease=refs/heads/v9.9-x-green:$MAIN" upstream "$NEW_GREEN:refs/heads/v9.9-x-green")
has "with a push leased on where it is now" "$out" "    ${move[*]}"
has "and exit 9" "$out" "EXIT=9"
out=$(run "${move[@]}")
has "that push is not refused" "$out" "EXIT=0"
is "and moves it" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"

echo
echo "=== 9. --confirm without a terminal, against remotes that refuse deletions and the canonical move"
restore
git -C "$FORK" config receive.denyDeletes true
git -C "$CANON" config receive.denyDeletes true
git -C "$CANON" config receive.denyNonFastForwards true
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$NEW_GREEN" --upstream "$UP" --out "$OUT" </dev/null)
[ -z "${KEEP:-}" ] || echo "$out"
hasnt "the coverage gate is verified against the clone" "$out" "coverage gate not verified"
hasnt "and holds" "$out" "coverage would regress"
has "the confirmation is on record, the full SHA too" "$out" \
  "Replacing series v9.9-x with v9.9-x-fwd-*, confirmed by --confirm v9.9-x@$NEW_GREEN, the tip of v9.9-x-fwd-green."
has "the archive comes first" "$out" "archived v9.9-x-dev as test/fork#101"
has "the series is replaced" "$out" "Series v9.9-x replaced by its forward counterpart."
is "-dev is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-dev | cut -f1)" "$NEW_DEV"
is "-green is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"
is "the canonical green is refused" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$OLD_GREEN"
has "the run says the swap stands, and what is left" "$out" "left behind: the swap stands, and what follows it did not happen."
has "the canonical green among it" "$out" \
  "  v9.9-x-green in upstream is still on the pre-cutover lineage, which r-universe publishes; move it:"
move=(git push "--force-with-lease=refs/heads/v9.9-x-green:$OLD_GREEN" upstream "$NEW_GREEN:refs/heads/v9.9-x-green")
has "with the leased push that moves it" "$out" "    ${move[*]}"
has "the undo still puts the fork back" "$out" "--force-with-lease=refs/heads/v9.9-x-vendor:$NEW_VENDOR origin $OLD_BUILD:refs/heads/v9.9-x-build"
hasnt "and offers none for the green it did not move" "$out" "git fetch upstream refs/pull/"
has "the litter in the fork is named" "$out" \
  "  cutover litter in origin, which loses nothing when deleted: v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base v9.9-x-fwd-vendor"
for r in build dev green build-base vendor; do
  has "with one gh api call for -fwd-$r" "$out" "    gh api -X DELETE repos/test/fork/git/refs/heads/v9.9-x-fwd-$r"
done
has "and the canonical copy" "$out" "  cutover litter in upstream, which loses nothing when deleted: v9.9-x-fwd-green"
has "with its own" "$out" "    gh api -X DELETE repos/test/canonical/git/refs/heads/v9.9-x-fwd-green"
is "the last line says so" "$(grep -v '^EXIT=' <<<"$out" | tail -n 1)" \
  "SWAPPED, LEFT BEHIND: v9.9-x is cut over; run the lines above, or hand them to a maintainer."
has "and the status is 9" "$out" "EXIT=9"
is "the litter is what the remote holds" "$(git ls-remote origin 'refs/heads/*fwd*' | wc -l)" 5
# Back to where a deletion that went through leaves both repositories, the
# canonical green moved by the line the run printed.
git -C "$FORK" config --unset receive.denyDeletes
git -C "$CANON" config --unset receive.denyDeletes
git -C "$CANON" config --unset receive.denyNonFastForwards
out=$(run "${move[@]}")
has "that line moves it" "$out" "EXIT=0"
is "to the forward's green" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"
git push -q --delete origin v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base v9.9-x-fwd-vendor
git push -q --delete upstream v9.9-x-fwd-green

echo
echo "=== 10. series-check.sh ignores cutover litter"
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
echo "=== 11. series-prune.sh lists the litter and runs nothing"
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
has "and one gh api call per ref in the fork" "$out" "gh api -X DELETE repos/test/fork/git/refs/heads/v9.9-x-fwd-rc-dev"
has "and in the canonical repository" "$out" "gh api -X DELETE repos/test/canonical/git/refs/heads/v9.9-x-fwd-green"
has "and nothing was run" "$out" "Nothing above was run."
is "the fork's refs are untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
# A live forward: its green is no ancestor of the series'.
git checkout -q --detach "$MAIN"
echo "engine ${shas[3]}" > src/duckdb/engine.cpp
desc 1.0.0.9002.1
commit "vendor: Update vendored sources to duckdb/duckdb@${shas[3]}"
git push -q -f origin HEAD:refs/heads/v9.9-x-fwd-green HEAD:refs/heads/v9.9-x-fwd-dev
git checkout -q main
out=$(run scripts/series-prune.sh v9.9-x)
has "a live forward is not litter" "$out" "is not an ancestor of v9.9-x-green: the forward is live"
has "and nothing is offered" "$out" "Nothing to prune."

echo
echo "=== 12. series-advance.sh mirrors a forward's green under a lease, a base green plainly"
# The live forward's green was reset in 11, as a rebase resets one, and the
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
echo "=== 13. a forward ref that moves while the run archives is kept, not deleted"
restore
# A commit an overlapping firing pushes onto the forward while gh runs: onto
# its green and -dev in the fork, and green's copy in the canonical repository.
git checkout -q --detach "$NEW_GREEN"
echo 'baz <- function() 4' > R/baz.R
commit 'feat: Add baz()'
LATE=$(git rev-parse HEAD)
git checkout -q main
git push -q origin "$LATE:refs/heads/tmp-late"
cat > "$BIN/gh-race" <<'GH'
#!/bin/bash
if [ ! -e "$RACED" ]; then
  touch "$RACED"
  git -C "$FORK_DIR" update-ref refs/heads/v9.9-x-fwd-green "$LATE"
  git -C "$FORK_DIR" update-ref refs/heads/v9.9-x-fwd-dev "$LATE"
  git -C "$FORK_DIR" update-ref -d refs/heads/tmp-late
  git -C "$FORK_DIR" push -q "$CANON_DIR" "$LATE:refs/heads/v9.9-x-fwd-green"
fi
exec "$REAL_GH" "$@"
GH
chmod +x "$BIN/gh-race"
out=$(RACED=$SCRATCH/raced FORK_DIR=$FORK CANON_DIR=$CANON LATE=$LATE REAL_GH=$BIN/gh SERIES_GH=$BIN/gh-race \
  run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --upstream "$UP" --out "$OUT" </dev/null)
[ -z "${KEEP:-}" ] || echo "$out"
is "the forward moved during the archive" "$([ -e "$SCRATCH/raced" ] && echo yes)" yes
has "the series is replaced" "$out" "Series v9.9-x replaced by its forward counterpart."
is "by the green the confirmation names" "$(git ls-remote origin refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"
is "the forward's green that moved is kept" "$(git ls-remote origin refs/heads/v9.9-x-fwd-green | cut -f1)" "$LATE"
is "and its -dev" "$(git ls-remote origin refs/heads/v9.9-x-fwd-dev | cut -f1)" "$LATE"
is "the rest of the forward is deleted" "$(git ls-remote origin 'refs/heads/*fwd*' | wc -l)" 2
is "the canonical copy that moved is kept" "$(git ls-remote upstream refs/heads/v9.9-x-fwd-green | cut -f1)" "$LATE"
has "the moved refs are named in the fork" "$out" \
  "  moved in origin since this run read them, so kept: each may hold commits no other ref has. Read them:"
has "each with the tip read and the tip now" "$out" "    v9.9-x-fwd-green, read at ${NEW_GREEN:0:12}, at ${LATE:0:12} now:"
has "and -dev" "$out" "    v9.9-x-fwd-dev, read at ${NEW_DEV:0:12}, at ${LATE:0:12} now:"
show="git fetch origin refs/heads/v9.9-x-fwd-green && git log --oneline $NEW_GREEN..FETCH_HEAD"
has "with the line that shows what moved" "$out" "      $show"
has "and in the canonical repository" "$out" "  moved in upstream since this run read them, so kept"
has "with what to do about them" "$out" "What v9.9-x needs of them goes onto v9.9-x-dev as a repair; then delete each by hand, never by a rerun."
hasnt "and none as litter that loses nothing" "$out" "cutover litter"
has "the run ends as left behind" "$out" "SWAPPED, LEFT BEHIND"
has "exit 9" "$out" "EXIT=9"
has "the line shows the commit that moved" "$(cd "$WORK" && bash -c "$show")" "feat: Add baz()"
is "which a ref still reaches" "$(git -C "$FORK" for-each-ref --contains "$LATE" --format='%(refname)' | tr '\n' ' ')" \
  "refs/heads/v9.9-x-fwd-dev refs/heads/v9.9-x-fwd-green "
undo=$(awk '/^undo, while nothing has moved since/ { f = 1; next } f && /^$/ { f = 0 } f && /^  git / { sub(/^  /, ""); print }' <<<"$out")
[ -z "${KEEP:-}" ] || echo "$undo"
hasnt "the undo writes no moved ref back, in the fork" "$undo" "refs/heads/v9.9-x-fwd-dev"
hasnt "nor in the canonical repository" "$undo" "refs/heads/v9.9-x-fwd-green"
has "but the forward's refs it deleted" "$undo" "$NEW_BUILD:refs/heads/v9.9-x-fwd-build"
has "and says why" "$out" "  It leaves out the forward's refs that moved since this run read them, listed below:"
has "as never deleted" "$out" "  they were never deleted, so they need no undo."
out=$(run bash -ec "$undo")
[ -z "${KEEP:-}" ] || echo "$out"
has "that undo runs" "$out" "EXIT=0"
is "-dev is the old one" "$(git ls-remote origin refs/heads/v9.9-x-dev | cut -f1)" "$OLD_DEV"
is "the canonical green too" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$OLD_GREEN"
is "the forward's -build is back" "$(git ls-remote origin refs/heads/v9.9-x-fwd-build | cut -f1)" "$NEW_BUILD"
is "the moved ones are where they moved, in the fork" \
  "$(git ls-remote origin refs/heads/v9.9-x-fwd-green refs/heads/v9.9-x-fwd-dev | cut -f1 | sort -u)" "$LATE"
is "and in the canonical repository" "$(git ls-remote upstream refs/heads/v9.9-x-fwd-green | cut -f1)" "$LATE"

echo
echo "=== 14. on a terminal, a divergence is printed, and the swap follows the confirmation"
restore
DIVERGED_DEV=$(move_to "$OLD_DEV" R/foo.R 'foo <- function() 5' v9.9-x-dev)
out=$(tty_run scripts/series-cutover.sh v9.9-x --upstream "$UP" --out "$OUT")
[ -z "${KEEP:-}" ] || echo "$out"
has "the divergence is printed" "$out" "DIVERGED: 1 path(s) the forwarding does not explain."
has "for the operator to read" "$out" "^ read these before confirming. A swap does not resolve them: it makes"
has "the confirmation is asked for after it" "$out" "Type the series name to confirm"
has "the series is replaced" "$out" "Series v9.9-x replaced by its forward counterpart."
has "the diverged -dev is archived" "$out" "archived v9.9-x-dev as test/fork#"
is "-dev is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-dev | cut -f1)" "$NEW_DEV"
is "and the diverged one is the archive's head" "$(git -C "$FORK" for-each-ref --points-at "$DIVERGED_DEV" --format='%(refname)' 'refs/pull/*/head' | wc -l | tr -d ' ')" 1
has "and the run exits 0" "$out" "EXIT=0"

echo
echo "=== 15. what an earlier fetch left of a ref deleted since is not planned on"
restore
# A strand deleted in the fork after an earlier fetch, and the forward's copy of
# green deleted in the canonical repository: both tracking refs are left here.
git update-ref refs/remotes/origin/v9.9-x-fwd-alpha "$NEW_DEV"
git -C "$CANON" update-ref -d refs/heads/v9.9-x-fwd-green
is "the canonical copy's tracking ref is left too" "$(git rev-parse refs/remotes/upstream/v9.9-x-fwd-green)" "$NEW_GREEN"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --upstream "$UP" --out "$OUT" </dev/null)
[ -z "${KEEP:-}" ] || echo "$out"
has "the fork's cleanup is what the fork holds" "$out" \
  "deleted after the swap: v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base v9.9-x-fwd-vendor on origin"
hasnt "and not the strand deleted there since" "$out" "v9.9-x-fwd-alpha"
hasnt "nor the canonical copy deleted there since" "$out" "v9.9-x-fwd-green on upstream"
has "whose green is archived against main instead" "$(cat "$GH_LOG")" "-f head=v9.9-x-green -f base=main"
undo=$(awk '/^undo, while nothing has moved since/ { f = 1; next } f && /^$/ { f = 0 } f && /^  git push / { sub(/^  /, ""); print }' <<<"$out")
is "nor written back there by the undo, which puts green back alone" "$(grep -F ' upstream ' <<<"$undo")" \
  "git push --atomic --force-with-lease=refs/heads/v9.9-x-green:$NEW_GREEN upstream $OLD_GREEN:refs/heads/v9.9-x-green"
is "both tracking refs are dropped" \
  "$(git for-each-ref --format='%(refname)' refs/remotes/origin/v9.9-x-fwd-alpha refs/remotes/upstream/v9.9-x-fwd-green)" ""
has "and the run exits 0" "$out" "EXIT=0"

echo
echo "=== 16. a canonical forward green a cycle behind the fork's is undone to where it was"
restore
LAG=$(git rev-parse "$NEW_GREEN^")
git push -q -f upstream "$LAG:refs/heads/v9.9-x-fwd-green"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --upstream "$UP" --out "$OUT" </dev/null)
[ -z "${KEEP:-}" ] || echo "$out"
has "the cutover runs" "$out" "EXIT=0"
is "and deletes the lagging copy" "$(git ls-remote upstream refs/heads/v9.9-x-fwd-green | wc -l)" 0
has "the canonical undo writes it back at the tip it had" "$out" \
  "  git push --atomic --force-with-lease=refs/heads/v9.9-x-green:$NEW_GREEN upstream $OLD_GREEN:refs/heads/v9.9-x-green $LAG:refs/heads/v9.9-x-fwd-green"
undo=$(awk '/^undo, while nothing has moved since/ { f = 1; next } f && /^$/ { f = 0 } f && /^  git / { sub(/^  /, ""); print }' <<<"$out")
out=$(run bash -ec "$undo")
[ -z "${KEEP:-}" ] || echo "$out"
has "that undo runs" "$out" "EXIT=0"
is "the canonical green is the old one" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$OLD_GREEN"
is "and the forward's copy is where it lagged" "$(git ls-remote upstream refs/heads/v9.9-x-fwd-green | cut -f1)" "$LAG"

echo
echo "=== 17. a refused deletion that cannot be read back is reported as not known, not as moved"
restore
# The fork refuses to delete the forward's green alone, as a per-ref rule does,
# deleting the rest of the push, and cannot be read after that.
cat > "$FORK/hooks/update" <<HOOK
#!/bin/bash
[ "\$3" != 0000000000000000000000000000000000000000 ] || [ "\$1" != refs/heads/v9.9-x-fwd-green ] ||
  { touch "$FORK/unreadable"; echo "deletion refused" >&2; exit 1; }
HOOK
chmod +x "$FORK/hooks/update"
cat > "$BIN/upload-pack" <<PACK
#!/bin/bash
[ ! -e "$FORK/unreadable" ] || { echo "upload-pack: refused" >&2; exit 1; }
exec git upload-pack "\$@"
PACK
chmod +x "$BIN/upload-pack"
git config remote.origin.uploadpack "$BIN/upload-pack"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --upstream "$UP" --out "$OUT" </dev/null)
[ -z "${KEEP:-}" ] || echo "$out"
has "the series is replaced" "$out" "Series v9.9-x replaced by its forward counterpart."
is "the fork could not be read afterwards" "$([ -e "$FORK/unreadable" ] && echo yes)" yes
rm -f "$FORK/hooks/update" "$FORK/unreadable"
git config --unset remote.origin.uploadpack
is "the push deleted all but the forward's green" "$(git ls-remote origin 'refs/heads/*fwd*' | cut -f2)" refs/heads/v9.9-x-fwd-green
has "every ref it named is reported as not known" "$out" \
  "  not read back from origin after a deletion was refused there, so in a state this run does not know:"
has "a deleted one among them" "$out" "    v9.9-x-fwd-dev, read at ${NEW_DEV:0:12}:"
has "each with the line that reads it" "$out" "      git ls-remote origin refs/heads/v9.9-x-fwd-dev"
has "and what each answer means" "$out" "    One gone needs nothing; one still at the tip read is cutover litter"
hasnt "none as moved" "$out" "moved in origin since this run read them"
hasnt "nor as litter" "$out" "cutover litter in origin"
is "the last line says the swap stands" "$(grep -v '^EXIT=' <<<"$out" | tail -n 1)" \
  "SWAPPED, LEFT BEHIND: v9.9-x is cut over; run the lines above, or hand them to a maintainer."
has "exit 9" "$out" "EXIT=9"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
