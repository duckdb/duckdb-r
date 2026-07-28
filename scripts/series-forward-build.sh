#!/bin/bash
# Populate `<S>-fwd-build`: replay every vendor commit of the old `<S>-build`
# onto HEAD, which must be the freshly flavored pair on current `main`
# (.claude/skills/series-forward.md).
#
# Ownership split per commit: everything the chain owns comes from the old
# commit's tree (the vendored sources, the glue, the patch stack, the version
# files); every path `main` changed since the old base is restored from HEAD's
# state; files deleted on `main` are dropped; `.github` is restored wholesale
# rather than file by file, so a pruned workflow never resurrects. The fifth
# version component is renumbered onto HEAD's four-component prefix.
#
# Usage: series-forward-build.sh <old-build-ref> <old-base-ref>
#   old-base-ref is the `main` commit the old series was built on
#   (git merge-base <old-build-ref> main).

set -euo pipefail

OLD=${1:?usage: series-forward-build.sh <old-build-ref> <old-base-ref>}
OLDBASE=${2:?usage: series-forward-build.sh <old-build-ref> <old-base-ref>}

cd "$(dirname "$0")/.."
WF=$(git rev-parse HEAD)

prefix=$(sed -rn 's/^Version: ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(\.[0-9]+)?$/\1/p' DESCRIPTION)
[ -n "$prefix" ] ||
  { echo "Error: HEAD's DESCRIPTION has no four-component version prefix (seed the series first)"; exit 1; }

# The chain owns the package sources and their version bookkeeping; main owns
# the rest. Tests and snapshots are main-owned here: a -build branch carries
# glue fixes only, and test amendments live on -dev.
owned() {
  case "$1" in
    src/*|patch/*|DESCRIPTION|R/version.R|R/cpp11.R) return 0 ;;
  esac
  return 1
}

RESTORE=()
DROP=()
while IFS= read -r f; do
  owned "$f" && continue
  case "$f" in .github/*) continue ;; esac
  if git cat-file -e "$WF:$f" 2>/dev/null; then RESTORE+=("$f"); else DROP+=("$f"); fi
done < <(git diff --name-only "$OLDBASE" "$WF")
echo "restoring ${#RESTORE[@]} path(s), dropping ${#DROP[@]}, .github wholesale"

n=0
while IFS=$'\t' read -r c subj; do
  case "$subj" in vendor:*) ;; *) continue ;; esac
  n=$((n + 1))
  git read-tree --reset -u "$c"
  rm -rf .github
  git checkout "$WF" -- .github "${RESTORE[@]}"
  for f in "${DROP[@]}"; do rm -f "$f"; done
  sed -i -r "s/^(Version: ).*$/\1$prefix.$n/" DESCRIPTION
  git add -A
  git commit -q --no-verify --file <(git log -1 --format=%B "$c")
  [ $((n % 100)) -eq 0 ] && echo "$n replayed -> $(git rev-parse --short HEAD)"
done < <(git log --reverse --format='%H%x09%s' "$OLDBASE..$OLD")

echo "DONE: $n vendor commit(s) replayed -> $(git rev-parse --short HEAD)"
