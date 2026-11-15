#!/bin/bash
# Check a cutover, offline, against a synthetic fork, canonical repository and clone built here:
# no network, no fixtures on disk, the stacks built by hand and their pull requests' heads written as GitHub keeps them,
# and a `gh` first on PATH that fails and records any call.
#
# The claim is that scripts/series-cutover.sh never reads from a terminal and never calls `gh`;
# that --prepare reports and moves nothing; that --confirm swaps only on the state it was decided on,
# with coverage verified, the canonical repository read, and every tip it replaces pinned by a pull request's head,
# and reports convergence, the package and the versions without refusing on them;
# that it swaps the refs atomically, moves the canonical copy of green,
# deletes what the forward leaves behind in both repositories, and prints an undo that works;
# and that it lists what a refused deletion leaves, keeping a forward ref that moved meanwhile.
# scripts/series-prune.sh offers only cutover litter, and runs nothing.
# Eighteen things are checked.
#
#   1. Without --confirm and without --prepare the cutover is a usage error, exit 2,
#      before anything is read, and names both.
#   2. A --confirm that names another series, names no SHA or one of another shape,
#      or comes with --prepare is a usage error, exit 2, and so is the --no-archive that is gone;
#      nothing is moved.
#   3. --prepare prints the coverage gate, the convergence read, the package on both sides,
#      the refs with their versions, the review stat with the engine excluded,
#      the pin of each tip or the stack to build where it has none, the cleanup plan,
#      what --confirm would refuse on and the SHA to decide on; it writes the review diff and moves nothing.
#   4. Under --confirm a forward green not at the SHA it names, or moved since --prepare, refuses;
#      so do a coverage gate it cannot verify, for want of a clone or of a vendored SHA on the old green,
#      a coverage regression, and a canonical remote that does not exist or cannot be read;
#      each before anything is moved.
#   5. A tip no pin reaches refuses the swap, naming the ref and the stack to build, and moves nothing:
#      each ref moved past its stack, the canonical green off the fork's lineage,
#      a stack branch that is no pull request's head, and one deleted since an earlier fetch,
#      under the remote's own refspec and under one that leaves the stacks out.
#      A canonical green behind the fork's is pinned through the fork's stacks, and swaps.
#   6. The cutover, with stdin closed: the refs and the vendor strand swapped to the forward's tips,
#      the canonical green moved, the forward's refs, its strands, its ledger and its canonical copy deleted,
#      the stacks left, and the pins and the undo printed.
#   7. That undo, run in a fresh clone once the stack branches are deleted,
#      puts the old lineage back in both repositories and the forward's refs beside it.
#   8. A divergence, a convergence read that stopped, a renamed package, a version kept or going back,
#      and versions not compared are printed, and the swap runs all the same.
#   9. Against remotes that refuse deletions alone, as a cloud session's git proxy does:
#      swapped and the canonical green moved, the forward's refs listed as litter,
#      and exit 9, read back correctly from a listing thousands of branches long.
#  10. The canonical copy of green: with --canonical '' there is none, and the run exits 0;
#      one that moves under the run is printed with a push leased on where it is now, which works.
#  11. Against remotes that refuse deletions, and a canonical repository that refuses to move green:
#      swapped all the same, every ref left behind listed with the one command that finishes it, and exit 9.
#  12. series-check.sh ignores what a refused deletion leaves as cutover litter.
#  13. series-prune.sh lists that litter with the commands that remove it and runs none of them,
#      a dispatch naming the pull requests whose head is the ref's tip, or a tip-checked deletion for a maintainer where none is;
#      it offers nothing of a live forward, nor of one at birth, whose green sits below its seed on a commit the series' green has,
#      which series-check.sh does not take for litter either;
#      and both take for litter what a swap taken while the forward was at birth leaves, by its `-dev`.
#  14. series-advance.sh mirrors a forward's green into the canonical repository under a lease,
#      so a rebase that reset it does not stop the firing, and a base green plainly, so a divergence there does.
#  15. A forward ref that moves while the run swaps, in the fork or in the canonical repository,
#      is kept and shown with what moved, not deleted, and the run exits 9;
#      the undo it prints leaves that ref out, and works.
#  16. A ref deleted since an earlier fetch, in the fork or the canonical repository, is neither deleted nor undone.
#  17. A canonical forward green that lags the fork's is undone to its own tip.
#  18. A refused deletion whose remote cannot be read back is reported as in a state the run does not know,
#      not as moved, with the line that reads each ref, and the run exits 9.
# Every run of the cutover has its stdin closed, and none of them calls `gh`, which the last check reads.
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
# The leased push series-prune.sh prints: <remote> <branch>..., at the tips the remote holds now.
leased() {
  local r=$1 b
  shift
  printf 'git push'
  for b in "$@"; do printf ' --force-with-lease=refs/heads/%s:%s' "$b" "$(git ls-remote "$r" "refs/heads/$b" | cut -f1)"; done
  printf ' %s' "$r"
  printf ' :refs/heads/%s' "$@"
}
# The dispatch printed for a forward's ref at its twin's tip: <slug> <branch>.
twinned() {
  printf "gh api -X POST repos/%s/actions/workflows/delete-branch.yaml/dispatches -f ref=main -f 'inputs[branch]=%s'\n" "$1" "$2"
}
# The tip-checked deletion printed for a maintainer, for a ref no pull request's head pins: <remote> <slug> <branch>,
# at the tip the remote holds now.
checked() {
  local t
  t=$(git ls-remote "$1" "refs/heads/$3" | cut -f1)
  # shellcheck disable=SC2016  # the command as it is printed
  printf 'if [ "$(gh api repos/%s/git/ref/heads/%s --jq .object.sha)" = %s ]; then gh api -X DELETE repos/%s/git/refs/heads/%s; else echo '"'"'%s is not at %s: read what moved before deleting it'"'"'; fi  # for a maintainer'"'"'s shell: no pull request'"'"'s head is at %s, so the workflow cannot pin it' \
    "$2" "$3" "$t" "$2" "$3" "$3" "${t:0:12}" "${t:0:12}"
}

# --- the fixture -----------------------------------------------------------
#
# A series `v9.9-x` seeded on an older `main`, two vendor commits deep, and its forward seeded on the current `main`,
# three deep: the forward covers the series.
# Both have a green at their tip and a buffer, and the series a vendor strand of its own lineage;
# the forward has an rc strand, a retry ledger and a vendor strand.
# The canonical repository holds `main` and both greens, as the loop's mirroring leaves them.

FORK=$SCRATCH/fork.git
CANON=$SCRATCH/canonical.git
WORK=$SCRATCH/work
BIN=$SCRATCH/bin
for r in "$FORK" "$CANON"; do git init -q --bare -b main "$r"; done

# The `gh` stand-in, first on PATH: every call appended to a log, and a failure.
mkdir -p "$BIN"
cat > "$BIN/gh" <<'EOF'
#!/bin/bash
echo "$*" >> "$GH_LOG"
echo "gh: a cutover never calls gh" >&2
exit 1
EOF
chmod +x "$BIN/gh"
export GH_LOG=$SCRATCH/gh.log
export PATH="$BIN:$PATH"
: > "$GH_LOG"

git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$FORK"
git remote add upstream "$CANON"
# The repositories the printed dispatches of the deletion workflow name.
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

# The upstream clone the coverage gate reads: four commits in a line, whose short SHAs the vendor commits below name.
UP=$SCRATCH/duckdb
git init -q -b main "$UP"
shas=()
for i in 1 2 3 4; do
  git -C "$UP" -c user.name=Test -c user.email=test@example.invalid -c commit.gpgsign=false \
    commit -q --allow-empty -m "upstream $i"
  shas+=("$(git -C "$UP" rev-parse --short=7 HEAD)")
done
# Both series carry the same glue and R code, the base one by a port of `main`, so that they converge.
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
# The series' vendor strand is a lineage of its own, as the model has it: no other ref reaches it.
git branch -f v9.9-x-vendor "$(git commit-tree -p "$OLD_MAIN" \
  -m "vendor: Update vendored sources to duckdb/duckdb@${shas[1]}" "v9.9-x-build~1^{tree}")"
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

# Every run has its stdin closed: a cutover that read a terminal would fail on it.
run() { set +e; "$@" 2>&1 <&-; echo "EXIT=$?"; set -e; }
heads() { git ls-remote --heads "$1" | sort; }

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

# The stacks, built by hand: for each strand, `cutover/v9.9-x/<strand>/1-main`, one commit on its old tip
# standing in for `main` replayed onto it, pushed to the fork,
# and the head of pull request <n> there, written as GitHub keeps one.
STRANDS=(vendor build dev green)
PULLS=(11 12 13 14)
STACK_HEADS=()
stack() { # <strand> <n> -> the stack branch's tip
  local c
  c=$(git commit-tree -p "origin/v9.9-x-$1" -m "cutover: replay main onto v9.9-x-$1" "origin/v9.9-x-$1^{tree}")
  git push -q -f origin "$c:refs/heads/cutover/v9.9-x/$1/1-main"
  git -C "$FORK" update-ref "refs/pull/$2/head" "$c"
  echo "$c"
}
# One line of the pins table, as the run prints it.
pin() { printf '  %-30s %-7s %s' "$1" "${2:0:7}" "$3"; }

# Back to the series and its forward as the fixture built them, in both repositories, and their stacks:
# what a test that moved a ref, or a cutover, undoes.
# The forward's rc strand and ledger are not put back, as the undo does not put them back.
restore() {
  local i specs=()
  for i in "${!STRANDS[@]}"; do
    specs+=("${STACK_HEADS[i]}:refs/heads/cutover/v9.9-x/${STRANDS[i]}/1-main")
    git -C "$FORK" update-ref "refs/pull/${PULLS[i]}/head" "${STACK_HEADS[i]}"
  done
  git push -q -f origin "$OLD_DEV:refs/heads/v9.9-x-dev" "$OLD_BUILD:refs/heads/v9.9-x-build" \
    "$OLD_GREEN:refs/heads/v9.9-x-green" "$OLD_BB:refs/heads/v9.9-x-build-base" \
    "$OLD_VENDOR:refs/heads/v9.9-x-vendor" "$NEW_DEV:refs/heads/v9.9-x-fwd-dev" \
    "$NEW_BUILD:refs/heads/v9.9-x-fwd-build" "$NEW_GREEN:refs/heads/v9.9-x-fwd-green" \
    "$NEW_BB:refs/heads/v9.9-x-fwd-build-base" "$NEW_VENDOR:refs/heads/v9.9-x-fwd-vendor" "${specs[@]}"
  git push -q -f upstream "$OLD_GREEN:refs/heads/v9.9-x-green" "$NEW_GREEN:refs/heads/v9.9-x-fwd-green"
  git fetch -q --prune origin
  git fetch -q --prune upstream
}
# A commit on top of <base> that writes <file> with <content>, pushed to <refs> in the fork:
# a forward or a series that moved, for a refusal to read.
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
# A post-receive hook in the fork that runs <commands> once, on the first push it receives once armed:
# the swap, which is a cutover's first push there.
arm() { # <commands>
  rm -f "$SCRATCH/fired"
  cat > "$FORK/hooks/post-receive" <<HOOK
#!/bin/bash
unset \$(git rev-parse --local-env-vars)
[ ! -e "$SCRATCH/fired" ] || exit 0
touch "$SCRATCH/fired"
$1
HOOK
  chmod +x "$FORK/hooks/post-receive"
}
disarm() { rm -f "$FORK/hooks/post-receive"; }

echo "=== 1. without --confirm and without --prepare the cutover is a usage error, and names both"
before_fork=$(heads origin); before_canon=$(heads upstream)
out=$(run scripts/series-cutover.sh v9.9-x)
has "it is a usage error" "$out" "EXIT=2"
has "naming both" "$out" "pass --prepare to report what a cutover of v9.9-x would do, or --confirm v9.9-x@<sha> to swap it"
has "and that the loop never confirms one" "$out" "it never confirms one. Nothing was read."
has "with the usage" "$out" "(--prepare | --confirm <series>@<sha>)"
out=$(run scripts/series-cutover.sh v9.9-x --remote nosuch)
has "before anything is read, a remote that is not there among it" "$out" "EXIT=2"
hasnt "which git never reads" "$out" "fatal:"
is "and moved nothing" "$(heads origin)" "$before_fork"

echo
echo "=== 2. a --confirm that does not name the series and a SHA is a usage error, and moves nothing"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-y@$SHA")
has "another series is refused" "$out" "EXIT=2"
has "naming both" "$out" "--confirm names 'v9.9-y', but the series to cut over is 'v9.9-x'; nothing was moved."
out=$(run scripts/series-cutover.sh v9.9-x --confirm '')
has "an empty one too" "$out" "EXIT=2"
out=$(run scripts/series-cutover.sh v9.9-x --confirm)
has "and a missing one" "$out" "EXIT=2"
has "with the usage" "$out" "(--prepare | --confirm <series>@<sha>)"
out=$(run scripts/series-cutover.sh v9.9-x --confirm v9.9-x)
has "the series without a SHA is refused" "$out" "EXIT=2"
has "naming what it takes" "$out" "--confirm takes v9.9-x@<sha>, the tip of v9.9-x-fwd-green that --prepare printed,"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@${NEW_GREEN:0:11}")
has "a SHA shorter than 12 digits is refused" "$out" "EXIT=2"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@${NEW_GREEN}0")
has "and one longer than 40" "$out" "EXIT=2"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@not-a-sha-at-all")
has "and one that is not hex" "$out" "EXIT=2"
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$(tr a-f A-F <<<"$SHA")")
has "and one in capitals" "$out" "EXIT=2"
out=$(run scripts/series-cutover.sh v9.9-x --prepare --confirm "v9.9-x@$SHA")
has "beside --prepare it is refused" "$out" "EXIT=2"
has "as a contradiction" "$out" "--prepare moves nothing and --confirm swaps; pass one of them."
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --no-archive)
has "--no-archive is gone, an unknown option" "$out" "EXIT=2"
is "the fork's refs are untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"

echo
echo "=== 3. --prepare reports the gates, the review, the pins and the plan, and moves nothing"
OUT=$SCRATCH/prepare
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT")
[ -z "${KEEP:-}" ] || echo "$out"
has "the run finishes" "$out" "EXIT=0"
has "old green named" "$out" "old green vendors: ${shas[1]}"
has "new green named" "$out" "new green vendors: ${shas[2]}"
has "coverage not verified without a clone" "$out" "no upstream clone given, coverage gate not verified"
has "the convergence read is printed" "$out" "=== v9.9-x"
has "the read converges" "$out" "CONVERGED"
has "the package on both sides" "$out" "package: duckdb.9.9.dev"
has "the four refs with their versions" "$out" "v9.9-x-green               ${OLD_GREEN:0:7} 1.0.0.9000.2     ->  ${NEW_GREEN:0:7} 1.0.0.9001.3"
has "the review names the glue" "$out" "src/glue.cpp"
hasnt "and not the engine" "$out" "src/duckdb/engine.cpp"
has "no tip is pinned yet: -dev names its stack to build" "$out" \
  "$(pin v9.9-x-dev "$OLD_DEV" "not yet: build the stack, scripts/series-cutover-stack.sh v9.9-x dev, and open cutover/v9.9-x/dev/1-main as a pull request in origin")"
has "-build its own" "$out" \
  "$(pin v9.9-x-build "$OLD_BUILD" "not yet: build the stack, scripts/series-cutover-stack.sh v9.9-x build,")"
has "-build-base the stack of -build, which it is on" "$out" \
  "$(pin v9.9-x-build-base "$OLD_BB" "not yet: build the stack, scripts/series-cutover-stack.sh v9.9-x build,")"
has "-green its own" "$out" \
  "$(pin v9.9-x-green "$OLD_GREEN" "not yet: build the stack, scripts/series-cutover-stack.sh v9.9-x green,")"
has "the vendor strand its own" "$out" \
  "$(pin v9.9-x-vendor "$OLD_VENDOR" "not yet: build the stack, scripts/series-cutover-stack.sh v9.9-x vendor,")"
has "and the canonical green that of green" "$out" \
  "$(pin "v9.9-x-green in upstream" "$OLD_GREEN" "not yet: build the stack, scripts/series-cutover-stack.sh v9.9-x green,")"
has "the cleanup names the forward's refs and strands" "$out" \
  "deleted after the swap: v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base v9.9-x-fwd-vendor v9.9-x-fwd-rc-dev retry-v9.9-x-fwd-dev on origin"
has "and the canonical copy" "$out" "v9.9-x-fwd-green on upstream"
has "what --confirm would refuse on is listed" "$out" "--confirm would refuse on these, as they stand:"
has "the coverage not verified among it" "$out" "  coverage: no upstream clone given"
has "and each tip no pin reaches" "$out" "  pins: v9.9-x-vendor is reachable from no pull request's head in origin"
has "the canonical green's among them" "$out" "  pins: v9.9-x-green in upstream is reachable from no pull request's head in origin"
hasnt "but not the convergence read, which is reported only" "$out" "  convergence:"
has "and says nothing happened" "$out" "Prepared; nothing was pushed or deleted. The state to decide on:"
has "the SHA to decide on, in full" "$out" "  v9.9-x-fwd-green at $NEW_GREEN"
hasnt "but no command line that confirms" "$out" "--confirm v9.9-x"
is "the review diff is written" "$([ -s "$OUT/review.diff" ] && echo yes)" yes
hasnt "without the version bookkeeping" "$(cat "$OUT/review.stat")" "DESCRIPTION"
has "with the forward's R side" "$(cat "$OUT/review.diff")" "+glue series"
is "the fork's refs are untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
# The stacks the skill builds and opens before it confirms.
for i in "${!STRANDS[@]}"; do STACK_HEADS+=("$(stack "${STRANDS[i]}" "${PULLS[i]}")"); done
git fetch -q origin
before_fork=$(heads origin)
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP")
[ -z "${KEEP:-}" ] || echo "$out"
has "with a clone and the stacks, the run finishes" "$out" "EXIT=0"
has "coverage is verified" "$out" "coverage: the forward green's ${shas[2]} covers the old green's ${shas[1]}"
has "-dev is pinned by its stack and its pull request" "$out" \
  "$(pin v9.9-x-dev "$OLD_DEV" "pinned by cutover/v9.9-x/dev/1-main, refs/pull/13/head")"
has "-build too" "$out" "$(pin v9.9-x-build "$OLD_BUILD" "pinned by cutover/v9.9-x/build/1-main, refs/pull/12/head")"
has "-build-base by the stack of -build" "$out" \
  "$(pin v9.9-x-build-base "$OLD_BB" "pinned by cutover/v9.9-x/build/1-main, refs/pull/12/head")"
has "-green by its own" "$out" "$(pin v9.9-x-green "$OLD_GREEN" "pinned by cutover/v9.9-x/green/1-main, refs/pull/14/head")"
has "the vendor strand by its own" "$out" \
  "$(pin v9.9-x-vendor "$OLD_VENDOR" "pinned by cutover/v9.9-x/vendor/1-main, refs/pull/11/head")"
has "and the canonical green through the fork's" "$out" \
  "$(pin "v9.9-x-green in upstream" "$OLD_GREEN" "pinned by cutover/v9.9-x/green/1-main, refs/pull/14/head")"
hasnt "nothing is left to pin" "$out" "not yet:"
hasnt "and --confirm would refuse on nothing" "$out" "--confirm would refuse on"
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP" --canonical '')
has "with --canonical '' there is no canonical green to pin" "$out" "EXIT=0"
hasnt "nor a canonical copy to delete" "$out" "on upstream"
hasnt "and none is listed" "$out" "v9.9-x-green in upstream"
is "the fork's refs are untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"

echo
echo "=== 4. under --confirm, another state, a gate it cannot verify or a canonical repository out of reach swaps nothing"
confirm() { run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@${1:-$SHA}" --upstream "$UP" --out "$OUT" "${@:2}"; }
# Run --confirm and check it refuses, exit 1, with <text> in its output, moving nothing in either repository.
refuses() { # <what> <text> [<sha> [<option>...]]
  local what=$1 text=$2 f c
  shift 2
  f=$(heads origin) c=$(heads upstream)
  out=$(confirm "$@")
  [ -z "${KEEP:-}" ] || echo "$out"
  has "$what" "$out" "$text"
  has "$what: the run stops" "$out" "EXIT=1"
  hasnt "$what: before the swap" "$out" "Replacing series"
  is "$what: with the fork's refs untouched" "$(heads origin)" "$f"
  is "$what: and the canonical repository's" "$(heads upstream)" "$c"
}
out=$(run scripts/series-cutover.sh v9.9-x --confirm "v9.9-x@$SHA" --out "$OUT")
[ -z "${KEEP:-}" ] || echo "$out"
has "--confirm without a clone refuses at the coverage gate" "$out" \
  "no upstream clone given, so the coverage gate cannot be verified, and --confirm"
has "naming the option" "$out" "pass --upstream <path>. Nothing was moved."
has "and the run stops" "$out" "EXIT=1"
hasnt "where --prepare only warns" "$out" "coverage gate not verified"
is "with the fork's refs untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
refuses "a SHA that is not the forward green's is refused" \
  "v9.9-x-fwd-green is at $NEW_GREEN on origin, not at the ${OLD_GREEN:0:12} that --confirm names." "${OLD_GREEN:0:12}"
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP")
decided=$(sed -n 's/^  v9.9-x-fwd-green at //p' <<<"$out")
is "--prepare names the tip to decide on" "$decided" "$NEW_GREEN"
moved=$(move_to "$NEW_GREEN" R/foo.R 'foo <- function() 3' v9.9-x-fwd-green)
refuses "a forward green that moved after --prepare is refused" \
  "v9.9-x-fwd-green is at $moved on origin, not at the $NEW_GREEN that --confirm names." "$decided"
has "with the decision sent back" "$out" "The forward moved after the state the decision was taken on"
restore
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP" --canonical nosuch)
[ -z "${KEEP:-}" ] || echo "$out"
has "a --canonical naming no remote warns on --prepare" "$out" \
  "Warning: there is no remote 'nosuch', so the canonical copy of v9.9-x-green can be neither checked nor moved."
has "and is what --confirm would refuse on" "$out" "  canonical: no remote 'nosuch'"
refuses "under --confirm it refuses" \
  "there is no remote 'nosuch', so the canonical copy of v9.9-x-green could be neither checked nor moved." "$SHA" --canonical nosuch
has "naming the way to say there is none" "$out" "or pass --canonical '' where there is no canonical repository."
# A commit on the old green that touches the engine without vendoring: one commit deep, the scan finds no vendored SHA on it.
move_to "$OLD_GREEN" src/duckdb/engine.cpp 'engine patched' v9.9-x-green v9.9-x-dev >/dev/null
out=$(BASE_SCAN_DEPTH=1 run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP")
[ -z "${KEEP:-}" ] || echo "$out"
has "an old green with no vendored SHA to read warns on --prepare" "$out" \
  "Warning: no vendored SHA could be read on v9.9-x-green, coverage gate not verified"
has "and is what --confirm would refuse on" "$out" "  coverage: no vendored SHA read on v9.9-x-green"
BASE_SCAN_DEPTH=1 refuses "under --confirm it refuses" \
  "no vendored SHA could be read on v9.9-x-green, so the coverage gate cannot be verified,"
restore
# A forward green that vendors an upstream commit older than the old green's.
git checkout -q --detach "$NEW_GREEN"
echo "engine ${shas[0]}" > src/duckdb/engine.cpp
commit "vendor: Update vendored sources to duckdb/duckdb@${shas[0]}"
REGRESS=$(git rev-parse HEAD)
git checkout -q main
git push -q -f origin "$REGRESS:refs/heads/v9.9-x-fwd-green" "$REGRESS:refs/heads/v9.9-x-fwd-dev"
git fetch -q origin
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP")
has "a coverage regression stops --prepare" "$out" "forward green does not cover old green; coverage would regress"
has "as the gate it is" "$out" "EXIT=1"
refuses "and refuses --confirm" "forward green does not cover old green; coverage would regress" "${REGRESS:0:12}"
restore
# A canonical remote that exists and cannot be read, whose tracking refs an earlier fetch left: nothing is planned on them.
git remote add broken "$SCRATCH/does-not-exist.git"
for b in main v9.9-x-green v9.9-x-fwd-green; do git update-ref "refs/remotes/broken/$b" "refs/remotes/upstream/$b"; done
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP" --canonical broken)
[ -z "${KEEP:-}" ] || echo "$out"
has "a canonical remote that cannot be read warns on --prepare" "$out" \
  "Warning: could not read broken (above), so the canonical copy of v9.9-x-green can be neither checked nor moved."
has "and is what --confirm would refuse on" "$out" "  canonical: could not read broken"
hasnt "no pin is read for the copy an earlier fetch left" "$out" "v9.9-x-green in broken"
hasnt "nor is it deleted" "$out" "v9.9-x-fwd-green on broken"
refuses "under --confirm it refuses" \
  "could not read broken (above), so the canonical copy of v9.9-x-green could be neither checked nor moved." "$SHA" --canonical broken
git remote remove broken

echo
echo "=== 5. a tip no pin reaches refuses the swap, naming the ref and the stack to build"
# Each old tip moved past the stack built on it, as a ref that moved after its stack was built reads.
for r in dev build green build-base vendor; do
  x=$r
  [ "$r" != build-base ] || x=build
  case $r in
    dev) base=$OLD_DEV ;;
    build) base=$OLD_BUILD ;;
    green) base=$OLD_GREEN ;;
    build-base) base=$OLD_BB ;;
    vendor) base=$OLD_VENDOR ;;
  esac
  past=$(move_to "$base" R/foo.R 'foo <- function() 6' "v9.9-x-$r")
  refuses "v9.9-x-$r moved past its stack is refused" \
    "  v9.9-x-$r at ${past:0:12}: cutover/v9.9-x/$x/1-main does not reach it: rebuild the stack, scripts/series-cutover-stack.sh v9.9-x $x"
  is "v9.9-x-$r: and alone" "$(grep -c '^  .* at [0-9a-f]\{12\}: ' <<<"$out")" 1
  restore
done
# The canonical green on a commit the fork does not have.
git checkout -q --detach "$OLD_GREEN"
echo 'qux <- function() 7' > R/qux.R
commit 'fix: only in the canonical repository'
CANON_ONLY=$(git rev-parse HEAD)
git checkout -q main
git push -q -f upstream "$CANON_ONLY:refs/heads/v9.9-x-green"
refuses "a canonical green off the fork's lineage is refused" \
  "  v9.9-x-green in upstream at ${CANON_ONLY:0:12}: cutover/v9.9-x/green/1-main does not reach it"
is "and alone" "$(grep -c '^  .* at [0-9a-f]\{12\}: ' <<<"$out")" 1
restore
# A stack branch whose pull request is gone, or was never opened.
git -C "$FORK" update-ref -d refs/pull/11/head
refuses "a stack branch that is no pull request's head is no pin" \
  "  v9.9-x-vendor at ${OLD_VENDOR:0:12}: cutover/v9.9-x/vendor/1-main reaches it but is no pull request's head in origin: open it as one"
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP")
has "--prepare names it as not yet pinned" "$out" \
  "$(pin v9.9-x-vendor "$OLD_VENDOR" "not yet: cutover/v9.9-x/vendor/1-main reaches it but is no pull request's head in origin")"
restore
# A stack branch deleted since an earlier fetch, whose pull request's head is still there, as GitHub keeps it.
git -C "$FORK" update-ref -d refs/heads/cutover/v9.9-x/build/1-main
is "the tracking ref an earlier fetch left is here" \
  "$(git rev-parse refs/remotes/origin/cutover/v9.9-x/build/1-main)" "$(git -C "$FORK" rev-parse refs/pull/12/head)"
refuses "a stack branch deleted since an earlier fetch is no pin" \
  "  v9.9-x-build at ${OLD_BUILD:0:12}: build the stack, scripts/series-cutover-stack.sh v9.9-x build, and open cutover/v9.9-x/build/1-main as a pull request in origin"
is "and its tracking ref is dropped" "$(git for-each-ref refs/remotes/origin/cutover/v9.9-x/build/)" ""
restore
# The same under a refspec that leaves the stacks out, where only the run's own fetch of them can drop the tracking ref.
git config --replace-all remote.origin.fetch '+refs/heads/main:refs/remotes/origin/main'
git config --add remote.origin.fetch '+refs/heads/v9.9-x*:refs/remotes/origin/v9.9-x*'
git -C "$FORK" update-ref -d refs/heads/cutover/v9.9-x/build/1-main
is "the tracking ref an earlier fetch left is here too" \
  "$(git rev-parse refs/remotes/origin/cutover/v9.9-x/build/1-main)" "$(git -C "$FORK" rev-parse refs/pull/12/head)"
refuses "under a refspec that leaves the stacks out, it is no pin either" \
  "  v9.9-x-build at ${OLD_BUILD:0:12}: build the stack, scripts/series-cutover-stack.sh v9.9-x build, and open cutover/v9.9-x/build/1-main as a pull request in origin"
is "and its tracking ref is dropped there too" "$(git for-each-ref refs/remotes/origin/cutover/v9.9-x/build/)" ""
git config --replace-all remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
restore
# A canonical green a cycle behind the fork's: no stack starts from it, and the fork's green stack reaches it.
LAGC=$(git rev-parse "$OLD_GREEN^")
git push -q -f upstream "$LAGC:refs/heads/v9.9-x-green"
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "a canonical green behind the fork's is pinned through the fork's stacks" "$out" \
  "$(pin "v9.9-x-green in upstream" "$LAGC" "pinned by cutover/v9.9-x/green/1-main, refs/pull/14/head")"
has "and the swap runs" "$out" "EXIT=0"
is "the canonical green is the forward's" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"
has "and its undo puts back the tip it held" "$out" \
  "  git push --atomic --force-with-lease=refs/heads/v9.9-x-green:$NEW_GREEN upstream $LAGC:refs/heads/v9.9-x-green"
restore

echo
echo "=== 6. the cutover: swap, mirror, delete, with stdin closed and gh failing"
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "the run finishes" "$out" "EXIT=0"
has "the confirmation is on record" "$out" \
  "Replacing series v9.9-x with v9.9-x-fwd-*, confirmed by --confirm v9.9-x@$SHA, the tip of v9.9-x-fwd-green."
has "the series is replaced" "$out" "Series v9.9-x replaced by its forward counterpart."
hasnt "no confirmation is asked for" "$out" "Type the series name"
has "the pins are printed before the swap" "$out" \
  "$(pin v9.9-x-dev "$OLD_DEV" "pinned by cutover/v9.9-x/dev/1-main, refs/pull/13/head")"
has "the canonical green moved" "$out" "canonical v9.9-x-green -> ${NEW_GREEN:0:7}"
has "the strands are to be re-cut" "$out" "scripts/series-rc.sh v9.9-x --push"
has "the fork's universe entry is named" "$out" "The fork's universe still names v9.9-x-fwd-green"
is "-dev is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-dev | cut -f1)" "$NEW_DEV"
is "-build is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-build | cut -f1)" "$NEW_BUILD"
is "-green is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"
is "-build-base is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-build-base | cut -f1)" "$NEW_BB"
is "-vendor is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-vendor | cut -f1)" "$NEW_VENDOR"
is "the forward's refs, its vendor strand, its rc strand and its ledger are gone" "$(git ls-remote origin 'refs/heads/*fwd*' | wc -l)" 0
is "the canonical green is the forward's" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"
is "and the canonical copy of the forward's green is gone" "$(git ls-remote upstream refs/heads/v9.9-x-fwd-green | wc -l)" 0
is "the stack branches stay, for the skill to close" "$(git ls-remote origin 'refs/heads/cutover/*' | wc -l)" 4
has "the undo fetches the pinning pull requests' heads, each once" "$out" \
  "  git fetch origin refs/pull/12/head refs/pull/13/head refs/pull/14/head refs/pull/11/head"
has "with one atomic push in the canonical repository" "$out" \
  "  git push --atomic --force-with-lease=refs/heads/v9.9-x-green:$NEW_GREEN upstream $OLD_GREEN:refs/heads/v9.9-x-green $NEW_GREEN:refs/heads/v9.9-x-fwd-green"
has "and leases the fork's refs on the forward's tips" "$out" "--force-with-lease=refs/heads/v9.9-x-green:$NEW_GREEN"
hasnt "nothing is left behind" "$out" "SWAPPED, LEFT BEHIND"
is "and gh was not called" "$(wc -l < "$GH_LOG")" 0

echo
echo "=== 7. the undo the cutover printed puts the old lineage back, from a fresh clone, once the stacks are deleted"
undo=$(awk '/^undo, while nothing has moved since/ { f = 1; next } f && /^$/ { f = 0 } f && /^  git / { sub(/^  /, ""); print }' <<<"$out")
[ -z "${KEEP:-}" ] || echo "$undo"
is "a fetch, and a push for each repository" "$(grep -c . <<<"$undo")" 3
# As the skill leaves the fork: the stack branches deleted, their pull requests' heads kept.
git push -q origin --delete cutover/v9.9-x/{vendor,build,dev,green}/1-main
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
echo "=== 8. what --confirm reports and never enforces: each finding is printed, and the swap runs"
restore
swapped() { # <what>: the run swapped and finished; then back to the fixture
  has "$1: the series is replaced" "$out" "Series v9.9-x replaced by its forward counterpart."
  is "$1: -green is the forward's" "$(git ls-remote origin refs/heads/v9.9-x-green | cut -f1)" "$2"
  has "$1: and the run exits 0" "$out" "EXIT=0"
  restore
}
# A fix on the series' -dev that the forward does not carry, its stack rebuilt on it.
DIVERGED_DEV=$(move_to "$OLD_DEV" R/foo.R 'foo <- function() 5' v9.9-x-dev)
stack dev 13 >/dev/null
out=$(run scripts/series-cutover.sh v9.9-x --prepare --out "$OUT" --upstream "$UP")
has "a divergence is printed by --prepare" "$out" "DIVERGED: 1 path(s) the forwarding does not explain."
hasnt "and is not what --confirm refuses on" "$out" "--confirm would refuse on"
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "a divergence is printed" "$out" "DIVERGED: 1 path(s) the forwarding does not explain."
has "as reported, not enforced" "$out" "^ reported, not enforced: the review explains each, or the forward is repaired where it differs."
has "the diverged -dev is pinned by its rebuilt stack" "$out" \
  "$(pin v9.9-x-dev "$DIVERGED_DEV" "pinned by cutover/v9.9-x/dev/1-main, refs/pull/13/head")"
is "which a pull request's head still reaches" \
  "$(git -C "$FORK" for-each-ref --contains "$DIVERGED_DEV" --format='%(refname)' 'refs/pull/*/head')" refs/pull/13/head
swapped "a divergence" "$NEW_GREEN"
move_to "$NEW_DEV" DESCRIPTION "$(printf 'Package: duckdb.other\nVersion: 1.0.0.9001.4')" v9.9-x-fwd-dev >/dev/null
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "a renamed package is printed" "$out" "package: duckdb.9.9.dev -> duckdb.other"
has "as reported, not enforced" "$out" "and the swap would publish a different package. Reported, not enforced."
swapped "a renamed package" "$NEW_GREEN"
kept=$(move_to "$NEW_GREEN" DESCRIPTION "$(printf 'Package: duckdb.9.9.dev\nVersion: 1.0.0.9000.2')" v9.9-x-fwd-dev v9.9-x-fwd-green)
out=$(confirm "$kept")
[ -z "${KEEP:-}" ] || echo "$out"
has "a version kept is printed, for -dev" "$out" "Warning: v9.9-x-dev keeps version 1.0.0.9000.2 across the swap."
has "and for -green" "$out" "Warning: v9.9-x-green keeps version 1.0.0.9000.2 across the swap."
swapped "a version kept" "$kept"
back=$(move_to "$NEW_GREEN" DESCRIPTION "$(printf 'Package: duckdb.9.9.dev\nVersion: 1.0.0.9000.1')" v9.9-x-fwd-dev v9.9-x-fwd-green)
out=$(confirm "$back")
[ -z "${KEEP:-}" ] || echo "$out"
has "a version going back is printed" "$out" "Warning: v9.9-x-green would go from 1.0.0.9000.2 back to 1.0.0.9000.1."
has "with what it costs" "$out" "r-universe publishes from this ref and has no upgrade to offer"
swapped "a version going back" "$back"
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
swapped "versions not compared" "$NEW_GREEN"
# The convergence read that stops for another reason than a divergence.
printf '#!/bin/bash\necho "converge: could not read the store" >&2\nexit 3\n' > scripts/series-converge.sh
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "a convergence read that stopped is printed" "$out" "the convergence read stopped with status 3 although v9.9-x-dev exists;"
has "as reported, not enforced" "$out" "    reported, not enforced: read why above."
swapped "a convergence read that stopped" "$NEW_GREEN"
cp "$HERE/series-converge.sh" scripts/series-converge.sh

echo
echo "=== 9. --confirm against remotes that refuse deletions alone"
git -C "$FORK" config receive.denyDeletes true
git -C "$CANON" config receive.denyDeletes true
# Enough branches after the forward's, in the listing the run reads back,
# that a reader stopping at the first match would end the one before it by SIGPIPE.
for i in $(seq -w 1 4000); do echo "create refs/heads/zz-pad-$i $MAIN"; done | git -C "$FORK" update-ref --stdin
out=$(confirm)
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
  "SWAPPED, LEFT BEHIND: v9.9-x is cut over; dispatch the workflow lines above, and hand the rest to a maintainer."
has "and a refused deletion alone is exit 9" "$out" "EXIT=9"
git -C "$FORK" config --unset receive.denyDeletes
git -C "$CANON" config --unset receive.denyDeletes
git -C "$FORK" for-each-ref --format='delete %(refname)' 'refs/heads/zz-pad-*' | git -C "$FORK" update-ref --stdin

echo
echo "=== 10. the canonical copy of green: none, or moved under the run"
restore
out=$(confirm "$SHA" --canonical '')
[ -z "${KEEP:-}" ] || echo "$out"
has "with --canonical '' the cutover runs" "$out" "Series v9.9-x replaced by its forward counterpart."
hasnt "with nothing left behind" "$out" "SWAPPED, LEFT BEHIND"
has "and exits 0" "$out" "EXIT=0"
is "and the canonical green is untouched" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$OLD_GREEN"
restore
# The loop's mirror moves the canonical green while the run swaps: the fork's hook does that on the swap.
arm "git -C $(printf %q "$CANON") update-ref refs/heads/v9.9-x-green $MAIN"
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
disarm
is "the canonical green moved during the swap" "$([ -e "$SCRATCH/fired" ] && echo yes)" yes
has "a canonical green that moved under the run is left behind" "$out" \
  "  v9.9-x-green in upstream is still on the pre-cutover lineage, which r-universe publishes; move it:"
has "named as moved" "$out" "  It is at $MAIN now, not at the $OLD_GREEN this run read;"
move=(git push "--force-with-lease=refs/heads/v9.9-x-green:$MAIN" upstream "$NEW_GREEN:refs/heads/v9.9-x-green")
has "with a push leased on where it is now" "$out" "    ${move[*]}"
has "and exit 9" "$out" "EXIT=9"
out=$(run "${move[@]}")
has "that push is not refused" "$out" "EXIT=0"
is "and moves it" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"

echo
echo "=== 11. --confirm against remotes that refuse deletions and the canonical move"
restore
git -C "$FORK" config receive.denyDeletes true
git -C "$CANON" config receive.denyDeletes true
git -C "$CANON" config receive.denyNonFastForwards true
out=$(confirm "$NEW_GREEN")
[ -z "${KEEP:-}" ] || echo "$out"
hasnt "the coverage gate is verified against the clone" "$out" "coverage gate not verified"
hasnt "and holds" "$out" "coverage would regress"
has "the confirmation is on record, the full SHA too" "$out" \
  "Replacing series v9.9-x with v9.9-x-fwd-*, confirmed by --confirm v9.9-x@$NEW_GREEN, the tip of v9.9-x-fwd-green."
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
hasnt "and offers none for the green it did not move" "$out" "upstream $OLD_GREEN:refs/heads/v9.9-x-green"
has "the litter in the fork is named" "$out" \
  "  cutover litter in origin, which loses nothing when deleted: v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base v9.9-x-fwd-vendor"
for r in build dev green build-base vendor; do
  has "with one dispatch for -fwd-$r, for a session, as its twin v9.9-x-$r is at its tip" "$out" "    $(twinned test/fork "v9.9-x-fwd-$r")"
done
has "and the canonical copy" "$out" "  cutover litter in upstream, which loses nothing when deleted: v9.9-x-fwd-green"
has "with a tip-checked one for a maintainer, as the canonical green was not moved to its tip" "$out" "    $(checked upstream test/canonical v9.9-x-fwd-green)"
is "the last line says so" "$(grep -v '^EXIT=' <<<"$out" | tail -n 1)" \
  "SWAPPED, LEFT BEHIND: v9.9-x is cut over; dispatch the workflow lines above, and hand the rest to a maintainer."
has "and the status is 9" "$out" "EXIT=9"
is "the litter is what the remote holds" "$(git ls-remote origin 'refs/heads/*fwd*' | wc -l)" 5
# Back to where a deletion that went through leaves both repositories, the canonical green moved by the line the run printed,
# and the stack branches deleted, as the skill deletes them.
git -C "$FORK" config --unset receive.denyDeletes
git -C "$CANON" config --unset receive.denyDeletes
git -C "$CANON" config --unset receive.denyNonFastForwards
out=$(run "${move[@]}")
has "that line moves it" "$out" "EXIT=0"
is "to the forward's green" "$(git ls-remote upstream refs/heads/v9.9-x-green | cut -f1)" "$NEW_GREEN"
git push -q --delete origin v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base v9.9-x-fwd-vendor \
  cutover/v9.9-x/{vendor,build,dev,green}/1-main
git push -q --delete upstream v9.9-x-fwd-green

echo
echo "=== 12. series-check.sh ignores cutover litter"
# A refused deletion leaves the forward's refs at the series' tips; and an older cutover left its rc strand behind.
git push -q origin "$NEW_GREEN:refs/heads/v9.9-x-fwd-green" "$NEW_DEV:refs/heads/v9.9-x-fwd-dev" \
  "$NEW_BUILD:refs/heads/v9.9-x-fwd-build" "$NEW_DEV:refs/heads/v9.9-x-fwd-rc-dev" "$NEW_BUILD~1:refs/heads/v9.9-x-fwd-vendor"
git push -q upstream "$NEW_GREEN:refs/heads/v9.9-x-fwd-green"
git fetch -q --prune origin
out=$(run scripts/series-check.sh --canonical '')
[ -z "${KEEP:-}" ] || echo "$out"
has "the forward is litter" "$out" "v9.9-x-fwd: cutover litter, ignoring: its green is an ancestor of v9.9-x's"
has "and the series gets a verdict" "$out" "=== v9.9-x:"

echo
echo "=== 13. series-prune.sh lists the litter and runs nothing"
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
has "the deletion in the fork, leased on every tip read" "$out" "$(leased origin v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-vendor v9.9-x-fwd-rc-dev)"
has "and in the canonical repository" "$out" "$(leased upstream v9.9-x-fwd-green)"
has "and one line per ref in the fork" "$out" "$(checked origin test/fork v9.9-x-fwd-rc-dev)"
has "and in the canonical repository, whose green the swap moved there" "$out" "$(twinned test/canonical v9.9-x-fwd-green)"
has "a ref no pull request's head is at is for a maintainer's shell, and says why" "$out" \
  "# for a maintainer's shell: no pull request's head is at ${NEW_DEV:0:12}, so the workflow cannot pin it"
has "and nothing was run" "$out" "Nothing above was run."
# A pull request whose head is the tip of a ref is named in its dispatch, the lowest-numbered of them.
git -C "$FORK" update-ref refs/pull/98/head "$NEW_DEV"
git -C "$FORK" update-ref refs/pull/99/head "$NEW_DEV"
out=$(run scripts/series-prune.sh v9.9-x)
has "a ref at pull requests' heads is a dispatch naming the lowest, listing them all" "$out" \
  "gh api -X POST repos/test/fork/actions/workflows/delete-branch.yaml/dispatches -f ref=main -f 'inputs[branch]=v9.9-x-fwd-rc-dev' -f 'inputs[pr]=98'  # pull requests whose head is this tip: 98 99; name a closed one"
git -C "$FORK" update-ref -d refs/pull/98/head
git -C "$FORK" update-ref -d refs/pull/99/head
is "the fork's refs are untouched" "$(heads origin)" "$before_fork"
is "and the canonical repository's" "$(heads upstream)" "$before_canon"
# A forward at birth, seeded on the commit the series now stands on: its green sits there, below its seed,
# where the series' green has it too.
git checkout -q --detach "$MAIN"
desc 1.0.0.9003.0
commit 'chore: Add fifth version component'
git push -q -f origin "$MAIN:refs/heads/v9.9-x-fwd-green" HEAD:refs/heads/v9.9-x-fwd-dev
BIRTH=$(git rev-parse HEAD)
git checkout -q main
out=$(run scripts/series-prune.sh v9.9-x)
[ -z "${KEEP:-}" ] || echo "$out"
has "a forward's green below its seed tells nothing" "$out" \
  "v9.9-x-fwd-green ${MAIN:0:7} sits below the seed of v9.9-x-fwd-dev, as at the forward's birth, which tells nothing"
has "so its -dev is read, and the forward is live" "$out" "v9.9-x-fwd-dev is not an ancestor of v9.9-x-dev: the forward is live"
has "and nothing of it is offered" "$out" "Nothing to prune."
git fetch -q --prune origin
out=$(run scripts/series-check.sh --canonical '')
[ -z "${KEEP:-}" ] || echo "$out"
hasnt "nor does series-check.sh take it for litter" "$out" "v9.9-x-fwd: cutover litter"
has "but serves it" "$out" "=== v9.9-x-fwd:"
# A swap taken while the forward was at birth: the series' refs at the forward's tips, the forward's refs left behind.
was=()
for r in v9.9-x-green v9.9-x-dev v9.9-x-build v9.9-x-fwd-build; do was+=("$(git rev-parse "origin/$r"):refs/heads/$r"); done
git push -q -f origin "$MAIN:refs/heads/v9.9-x-green" "$BIRTH:refs/heads/v9.9-x-dev" "$BIRTH:refs/heads/v9.9-x-fwd-build" \
  "$BIRTH:refs/heads/v9.9-x-build"
out=$(run scripts/series-prune.sh v9.9-x)
[ -z "${KEEP:-}" ] || echo "$out"
has "its green below its seed tells nothing" "$out" \
  "v9.9-x-fwd-green ${MAIN:0:7} sits below the seed of v9.9-x-fwd-dev, as at the forward's birth, which tells nothing"
has "so its -dev is read, and the forward was swapped in" "$out" "v9.9-x-fwd-dev is an ancestor of v9.9-x-dev: the forward was swapped in"
has "and it is offered as litter" "$out" "git push --force-with-lease=refs/heads/v9.9-x-fwd-build:$BIRTH --force-with-lease=refs/heads/v9.9-x-fwd-dev:$BIRTH"
git fetch -q --prune origin
out=$(run scripts/series-check.sh --canonical '')
[ -z "${KEEP:-}" ] || echo "$out"
has "series-check.sh reads it the same, and ignores it" "$out" \
  "v9.9-x-fwd: cutover litter, ignoring: its green sits below its seed, and its -dev is an ancestor of v9.9-x's"
hasnt "rather than serving it" "$out" "=== v9.9-x-fwd:"
has "while the series gets a verdict" "$out" "=== v9.9-x:"
git push -q -f origin "${was[@]}"
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
echo "=== 14. series-advance.sh mirrors a forward's green under a lease, a base green plainly"
# The live forward's green was reset in 13, as a rebase resets one, and the canonical copy still holds the pre-reset green.
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
echo "=== 15. a forward ref that moves while the run swaps is kept, not deleted"
restore
# A commit an overlapping firing pushes onto the forward during the swap:
# onto its green and -dev in the fork, and green's copy in the canonical repository.
git checkout -q --detach "$NEW_GREEN"
echo 'baz <- function() 4' > R/baz.R
commit 'feat: Add baz()'
LATE=$(git rev-parse HEAD)
git checkout -q main
git push -q origin "$LATE:refs/heads/tmp-late"
arm "git -C $(printf %q "$FORK") update-ref refs/heads/v9.9-x-fwd-green $LATE
git -C $(printf %q "$FORK") update-ref refs/heads/v9.9-x-fwd-dev $LATE
git -C $(printf %q "$FORK") update-ref -d refs/heads/tmp-late
git -C $(printf %q "$FORK") push -q $(printf %q "$CANON") $LATE:refs/heads/v9.9-x-fwd-green"
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
disarm
is "the forward moved during the swap" "$([ -e "$SCRATCH/fired" ] && echo yes)" yes
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
echo "=== 16. what an earlier fetch left of a ref deleted since is not planned on"
restore
# A strand deleted in the fork after an earlier fetch, and the forward's copy of green deleted in the canonical repository:
# both tracking refs are left here.
git update-ref refs/remotes/origin/v9.9-x-fwd-alpha "$NEW_DEV"
git -C "$CANON" update-ref -d refs/heads/v9.9-x-fwd-green
is "the canonical copy's tracking ref is left too" "$(git rev-parse refs/remotes/upstream/v9.9-x-fwd-green)" "$NEW_GREEN"
out=$(confirm)
[ -z "${KEEP:-}" ] || echo "$out"
has "the fork's cleanup is what the fork holds" "$out" \
  "deleted after the swap: v9.9-x-fwd-build v9.9-x-fwd-dev v9.9-x-fwd-green v9.9-x-fwd-build-base v9.9-x-fwd-vendor on origin"
hasnt "and not the strand deleted there since" "$out" "v9.9-x-fwd-alpha"
hasnt "nor the canonical copy deleted there since" "$out" "v9.9-x-fwd-green on upstream"
undo=$(awk '/^undo, while nothing has moved since/ { f = 1; next } f && /^$/ { f = 0 } f && /^  git push / { sub(/^  /, ""); print }' <<<"$out")
is "nor written back there by the undo, which puts green back alone" "$(grep -F ' upstream ' <<<"$undo")" \
  "git push --atomic --force-with-lease=refs/heads/v9.9-x-green:$NEW_GREEN upstream $OLD_GREEN:refs/heads/v9.9-x-green"
is "both tracking refs are dropped" \
  "$(git for-each-ref --format='%(refname)' refs/remotes/origin/v9.9-x-fwd-alpha refs/remotes/upstream/v9.9-x-fwd-green)" ""
has "and the run exits 0" "$out" "EXIT=0"

echo
echo "=== 17. a canonical forward green a cycle behind the fork's is undone to where it was"
restore
LAG=$(git rev-parse "$NEW_GREEN^")
git push -q -f upstream "$LAG:refs/heads/v9.9-x-fwd-green"
out=$(confirm)
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
echo "=== 18. a refused deletion that cannot be read back is reported as not known, not as moved"
restore
# The fork refuses to delete the forward's green alone, as a per-ref rule does, deleting the rest of the push,
# and cannot be read after that.
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
out=$(confirm)
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
  "SWAPPED, LEFT BEHIND: v9.9-x is cut over; dispatch the workflow lines above, and hand the rest to a maintainer."
has "exit 9" "$out" "EXIT=9"

echo
is "no run called gh" "$(cat "$GH_LOG")" ""

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
