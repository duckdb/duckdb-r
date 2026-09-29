#!/bin/bash
# Populate `<S>-fwd-build`: replay every vendor commit of the old `<S>-build`
# onto HEAD, which must be the freshly flavored seed on current `main`
# (.claude/skills/series-forward/SKILL.md).
#
# The replay is a cherry-pick, not a tree reconstruction. A vendor commit's diff
# is exactly what vendoring changed -- `src/duckdb/`, the version bookkeeping,
# and the glue that commit had to adapt -- so replaying the diffs takes the whole
# of the new base for everything else, by construction: files `main` deleted stay
# deleted, tooling `main` gained comes along, and glue born on a `-dev` branch
# rides in the commit that needed it.
#
# Only `vendor:` subjects are replayed. Most of the others are `main`'s, which
# the regenerated seed already carries -- on a `-dev` branch as ports, and on a
# `-build` branch as the merges that advance the buffer's base. What is left is
# the buffer's own, chiefly the `patch/` entries stage 3 requires. So a
# non-vendor commit above the first vendor commit is checked rather than
# assumed: if the new base does not already carry its change, the run refuses to
# start and names it, because replaying the vendor commits above it would
# succeed and leave its effect silently missing (duckdb/duckdb-r#2545).
# `--placed` is how the caller says a commit has been dealt with; where such a
# change belongs is handbook/operations/vendoring/troubleshooting/README.md.
#
# The fifth version component is renumbered as a true counter, one per replayed
# commit, so it counts this chain rather than carrying the old one's numbering.
#
# The foot of the range is read from the trees rather than taken on trust, so a
# new seed vendoring a newer release than the old one needs no hand work:
#
#   * what the seed already vendors is not replayed: the range starts above the
#     vendor commit naming the engine HEAD's tree records, which is how a
#     release line forwards once `main` has vendored its release;
#   * a first pick whose old parent vendors another engine than HEAD is a
#     rewind, and takes the vendored strand whole instead of as a diff
#     (rewind_pick), which is how a line tracking upstream `main` forwards once
#     `main` has moved from one release to the next.
#
# `DESCRIPTION` merges on every commit -- the two strands advance different
# version counters -- so the `ours-version` merge driver must be registered:
# run scripts/setup-git.sh once per clone.
#
# Restartable: on a conflict the pick stops with the tree in place. Resolve,
# `git add`, and rerun; the counter and the remaining picks are derived from
# HEAD, so the replay continues where it stopped.
#
# Usage: series-forward-build.sh <old-build-ref> <old-base-ref> [--placed <sha>]...
#                                [--graft-from <ref>]
#   old-base-ref only delimits the replay range; it has to sit below the oldest
#   vendor commit to replay, and nothing else is read from it. The old seed's
#   base is always right: the script finds where the replay starts.
#   --placed names a non-vendor commit whose change has been dealt with, once
#   per commit. The acknowledgement is remembered for the rest of the replay,
#   so a resumed run does not need it again.
#   --graft-from names the forwarded buffer of the series a graft at the foot of
#   the range was cut for (graft_pick), `v2.0-cyanoptera-fwd-build` for `main`.
#   Required when the range stands on a graft, and refused otherwise.
#   --no-check-glue skips the glue gate (glue_gate), as vendor-one.sh's does.

set -euo pipefail

usage='usage: series-forward-build.sh <old-build-ref> <old-base-ref> [--placed <sha>]... [--graft-from <ref>] [--no-check-glue]'
argerr() { echo "$usage" >&2; exit 2; }

# It names two refs rather than a series, so it takes no --remote; the options
# and the exit status are the shared contract's all the same
# (handbook/operations/vendoring/series-loop/README.md).
PLACED_ARGS=()
GRAFT_FROM=
CHECK_GLUE=true
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --placed) [ $# -ge 2 ] || argerr; PLACED_ARGS+=("$2"); shift 2 ;;
    --graft-from) [ $# -ge 2 ] || argerr; GRAFT_FROM=$2; shift 2 ;;
    --no-check-glue) CHECK_GLUE=false; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 2 ] || argerr
OLD=${args[0]}
OLDBASE=${args[1]}

# The tree to replay into, the same knob vendor-one.sh takes; see series-glue.sh.
toplevel=${VENDOR_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || true)}
[ -n "$toplevel" ] || { echo "Error: $PWD is not a git worktree" >&2; exit 1; }
cd "$toplevel"

for r in "$OLD" "$OLDBASE" ${GRAFT_FROM:+"$GRAFT_FROM"}; do
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

# The engine a tree vendors, as the tree itself records it: the abbreviated
# upstream SHA the vendored `pragma_version.cpp` carries. Read from the tree
# rather than from a subject because the commits that matter here -- a seed, a
# graft -- vendor nothing and name no SHA.
engine() {
  git show "$1:src/duckdb/src/function/table/version/pragma_version.cpp" 2>/dev/null |
    sed -rn 's/^#define DUCKDB_SOURCE_ID "([0-9a-f]+)"$/\1/p'
}

# The vendored strand a rewinding pick takes whole (see rewind_pick): the
# engine's tree, the patch stack applied to it, and the two files generated
# from nothing but that tree. The Makevars are generated as well, but from
# `src/Makevars.in`, which is `main`'s, so they travel as a diff.
STRAND=(src/duckdb patch R/version.R src/include/sources.mk)

# The glue gate: the check vendor-one.sh runs after every vendor commit
# (glue_compiles() there), syntax-checking the glue against the vendored
# headers. The replay needs it for a reason vendoring never had. The old buffer
# was gated against the glue of *its* seed, and the new seed brings `main`'s
# glue as it is today, written against today's release: at the foot of a
# rewind it meets an engine older than the calls it makes, and further up an
# upstream change the old glue was adapted to reaches code the old glue never
# had. Neither conflicts, so the pick applies and the buffer stops compiling
# without a word (`CheckResultTypeForR()` against upstream's `Identifier`, in
# the first replay that met it).
#
# It runs where a break is likely rather than on every pick, because a check
# costs most of a minute: after a rewind or a graft, after every pick whose old
# commit adapted glue -- those are the upstream changes the glue noticed -- and
# once at the end. A break it finds may therefore be older than HEAD; it names
# the last commit that passed, which bounds the search.
GLUE_STATE="$(git rev-parse --git-dir)/series-forward-glue"
GLUE_BROKEN="$(git rev-parse --git-dir)/series-forward-glue-broken"
glue_failures="$(git rev-parse --git-dir)/series-forward-glue-failures"

glue_compile_flags() {
  [ -f src/Makevars.rstrtmgr ] || ./configure >/dev/null 2>&1
  (cd src && R CMD SHLIB -n cpp11.cpp 2>/dev/null) |
    grep -m 1 -E -- '-c cpp11\.cpp' |
    sed -E 's/^ *(ccache )?g\+\+ //; s/ -c cpp11\.cpp -o cpp11\.o *$//'
}

glue_compiles() { # 0 compiles, 1 some file does not, 2 the check could not run
  local flags
  flags=$(glue_compile_flags)
  [ -n "$flags" ] || return 2
  (cd src && printf '%s\n' *.cpp | FLAGS="$flags" xargs -P "$(nproc 2>/dev/null || echo 4)" -I{} \
    sh -c 'eval "g++ $FLAGS -fsyntax-only \"\$1\"" 2>/dev/null || echo "$1"' sh {}) | sort |
    tee "$glue_failures" |
    { ! grep -q .; }
}

touches_strand() { git show --format= --name-only "$1" -- "${STRAND[@]}" | grep -q .; }

touches_glue() {
  git show --format= --name-only "$1" -- src ':(exclude)src/duckdb' \
    ':(exclude)src/include/sources.mk' ':(exclude)src/Makevars' ':(exclude)src/Makevars.win' | grep -q .
}

glue_gate() { # <why>
  [ "$CHECK_GLUE" = true ] || return 0
  local st=0 last=
  glue_compiles || st=$?
  case "$st" in
    0) git rev-parse HEAD > "$GLUE_STATE"; rm -f "$GLUE_BROKEN"; return 0 ;;
    2)
      echo "Error: the glue check could not run at $(git rev-parse --short HEAD) ($1):"
      echo "  deriving the compile flags needs src/Makevars.rstrtmgr, which ./configure writes;"
      echo "  run ./configure and read its output, or pass --no-check-glue"
      exit 6
      ;;
  esac
  [ -f "$GLUE_STATE" ] && last=$(git rev-parse --short "$(cat "$GLUE_STATE")")
  git rev-parse HEAD > "$GLUE_BROKEN"
  echo
  echo "=== GLUE BROKEN at $(git rev-parse --short HEAD): $(git log -1 --format=%s HEAD)"
  echo "Checked after $1. Files: $(tr '\n' ' ' < "$glue_failures")"
  [ -n "$last" ] && echo "The glue last compiled at $last; the break is in $last..HEAD."
  echo "Fix the glue in the commit that broke it, clang-format, amend with an"
  echo "'R-side fix' section, replay anything above it, and rerun this script."
  exit 3
}

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
# Three tests, because each sees what the others miss, and a false alarm costs
# one `--placed` while a miss costs a wrong forward:
#
#   * ancestry -- about the commit, and the only one of the three that cannot be
#     wrong: a commit the new base descends from is in the new base, whatever
#     later commits did to the lines it touched. The content tests cannot see
#     that, so `main`'s own commits strand whenever the base has moved past the
#     shape they left -- a `fledge:` bump the base has bumped a hundred times
#     since, a `NEWS.md` section it has rewritten. Replaying a range that
#     reached back to the parent series' 2024 seed stranded 906 such commits,
#     903 of them plain ancestors of the base;
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
  git merge-base --is-ancestor "$1" HEAD 2>/dev/null && return 0
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

# A pick whose old parent vendors another engine than HEAD is a rewind: the
# foot of a range that walks from a released engine back to where the line
# forks, `v1.5.5` down to `main`'s January fork point. Its diff is taken against
# the engine the *old* seed vendored, so once the new seed vendors a newer
# release it lays one release's delta over another's tree, and conflicts in
# hundreds of files. Its result does not depend on that engine, though: the
# strand it lands on is upstream's tree at the commit it names, with the patch
# stack the base series carried there. So the strand is taken whole from the
# commit, and only the rest of its diff -- the glue that rewind had to adapt --
# is replayed, where `main`'s drift is a conflict like any other.
#
# The patches the new seed carries and the old one did not are dropped with the
# rest of the seed's strand. Every one was written against the released engine,
# and the base series never had them at this commit; the strand stays equal to
# the base buffer's, which is what the tree check after the replay reads.
rewind_pick() { # <commit>
  echo "rewind: $(git rev-parse --short "$1") lands on $(engine "$1"), from $(engine "$1~1");" \
    "HEAD vendors $(engine HEAD), so the strand is taken whole"
  strand_pick "$1" "$1~1" "$1"
}

# Take the strand whole from <tree>, and replay <from>..<to> for everything else
# but `DESCRIPTION`, whose counter commit_pick stamps. A conflict is left in the
# tree for conflict_stop, like a pick's.
strand_pick() { # <tree> <from> <to>
  local p paths=() excludes=() diff
  for p in "${STRAND[@]}"; do
    git cat-file -e "$1:$p" 2>/dev/null && paths+=("$p")
    excludes+=(":(exclude)$p")
  done
  git rm -rq --ignore-unmatch -- "${STRAND[@]}"
  git checkout "$1" -- "${paths[@]}"
  diff=$(mktemp)
  git diff --binary "$2" "$3" -- . ':(exclude)DESCRIPTION' "${excludes[@]}" > "$diff"
  [ -s "$diff" ] || { rm -f "$diff"; return 0; }
  git apply --3way --index "$diff" || { rm -f "$diff"; return 1; }
  rm -f "$diff"
}

# A range standing on a graft has no seed below it. An opening re-roots the
# parent series on one commit whose tree is the fork point's, verbatim
# (.claude/skills/series-open/SKILL.md step 5), so that commit carries the glue
# of every vendor commit below the fork point, and none of them is in the range
# any more: they belong to the series the opening cut. A rewind of the first
# pick would take its strand and leave all of that glue behind, which is 108
# compile errors against a 2.0 engine (plan/PLAN-v2-series-open.md).
#
# That series owns the history, so its forward has already replayed it onto the
# new `main` and resolved every conflict on the way. The graft is rebuilt from
# there, as one vendor commit: the strand is the graft's, and the rest is what
# the forwarded buffer changed between its own seed and the commit vendoring the
# fork point. `--graft-from` names that buffer.
is_graft() { git log -1 --format=%s "$1" | grep -q '^graft:'; }

# <engine> -> "<commit vendoring it on GRAFT_FROM> <that buffer's seed tip>"
graft_source() {
  local e=$1 base c subj seed='' f='' inside=''
  base=$(git merge-base "$GRAFT_FROM" HEAD) || return 0
  while IFS=$'\t' read -r c subj; do
    case "$subj" in
      vendor:*)
        [ -n "$seed" ] || seed=$(git rev-parse "$c~1")
        [ -n "$inside" ] && break
        [[ "$(upstream_sha "$c")" == "$e"* ]] && { f=$c; inside=1; }
        ;;
      *) [ -n "$inside" ] && f=$c ;;
    esac
  done < <(git log --reverse --first-parent --format='%H%x09%s' "$base..$GRAFT_FROM")
  if [ -n "$f" ]; then echo "$f $seed"; fi
}

graft_pick() { # <graft> <commit vendoring its engine on GRAFT_FROM> <that buffer's seed tip>
  echo "graft: $(git rev-parse --short "$1") holds $(engine "$1") as a tree;" \
    "rebuilding it from $GRAFT_FROM, $(git rev-parse --short "$3")..$(git rev-parse --short "$2")"
  strand_pick "$1" "$3" "$2"
}

commit_graft() { # <graft> <commit vendoring its engine on GRAFT_FROM> <seed tip> <GRAFT_FROM>
  n=$((n + 1))
  sed -i -r "s/^(Version: ).*$/\1$prefix.$n/" DESCRIPTION
  git add DESCRIPTION
  git commit -q --no-verify -F - <<MSG
vendor: Update vendored sources to duckdb/duckdb@$(upstream_sha "$2")

The fork point, which the old buffer held as a graft,
\`$(git log -1 --format=%s "$1")\` ($(git rev-parse --short "$1")),
rebuilt as a vendor commit on this seed.

The vendored strand is the graft's, verbatim.
Everything else is what \`$4\` changed between its seed
($(git rev-parse --short "$3")) and the commit that vendors the fork point
($(git rev-parse --short "$2")): the glue of every commit below the fork point,
replayed onto the same \`main\` by the forward of the series that owns them,
which resolved each conflict there, once.
MSG
  rm -f "$STATE"
}

# A stopped pick left its tree in place; finish it before taking new work.
if [ -f "$STATE" ]; then
  read -r c g f s from < "$STATE"
  if [ "$c" = graft ]; then
    [ -z "$(git diff --name-only --diff-filter=U)" ] || conflict_stop "$g"
    echo "resuming: committing the resolved graft $(git rev-parse --short "$g")"
    commit_graft "$g" "$f" "$s" "$from"
    glue_gate "a resolved graft"
  else
    [ -z "$(git diff --name-only --diff-filter=U)" ] || conflict_stop "$c"
    echo "resuming: committing the resolved pick $(git rev-parse --short "$c")"
    commit_pick "$c"
    glue_gate "a resolved conflict"
  fi
fi

[ -z "$(git status --porcelain)" ] || { echo "Error: working directory not clean"; exit 1; }

# A run that stopped on the gate left HEAD for an amend; check it again first.
[ -f "$GLUE_BROKEN" ] && glue_gate "the amend of a broken commit"

# Everything already replayed sits in the last $n commits, one per counter step.
DONE=" $(git log -n "$n" --format=%H HEAD | while read -r c; do upstream_sha "$c"; done | tr '\n' ' ')"

# What HEAD already vendors is not replayed, and neither is anything below it.
# A range may start above the old base where the new base vendors the commit it
# starts at, and nowhere else (.claude/skills/series-forward/SKILL.md): a
# release line whose release `main` has since vendored is that case, and so is a
# resumed replay, where DONE already says the same.
base_engine=$(engine HEAD)

PICKS=()
OWN=()
seen_vendor=
foot=''
while IFS=$'\t' read -r c subj; do
  case "$subj" in
    vendor:*)
      [ -n "$seen_vendor" ] || foot=$(git rev-parse "$c~1")
      seen_vendor=1
      if [ -n "$base_engine" ] && [[ "$(upstream_sha "$c")" == "$base_engine"* ]]; then
        PICKS=()
        continue
      fi
      case "$DONE" in *" $(upstream_sha "$c") "*) continue ;; esac
      PICKS+=("$c")
      ;;
    *)
      # Below the first vendor commit is the old seed, which is regenerated
      # rather than replayed. Above it, a non-vendor commit is the buffer's own
      # work, and the replay has no place to put it.
      [ -n "$seen_vendor" ] || continue
      placed "$c" && continue
      OWN+=("$c")
      ;;
  esac
done < <(git log --reverse --format='%H%x09%s' "$OLDBASE..$OLD")

# A replay that opens on a rewind (rewind_pick) drops the seed's strand for the
# base buffer's, so the seed is no evidence about a change to the strand: a
# `patch/` entry the base buffer carried onto a 2.0 engine reverse-applies to
# the seed whenever `main` carries the same entry for its release, and the
# rewind then takes it out again. Only ancestry still answers there.
#
# The graft is rebuilt once, as the first commit: a replay whose counter has
# left the seed's `.0` has it already, and a resumed run passing the same
# `--graft-from` carries on.
rewinds='' graft=''
if [ ${#PICKS[@]} -gt 0 ] && [ "$(engine "${PICKS[0]}~1")" != "$(engine HEAD)" ]; then
  rewinds=1
fi
if [ -n "$foot" ] && is_graft "$foot" && [ "$n" -eq 0 ]; then
  graft=$foot
  rewinds=1
fi
if [ -n "$graft" ] && [ -z "$GRAFT_FROM" ]; then
  echo "Error: $OLDBASE..$OLD stands on a graft, $(git rev-parse --short "$graft"):" \
    "$(git log -1 --format=%s "$graft")" >&2
  echo "  Its tree carries the glue of the series it was cut for; forward that series" >&2
  echo "  first and name its buffer with --graft-from <S>-fwd-build." >&2
  exit 1
fi
if [ -n "$GRAFT_FROM" ] && ! { [ -n "$foot" ] && is_graft "$foot"; }; then
  echo "Error: --graft-from given, but $OLDBASE..$OLD does not stand on a graft" >&2
  exit 1
fi
STRANDED=()
for c in ${OWN+"${OWN[@]}"}; do
  if [ -n "$rewinds" ] && touches_strand "$c"; then
    git merge-base --is-ancestor "$c" HEAD 2>/dev/null && continue
  else
    in_base "$c" && continue
  fi
  STRANDED+=("$c")
done

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

Already carried is a real outcome, not an excuse: this refuses on the
cheap tests it has, so a change the new base holds in a shape none of them
recognises is listed here too. Confirm one by reading the base for its effect,
not by assuming either way.
EOF
  exit 1
fi

[ ${#PICKS[@]} -gt 0 ] || {
  rm -f "$PLACED" "$GLUE_STATE" "$glue_failures"
  echo "Nothing to replay: $OLDBASE..$OLD is already on HEAD"
  exit 0
}
echo "replaying ${#PICKS[@]} vendor commit(s) onto $(git rev-parse --short HEAD), counter at $n"

if [ -n "$graft" ]; then
  src=$(graft_source "$(engine "$graft")")
  [ -n "$src" ] ||
    { echo "Error: $GRAFT_FROM vendors nothing at $(engine "$graft"), the graft's fork point"; exit 1; }
  read -r f s <<<"$src"
  echo "graft $graft $f $s $GRAFT_FROM" > "$STATE"
  graft_pick "$graft" "$f" "$s" || conflict_stop "$graft"
  commit_graft "$graft" "$f" "$s" "$GRAFT_FROM"
  glue_gate "the graft"
fi

for c in "${PICKS[@]}"; do
  echo "$c" > "$STATE"
  if [ "$(engine "$c~1")" != "$(engine HEAD)" ]; then
    rewind_pick "$c" || conflict_stop "$c"
    commit_pick "$c"
    glue_gate "the rewind"
  else
    git cherry-pick -n "$c" >/dev/null || conflict_stop "$c"
    commit_pick "$c"
    touches_glue "$c" && glue_gate "a pick that adapted glue"
  fi
  [ $((n % 100)) -eq 0 ] && echo "$n replayed -> $(git rev-parse --short HEAD)"
done

glue_gate "the last pick"
rm -f "$PLACED" "$GLUE_STATE" "$GLUE_BROKEN" "$glue_failures"
echo "DONE: ${#PICKS[@]} vendor commit(s) replayed -> $(git rev-parse --short HEAD)"
