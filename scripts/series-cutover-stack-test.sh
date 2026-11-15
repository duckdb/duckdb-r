#!/bin/bash
# shellcheck disable=SC2016  # Markdown backticks in the expected output, not commands
# Check scripts/series-cutover-stack.sh offline, against a synthetic fork and upstream clone built here:
# no network, no fixtures on disk, a `gh` first on PATH that fails, and every run with stdin closed and no controlling terminal.
#
# The claim is that the script builds the review stack of a strand as its header says,
# pushes it leased and atomically, stops on a conflict and resumes, and writes the same SHAs from the same inputs.
# Ten things are checked.
#
#   1. The commit-by-commit replay onto the vendor strand: each first-parent commit of `main` picked with `-x`,
#      a merge against its first parent, its author and dates kept, a version bump through the DESCRIPTION merge driver;
#      a vendor commit picked without its engine paths and DESCRIPTION, its patch change kept, or recorded as vendoring only;
#      a commit that patches the engine picked without a conflict and without its engine paths;
#      then `2-engine` with the forward's engine, the engine part of that commit included, and the patch stack of `1-main`,
#      its summary naming that commit; `3-fwd` empty, `4-old` the old tree; the old tip under `1-main`;
#      the summary, the --summary file and the pull requests to open.
#      A commit of `main` that changes the engine alone is left out of `1-main`, and the `2-engine` summary names it.
#   2. A conflict on `-dev` stops the build with the worktree kept and nothing pushed;
#      a plain rerun refuses beside it, --abort from the kept worktree discards it,
#      and a resolution finishes with --continue. A commit the strand already carries is recorded as present.
#   3. `-green`, whose two tips vendor the same upstream commit, has a `2-engine` all the same,
#      as their engines differ by the patch `main` added, and rerere resolves the conflict `-dev` resolved, unattended.
#   4. A rebuild mints the same SHAs, in this clone and in another one with another identity and time zone.
#   5. A rebuild over existing branches moves them under their leases;
#      a branch that moved since the build read it refuses the whole push and removes the --summary file,
#      and the next rebuild moves it back.
#      A fork that refuses the push leaves a --summary that is a link, or no regular file, as it is, and the run says so.
#   6. Once the engines agree, `2-engine` leaves the stack, and its branch stays:
#      the run exits 9 with the steps that retire it, and once they are taken a rebuild exits 0.
#      Both deletions it prints refuse a branch that moved and delete one at the tip read:
#      the git one by its lease, the `gh api` one by checking the tip first.
#   7. Where the old base is not an ancestor of the forward's, `1-main` is one three-way merge,
#      which keeps the old engine and takes `main`'s patch stack, and a conflict there stops and resumes the same way;
#      the `2-engine` summary says it carries the engine side of the changes that merge leaves out.
#   8. Usage errors exit 2; a missing forward, a series on its forward's lineage as after the swap,
#      read on `-dev` by the forward's seed, whatever was folded above it since,
#      and a summary file that cannot be written refuse with 1 and push nothing.
#      A forward at birth, whose green sits below its seed on a commit the series' green has, builds its green stack.
#      A forward with no seed is read by ancestry, either way: one on the series' lineage refuses, one apart builds.
#   9. Nothing called `gh`.
#  10. Nothing read a terminal: the wrapper every run went through gives neither stdin nor a controlling terminal,
#      and no build or worktree is left behind.
#
# Usage:
#   scripts/series-cutover-stack-test.sh
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
holds() { # <what> <command...>: ok when the command succeeds
  local what=$1
  shift
  if "$@"; then ok "$what"; else no "$what"; fi
}

# --- the fixture -----------------------------------------------------------
#
# `main` moves from OLD_MAIN to FWD_MAIN by a feature, a merge, a vendor commit that also adapts the glue and rebases a patch,
# a commit that adds a patch and applies it to the engine, a vendor commit that only stamps its counter,
# a version bump, and a fix to `R/foo.R`.
# The series `v9.9-x` stands on OLD_MAIN: its vendor strand and buffer vendor u1 and u2,
# and its `-dev` carries a port of the feature and a fix to the same line of `R/foo.R`, folded into its u2 commit.
# Its forward stands on FWD_MAIN and vendors u1 to u3, its green at u2.
# `v8.8-y` is the same on a `main` whose history was replaced, so its base is no ancestor of FWD_MAIN.
# `v5.5-v` stands on FWD_MAIN, and its forward on HOTFIX, one commit past it that changes the engine alone.

FORK=$SCRATCH/fork.git
WORK=$SCRATCH/work
BIN=$SCRATCH/bin
UP=$SCRATCH/duckdb
git init -q --bare -b main "$FORK"

# A `gh` that fails, first on PATH, and logs every call.
mkdir -p "$BIN"
cat > "$BIN/gh" <<'EOF'
#!/bin/bash
echo "$*" >> "$GH_LOG"
exit 1
EOF
chmod +x "$BIN/gh"
export GH_LOG=$SCRATCH/gh.log
: > "$GH_LOG"
export PATH="$BIN:$PATH"

git init -q -b main "$UP"
u=()
for i in 0 1 2 3 4; do
  git -C "$UP" -c user.name=Test -c user.email=test@example.invalid -c commit.gpgsign=false \
    commit -q --allow-empty -m "upstream $i"
  u+=("$(git -C "$UP" rev-parse --short=10 HEAD)")
done

git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$FORK"
git config remote.origin.github test/fork
t=1700000000
tick() { t=$((t + 60)); export GIT_AUTHOR_DATE="$t +0000" GIT_COMMITTER_DATE="$t +0000"; }
tick

mkdir -p scripts R src/duckdb/src/function/table/version patch
for s in series-cutover-stack.sh series-lib.sh series-config.sh setup-git.sh merge-version.sh; do
  cp "$HERE/$s" scripts/
done
chmod +x scripts/*.sh
echo 'DESCRIPTION merge=ours-version' > .gitattributes
printf 'Package: duckdb\nVersion: 1.0.0.9000\n' > DESCRIPTION
printf 'foo <- function() {\n  "two"\n}\n' > R/foo.R
echo 'glue' > src/glue.cpp
echo 'patch one' > patch/0001-one.patch
engine() { # <upstream sha>: the vendored files, as a vendor commit writes them, the patch stack applied
  echo "engine $1" > src/duckdb/engine.cpp
  printf '#define DUCKDB_SOURCE_ID "%s"\n' "$1" > src/duckdb/src/function/table/version/pragma_version.cpp
  echo "duckdb_version <- \"$1\"" > R/version.R
  echo "upstream $1" > src/duckdb/patched.cpp
  [ ! -f patch/0002-two.patch ] || echo '// patched' >> src/duckdb/patched.cpp
}
engine "${u[0]}"
git add -A
git commit -qm 'vendor: Update vendored sources to duckdb/duckdb@'"${u[0]}"
OLD_MAIN=$(git rev-parse HEAD)

tick
echo 'bar <- function() 2' > R/bar.R
git add -A
git commit -qm 'feat: Add bar()'
FEAT=$(git rev-parse HEAD)
git checkout -q -b side
tick
echo 'baz <- function() 3' > R/baz.R
git add -A
git commit -qm 'feat: Add baz()'
git checkout -q main
tick
git merge -q --no-ff side -m 'Merge pull request #1 from side'
MERGE=$(git rev-parse HEAD)
tick
engine "${u[1]}"
echo 'glue (adapted)' > src/glue.cpp
echo 'patch one (rebased)' > patch/0001-one.patch
sed -i 's/^Version: .*/Version: 1.0.0.9000.1/' DESCRIPTION
git add -A
git commit -qm "vendor: Update vendored sources to duckdb/duckdb@${u[1]}"
V1=$(git rev-parse HEAD)
tick
echo 'patch two' > patch/0002-two.patch
echo '// patched' >> src/duckdb/patched.cpp
git add -A
git commit -qm 'fix(patch): Patch the engine'
PATCH=$(git rev-parse HEAD)
tick
engine "${u[2]}"
sed -i 's/^Version: .*/Version: 1.0.0.9000.2/' DESCRIPTION
git add -A
git commit -qm "vendor: Update vendored sources to duckdb/duckdb@${u[2]}"
V2=$(git rev-parse HEAD)
tick
sed -i 's/^Version: .*/Version: 1.0.0.9001/' DESCRIPTION
git commit -qam 'chore: Bump version to 1.0.0.9001'
tick
sed -i 's/"two"/"two (main)"/' R/foo.R
git commit -qam 'fix: foo() says two, as main has it'
FIX=$(git rev-parse HEAD)
FWD_MAIN=$FIX

vend() { # <upstream sha> [<counter>]: one vendor commit here
  tick
  engine "$1"
  [ -z "${2:-}" ] || sed -i -E "s/^(Version: [0-9]+[.][0-9]+[.][0-9]+[.][0-9]+).*/\1.$2/" DESCRIPTION
  git add -A
  git commit -qm "vendor: Update vendored sources to duckdb/duckdb@$1"
}
seed() { # <base> <flavor>: the two flavor commits and the seed on <base>
  git checkout -q --detach "$1"
  tick
  echo "flavor $2" > flavor.txt
  git add -A
  git commit -qm "chore: Update flavor patch to $2"
  sed -i "s/^Package: .*/Package: $2/" DESCRIPTION
  git commit -qam "chore: Update version to $2"
  sed -i 's/^Version: \(.*\)$/Version: \1.0/' DESCRIPTION
  git commit -qam 'chore: Add fifth version component'
}
# A series: <name> <base> <flavor> <foo fix folded into its u2 on -dev> <newest
# upstream index> <port the feature onto -dev?> <green: dev or dev~1>.
series() {
  local s=$1 base=$2 flavor=$3 fix=$4 top=$5 port=$6 green=$7 sd i
  seed "$base" "$flavor"
  sd=$(git rev-parse HEAD)
  for ((i = 1; i <= top; i++)); do vend "${u[i]}"; done
  git branch -f "$s-vendor" HEAD
  git checkout -q --detach "$sd"
  for ((i = 1; i <= top; i++)); do vend "${u[i]}" "$i"; done
  git branch -f "$s-build" HEAD
  git checkout -q --detach "$sd"
  for ((i = 1; i <= top; i++)); do
    if [ "$i" = 2 ] && [ -n "$port" ]; then tick; git cherry-pick "$FEAT" >/dev/null; fi
    [ "$i" != 2 ] || sed -i "s/^  \".*\"\$/  \"$fix\"/" R/foo.R
    vend "${u[i]}" "$i"
  done
  git branch -f "$s-dev" HEAD
  git branch -f "$s-green" "HEAD~$green"
}
series v9.9-x "$OLD_MAIN" duckdb.9.9 'two (series)' 2 port 0
series v9.9-x-fwd "$FWD_MAIN" duckdb.9.9 'two (main, series)' 3 '' 1
# `main` as it stood before its history was replaced: the same tree, no parent.
tick
OLDMAIN_Y=$(git commit-tree "$OLD_MAIN^{tree}" -m 'main, before its history was replaced')
series v8.8-y "$OLDMAIN_Y" duckdb.8.8 'two (y)' 2 '' 0
series v8.8-y-fwd "$FWD_MAIN" duckdb.8.8 'two (main, y)' 3 '' 1
# `v6.6-w` and a forward of it at birth on the same base: the forward's green sits on the commit its seed sits on,
# below the flavor commits, which the series' green has too.
series v6.6-w "$OLD_MAIN" duckdb.6.6 'two (w)' 2 '' 0
series v6.6-w-fwd "$OLD_MAIN" duckdb.6.6 'two (w, forward)' 2 '' 0
git branch -f v6.6-w-fwd-green "$OLD_MAIN"
git checkout -q --detach "$FWD_MAIN"
tick
echo 'hotfix' > src/duckdb/hotfix.cpp
git add -A
git commit -qm 'fix: Patch the vendored sources in place'
HOTFIX=$(git rev-parse HEAD)
series v5.5-v "$FWD_MAIN" duckdb.5.5 'two (main)' 2 '' 0
series v5.5-v-fwd "$HOTFIX" duckdb.5.5 'two (main)' 3 '' 1
git checkout -q main
unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE
git push -q origin main 'refs/heads/v9.9-x*' 'refs/heads/v8.8-y*' 'refs/heads/v6.6-w*' 'refs/heads/v5.5-v*' 2>/dev/null
for b in $(git for-each-ref --format='%(refname:short)' 'refs/heads/v*'); do git branch -q -D "$b"; done
git branch -q -D side

# Every run: stdin closed, no controlling terminal, so a read of either fails.
run() { # <args...> -> output, then EXIT=<status>
  set +e
  if command -v setsid >/dev/null; then
    setsid -w "$@" <&- 2>&1
  else
    "$@" <&- 2>&1
  fi
  echo "EXIT=$?"
  set -e
}
status() { sed -n 's/^EXIT=//p' <<<"$1"; }
tip() { git ls-remote "$FORK" "refs/heads/$1" | cut -f1; }
stack() { git ls-remote "$FORK" "refs/heads/cutover/$1/*" | sort -k2; }
fetch() { git fetch -q origin '+refs/heads/*:refs/remotes/origin/*' --prune; }
section() { # <branch> <output>: that branch's section of the summary in a run's output
  awk -v h="## $1" '/^## / { f = ($0 == h) } f' <<<"$2"
}
STACK=scripts/series-cutover-stack.sh
c=cutover/v9.9-x

echo "=== 1. the commit-by-commit replay onto the vendor strand"
out=$(run "$STACK" v9.9-x vendor --upstream "$UP" --summary "$SCRATCH/vendor.md")
is "it builds and pushes" "$(status "$out")" 0
fetch
old=$(tip v9.9-x-vendor) fwdv=$(tip v9.9-x-fwd-vendor)
L1=origin/$c/vendor/1-main L2=origin/$c/vendor/2-engine L3=origin/$c/vendor/3-fwd L4=origin/$c/vendor/4-old
is "four layers in the fork" "$(stack v9.9-x/vendor | awk '{ sub(".*/", "", $2); print $2 }' | tr '\n' ' ')" "1-main 2-engine 3-fwd 4-old "
holds "the old tip is under 1-main, which pins it" git merge-base --is-ancestor "$old" "$L1"
is "1-main replays the feature, the merge, the rest of a vendor commit, the patch, the bump and the fix" \
  "$(git log --reverse --format=%s "$old..$L1" | tr '\n' '|')" \
  "feat: Add bar()|Merge pull request #1 from side|vendor: Update vendored sources to duckdb/duckdb@${u[1]}|fix(patch): Patch the engine|chore: Bump version to 1.0.0.9001|fix: foo() says two, as main has it|"
has "a pick says where it came from" "$(git log -1 --format=%B "$L1")" "(cherry picked from commit $FIX)"
has "a vendor commit too" "$(git log -1 --format=%B "$L1~3")" "(cherry picked from commit $V1)"
has "a merge too" "$(git log -1 --format=%B "$L1~4")" "(cherry picked from commit $MERGE)"
is "the merge is replayed against its first parent" "$(git show "$L1~4:R/baz.R")" 'baz <- function() 3'
is "a pick keeps its author and its dates" "$(git log -1 --format='%an %ad %cd' --date=raw "$L1")" \
  "$(git log -1 --format='%an %ad %cd' --date=raw "$FIX")"
is "and has the stack's committer" "$(git log --format=%cn "$old..$L4" | sort -u)" series-cutover-stack
has "a vendor commit is picked without its engine paths and DESCRIPTION" "$(git log -1 --format=%B "$L1~3")" \
  'Its engine paths and DESCRIPTION are left out: this layer keeps the engine of `v9.9-x-vendor`.'
is "so its counter stays the old one" "$(git show "$L1~3:DESCRIPTION" | sed -n 2p)" 'Version: 1.0.0.9000.0'
is "and a bump goes through the DESCRIPTION merge driver" "$(git show "$L1:DESCRIPTION" | sed -n 2p)" 'Version: 1.0.0.9001.0'
is "so its glue comes" "$(git show "$L1:src/glue.cpp")" 'glue (adapted)'
is "and so does the patch it rebased" "$(git show "$L1~3:patch/0001-one.patch")" 'patch one (rebased)'
has "a commit that patches the engine is picked without its engine paths" "$(git log -1 --format=%B "$L1~2")" \
  'Its engine paths are left out: this layer keeps the engine of `v9.9-x-vendor`.'
is "so its patch comes, and the engine stays the old tip's" \
  "$(git show "$L1:patch/0002-two.patch") / $(git show "$L1:src/duckdb/patched.cpp")" "patch two / upstream ${u[2]}"
is "and 1-main keeps the old engine" "$(git show "$L1:src/duckdb/engine.cpp")" "engine ${u[2]}"
has "a vendor commit with nothing else but its counter is recorded as vendoring only" "$out" \
  "$(printf -- '- `%s` vendor: Update vendored sources to duckdb/duckdb@%s' "$(git rev-parse --short=10 "$V2")" "${u[2]}")"
is "2-engine takes the forward's engine" "$(git show "$L2:src/duckdb/engine.cpp") $(git show "$L2:R/version.R")" \
  "engine ${u[3]} duckdb_version <- \"${u[3]}\""
is "the engine part of the commit that patches it included" "$(git show "$L2:src/duckdb/patched.cpp")" "upstream ${u[3]}
// patched"
is "and keeps the patch stack" "$(git rev-parse "$L2:patch")" "$(git rev-parse "$L1:patch")"
has "its message names the upstream range" "$(git log -1 --format=%B "$L2")" "duckdb/duckdb@${u[2]}..${u[3]}"
engine_section=$(section "$c/vendor/2-engine" "$out")
has "its summary names the commit of main whose engine paths it carries" "$engine_section" \
  "$(printf 'Beside vendoring, it carries the engine paths of these commits of `main`, as the forward has them, which `1-main` replays without them or leaves out:\n\n- `%s` fix(patch): Patch the engine' "$(git rev-parse --short=10 "$PATCH")")"
hasnt "and no vendor commit, whose engine the upstream range is" "$engine_section" "$(git rev-parse --short=10 "$V1")"
hasnt "in its body, not its subject" "$(git log -1 --format=%s "$L2")" "duckdb/duckdb@"
is "3-fwd has the forward's tree" "$(git rev-parse "$L3^{tree}")" "$(git rev-parse "$fwdv^{tree}")"
is "and is empty for the vendor strand" "$(git diff --name-only "$L2" "$L3")" ""
is "4-old has the old tree" "$(git rev-parse "$L4^{tree}")" "$(git rev-parse "$old^{tree}")"
is "each layer is one commit on the one before" "$(git rev-parse "$L4^" "$L3^" "$L2^" | tr '\n' ' ')" \
  "$(git rev-parse "$L3" "$L2" "$L1" | tr '\n' ' ')"
has "the summary counts the replay" "$out" "- replayed whole: 4
- replayed without their engine paths: 1
- vendor commits replayed without their engine paths and \`DESCRIPTION\`: 1
- recorded as present: 0
- vendoring only, left out: 1
- engine changes only, left out: 0
- conflicts resolved: 0"
has "and the upstream range" "$out" "Upstream, \`${u[3]}\` is 1 commits ahead of \`${u[2]}\` and 0 behind it."
has "the pull requests name the repository" "$out" "1. repository: test/fork"
has "the first goes into the old tip" "$out" "   base: v9.9-x-vendor
   head: $c/vendor/1-main
   title: Cutover v9.9-x, vendor 1-main: main's changes replayed onto v9.9-x-vendor"
has "each further one into the one below" "$out" "   base: $c/vendor/2-engine
   head: $c/vendor/3-fwd"
is "the --summary file is what was printed" "$(cat "$SCRATCH/vendor.md")" "$(sed -n '/^## /,/^EXIT=/p' <<<"$out" | sed '/^pushed: /d; /^EXIT=/d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')"
out=$(run "$STACK" v5.5-v vendor)
is "a span whose commit changes the engine alone builds" "$(status "$out")" 0
hotfix_line=$(printf -- '- `%s` fix: Patch the vendored sources in place' "$(git rev-parse --short=10 "$HOTFIX")")
has "1-main leaves that commit out" "$(section cutover/v5.5-v/vendor/1-main "$out")" \
  "$(printf 'Engine changes only, left out because this layer keeps the engine of `v5.5-v-vendor`:\n\n%s' "$hotfix_line")"
has "and the 2-engine summary names it" "$(section cutover/v5.5-v/vendor/2-engine "$out")" \
  "$(printf 'which `1-main` replays without them or leaves out:\n\n%s' "$hotfix_line")"

echo "=== 2. a conflict on -dev: stop, refuse beside it, --abort from the worktree, --continue"
out=$(run "$STACK" v9.9-x dev)
is "the replay stops with 3" "$(status "$out")" 3
has "naming the path" "$out" "  R/foo.R"
has "and how to go on" "$out" "v9.9-x dev --continue"
is "nothing is pushed" "$(stack v9.9-x/dev)" ""
wt=$(sed -n 's/^  cd //p' <<<"$out")
has "the worktree holds the conflict" "$(cat "$wt/R/foo.R")" "<<<<<<<"
out=$(run "$STACK" v9.9-x dev)
is "a fresh build beside it refuses" "$(status "$out")" 1
has "and says so" "$out" "stopped at"
out=$(cd "$wt" && run "$WORK/$STACK" v9.9-x dev --abort)
is "--abort, from the kept worktree, discards it" "$(status "$out")" 0
holds "with its worktree" test ! -d "$wt"
hasnt "which git forgets too" "$(git worktree list)" "$wt"
is "and the build's state" "$(ls "$(git rev-parse --git-common-dir)/series-cutover-stack" 2>/dev/null)" ""
out=$(run "$STACK" v9.9-x dev --continue)
is "--continue with nothing stopped refuses" "$(status "$out")" 1
out=$(run "$STACK" v9.9-x dev)
is "a new build stops again" "$(status "$out")" 3
wt=$(sed -n 's/^  cd //p' <<<"$out")
printf 'foo <- function() {\n  "two (main, series)"\n}\n' > "$wt/R/foo.R"
git -C "$wt" add R/foo.R
out=$(cd "$wt" && run "$WORK/$STACK" v9.9-x dev --continue)
is "--continue, from the kept worktree, finishes and pushes" "$(status "$out")" 0
holds "and removes the worktree" test ! -d "$wt"
fetch
D1=origin/$c/dev/1-main
is "four layers" "$(stack v9.9-x/dev | wc -l | tr -d ' ')" 4
is "the resolution is in 1-main" "$(git show "$D1:R/foo.R" | sed -n 2p)" '  "two (main, series)"'
has "the resolved pick names its paths" "$(git log -1 --format=%B "$D1")" 'Conflicts resolved replaying it onto `v9.9-x-dev`: R/foo.R.'
has "the ported feature is recorded as present" "$out" \
  "$(printf -- '- `%s` feat: Add bar(): the same change as' "$(git rev-parse --short=10 "$FEAT")")"
has "the conflict is listed" "$out" "$(printf -- '- `%s` fix: foo() says two, as main has it: R/foo.R' "$(git rev-parse --short=10 "$FIX")")"
is "the feature is not picked again" "$(git log --format=%s "$(tip v9.9-x-dev)..$D1" | grep -c 'Add bar' || true)" 0

echo "=== 3. -green: the same upstream commit, an engine that differs all the same, and rerere resolves"
out=$(run "$STACK" v9.9-x green)
is "it builds without stopping" "$(status "$out")" 0
has "the conflict resolved by rerere" "$out" "R/foo.R (by rerere)"
fetch
G2=origin/$c/green/2-engine
is "four layers" "$(stack v9.9-x/green | awk '{ sub(".*/", "", $2); print $2 }' | tr '\n' ' ')" "1-main 2-engine 3-fwd 4-old "
is "2-engine brings the engine part of main's patch alone" "$(git diff --name-only "origin/$c/green/1-main" "$G2")" src/duckdb/patched.cpp
has "and says both tips vendor the same upstream commit" "$(git log -1 --format=%B "$G2")" "Both tips vendor duckdb/duckdb@${u[2]}"
hasnt "so the summary counts no upstream range" "$out" "Upstream, "
has "and names the commit of main that differs instead" "$(section "$c/green/2-engine" "$out")" \
  "$(printf -- '- `%s` fix(patch): Patch the engine' "$(git rev-parse --short=10 "$PATCH")")"
is "3-fwd stands on it" "$(git rev-parse "origin/$c/green/3-fwd^")" "$(git rev-parse "$G2")"
has "and its pull request goes into it" "$out" "   base: $c/green/2-engine
   head: $c/green/3-fwd"
is "the resolution is the one -dev made" "$(git rev-parse "origin/$c/green/1-main:R/foo.R")" "$(git rev-parse "$D1:R/foo.R")"

echo "=== 4. the same inputs mint the same SHAs"
before=$(stack v9.9-x/green)
out=$(run "$STACK" v9.9-x green)
is "a rebuild succeeds" "$(status "$out")" 0
is "with the same SHAs" "$(stack v9.9-x/green)" "$before"
before=$(stack v9.9-x/vendor)
OTHER=$SCRATCH/other
git clone -q "$FORK" "$OTHER"
git -C "$OTHER" config user.name Someone
git -C "$OTHER" config user.email someone@example.invalid
git -C "$OTHER" config remote.origin.github test/fork
out=$(cd "$OTHER" && TZ=Pacific/Auckland run scripts/series-cutover-stack.sh v9.9-x vendor)
is "another clone, identity and time zone succeed" "$(status "$out")" 0
is "with the same SHAs" "$(stack v9.9-x/vendor)" "$before"

echo "=== 5. leased pushes over existing branches"
git checkout -q --detach "$(tip v9.9-x-fwd-vendor)"
GIT_AUTHOR_DATE='1800000000 +0000' GIT_COMMITTER_DATE='1800000000 +0000' vend "${u[4]}"
git push -q origin HEAD:refs/heads/v9.9-x-fwd-vendor
git checkout -q main
l1=$(tip "$c/vendor/1-main") l3=$(tip "$c/vendor/3-fwd")
out=$(run "$STACK" v9.9-x vendor)
is "a forward that moved rebuilds the stack" "$(status "$out")" 0
is "1-main keeps its SHA" "$(tip "$c/vendor/1-main")" "$l1"
holds "3-fwd moves, under its lease" test "$(tip "$c/vendor/3-fwd")" != "$l3"
fetch
is "to the forward's new tree" "$(git rev-parse "origin/$c/vendor/3-fwd^{tree}")" "$(git rev-parse "origin/v9.9-x-fwd-vendor^{tree}")"
d4=$(tip "$c/dev/4-old") d1=$(tip "$c/dev/1-main")
rm -rf "$(git rev-parse --git-common-dir)/rr-cache"
out=$(run "$STACK" v9.9-x dev)
is "with rerere forgotten, -dev stops again" "$(status "$out")" 3
wt=$(sed -n 's/^  cd //p' <<<"$out")
git push -q --force origin "$FWD_MAIN:refs/heads/$c/dev/4-old"
printf 'foo <- function() {\n  "two (main, series)"\n}\n' > "$wt/R/foo.R"
git -C "$wt" add R/foo.R
out=$(run "$STACK" v9.9-x dev --continue --summary "$SCRATCH/refused.md")
is "a branch that moved meanwhile refuses the push" "$(status "$out")" 1
has "and says nothing moved" "$out" "the push was refused, and nothing moved"
holds "the summary written for the build is removed" test ! -e "$SCRATCH/refused.md"
has "which it says" "$out" "The summary written to $SCRATCH/refused.md for this build is removed, since the build was not pushed."
is "the moved branch stays" "$(tip "$c/dev/4-old")" "$FWD_MAIN"
is "and the others with it" "$(tip "$c/dev/1-main")" "$d1"
out=$(run "$STACK" v9.9-x dev --continue)
is "the refused build is gone" "$(status "$out")" 1
# A fork that refuses every push, for the two builds below.
printf '#!/bin/sh\necho "refused" >&2\nexit 1\n' > "$FORK/hooks/pre-receive"
chmod +x "$FORK/hooks/pre-receive"
# A summary written through a link: the link and the file it leads to stay, and the run says where the summary is.
echo 'an older summary' > "$SCRATCH/refused-target.md"
ln -s refused-target.md "$SCRATCH/refused-link.md"
out=$(run "$STACK" v9.9-x dev --summary "$SCRATCH/refused-link.md")
is "a refused push with the summary written through a link" "$(status "$out")" 1
holds "keeps the link" test -L "$SCRATCH/refused-link.md"
has "and the summary in the file it leads to" "$(cat "$SCRATCH/refused-target.md")" "## $c/dev/1-main"
has "which it says, naming that file" "$out" \
  "was written through the link $SCRATCH/refused-link.md
  to $(readlink -f "$SCRATCH/refused-target.md"), and both are left as they are"
# A summary written into what is no regular file, a FIFO standing in for a device: left as it is, and said to be.
mkfifo "$SCRATCH/refused.fifo"
cat "$SCRATCH/refused.fifo" > "$SCRATCH/refused.fifo.out" &
reader=$!
out=$(run "$STACK" v9.9-x dev --summary "$SCRATCH/refused.fifo")
# Opened and closed, so that a reader the run never wrote to ends.
: <> "$SCRATCH/refused.fifo"
wait "$reader" || true
is "a refused push with the summary written into a FIFO" "$(status "$out")" 1
holds "keeps the FIFO" test -p "$SCRATCH/refused.fifo"
has "which took the summary" "$(cat "$SCRATCH/refused.fifo.out")" "## $c/dev/1-main"
has "and says it is left" "$out" "$SCRATCH/refused.fifo is not a regular file, so it is left as it is"
rm "$FORK/hooks/pre-receive"
out=$(run "$STACK" v9.9-x dev)
is "a rebuild, on the resolution rerere recorded, pushes" "$(status "$out")" 0
is "and puts the branch back where it was" "$(tip "$c/dev/4-old")" "$d4"

echo "=== 6. 2-engine leaves the stack once the engines agree, and the session retires it"
# The old vendor strand carries main's patch and catches up with the forward's engine.
git checkout -q --detach "$(tip v9.9-x-vendor)"
tick
git show "$PATCH:patch/0002-two.patch" > patch/0002-two.patch
git add -A
git commit -qm 'fix(patch): Carry the engine patch'
vend "${u[3]}"
vend "${u[4]}"
git push -q origin HEAD:refs/heads/v9.9-x-vendor
git checkout -q main
e2=$(tip "$c/vendor/2-engine")
out=$(run "$STACK" v9.9-x vendor)
is "a 2-engine no longer needed exits 9" "$(status "$out")" 9
has "named, with the 3-fwd pull request to retarget first" "$out" "No longer in the stack: $c/vendor/2-engine"
has "onto 1-main" "$out" "1. Retarget the pull request of $c/vendor/3-fwd onto $c/vendor/1-main."
has "then its own to close" "$out" "2. Close the pull request of $c/vendor/2-engine."
has "and the line that deletes it where git cannot" "$out" "gh api -X DELETE repos/test/fork/git/refs/heads/$c/vendor/2-engine"
has "after a check of the tip read, since the API takes no lease" "$out" \
  "   if [ \"\$(gh api repos/test/fork/git/ref/heads/$c/vendor/2-engine --jq .object.sha)\" = $e2 ]; then gh api -X DELETE"
has "with the line that tells a moved branch" "$out" "else echo '$c/vendor/2-engine is not at $e2: read what moved before deleting it'; fi"
is "the branch stays, for the session" "$(tip "$c/vendor/2-engine")" "$e2"
fetch
is "3-fwd stands on 1-main" "$(git rev-parse "origin/$c/vendor/3-fwd^")" "$(git rev-parse "origin/$c/vendor/1-main")"
has "main's patch is recorded as present" "$out" \
  "$(printf -- '- `%s` fix(patch): Patch the engine: applies as no change' "$(git rev-parse --short=10 "$PATCH")")"
del=$(sed -n 's/^   \(git push --force-with-lease=.*\)$/\1/p' <<<"$out")
ghdel=$(sed -n 's/^   \(if \[ "\$(gh api .*\)$/\1/p' <<<"$out")
# A `gh` that answers the two calls the checked line makes, against the fork, first on PATH for those runs alone.
mkdir -p "$SCRATCH/ghapi"
cat > "$SCRATCH/ghapi/gh" <<'EOF'
#!/bin/bash
if [ "$1 $2 $3" = "api -X DELETE" ]; then
  git -C "$FORK" update-ref -d "refs/${4#repos/test/fork/git/refs/}"
elif [ "$1 $3 $4" = "api --jq .object.sha" ]; then
  git -C "$FORK" rev-parse -q --verify "refs/${2#repos/test/fork/git/ref/}" || true
else
  exit 1
fi
EOF
chmod +x "$SCRATCH/ghapi/gh"
git push -q -f origin "$FWD_MAIN:refs/heads/$c/vendor/2-engine"
out=$(run bash -c "$del")
holds "the leased deletion refuses a branch that moved" test "$(status "$out")" != 0
out=$(FORK=$FORK PATH="$SCRATCH/ghapi:$PATH" run bash -c "$ghdel")
has "and so does the checked one" "$out" "$c/vendor/2-engine is not at $e2: read what moved before deleting it"
is "the moved branch stays" "$(tip "$c/vendor/2-engine")" "$FWD_MAIN"
git push -q -f origin "$e2:refs/heads/$c/vendor/2-engine"
out=$(FORK=$FORK PATH="$SCRATCH/ghapi:$PATH" run bash -c "$ghdel")
is "the checked deletion of the tip read works" "$(status "$out") $(tip "$c/vendor/2-engine")" "0 "
git push -q origin "$e2:refs/heads/$c/vendor/2-engine"
out=$(run bash -c "$del")
is "and so does the leased one" "$(status "$out")" 0
is "and the branch is gone" "$(tip "$c/vendor/2-engine")" ""
out=$(run "$STACK" v9.9-x vendor)
is "a rebuild then exits 0" "$(status "$out")" 0
hasnt "and names no branch to retire" "$out" "No longer in the stack"

echo "=== 7. no shared history: one three-way merge"
out=$(run "$STACK" v8.8-y vendor)
is "it builds and pushes" "$(status "$out")" 0
fetch
Y1=origin/cutover/v8.8-y/vendor/1-main
is "1-main is one commit on the old tip" "$(git rev-list --count "origin/v8.8-y-vendor..$Y1") $(git rev-parse "$Y1^")" \
  "1 $(git rev-parse origin/v8.8-y-vendor)"
has "labeled as a three-way merge" "$(git log -1 --format=%s "$Y1")" "as one three-way merge"
has "with the command it stands for" "$(git log -1 --format=%B "$Y1")" "git merge-tree --write-tree --merge-base="
is "it takes main's changes" "$(git show "$Y1:src/glue.cpp") $(git show "$Y1:R/baz.R")" 'glue (adapted) baz <- function() 3'
is "and keeps the old engine" "$(git show "$Y1:src/duckdb/engine.cpp")" "engine ${u[2]}"
is "3-fwd is empty for the vendor strand" "$(git diff --name-only "origin/cutover/v8.8-y/vendor/2-engine" "origin/cutover/v8.8-y/vendor/3-fwd")" ""
engine_section=$(section cutover/v8.8-y/vendor/2-engine "$out")
has "the 2-engine summary says it carries the engine side the merge leaves out" "$engine_section" \
  'Beside vendoring, it carries the engine side of `main`'"'"'s changes, as the forward has it,
which the three-way merge of `1-main` leaves out.'
hasnt "and lists no commit, since none was replayed on its own" "$engine_section" "the engine paths of these commits of"
out=$(run "$STACK" v8.8-y dev)
is "a conflict in the merge stops with 3" "$(status "$out")" 3
has "naming the path" "$out" "  R/foo.R"
wt=$(sed -n 's/^  cd //p' <<<"$out")
printf 'foo <- function() {\n  "two (main, y)"\n}\n' > "$wt/R/foo.R"
git -C "$wt" add R/foo.R
out=$(run "$STACK" v8.8-y dev --continue)
is "and --continue finishes it" "$(status "$out")" 0
fetch
has "the merge names the resolution" "$(git log -1 --format=%B origin/cutover/v8.8-y/dev/1-main)" "Conflicts resolved: R/foo.R."
is "which 3-fwd agrees with" "$(git diff "origin/cutover/v8.8-y/dev/2-engine" "origin/cutover/v8.8-y/dev/3-fwd" -- R/foo.R)" ""

echo "=== 8. usage and refusals"
is "a strand that is none of the four" "$(status "$(run "$STACK" v9.9-x build-base)")" 2
is "--continue with --abort" "$(status "$(run "$STACK" v9.9-x dev --continue --abort)")" 2
is "no strand" "$(status "$(run "$STACK" v9.9-x)")" 2
is "--summary without a file" "$(status "$(run "$STACK" v9.9-x dev --summary)")" 2
out=$(run "$STACK" v7.7-z dev)
is "a series with no forward refuses" "$(status "$out")" 1
has "naming the ref" "$out" "has no v7.7-z-dev"
# After the swap the series' tips are the forward's, and -fwd refs a proxy would not delete stay beside them.
fetch
ov=$(tip v9.9-x-vendor) fv=$(tip v9.9-x-fwd-vendor) od=$(tip v9.9-x-dev) fd=$(tip v9.9-x-fwd-dev)
before=$(stack v9.9-x/vendor)
git checkout -q --detach "$fd"
tick
echo 'later <- function() 9' > R/later.R
git add -A
git commit -qm 'fix: Something the series added after its swap'
later=$(git rev-parse HEAD)
git checkout -q main
# A fold since the swap rewrote the commit the forward's -dev ended on, above its seed.
folded=$(git commit-tree "$fd^{tree}" -p "$fd~1" -m "$(git log -1 --format=%B "$fd")")
for pos in "at its forward's tip:$fd" "behind it:$(git rev-parse "$fd~1")" "past it:$later" "folded since:$folded"; do
  git push -q -f origin "${pos#*:}:refs/heads/v9.9-x-dev" "$fv:refs/heads/v9.9-x-vendor"
  out=$(run "$STACK" v9.9-x vendor)
  is "a series ${pos%%:*}, on its lineage, refuses" "$(status "$out")" 1
  has "${pos%%:*}: saying why" "$out" "are one lineage, as after the swap"
  is "${pos%%:*}: and pushes nothing" "$(stack v9.9-x/vendor)" "$before"
done
git push -q -f origin "$od:refs/heads/v9.9-x-dev" "$ov:refs/heads/v9.9-x-vendor"
# A forward with no seed, as a series cut from a parent has none, and a series on its lineage or apart from it.
git checkout -q --detach "$FWD_MAIN"
vend "${u[1]}"
vend "${u[2]}"
nf=$(git rev-parse HEAD)
tick
echo 'later <- function() 9' > R/later.R
git add -A
git commit -qm 'fix: Something the series added after its swap'
nl=$(git rev-parse HEAD)
git checkout -q --detach "$OLD_MAIN"
vend "${u[1]}"
apart=$(git rev-parse HEAD)
git checkout -q main
git push -q -f origin "$nf:refs/heads/v4.4-u-fwd-dev"
for pos in "at its forward's tip:$nf" "behind it:$(git rev-parse "$nf~1")" "past it:$nl"; do
  git push -q -f origin "${pos#*:}:refs/heads/v4.4-u-dev"
  out=$(run "$STACK" v4.4-u dev)
  is "a series ${pos%%:*}, its forward with no seed, refuses" "$(status "$out")" 1
  has "${pos%%:*}, no seed: saying why" "$out" "are one lineage, as after the swap"
done
git push -q -f origin "$apart:refs/heads/v4.4-u-dev"
out=$(run "$STACK" v4.4-u dev)
is "a series apart from a forward with no seed builds its stack" "$(status "$out")" 0
hasnt "and is not taken for one lineage" "$out" "are one lineage"
out=$(run "$STACK" v6.6-w green)
holds "a forward's green at birth is on its series' lineage" \
  git merge-base --is-ancestor "$(tip v6.6-w-fwd-green)" "$(tip v6.6-w-green)"
is "and its green stack builds all the same" "$(status "$out")" 0
is "with its layers" "$(stack v6.6-w/green | awk '{ sub(".*/", "", $2); print $2 }' | tr '\n' ' ')" "1-main 2-engine 3-fwd 4-old "
is "the last one the old green's tree" "$(git -C "$FORK" rev-parse "refs/heads/cutover/v6.6-w/green/4-old^{tree}")" \
  "$(git -C "$FORK" rev-parse "refs/heads/v6.6-w-green^{tree}")"
out=$(run "$STACK" v9.9-x build --summary "$SCRATCH/no/such/dir/build.md")
is "a summary file that cannot be written refuses" "$(status "$out")" 1
has "saying nothing was pushed" "$out" "cannot write the summary to $SCRATCH/no/such/dir/build.md, so nothing was pushed"
is "and nothing is" "$(stack v9.9-x/build)" ""

echo "=== 9. nothing called gh"
is "the failing gh is the one on PATH" "$(command -v gh)" "$BIN/gh"
is "and was never called" "$(cat "$GH_LOG")" ""

echo "=== 10. nothing read a terminal"
probe=$(run bash -c 'if (: < /dev/tty) 2>/dev/null; then echo "a terminal"; fi; if read -r _; then echo "a stdin"; fi; echo probed')
has "the wrapper every run above went through runs its command to the end" "$probe" probed
hasnt "with no controlling terminal to read" "$probe" "a terminal"
hasnt "and no stdin" "$probe" "a stdin"
is "no build is left stopped" "$(ls "$(git rev-parse --git-common-dir)/series-cutover-stack" 2>/dev/null)" ""
is "and no worktree is left" "$(git worktree list | wc -l | tr -d ' ')" 1

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
