#!/bin/bash
# The ref motion of the series loop, stages 3 and 4, for one series:
# fast-forward `<S>-green` over the all-green prefix, move `<S>-build-base` to
# the equivalent `-build` commit, and extend `<S>-dev` from the buffer.
#
# Everything here is mechanical and gated; the judgement calls (repairs,
# review) stay with the skill. Refuses to do anything when a commit in the
# in-flight range has a failure — run series-check.sh first and repair.
#
# Usage: series-advance.sh <series> [chunk-size]     # chunk default 100

set -euo pipefail

S=${1:?usage: series-advance.sh <series> [chunk-size]}
chunk=${2:-100}
remote=origin

git fetch -q "$remote"
green="$remote/$S-green"; dev="$remote/$S-dev"; build="$remote/$S-build"; base="$remote/$S-build-base"
for r in "$green" "$dev" "$build" "$base"; do
  git rev-parse -q --verify "$r" >/dev/null || { echo "Error: missing ${r#"$remote"/}"; exit 1; }
done

state_of() {
  local rec
  # Per-commit record first, aggregate as the fallback; see
  # scripts/rcc-merge.sh and the identical helper in scripts/series-check.sh.
  rec=$(git show "$remote/rcc:runs2.d/${1:0:2}/$1.ndjson" 2>/dev/null || true)
  [ -z "$rec" ] &&
    rec=$(git show "$remote/rcc:runs2.ndjson" 2>/dev/null | grep -m 1 "\"commit\": *\"$1\"" || true)
  [ -z "$rec" ] && { echo missing; return; }
  echo "$rec" | sed -nr 's/.*"status":[^}]*"state": *"([a-z]+)".*/\1/p' | head -n 1
}

vendored_sha() {
  git log -n 10 --format=%s "$1" -- src/duckdb |
    sed -nr 's/^.*duckdb.duckdb@([0-9a-f]+)( .*)?$/\1/p' | head -n 1
}

# --- stage 3: the all-green prefix -------------------------------------------
new_green=$(git rev-parse "$green")
while IFS= read -r sha; do
  st=$(state_of "$sha")
  case "$st" in
    success) new_green="$sha" ;;
    missing|pending) break ;;
    *) echo "Error: $sha is '$st' — repair before advancing"; exit 1 ;;
  esac
done < <(git rev-list --reverse "$green..$dev")

if [ "$new_green" != "$(git rev-parse "$green")" ]; then
  git merge-base --is-ancestor "$(git rev-parse "$green")" "$new_green" ||
    { echo "Error: green would not fast-forward — verified history was rewritten"; exit 1; }
  git push "$remote" "$new_green:refs/heads/$S-green"
  echo "green -> $(git rev-parse --short "$new_green")"

  up=$(vendored_sha "$new_green")
  if [ -n "$up" ]; then
    eq=$(git log --format='%H %s' "$build" | grep -m 1 "duckdb@$up" | cut -d' ' -f1 || true)
    if [ -n "$eq" ]; then
      git merge-base --is-ancestor "$base" "$eq" ||
        { echo "Error: build-base would not move forward"; exit 1; }
      git push "$remote" "$eq:refs/heads/$S-build-base"
      echo "build-base -> $(git rev-parse --short "$eq")"
    fi
  fi
else
  echo "green unchanged at $(git rev-parse --short "$green")"
fi

# --- stage 4: extend -dev from the buffer ------------------------------------
# A live forward counterpart replaces this series; leftover -fwd refs whose
# green is an ancestor of ours are cutover litter and do not block.
if git rev-parse -q --verify "$remote/$S-fwd-build" >/dev/null &&
   ! git merge-base --is-ancestor "$remote/$S-fwd-green" "$green" 2>/dev/null; then
  echo "$S has a live forward counterpart — not extending"
  exit 0
fi
if [ "$(git rev-parse "$new_green")" != "$(git rev-parse "$dev")" ]; then
  echo "in-flight work remains — not extending"
  exit 0
fi

# The consumption anchor on -build: -dev's own tip while it sits on -build's
# line, otherwise the -build commit equivalent to -dev's newest vendor commit.
# Read from the newest vendor commit rather than the tip, because -dev also
# carries commits that vendor nothing — tooling cherry-picked from main, and the
# test/R adaptations folded in during repair. Searched over all of -build, since
# the newest vendor commit may sit at or before the divergence point.
mb=$(git merge-base "$dev" "$build")
if [ "$mb" = "$(git rev-parse "$dev")" ]; then
  anchor=$mb
else
  # `-1` with a pathspec, never `head`: closing a long `git log`'s pipe kills it
  # with SIGPIPE, which `pipefail` turns into a failed assignment (141), and
  # -dev's history is thousands of commits. Every commit that touches
  # src/duckdb is a vendor commit — a repair folds into one, it never stacks.
  dev_up=$(git log -1 --format=%s "$dev" -- src/duckdb |
    sed -nr 's/^.*duckdb.duckdb@([0-9a-f]+)( .*)?$/\1/p')
  [ -n "$dev_up" ] ||
    { echo "Error: no vendor commit in -dev's history — reconcile by hand"; exit 1; }
  anchor=$(git log --format='%H %s' "$build" | grep -m 1 "duckdb@$dev_up" | cut -d' ' -f1 || true)
  [ -n "$anchor" ] ||
    { echo "Error: no -build commit vendors duckdb@$dev_up — mirror the fold in -build first"; exit 1; }
fi
ahead=$(git rev-list --count "$anchor..$build")
if [ "$ahead" -eq 0 ]; then
  echo "buffer empty — vendor"
  exit 0
fi
n=$((ahead < chunk ? ahead : chunk))
if [ "$anchor" = "$(git rev-parse "$dev")" ]; then
  next=$(git rev-list --reverse "$anchor..$build" | sed -n "${n}p")
  git push "$remote" "$next:refs/heads/$S-dev"
else
  # Replay onto the repaired tip in a throwaway worktree; a conflict means the
  # repair and the buffer touch the same paths — judgement, not mechanics.
  wt=$(mktemp -d)
  git worktree add --detach -q "$wt" "$dev"
  if ! git -C "$wt" cherry-pick $(git rev-list --reverse "$anchor..$build" | head -n "$n"); then
    git -C "$wt" cherry-pick --abort || true
    git worktree remove --force "$wt"
    echo "Error: replay conflicted — extend by hand"
    exit 1
  fi
  next=$(git -C "$wt" rev-parse HEAD)
  git worktree remove --force "$wt"
  git push "$remote" "$next:refs/heads/$S-dev"
fi
echo "dev -> $(git rev-parse --short "$next") (+$n)"
