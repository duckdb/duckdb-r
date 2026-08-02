#!/bin/bash
# The ref motion of the series loop, stages 3 and 5, for one series:
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

# The upstream SHA a ref has vendored. The pathspec narrows the walk, the
# subject decides: commits that touch src/duckdb without vendoring are ordinary
# (the patch stack is applied to the vendored tree in place), so look past them
# — 20 deep, far more than a series stacks above its buffer, and bounded so
# git ends the walk itself rather than being killed by a closing pipe.
#
# Empty is the answer being absent, not a wrong answer: callers refuse on it,
# and the reason is on stderr for a human to act on.
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

# --- stage 5: extend -dev from the buffer ------------------------------------
# A live forward counterpart replaces this series; leftover -fwd refs whose
# green is an ancestor of ours are cutover litter and do not block.
if git rev-parse -q --verify "$remote/$S-fwd-build" >/dev/null &&
   ! git merge-base --is-ancestor "$remote/$S-fwd-green" "$green" 2>/dev/null; then
  echo "$S has a live forward counterpart — not extending"
  exit 0
fi
# Pending work does not hold the buffer (.claude/skills/series-loop.md stage 5):
# each.yaml plans every commit in green..tip that has no status, so a longer tip
# is more work planned in the same pass, not work deferred. A known failure does
# hold it: stage 2 will fold a fix into that commit and replay everything above,
# so anything appended now is minted only to be re-minted. The stage-3 walk above
# stops at the first commit without a verdict, so it sees a failure only when no
# pending commit precedes it -- scan the whole range here.
red=
while IFS= read -r sha; do
  case "$(state_of "$sha")" in
    success | missing | pending) ;;
    *) red=$sha; break ;;
  esac
done < <(git rev-list --reverse "$new_green..$dev")
if [ -n "$red" ]; then
  echo "$(git rev-parse --short "$red") has failed — repair before extending"
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
  dev_up=$(vendored_sha "$dev")
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
  #
  # Every buffer commit bumps DESCRIPTION's vendor counter, so a -dev that has
  # taken a fledge bump conflicts on the `Version:` line at the first replayed
  # commit and at every one after it. That line is what the ours-version merge
  # driver exists for; register it here as series-port.sh does, so only genuine
  # conflicts reach the judgement above.
  if [ -x "$(dirname "$0")/setup-git.sh" ]; then
    "$(dirname "$0")/setup-git.sh" >/dev/null
  fi
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
