#!/bin/bash
# Populate `<S>-fwd-build`: replay every vendor commit of the old `<S>-build`
# onto HEAD, which must be the freshly flavored seed on current `main`
# (.claude/skills/series-forward.md).
#
# The replay is a cherry-pick, not a tree reconstruction. A vendor commit's diff
# is exactly what vendoring changed -- `src/duckdb/`, the version bookkeeping,
# and the glue that commit had to adapt -- so replaying the diffs takes the whole
# of the new base for everything else, by construction: files `main` deleted stay
# deleted, tooling `main` gained comes along, and glue born on a `-dev` branch
# rides in the commit that needed it.
#
# Only `vendor:` subjects are replayed: a `-dev` branch's non-vendor commits
# belong to `main` and are already in the seed.
#
# The fifth version component is renumbered as a true counter, one per replayed
# commit, so it counts this chain rather than carrying the old one's numbering.
#
# `DESCRIPTION` merges on every commit -- the two strands advance different
# version counters -- so the `ours-version` merge driver must be registered:
# run scripts/setup-git.sh once per clone.
#
# Restartable: on a conflict the pick stops with the tree in place. Resolve,
# `git add`, and rerun; the counter and the remaining picks are derived from
# HEAD, so the replay continues where it stopped.
#
# Usage: series-forward-build.sh <old-build-ref> <old-base-ref>
#   old-base-ref only delimits the replay range; it has to sit below the oldest
#   vendor commit to replay, and nothing else is read from it.

set -euo pipefail

OLD=${1:?usage: series-forward-build.sh <old-build-ref> <old-base-ref>}
OLDBASE=${2:?usage: series-forward-build.sh <old-build-ref> <old-base-ref>}

cd "$(dirname "$0")/.."

for r in "$OLD" "$OLDBASE"; do
  git rev-parse -q --verify "$r^{commit}" >/dev/null ||
    { echo "Error: $r is not a commit"; exit 1; }
done

git config --get merge.ours-version.driver >/dev/null ||
  { echo "Error: merge driver not registered, run scripts/setup-git.sh"; exit 1; }

version() { sed -rn 's/^Version: (.*)$/\1/p' DESCRIPTION; }

# The counter is state, read back from the tree: the seed stamps `.0` and every
# replayed commit stamps the next number, so HEAD says how far the replay got.
prefix=$(version | sed -rn 's/^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+$/\1/p')
n=$(version | sed -rn 's/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\.([0-9]+)$/\1/p')
[ -n "$prefix" ] ||
  { echo "Error: HEAD's DESCRIPTION has no five-component version (seed the series first)"; exit 1; }

upstream_sha() { git log -1 --format=%s "$1" | sed -rn 's|^.*duckdb/duckdb@([0-9a-f]+).*$|\1|p'; }

# `git cherry-pick -n` leaves no CHERRY_PICK_HEAD, so the in-flight pick is
# recorded here instead; it is what makes a stopped replay resumable.
STATE="$(git rev-parse --git-dir)/series-forward-pick"

# Stamp the counter and commit the picked tree, keeping the original message and
# author; only the committer changes, as on any replay.
commit_pick() {
  n=$((n + 1))
  sed -i -r "s/^(Version: ).*$/\1$prefix.$n/" DESCRIPTION
  git add DESCRIPTION
  git commit -q --no-verify -C "$1"
  rm -f "$STATE"
}

conflict_stop() {
  echo
  echo "Conflict at $(git rev-parse --short "$1"): $(git log -1 --format=%s "$1")"
  git diff --name-only --diff-filter=U | sed 's/^/  /'
  echo "Resolve, 'git add' them, then rerun this script to continue."
  exit 1
}

# A stopped pick left its tree in place; finish it before taking new work.
if [ -f "$STATE" ]; then
  c=$(cat "$STATE")
  [ -z "$(git diff --name-only --diff-filter=U)" ] || conflict_stop "$c"
  echo "resuming: committing the resolved pick $(git rev-parse --short "$c")"
  commit_pick "$c"
fi

[ -z "$(git status --porcelain)" ] || { echo "Error: working directory not clean"; exit 1; }

# Everything already replayed sits in the last $n commits, one per counter step.
DONE=" $(git log -n "$n" --format=%H HEAD | while read -r c; do upstream_sha "$c"; done | tr '\n' ' ')"

PICKS=()
while IFS=$'\t' read -r c subj; do
  case "$subj" in vendor:*) ;; *) continue ;; esac
  case "$DONE" in *" $(upstream_sha "$c") "*) continue ;; esac
  PICKS+=("$c")
done < <(git log --reverse --format='%H%x09%s' "$OLDBASE..$OLD")

[ ${#PICKS[@]} -gt 0 ] || { echo "Nothing to replay: $OLDBASE..$OLD is already on HEAD"; exit 0; }
echo "replaying ${#PICKS[@]} vendor commit(s) onto $(git rev-parse --short HEAD), counter at $n"

for c in "${PICKS[@]}"; do
  echo "$c" > "$STATE"
  git cherry-pick -n "$c" >/dev/null || conflict_stop "$c"
  commit_pick "$c"
  [ $((n % 100)) -eq 0 ] && echo "$n replayed -> $(git rev-parse --short HEAD)"
done

echo "DONE: ${#PICKS[@]} vendor commit(s) replayed -> $(git rev-parse --short HEAD)"
