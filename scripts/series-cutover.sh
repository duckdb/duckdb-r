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
# Usage: series-cutover.sh <series> [remote] [upstream-clone]
#   series-cutover.sh main origin ../duckdb
#
# The upstream clone is needed for the coverage gate (an ancestry check
# between vendored upstream SHAs); without it the gate degrades to a warning.

set -euo pipefail

S=${1:?usage: series-cutover.sh <series> [remote] [upstream-clone]}
remote=${2:-origin}
upstream=${3:-}

git fetch -q "$remote"

vendored_sha() {
  git log -n 10 --format=%s "$1" -- src/duckdb |
    sed -nr 's/^.*duckdb.duckdb@([0-9a-f]+)( .*)?$/\1/p' | head -n 1
}

for r in build dev green build-base; do
  git rev-parse -q --verify "refs/remotes/$remote/$S-$r" >/dev/null ||
    { echo "Error: $S-$r does not exist on $remote"; exit 1; }
  git rev-parse -q --verify "refs/remotes/$remote/$S-fwd-$r" >/dev/null ||
    { echo "Error: $S-fwd-$r does not exist on $remote"; exit 1; }
done

old_up=$(vendored_sha "refs/remotes/$remote/$S-green")
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
for r in build dev green build-base; do
  cur=$(git rev-parse "refs/remotes/$remote/$S-$r")
  new=$(git rev-parse "refs/remotes/$remote/$S-fwd-$r")
  leases+=("--force-with-lease=refs/heads/$S-$r:$cur")
  refspecs+=("+$new:refs/heads/$S-$r")
done

git push --atomic "${leases[@]}" "$remote" "${refspecs[@]}"
echo "Series $S replaced by its forward counterpart."

# Best-effort: some git proxies refuse deletions. Until these refs are gone,
# the loop ignores a forward series whose refs equal its base series.
if ! git push "$remote" ":refs/heads/$S-fwd-build" ":refs/heads/$S-fwd-dev" \
    ":refs/heads/$S-fwd-green" ":refs/heads/$S-fwd-build-base"; then
  echo "Warning: could not delete $S-fwd-* refs; remove them via the forge UI"
fi
