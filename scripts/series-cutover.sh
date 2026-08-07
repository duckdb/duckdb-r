#!/bin/bash
# Atomically replace a series with its forward counterpart.
#
# A forward series <S>-fwd-* is the same series rebuilt on a newer `main`
# (.claude/skills/series-forward.md). Once its green ref covers at least the
# upstream commits the old green covered, this script swaps all four series
# refs in one atomic push, so consumers of <S>-green never observe a
# half-replaced series. The swap is the one sanctioned non-fast-forward move
# of a green ref.
#
# It is also the one move the series loop never makes: the loop reports a ready
# cutover and stops (.claude/skills/series-loop.md), because retiring the
# lineage r-universe builds from is a decision, not a stage. This script is the
# mechanical half of that rule — it runs from a terminal, on a typed
# confirmation, and nowhere else.
#
# A base series ref that does not exist yet is created rather than swapped:
# a series that started as -fwd has no counterpart to replace.
#
# Usage: series-cutover.sh <series> [remote] [upstream-clone]
#   series-cutover.sh main origin ../duckdb
#
# The upstream clone is needed for the coverage gate (an ancestry check
# between vendored upstream SHAs); without it the gate degrades to a warning.

set -euo pipefail

S=${1:?usage: series-cutover.sh <series> [remote] [upstream-clone]}
remote=${2:-origin}
upstream=${3:-}

# Fail before the fetch, not after it: an unattended firing has no terminal, so
# there is nothing for it to confirm with and no reason to do any work first.
if [ ! -t 0 ] || [ ! -t 1 ]; then
  echo "Error: cutover is a manual operation; run this script from a terminal." >&2
  echo "  The series loop reports a ready cutover and stops; a human runs it." >&2
  echo "  See .claude/skills/series-forward.md and series-loop.md." >&2
  exit 1
fi

git fetch -q "$remote"

# See scripts/series-advance.sh: the pathspec narrows the walk, the subject
# decides, and an empty answer explains itself on stderr.
vendored_sha() {
  local subjects sha n
  subjects=$(git log -n 20 --format=%s "$1" -- src/duckdb || true)
  sha=$(sed -nr 's/^.*duckdb.duckdb@([0-9a-f]+)( .*)?$/\1/p' <<<"$subjects" | head -n 1)
  if [ -z "$sha" ]; then
    n=$(grep -c . <<<"$subjects" || true)
    if [ "$n" -ge 20 ]; then
      echo "vendored_sha: 20 src/duckdb commits on $1, none of them vendoring;" >&2
      echo "  if that is genuine, raise the bound in this helper" >&2
    else
      echo "vendored_sha: no vendor commit among $n src/duckdb commits on $1" >&2
    fi
  fi
  echo "$sha"
}

for r in build dev green build-base; do
  git rev-parse -q --verify "refs/remotes/$remote/$S-fwd-$r" >/dev/null ||
    { echo "Error: $S-fwd-$r does not exist on $remote"; exit 1; }
done

# A base series ref may legitimately be missing: a series started as -fwd has
# no counterpart to replace, and the cutover creates the ref rather than
# swapping it. Only the forward refs are required.
missing=()
for r in build dev green build-base; do
  git rev-parse -q --verify "refs/remotes/$remote/$S-$r" >/dev/null ||
    missing+=("$S-$r")
done
[ ${#missing[@]} -eq 0 ] ||
  echo "Note: ${missing[*]} missing on $remote, will be created from $S-fwd-*"

if git rev-parse -q --verify "refs/remotes/$remote/$S-green" >/dev/null; then
  old_up=$(vendored_sha "refs/remotes/$remote/$S-green")
else
  old_up=
fi
new_up=$(vendored_sha "refs/remotes/$remote/$S-fwd-green")
echo "old green vendors: ${old_up:-<nothing>}"
echo "new green vendors: ${new_up:-<nothing>}"

# Coverage gate: the forward green must vendor at least what the old green
# vendored, so verification never moves backwards at cutover.
if [ -n "$old_up" ]; then
  if [ -z "$new_up" ]; then
    echo "Error: old green vendors $old_up but forward green vendors nothing"
    exit 1
  fi
  if [ -n "$upstream" ]; then
    git -C "$upstream" merge-base --is-ancestor "$old_up" "$new_up" || {
      echo "Error: forward green does not cover old green; coverage would regress"
      exit 1
    }
  else
    echo "Warning: no upstream clone given, coverage gate not verified"
  fi
fi

leases=()
refspecs=()
echo "refs to swap:"
for r in build dev green build-base; do
  new=$(git rev-parse "refs/remotes/$remote/$S-fwd-$r")
  # An empty expected value leases the ref as "must not exist yet", which is
  # what a base ref from `missing` needs. The refspecs carry no leading `+`:
  # a forced refspec defeats --force-with-lease outright, and the lease alone
  # already authorizes the non-fast-forward swap.
  cur=$(git rev-parse -q --verify "refs/remotes/$remote/$S-$r") || cur=
  leases+=("--force-with-lease=refs/heads/$S-$r:$cur")
  refspecs+=("$new:refs/heads/$S-$r")
  short=${cur:0:7}
  printf '  %-20s %s -> %s\n' "$S-$r" "${short:-<new>}" "${new:0:7}"
done

# The gate above says the swap is allowed; this asks whether it is wanted. It
# comes last so the operator confirms with the coverage lines and the four ref
# moves on screen, and it takes the series name rather than a keystroke because
# the mistake worth catching is cutting over the wrong series.
printf 'Replace series %s with %s-fwd-*? Type the series name to confirm: ' "$S" "$S"
read -r confirm
[ "$confirm" = "$S" ] || { echo "Aborted; nothing was pushed."; exit 1; }

git push --atomic "${leases[@]}" "$remote" "${refspecs[@]}"
if [ ${#missing[@]} -eq 4 ]; then
  echo "Series $S created from its forward counterpart."
else
  echo "Series $S replaced by its forward counterpart."
fi

# Best-effort: some git proxies refuse deletions. Until these refs are gone,
# the loop ignores a forward series whose refs equal its base series.
if ! git push "$remote" ":refs/heads/$S-fwd-build" ":refs/heads/$S-fwd-dev" \
    ":refs/heads/$S-fwd-green" ":refs/heads/$S-fwd-build-base"; then
  echo "Warning: could not delete $S-fwd-* refs; remove them via the forge UI"
fi
