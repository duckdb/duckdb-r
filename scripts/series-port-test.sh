#!/bin/bash
# Check which commits stage 4 offers, offline, against a synthetic remote and
# clone built here -- no network, no fixtures on disk.
#
# The question is what "`main` has it and the series does not" means. `git
# cherry` answers by patch-id over `mb..main`, which counts a commit `main`
# merged for its ancestry alone -- a merge whose tree is its first parent's, so
# nothing of the lineage it records ever entered main's tree. Porting one
# applies a tree from another era on top of this one. Four things are checked.
#
#   1. An ordinary `main` commit the series lacks is offered.
#   2. A commit that reached `main` only through an ancestry-only merge is not.
#   3. Nor is the ancestry-only merge itself.
#   4. A real merge is not an ancestry-only one: its side commits did reach
#      main's tree, so they are still offered. The test is the tree, not the
#      shape of the commit.

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
WORK=$SCRATCH/work
git init -q --bare -b main "$REMOTE"

git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$REMOTE"

mkdir -p scripts .github R
cp "$HERE/series-port.sh" "$HERE/setup-git.sh" "$HERE/merge-version.sh" scripts/
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

git push -q origin main s-dev

# --- the read ---------------------------------------------------------------

out=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out"

echo "series-port.sh: which commits stage 4 offers"
has "an ordinary commit is offered" "$out" 'An ordinary commit the series lacks'
hasnt "ancestry-only content is not offered" "$out" 'Ancient work that never reached the tree'
hasnt "nor the rest of that lineage" "$out" 'More of the same'
hasnt "nor the ancestry-only merge itself" "$out" 'Record the old tag on the mainline'
has "a real merge's content is still offered" "$out" 'Live work that did reach the tree'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
