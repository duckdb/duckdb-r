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
# **The old `-dev`'s R-side fixes ride along.** The buffer carries the vendored
# tree and the glue that compiles it; everything CI demanded afterwards -- the
# snapshot folds, the test and R-code adaptations, the `patch/` entries -- was
# folded into the equivalent commit on the old `-dev` and is invisible from
# `-build`. Replaying the buffer alone therefore drops all of it, and the loop
# rediscovers it one red commit at a time, at a CI cycle each
# (duckdb/duckdb-r#2590). So each pick is matched to the `-dev` commit vendoring
# the same upstream SHA, and the paths that commit touched which its `-build`
# twin did not are applied on top -- as one commit, because a fix belongs in the
# commit that needs it and never stacked above it.
#
# The carry is a three-way apply, so it is honest about what it cannot do: where
# the new base has moved the code the fix was written against, the run stops with
# the conflict in the tree and names both commits, exactly as a conflicting pick
# does. That is the case the skill's mining step exists for, and it is now the
# exception rather than every commit. Resolving toward the new base is a judgement
# call and stays with the caller; `--no-dev` replays the buffer alone, the old
# behaviour.
#
# Tooling paths are never carried. An adaptation folded into a vendor commit
# during repair can touch `.github/`, `scripts/` or `.claude/`, and the seed is
# current `main` -- the newest copy there is -- so carrying an older series'
# version of a workflow backwards would regress it. Those paths are dropped and
# the drop is printed, one line per commit, for a caller who wants to look.
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
# HEAD, so the replay continues where it stopped. Which half stopped -- the
# vendor pick or the R-side carry -- is remembered too, because it decides which
# commit's message the resumed run writes.
#
# scripts/series-forward-build-test.sh checks all of this offline.
#
# Usage: series-forward-build.sh [--placed <sha>]... [--dev <ref>|--no-dev] \
#          <old-build-ref> <old-base-ref>
#   old-base-ref only delimits the replay range; it has to sit below the oldest
#   vendor commit to replay, and nothing else is read from it.
#   --placed names a non-vendor commit whose change has been dealt with, once
#   per commit. The acknowledgement is remembered for the rest of the replay,
#   so a resumed run does not need it again.
#   --dev names the old `-dev` branch to carry R-side fixes from. Defaults to
#   old-build-ref with `-build` replaced by `-dev`, and the run refuses to start
#   when that does not resolve -- silently replaying without it is the bug this
#   option exists to prevent.
#   --no-dev replays the buffer alone. For a series that has no `-dev` worth
#   mining, and as the escape hatch when the carry is in the way.

set -euo pipefail

usage='usage: series-forward-build.sh [--placed <sha>]... [--dev <ref>|--no-dev] <old-build-ref> <old-base-ref>'

PLACED_ARGS=()
DEV=
NO_DEV=
while [ $# -gt 0 ]; do
  case "$1" in
    --placed) PLACED_ARGS+=("${2:?$usage}"); shift 2 ;;
    --dev) DEV=${2:?$usage}; shift 2 ;;
    --no-dev) NO_DEV=1; shift ;;
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

# The `-dev` counterpart of the buffer being replayed. Derived rather than
# required, because the pair is named by convention everywhere else in the loop;
# but never guessed away: a run that cannot find it says so and stops, since the
# failure it would otherwise produce is a forward that looks complete and is
# missing every R-side fix the base series proved.
if [ -z "$NO_DEV" ]; then
  if [ -z "$DEV" ]; then
    case "$OLD" in
      *-build) DEV=${OLD%-build}-dev ;;
      *) echo "Error: cannot derive the -dev ref from $OLD (it does not end in -build)." >&2
         echo "  Name it with --dev <ref>, or --no-dev to replay the buffer alone." >&2
         exit 1 ;;
    esac
  fi
  git rev-parse -q --verify "$DEV^{commit}" >/dev/null || {
    echo "Error: $DEV is not a commit." >&2
    echo "  It is where the R-side fixes folded during repair live, and replaying" >&2
    echo "  without them drops every one of them silently." >&2
    echo "  Name the right ref with --dev <ref>, or --no-dev to accept that." >&2
    exit 1
  }
fi

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
# recorded here instead; it is what makes a stopped replay resumable. Three
# fields: the buffer commit, its `-dev` twin (or `-`), and which half is in
# flight -- `pick` or `carry`. The last one is not cosmetic: it decides whose
# message the resumed commit gets, and a resume that guessed would write a vendor
# message over a commit that carries an R-side fix.
STATE="$(git rev-parse --git-dir)/series-forward-pick"
# The `--placed` ledger, so a resumed run does not ask again. Both files are
# removed when the replay finishes.
PLACED="$(git rev-parse --git-dir)/series-forward-placed"
# Scratch for the carried diff; never read back, so it needs no cleanup contract.
PATCH="$(git rev-parse --git-dir)/series-forward-carry.patch"

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

# --- the old -dev's R-side fixes -------------------------------------------
#
# Equivalence is by vendored upstream SHA, the same key the rest of the loop
# reads state by (.claude/skills/series-loop.md). Built once: the walk is one
# pass over a branch of a few thousand commits, against a lookup per pick.
declare -A DEV_OF=()
if [ -n "$DEV" ]; then
  devrange=$DEV
  # `-dev` and `-build` share the seed, so the same delimiter usually bounds
  # both; where it does not, walking the whole branch costs a second and is
  # never wrong.
  git merge-base --is-ancestor "$OLDBASE" "$DEV" 2>/dev/null && devrange="$OLDBASE..$DEV"
  while IFS=$'\t' read -r dc dsubj; do
    case "$dsubj" in
      vendor:* | *duckdb/duckdb@[0-9a-f]*) ;;
      *) continue ;;
    esac
    ds=$(sed -rn 's|^.*duckdb/duckdb@([0-9a-f]+).*$|\1|p' <<<"$dsubj")
    [ -n "$ds" ] || continue
    # Oldest wins. A SHA appears once in a healthy series; where a repair left
    # two, the first is the one the chain was verified on.
    [ -n "${DEV_OF[$ds]:-}" ] || DEV_OF[$ds]=$dc
  done < <(git log --reverse --format='%H%x09%s' "$devrange")
  echo "indexed ${#DEV_OF[@]} vendor commit(s) on $DEV for R-side fixes"
fi

dev_twin() { # <build-commit> -> the -dev commit vendoring the same SHA, or empty
  local s
  s=$(upstream_sha "$1")
  [ -n "$s" ] || return 0
  echo "${DEV_OF[$s]:-}"
}

# What the `-dev` twin folded in beyond vendoring: the paths its own diff touches
# that its `-build` twin's does not.
#
# A path set rather than "everything outside src/duckdb/", because the two
# commits share their glue: a fix the buffer already carries is in the pick
# already, and re-applying it would conflict with itself. Renames are expanded to
# their two sides so both spellings are comparable across the pair.
#
# DESCRIPTION is the counter's, and the tooling paths are current `main`'s -- see
# the header.
adaptation_paths() { # <build-commit> <dev-commit>
  comm -13 \
    <(git show --format= --name-only --no-renames "$1" | sort -u) \
    <(git show --format= --name-only --no-renames "$2" | sort -u) |
    grep -vxF 'DESCRIPTION' |
    grep -vE '^(\.github|scripts|\.claude)/' || true
}

tooling_paths() { # <build-commit> <dev-commit> -- what the line above dropped
  comm -13 \
    <(git show --format= --name-only --no-renames "$1" | sort -u) \
    <(git show --format= --name-only --no-renames "$2" | sort -u) |
    grep -E '^(\.github|scripts|\.claude)/' || true
}

# Apply the twin's adaptation onto the picked tree. Three-way, so the failure
# mode is a conflict in the tree rather than a silent miss: where `main` has
# moved the code the fix was written against, that is the honest answer and the
# caller resolves it.
#
# Returns 2 when there was nothing to carry, 1 on conflict, 0 when carried.
carry_adaptation() { # <build-commit> <dev-commit>
  local paths dropped
  mapfile -t paths < <(adaptation_paths "$1" "$2")
  dropped=$(tooling_paths "$1" "$2" | tr '\n' ' ')
  [ -z "$dropped" ] ||
    echo "  note: not carrying tooling paths from $(git rev-parse --short "$2"): $dropped"
  [ ${#paths[@]} -gt 0 ] || return 2
  git diff "$2^" "$2" -- "${paths[@]}" > "$PATCH"
  [ -s "$PATCH" ] || return 2
  git apply --3way --index "$PATCH" || return 1
  return 0
}

# Stamp the counter and commit the picked tree, keeping the original message and
# author; only the committer changes, as on any replay.
#
# Where an R-side fix was carried, the message is the `-dev` twin's: by the
# commit-message contract that is the vendor message plus the sections describing
# what was adapted (.claude/skills/series-loop.md), so taking it keeps the prose
# with the change it explains. A trailer names where it came from, because the
# next forward reads these messages to find what to mine.
commit_pick() { # <message-source-commit> [<carried-from-dev-commit>]
  n=$((n + 1))
  sed -i -r "s/^(Version: ).*$/\1$prefix.$n/" DESCRIPTION
  git add DESCRIPTION
  if [ -n "${2:-}" ]; then
    {
      git log -1 --format=%B "$1"
      echo "Carried from \`$DEV\` at $(git rev-parse --short "$2"):"
      echo "the R-side adaptation folded there for this same upstream commit,"
      echo "replayed with it so the forward starts from what the base proved."
    } > "$PATCH.msg"
    git commit -q --no-verify \
      --author="$(git log -1 --format='%an <%ae>' "$1")" -F "$PATCH.msg"
    rm -f "$PATCH.msg"
  else
    git commit -q --no-verify -C "$1"
  fi
  rm -f "$STATE"
}

conflict_stop() { # <build-commit> [<dev-commit-whose-carry-conflicted>]
  echo
  if [ -n "${2:-}" ]; then
    echo "Conflict carrying the R-side fix from $(git rev-parse --short "$2") into"
    echo "  $(git rev-parse --short "$1"): $(git log -1 --format=%s "$1")"
    echo
    echo "The vendored tree is picked and staged; what stopped is the adaptation"
    echo "the base series folded in for this commit. The new base has moved the"
    echo "code it was written against, so resolve toward the new base -- and read"
    echo "the whole set before deciding, because upstream moves the same call site"
    echo "repeatedly and only the last version of it survives the range:"
    echo
    echo "  scripts/series-glue.sh $OLDBASE..$OLD"
  else
    echo "Conflict at $(git rev-parse --short "$1"): $(git log -1 --format=%s "$1")"
  fi
  git diff --name-only --diff-filter=U | sed 's/^/  /'
  echo "Resolve, 'git add' them, then rerun this script to continue."
  exit 1
}

# A stopped pick left its tree in place; finish it before taking new work.
resumed=0
if [ -f "$STATE" ]; then
  read -r c d stage < "$STATE"
  [ "${d:--}" != - ] || d=
  if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    [ "${stage:-pick}" = carry ] && conflict_stop "$c" "$d"
    conflict_stop "$c"
  fi
  resumed=1
  # A carry that stopped is finished as a carry: the resolved tree holds the
  # adaptation, so the commit takes the twin's message like an unconflicted one.
  if [ "${stage:-pick}" = carry ]; then
    echo "resuming: committing the resolved carry $(git rev-parse --short "$c")"
    commit_pick "$d" "$d"
  else
    echo "resuming: committing the resolved pick $(git rev-parse --short "$c")"
    commit_pick "$c"
  fi
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

# Nothing left is a finished replay, not a no-op, when this run committed the
# last one: a resume that lands the final commit would otherwise report the
# replay as never having had anything to do, and leave its scratch behind.
if [ ${#PICKS[@]} -eq 0 ]; then
  rm -f "$PLACED" "$PATCH"
  if [ "$resumed" = 1 ]; then
    echo "DONE: replay complete -> $(git rev-parse --short HEAD)"
  else
    echo "Nothing to replay: $OLDBASE..$OLD is already on HEAD"
  fi
  exit 0
fi
echo "replaying ${#PICKS[@]} vendor commit(s) onto $(git rev-parse --short HEAD), counter at $n"

carried=0
for c in "${PICKS[@]}"; do
  d=$(dev_twin "$c")
  echo "$c ${d:--} pick" > "$STATE"
  git cherry-pick -n "$c" >/dev/null || conflict_stop "$c"

  # The pick and the carry become one commit: a fix belongs in the commit that
  # needs it, never stacked above it, so that every commit of the chain stays
  # independently green and the chain stays bisectable.
  rc=2
  if [ -n "$d" ]; then
    echo "$c $d carry" > "$STATE"
    set +e
    carry_adaptation "$c" "$d"
    rc=$?
    set -e
    [ $rc -eq 1 ] && conflict_stop "$c" "$d"
  fi
  if [ $rc -eq 0 ]; then
    carried=$((carried + 1))
    commit_pick "$d" "$d"
  else
    commit_pick "$c"
  fi
  [ $((n % 100)) -eq 0 ] && echo "$n replayed -> $(git rev-parse --short HEAD)"
done

rm -f "$PLACED" "$PATCH"
echo "DONE: ${#PICKS[@]} vendor commit(s) replayed -> $(git rev-parse --short HEAD)"
if [ -n "$DEV" ]; then
  echo "      $carried of them carried an R-side fix from $DEV"
else
  echo "      no -dev consulted (--no-dev): R-side fixes will be rediscovered by CI"
fi
