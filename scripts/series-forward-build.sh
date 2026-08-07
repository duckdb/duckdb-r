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
# Only `vendor:` subjects are replayed. On a `-dev` branch the other commits
# belong to `main` and the regenerated seed already carries them; on a `-build`
# branch they do not, because the buffer takes no ports -- the `patch/` entries
# stage 3 requires be committed onto it are its own. So a non-vendor commit
# above the first vendor commit is checked rather than assumed: if the new base
# does not already carry its change, the run refuses to start and names it,
# because replaying the vendor commits above it would succeed and leave its
# effect silently missing (duckdb/duckdb-r#2545). `--placed` is how the caller
# says a commit has been dealt with; where such a change belongs is
# handbook/operations/vendoring/troubleshooting/README.md.
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
# Usage: series-forward-build.sh [--placed <sha>]... <old-build-ref> <old-base-ref>
#   old-base-ref only delimits the replay range; it has to sit below the oldest
#   vendor commit to replay, and nothing else is read from it.
#   --placed names a non-vendor commit whose change has been dealt with, once
#   per commit. The acknowledgement is remembered for the rest of the replay,
#   so a resumed run does not need it again.

set -euo pipefail

usage='usage: series-forward-build.sh [--placed <sha>]... <old-build-ref> <old-base-ref>'

PLACED_ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --placed) PLACED_ARGS+=("${2:?$usage}"); shift 2 ;;
    -*) echo "$usage" >&2; exit 1 ;;
    *) break ;;
  esac
done

OLD=${1:?$usage}
OLDBASE=${2:?$usage}

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
# The `--placed` ledger, so a resumed run does not ask again. Both files are
# removed when the replay finishes.
PLACED="$(git rev-parse --git-dir)/series-forward-placed"

for p in ${PLACED_ARGS+"${PLACED_ARGS[@]}"}; do
  git rev-parse -q --verify "$p^{commit}" >/dev/null ||
    { echo "Error: --placed $p is not a commit"; exit 1; }
  git rev-parse "$p^{commit}" >> "$PLACED"
done
placed() { [ -f "$PLACED" ] && grep -qx "$1" "$PLACED"; }

# Is this commit's change already in the tree the replay is building on?
# Two tests, because each sees what the other misses, and a false alarm costs
# one `--placed` while a miss costs a wrong forward:
#
#   * reverse-applying the commit's own diff -- about content, so it holds when
#     `main` landed the same change under another subject or bundled with more
#     (patch/0034, carried onto the buffer alone and onto `main` inside a larger
#     commit);
#   * patch-id equality against what the new base gained -- about the change,
#     so it holds when the file has moved on since and the context no longer
#     matches (the jemalloc filter in `scripts/rconfigure.py`).
#
# `git cherry` marks a commit `-` when the base carries an equivalent patch.
CHERRY=$(git cherry HEAD "$OLD" "$OLDBASE" 2>/dev/null | sed -n 's/^- //p' || true)
in_base() {
  git show --format= "$1" | git apply --reverse --check - 2>/dev/null && return 0
  grep -qx "$1" <<<"$CHERRY"
}

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
STRANDED=()
seen_vendor=
while IFS=$'\t' read -r c subj; do
  case "$subj" in
    vendor:*)
      seen_vendor=1
      case "$DONE" in *" $(upstream_sha "$c") "*) continue ;; esac
      PICKS+=("$c")
      ;;
    *)
      # Below the first vendor commit is the old seed, which is regenerated
      # rather than replayed. Above it, a non-vendor commit is the buffer's own
      # work, and the replay has no place to put it.
      [ -n "$seen_vendor" ] || continue
      placed "$c" && continue
      in_base "$c" && continue
      STRANDED+=("$c")
      ;;
  esac
done < <(git log --reverse --format='%H%x09%s' "$OLDBASE..$OLD")

if [ ${#STRANDED[@]} -gt 0 ]; then
  echo "Error: ${#STRANDED[@]} commit(s) in $OLDBASE..$OLD vendor nothing," >&2
  echo "  and the new base does not carry their change:" >&2
  for c in "${STRANDED[@]}"; do
    echo >&2
    echo "  $(git rev-parse --short "$c")  $(git log -1 --format=%s "$c")" >&2
    git show --stat=76 --format= "$c" | sed '/^$/d; s/^/    /' >&2
  done
  cat >&2 <<EOF

Replaying only the vendor commits would leave these out, and it would do it
without a conflict: a vendor diff taken after such a change landed is neutral
in the region it touched, so it applies to a tree that lacks it and the region
stays as it was. Nothing has been replayed yet.

Decide where each change belongs -- usually the commit that first needs it, not
the one it was written at; see handbook/operations/vendoring/troubleshooting/,
"Where a patch goes in the chain". Then rerun with one --placed per commit:

  scripts/series-forward-build.sh$(for c in "${STRANDED[@]}"; do
      printf ' --placed %s' "$(git rev-parse --short "$c")"; done) $OLD $OLDBASE

--placed says the change has been dealt with, whether by folding it into a
commit this replay will produce -- fold after the replay reaches it, so the
counter this script reads back from HEAD keeps matching the commits it wrote --
or by judging it already carried, or obsolete. It is remembered for the rest of
the replay.

Already carried is a real outcome, not an excuse: this refuses on the two
cheap tests it has, so a change the new base holds in a shape neither
recognises is listed here too. Confirm one by reading the base for its effect,
not by assuming either way.
EOF
  exit 1
fi

[ ${#PICKS[@]} -gt 0 ] || { echo "Nothing to replay: $OLDBASE..$OLD is already on HEAD"; exit 0; }
echo "replaying ${#PICKS[@]} vendor commit(s) onto $(git rev-parse --short HEAD), counter at $n"

for c in "${PICKS[@]}"; do
  echo "$c" > "$STATE"
  git cherry-pick -n "$c" >/dev/null || conflict_stop "$c"
  commit_pick "$c"
  [ $((n % 100)) -eq 0 ] && echo "$n replayed -> $(git rev-parse --short HEAD)"
done

rm -f "$PLACED"
echo "DONE: ${#PICKS[@]} vendor commit(s) replayed -> $(git rev-parse --short HEAD)"
