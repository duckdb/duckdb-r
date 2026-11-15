#!/bin/bash
# Check which commits stage 4 offers, offline, against a synthetic remote and
# clone built here -- no network, no fixtures on disk.
#
# The question is what "the branch has it and the series does not" means. The
# walk reads the branch's first parents by patch-id, so a lineage merged in is
# never offered commit by commit: one merged for its ancestry alone -- a merge
# whose tree is its first parent's -- brings nothing, and one merged for its
# content, a forward merge among them, is offered as one port of its change.
# Seven things are checked.
#
#   1. An ordinary `main` commit the series lacks is offered.
#   2. A commit that reached `main` only through an ancestry-only merge is not.
#   3. Nor is the ancestry-only merge itself.
#   4. A real merge is not an ancestry-only one: it changed main's tree, so
#      it is offered, as one port, and its side commits are not offered alone.
#      The test is the tree, not the shape of the commit.
#   5. Release paperwork is held back whether or not it moves `Version:`:
#      notes written into NEWS.md for main's next release belong to the release
#      strand, and the series has no section to put them in. A commit that
#      edits DESCRIPTION without moving the version is package content and is
#      still offered.
#   6. A forward merge of a release branch, keeping main's engine, is offered
#      as one port carrying its R-side fix and the glue folded into its vendor
#      commit and no engine; neither commit behind it is offered alone, and a
#      rerun names the same port. --apply of one that changes only engine
#      paths says there is nothing to port and picks nothing.
#   7. A series whose `releases_from` names a release branch takes its R side
#      from that branch and not from `main`; one declared `stale: true` is
#      frozen, its forward with it; one releasing from `main` takes `main`'s.
#
# And one thing about *which* `main` answers. The series live in a fork whose
# `main` is a mirror the Pull app refreshes every six hours, so the fork's copy
# is routinely behind the canonical repository's. The walk reads the canonical
# one, so a commit merged since the last sync is offered rather than silently
# reverted by the tooling sync; with no canonical remote to read, the mirror is
# the fallback and answers with the subset it has.

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)

SCRATCH=$(mktemp -d)
[ -n "${KEEP:-}" ] || trap 'rm -rf "$SCRATCH"' EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac; }
hasnt() { case "$2" in *"$3"*) no "$1"; echo "     unexpected: $3" ;; *) ok "$1" ;; esac; }

# --- the fixture -----------------------------------------------------------
#
# A bare remote plus a clone, because stage 4 reads `origin/*`. The shape is
# `main` with three things above the series' seed: an ordinary commit, a
# lineage merged for its ancestry alone, and a lineage merged for its content.

REMOTE=$SCRATCH/remote.git
CANON=$SCRATCH/canonical.git
WORK=$SCRATCH/work
git init -q --bare -b main "$REMOTE"
git init -q --bare -b main "$CANON"

git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$REMOTE"
git remote add upstream "$CANON"

mkdir -p scripts .github R
for s in series-port.sh setup-git.sh merge-version.sh series-config.sh series-lib.sh vendor-lib.sh; do cp "$HERE/$s" scripts/; done
chmod +x scripts/*.sh
echo 'DESCRIPTION merge=ours-version' > .gitattributes

# The attribute is committed and the name -> command mapping is not, so a fresh
# clone has the first and never the second. Register it here, as every real
# clone does.
scripts/setup-git.sh >/dev/null

printf 'Package: duckdb\nVersion: 1.0.0\n' > DESCRIPTION
echo 'workflow' > .github/ci.yml
echo 'foo <- function() 1' > R/foo.R
git add -A
git commit -qm 'chore: The base both lineages share'
git branch fork-point

# --- the series: a seed on `main`, so the walk is not frozen ----------------

git checkout -q -b s-dev
echo 'flavored' > R/flavor.R
git add -A
git commit -qm 'chore: Update flavor patch to duckdb.test'

# --- what `main` gains ------------------------------------------------------

git checkout -q main
echo 'foo <- function() 2' > R/foo.R
git add -A
git commit -qm 'fix: An ordinary commit the series lacks'

# A lineage from another era, merged for its ancestry alone: `-s ours` keeps
# main's tree, so nothing of it is in the package `main` builds.
git checkout -q -b old-line fork-point
echo 'ancient <- function() 1' > R/ancient.R
git add -A
git commit -qm 'feat: Ancient work that never reached the tree'
echo 'ancient <- function() 2' > R/ancient.R
git add -A
git commit -qm 'fix: More of the same'
git checkout -q main
git merge -q -s ours --no-ff -m 'chore: Record the old tag on the mainline' old-line

# A lineage merged for its content: an ordinary merge, whose commits did reach
# main's tree and are therefore still the series' to take.
git checkout -q -b live-line main
echo 'live <- function() 1' > R/live.R
git add -A
git commit -qm 'feat: Live work that did reach the tree'
git checkout -q main
git merge -q --no-ff -m 'chore: Merge the live line' live-line

# The release strand, in the three shapes that reach `main`: fledge's bump,
# the notes written beside it before the bump lands, and a DESCRIPTION edit
# that is not a bump at all.
printf '# duckdb 1.0.0\n\n- Something a user meets.\n' > NEWS.md
git add -A
git commit -qm 'docs(news): Bullets for what merged since the last bump'

printf 'Package: duckdb\nVersion: 1.0.1\n' > DESCRIPTION
printf '# duckdb 1.0.1\n\n- Something a user meets.\n' > NEWS.md
git add -A
git commit -qm 'fledge: Bump version to 1.0.1'

printf 'Package: duckdb\nVersion: 1.0.1\nImports: DBI\n' > DESCRIPTION
git add -A
git commit -qm 'chore: Declare the dependency the package gained'

git push -q origin main s-dev
git push -q upstream main

# --- the mirror falls behind ------------------------------------------------
#
# One more commit reaches the canonical repository and not the fork's copy of
# `main`, which is the state the fork is in for most of the Pull app's cycle.

echo 'foo <- function() 3' > R/foo.R
git add -A
git commit -qm 'fix: A commit the mirror has not picked up yet'
git push -q upstream main
git checkout -q s-dev

# --- the read ---------------------------------------------------------------

out=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out"

echo "series-port.sh: which commits stage 4 offers"
has "an ordinary commit is offered" "$out" 'An ordinary commit the series lacks'
hasnt "ancestry-only content is not offered" "$out" 'Ancient work that never reached the tree'
hasnt "nor the rest of that lineage" "$out" 'More of the same'
hasnt "nor the ancestry-only merge itself" "$out" 'Record the old tag on the mainline'
has "a real merge is offered as one port" "$out" 'chore: Merge the live line'
hasnt "  and the commit behind it is not offered alone" "$out" 'Live work that did reach the tree'

# The class of the listed commit whose subject contains the given text.
klass() { echo "$out" | grep -F -- "$2" | head -n 1 | awk '{print $1}'; }
is() { # <name> <subject text> <expected class>
  local got
  got=$(klass "$1" "$2")
  if [ "$got" = "$3" ]; then ok "$1"; else no "$1"; echo "       $3 expected, got ${got:-nothing}"; fi
}

echo
echo "series-port.sh: what the release strand covers"
is "fledge's bump is release paperwork" 'Bump version to 1.0.1' VERSION
is "so are notes written without a bump" \
  'Bullets for what merged since the last bump' VERSION
is "a DESCRIPTION edit that is not a bump is package content" \
  'Declare the dependency the package gained' OTHER

echo
echo "series-port.sh: which \`main\` answers"
has "a commit the mirror lacks is offered" "$out" 'A commit the mirror has not picked up yet'
hasnt "and a behind mirror is not a refusal" "$out" 'commit(s) behind'

# With no canonical remote to read, the mirror answers -- with the subset it
# has, and saying so, rather than with a refusal.
out_fork=$(SERIES_CANONICAL= scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_fork"
hasnt "the fallback offers only what the mirror has" "$out_fork" 'A commit the mirror has not picked up yet'
has "and still offers what it does have" "$out_fork" 'An ordinary commit the series lacks'

echo
echo "series-port.sh: a line on a release branch of its own"
# The series is seeded on `main`, and its line has a release branch cut from
# `main` where that seed sits. Its R side comes from that branch: a fix there is
# offered, and `main`'s later work is not.
git checkout -q -B s-baseline "$(git merge-base s-dev main)"
mkdir -p R
echo 'release fix' > R/release-fix.R
git add -A; git commit -qm 'fix: A fix on the release branch'
git push -q -f upstream s-baseline
git checkout -q main
cat > scripts/series.yaml <<'EOF'
flavors:
  - flavor: duckdb.test
    kind: dev
    series: s
    releases_from: s-baseline
    publishes_from: s-green

  - flavor: duckdb.other
    kind: dev
    series: other
    releases_from: main
    publishes_from: other-green
EOF
git add scripts/series.yaml
git commit -qm 'chore: Release the line of series s from its own branch'
git push -q upstream main
git checkout -q s-dev
out_rel=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_rel"
hasnt "a line on its own release branch is not frozen" "$out_rel" "frozen"
has "it is offered that branch's fix" "$out_rel" 'A fix on the release branch'
hasnt "and not main's R side" "$out_rel" 'An ordinary commit the series lacks'

echo
echo "series-port.sh: a stale line"
git checkout -q main
sed -i 's/releases_from: s-baseline/releases_from: s-baseline\n    stale: true/' scripts/series.yaml
git add scripts/series.yaml
git commit -qm 'chore: Mark the line of series s stale'
git push -q upstream main
git checkout -q s-dev
out_parked=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_parked"
has "a stale line is frozen" "$out_parked" "s: frozen (stale)"
hasnt "and offers no R-side commit" "$out_parked" 'A fix on the release branch'

# Its forward is the same line, stale with it.
git push -q origin s-dev:refs/heads/s-fwd-dev
out_fwd=$(scripts/series-port.sh s-fwd 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_fwd"
has "and so is its forward" "$out_fwd" "s-fwd: frozen (stale)"

# A branch it cannot read stops the port, rather than reading as stale.
git checkout -q main
sed -i 's/releases_from: s-baseline/releases_from: s-nowhere/; /stale: true/d' scripts/series.yaml
git add scripts/series.yaml
git commit -qm 'chore: Name a branch that does not exist'
git push -q upstream main
git checkout -q s-dev
out_gone=$(scripts/series-port.sh s 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_gone"
has "a branch it cannot read is said so" "$out_gone" "could not read s-nowhere"
hasnt "  and not called stale" "$out_gone" "(stale)"
if [ "$st" -ne 0 ]; then ok "  and stops the port"; else no "  and stops the port"; fi
git checkout -q main
sed -i 's/releases_from: s-nowhere/releases_from: s-baseline/' scripts/series.yaml
git add scripts/series.yaml
git commit -qm 'chore: Name the release branch again'
git push -q upstream main

# A line declared on `main` is live, and says nothing about freezing.
git checkout -q main
sed -i 's/releases_from: s-baseline/releases_from: main/; /stale: true/d' scripts/series.yaml
git add scripts/series.yaml
git commit -qm 'chore: Release the line of series s from main again'
git push -q upstream main
git checkout -q s-dev
out_live=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_live"
hasnt "a line releasing from main is not frozen" "$out_live" "frozen"
has "and is offered main's R side" "$out_live" 'An ordinary commit the series lacks'

# A forward merge: the release branch, cut from main, takes a vendor commit
# whose engine main must not take, with glue folded into it, and an R-side fix;
# main merges it forward keeping its own engine. The merge is offered as one
# port, its change outside the engine; neither commit behind it is offered alone.
git checkout -q main
git checkout -q -b rel-line
mkdir -p src/duckdb src
echo 'engine of the release line' > src/duckdb/engine.cpp
echo 'glue the release engine needed' > src/glue.cpp
git add -A; git commit -qm 'vendor: Update vendored sources to duckdb/duckdb@abcdef0123'
echo 'fix rel' > R/rel-fix.R
git add -A; git commit -qm 'fix: A fix written on the release branch'
git checkout -q main
git merge -q --no-commit --no-ff rel-line
git rm -rq --cached --ignore-unmatch -- src/duckdb
git checkout HEAD -- src/duckdb 2>/dev/null || true
git clean -fdq -- src/duckdb
git commit -qm 'Merge rel-line forward into main'
MERGE=$(git rev-parse HEAD)
git push -q upstream main
git checkout -q s-dev
out_fwd=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_fwd"
has "the forward merge is offered as one port" "$out_fwd" 'Merge rel-line forward into main'
hasnt "the fix behind it is not offered alone" "$out_fwd" 'A fix written on the release branch'
hasnt "nor the vendor commit behind it" "$out_fwd" 'duckdb/duckdb@abcdef0123'
PORT=$(sed -n 's/^[A-Z]* *\([0-9a-f]*\) Merge rel-line forward into main$/\1/p' <<<"$out_fwd")
same() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
same "the port carries the fix" "$(git show "$PORT:R/rel-fix.R" 2>&1)" 'fix rel'
same "and the glue folded into the vendor commit" "$(git show "$PORT:src/glue.cpp" 2>&1)" 'glue the release engine needed'
same "and no engine" "$(git ls-tree -r --name-only "$PORT" -- src/duckdb | wc -l)" 0
out_again=$(GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=true \
  GIT_CONFIG_KEY_1=gpg.program GIT_CONFIG_VALUE_1=false scripts/series-port.sh s 2>&1 || true)
has "a rerun names the same commit, signing configured or not" "$out_again" "$PORT Merge rel-line forward into main"

# A fresh clone has no stand-in until it walks; --apply of the port's short SHA,
# or of the merge's own, ports the merge's change all the same.
SDEV=$(git rev-parse s-dev)
for named in "${PORT:0:10}" "$(git rev-parse --short "$MERGE")"; do
  rm -rf "$SCRATCH/fresh"
  git clone -q "$REMOTE" "$SCRATCH/fresh"
  # shellcheck disable=SC2015  # any failure is read off the output below
  out_apply=$(cd "$SCRATCH/fresh" &&
    git config user.name Test && git config user.email test@example.invalid && git config commit.gpgsign false &&
    git remote add upstream "$CANON" && git checkout -q s-dev && scripts/setup-git.sh >/dev/null &&
    scripts/series-port.sh s --apply "$named" 2>&1 || true)
  [ -z "${KEEP:-}" ] || echo "$out_apply"
  # The pick is what is checked; the fixture carries no tooling tree for the
  # sync that follows it to compare, so nothing reaches the remote here.
  has "--apply $named in a fresh clone picks the merge's port" "$out_apply" "] Merge rel-line forward into main"
  has "  carrying its fix" "$out_apply" "create mode 100644 R/rel-fix.R"
  git push -q -f origin "$SDEV:refs/heads/s-dev"
done

# A forward merge that brings only an engine change has nothing to port:
# --apply of it says so and picks nothing.
git checkout -q rel-line
echo 'engine of the release line, again' > src/duckdb/engine.cpp
git add -A; git commit -qm 'vendor: Update vendored sources to duckdb/duckdb@abcdef4567'
git checkout -q main
git merge -q --no-commit --no-ff rel-line >/dev/null 2>&1 || true
git rm -rq --cached --ignore-unmatch -- src/duckdb
git checkout HEAD -- src/duckdb 2>/dev/null || true
git clean -fdq -- src/duckdb
git commit -qm 'Merge an engine-only change forward into main'
EMERGE=$(git rev-parse HEAD)
git push -q upstream main
git checkout -q s-dev
out_eng=$(scripts/series-port.sh s --apply "$EMERGE" 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_eng"
has "--apply of an engine-only merge says there is nothing to port" "$out_eng" \
  "$(git rev-parse --short "$EMERGE"): nothing to port: the merge changes only engine paths"
same "  and succeeds" "$st" 0
same "  and picks nothing" "$(git ls-remote origin refs/heads/s-dev | cut -f1)" "$SDEV"
hasnt "  not even what the walk offers" "$out_eng" "cherry picked from commit"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
