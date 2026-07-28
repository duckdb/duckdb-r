#!/bin/bash
# Read-only diagnosis for the series loop: what should a firing do?
#
# For every series (or the ones named), walks `<S>-green..<S>-dev`, looks each
# commit up in the harvest on branch `rcc` (read via `git show`, no checkout of
# that 1.7 GB tree), classifies failures by what their log CONTAINS, and prints
# one verdict per series:
#
#   ADVANCE            every in-flight commit has a success run
#   WAIT               runs still missing from the harvest (age of harvest shown)
#   REPAIR <sha> <why>  the oldest failure and its classification
#
# Classification is by positive evidence only (.claude/skills/series-loop.md);
# "Job is waiting for a hosted runner" appears in every log and means nothing.
#
# Usage: series-check.sh [<series>...]     # default: discover all from refs

set -euo pipefail

remote=origin
git fetch -q "$remote"

rcc_tip() { git rev-parse -q --verify "refs/remotes/$remote/rcc" 2>/dev/null; }

state_of() { # <sha> -> success|failure|pending|missing
  local rec
  rec=$(git show "$remote/rcc:runs2.ndjson" 2>/dev/null | grep -m 1 "\"commit\": *\"$1\"" || true)
  [ -z "$rec" ] && { echo missing; return; }
  echo "$rec" | sed -nr 's/.*"status":[^}]*"state": *"([a-z]+)".*/\1/p' | head -n 1
}

classify() { # <sha> -> one line
  local log
  log=$(git show "$remote/rcc:logs2/$1.log" 2>/dev/null || true)
  [ -z "$log" ] && { echo "failure, no log harvested yet"; return; }
  if grep -qE "Updating snapshots: '" <<<"$log"; then
    echo "snapshot drift ($(grep -oE "Updating snapshots: [^.]*" <<<"$log" | head -1))"
  elif grep -qE "Error \('test-[^']+'\)" <<<"$log"; then
    echo "test failure ($(grep -oE "Error \('test-[^']+'\)" <<<"$log" | head -1))"
  elif grep -q "Changes detected in workflow_dispatch build" <<<"$log"; then
    echo "style/roxygen drift"
  elif ! grep -q "test_local\|testthat" <<<"$log"; then
    echo "cancelled or infra (no test phase in log)"
  else
    echo "unclassified: review logs2/$1.log on branch rcc by hand"
  fi
}

series=("$@")
if [ ${#series[@]} -eq 0 ]; then
  while IFS= read -r b; do
    s=${b#refs/heads/}; s=${s%-build}
    case "$s" in *-build-base) continue ;; esac
    git rev-parse -q --verify "refs/remotes/$remote/$s-dev" >/dev/null && series+=("$s")
  done < <(git ls-remote --heads "$remote" '*-build' | cut -f2)
fi

tip=$(rcc_tip) || { echo "no rcc branch on $remote"; exit 1; }
echo "harvest: $(git log -1 --format='%ci (%ar)' "$tip")"
echo

for S in "${series[@]}"; do
  green="$remote/$S-green"; dev="$remote/$S-dev"; build="$remote/$S-build"
  for r in "$green" "$dev" "$build"; do
    git rev-parse -q --verify "$r" >/dev/null || { echo "$S: missing ${r#"$remote"/}, skipping"; continue 2; }
  done
  # cutover litter: a forward series whose green is an ancestor of its base's
  # (the base moves on after cutover, so equality cannot be the test)
  case "$S" in *-fwd)
    base=${S%-fwd}
    if git rev-parse -q --verify "$remote/$base-green" >/dev/null &&
       git merge-base --is-ancestor "$green" "$remote/$base-green"; then
      echo "$S: green is an ancestor of $base's — cutover litter, ignoring"; continue
    fi ;;
  esac

  inflight=$(git rev-list --count "$green..$dev")
  # the buffer counts from -dev's consumption anchor on -build: the -dev tip
  # while it sits on -build's line, its vendored-SHA equivalent after a repair
  mb=$(git merge-base "$dev" "$build")
  if [ "$mb" = "$(git rev-parse "$dev")" ]; then
    buffered=$(git rev-list --count "$dev..$build")
  else
    dev_up=$(git log -1 --format=%s "$dev" | sed -nr 's/^.*duckdb.duckdb@([0-9a-f]+)( .*)?$/\1/p')
    anchor=$(git log --format='%H %s' "$mb..$build" | grep -m 1 "duckdb@${dev_up:-NONE}" | cut -d' ' -f1 || true)
    if [ -n "$anchor" ]; then
      buffered=$(git rev-list --count "$anchor..$build")
    else
      buffered="?"
    fi
  fi
  echo "=== $S: $inflight in flight, $buffered buffered, green=$(git rev-parse --short "$green") dev=$(git rev-parse --short "$dev")"

  verdict="ADVANCE" oldest="" why="" missing=0
  while IFS= read -r sha; do
    st=$(state_of "$sha")
    case "$st" in
      success) ;;
      missing|pending) missing=$((missing + 1)) ;;
      *) oldest="$sha"; why=$(classify "$sha") ;;   # keep last seen = oldest (list is newest-first)
    esac
  done < <(git rev-list "$green..$dev")

  if [ -n "$oldest" ]; then
    echo "  REPAIR $oldest"
    echo "         $why"
  elif [ "$missing" -gt 0 ]; then
    echo "  WAIT   $missing run(s) not harvested yet"
  elif [ "$inflight" -eq 0 ] && [ "$buffered" = 0 ]; then
    echo "  IDLE   nothing in flight, buffer empty — vendor"
  else
    echo "  ADVANCE"
  fi
done
