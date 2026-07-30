#!/bin/bash
# Bring a series' -dev branch level with `main` — stage 4 of the series loop
# (.claude/skills/series-loop.md).
#
# The goal is identity, not curation: after a successful --apply, the tooling
# paths — .github/, scripts/, .claude/ — of <S>-dev are byte-identical to
# `main`'s, and a tooling change never waits for a forward.
#
# The script lists EVERY commit on `main` since the series' base that has no
# patch-id equivalent on <S>-dev (`git cherry`), oldest first, classified by
# what it touches: TOOLING (only tooling paths), MIXED (tooling and more),
# OTHER (no tooling), VENDOR (`vendor:` subject, or anything under
# src/duckdb/ or the generated R/version.R / src/include/sources.mk).
# --apply cherry-picks everything except VENDOR — a MIXED or OTHER commit is
# a forward-port like any other, judged by CI like every -dev commit — or
# exactly the SHAs given, for when judgement says a commit cannot work
# against this series' engine yet. Picks are always whole commits: a pick
# that matches its main commit is skipped by patch-id at the next rebase,
# a half-pick would only replay. VENDOR commits are never auto-picked: the
# series' own vendoring owns that strand, main's engine is not this series'
# engine, and the base scan in vendor-one.sh and the anchors in
# series-advance.sh rely on every src/duckdb-touching commit on -dev being
# one of this series' vendor commits. After the picks, whatever tooling
# delta remains (history that diverged inside vendor commits, picks dropped
# as empty) is closed with one sync commit that takes `main`'s tooling tree
# verbatim; its diff is the residue the commit walk could not explain, and
# reading it is part of the port. In steady state the residue is empty and
# no sync commit is created.
#
# A conflict stops the sequence in place and keeps the worktree: resolving it
# is the routine's judgement. Continue the sequence there, push, and rerun
# this script to finish — the patch-id filter makes reruns cheap and exact.
#
# Ported and sync commits are ordinary -dev commits: they vendor nothing (the
# consumption anchor in scripts/series-advance.sh reads vendor subjects), and
# they are transient — a forward's seed already carries their content, and a
# rebase drops patch-id equivalents and empty leftovers.
#
# Usage: series-port.sh <series> [--apply [sha...]]

set -euo pipefail

S=${1:?usage: series-port.sh <series> [--apply [sha...]]}
shift
apply=
if [ "${1:-}" = "--apply" ]; then
  apply=1
  shift
fi
remote=origin

# The identity set: what CI and the routine execute. patch/ stays out
# (vendor-coupled: applied by vendor runs, refreshed by repairs), as do the
# root docs (README.md is flavored per branch, NEWS.md belongs to the release
# strand) — commits touching them are still listed and picked like any other,
# but the sync commit never rewrites them.
tooling=(.github scripts .claude)
paths_re='^(\.github/|scripts/|\.claude/)'
vendor_re='^(src/duckdb/|R/version\.R$|src/include/sources\.mk$)'

git fetch -q "$remote"
dev="$remote/$S-dev" main="$remote/main"
git rev-parse -q --verify "$dev" >/dev/null || { echo "Error: no $S-dev on $remote"; exit 1; }

classify() { # <sha> -> TOOLING | MIXED | OTHER | VENDOR
  local f t= o=
  case "$(git log -1 --format=%s "$1")" in vendor:*) echo VENDOR; return ;; esac
  while IFS= read -r f; do
    if [[ "$f" =~ $vendor_re ]]; then echo VENDOR; return; fi
    if [[ "$f" =~ $paths_re ]]; then t=1; else o=1; fi
  done < <(git diff-tree --no-commit-id --name-only -r "$1")
  if [ -n "$t" ] && [ -n "$o" ]; then
    echo MIXED
  elif [ -n "$t" ]; then
    echo TOOLING
  else
    echo OTHER
  fi
}

# Every commit of `main` the series does not carry, oldest first. Two dedupe
# layers make reruns exact: `git cherry` bounds the walk at the merge base and
# drops patch-id equivalents (clean picks), and the `-x` trailer written into
# every ported commit excludes picks whose resolution diverged from the
# original patch — those would otherwise be re-offered and re-conflict on
# every rerun.
mb=$(git merge-base "$dev" "$main")
declare -A ported=()
while IFS= read -r x; do ported[$x]=1; done < <(
  git log --format=%B "$mb..$dev" |
    sed -n 's/^(cherry picked from commit \([0-9a-f]\{40\}\))$/\1/p')
mapfile -t all < <(git cherry "$dev" "$main" | sed -n 's/^+ //p')
candidates=()
declare -A klass=()
for sha in "${all[@]}"; do
  [ -n "${ported[$sha]:-}" ] && continue
  candidates+=("$sha")
  klass[$sha]=$(classify "$sha")
  printf '%-7s %s %s\n' "${klass[$sha]}" \
    "$(git rev-parse --short "$sha")" "$(git log -1 --format=%s "$sha")"
done

if git diff --quiet "$dev" "$main" -- "${tooling[@]}"; then
  echo "tooling: identical to main"
else
  echo "tooling: differs from main —$(git diff --shortstat "$dev" "$main" -- "${tooling[@]}")"
fi

[ -n "$apply" ] || exit 0

# OTHER picks routinely touch DESCRIPTION's `Version:` (fledge bumps,
# forward-ports); the ours-version merge driver keeps that line off the
# conflict list. Idempotent; .git/config is shared with the worktree.
if [ -x "$(dirname "$0")/setup-git.sh" ]; then
  "$(dirname "$0")/setup-git.sh" >/dev/null
fi

picks=("$@")
if [ ${#picks[@]} -eq 0 ]; then
  for sha in "${candidates[@]}"; do
    [ "${klass[$sha]}" = VENDOR ] || picks+=("$sha")
  done
fi

wt=$(mktemp -d)
git worktree add --detach -q "$wt" "$dev"

# `-x` records the main commit in the message; `--empty=drop` skips a pick
# whose content arrived some other way. On conflict the worktree stays: the
# sequencer holds the remaining picks, so one --continue walks the rest.
if [ ${#picks[@]} -gt 0 ] && ! git -C "$wt" cherry-pick -x --empty=drop "${picks[@]}"; then
  echo "Conflict; worktree kept at $wt, conflicted files:"
  git -C "$wt" diff --name-only --diff-filter=U | sed 's/^/  /'
  echo "Resolve toward main's intent, then:"
  echo "  git -C $wt cherry-pick --continue    # repeats through the rest"
  echo "  git -C $wt push $remote HEAD:refs/heads/$S-dev"
  echo "  git worktree remove --force $wt"
  echo "  scripts/series-port.sh $S --apply    # finish: leftovers + sync"
  exit 1
fi

# Close the residue: make the tooling paths byte-identical to main's. `git rm`
# first, so a file the series has and main does not is deleted rather than
# kept — checkout alone only adds and overwrites.
if ! git -C "$wt" diff --quiet "$main" -- "${tooling[@]}"; then
  git -C "$wt" rm -qr --ignore-unmatch -- "${tooling[@]}"
  git -C "$wt" checkout "$main" -- "${tooling[@]}"
  git -C "$wt" commit -q -m "chore(series): Sync tooling with main" \
    -m "Takes main's ${tooling[*]} verbatim on top of the ported commits;
the diff is the residue the commit walk could not explain."
fi
git -C "$wt" diff --quiet "$main" -- "${tooling[@]}" ||
  { echo "Error: tooling still differs after sync"; exit 1; }

next=$(git -C "$wt" rev-parse HEAD)
git worktree remove --force "$wt"
if [ "$next" = "$(git rev-parse "$dev")" ]; then
  echo "nothing to port"
  exit 0
fi
git push "$remote" "$next:refs/heads/$S-dev"
echo "dev -> $(git rev-parse --short "$next")"
