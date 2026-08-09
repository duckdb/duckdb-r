#!/bin/bash
# The ref motion of the series loop, stages 3 and 5, for one series:
# fast-forward `<S>-green` over the all-green prefix, set `<S>-build-base` to
# the equivalent `-build` commit, and extend `<S>-dev` from the buffer.
#
# Everything here is mechanical and gated; the judgement calls (repairs,
# review) stay with the skill. Refuses to do anything when a commit in the
# in-flight range has a failure — run series-check.sh first and repair.
#
# **Stage 5 carries the base series' fixes** onto a forward series as it
# consumes its buffer. The two branches divide by how far a fix was demanded:
# `-build` holds what the code needs to **compile**, because that is what the
# vendor gate checks at every commit, and `-dev` holds everything CI asked for
# after that -- snapshots, test files, R code, and the glue a test or a check
# turned out to need. A forward's `-fwd-build` was replayed out of the base
# buffer, so it has the first and none of the second, and every one of those
# fixes would be rediscovered as a red commit, at a repair plus a replay of
# everything above it. The base `<S>-dev` proved them already, against the same
# upstream commit; this folds them into the commit that needs them as it is
# minted (duckdb/duckdb-r#2594).
#
# What carries is the **difference** between the twin and its `-build` commit,
# not an allow-list of directories. `src/` is not compile-only territory: the
# buffer already compiles, so glue the `-dev` twin has on top of it was demanded
# by something later than the compiler, and holding it back would strand exactly
# the fixes this exists to move. Taking the difference is also what keeps the
# glue the buffer already carries from being applied twice.
#
# Two kinds are excluded, and neither is a judgement about the fix: the buffer's
# own strand (`src/duckdb/`, `patch/` -- a forward regenerates the tree from its
# own patches) and what vendoring regenerates (`R/version.R`,
# `src/include/sources.mk`, the Makevars, the logos), which differs between any
# two vendor runs of the same SHA and is noise wearing the shape of a fix.
# Carried glue is reported as it goes, because glue the base `-dev` has and the
# base `-build` lacks is buffer drift and wants mirroring there.
#
# **This stage is attended.** A carry the series has moved out from under stops
# the run with the conflict in a worktree that is kept, because resolving it is
# judgement and guessing costs a wrong commit on a chain CI is about to judge.
# `--continue` picks the run up where it stopped; `--abort` throws the worktree
# away and leaves the refs untouched.
#
# Usage: series-advance.sh <series> [chunk-size]     # chunk default 100
#        series-advance.sh <series> --continue       # after resolving a stop
#        series-advance.sh <series> --abort          # discard a stopped replay

set -euo pipefail

usage='usage: series-advance.sh <series> [chunk-size | --continue | --abort]'
S=${1:?$usage}
CONTINUE=
ABORT=
chunk=100
case "${2:-}" in
  '') ;;
  --continue) CONTINUE=1 ;;
  --abort) ABORT=1 ;;
  -*) echo "$usage" >&2; exit 1 ;;
  *) chunk=$2 ;;
esac
remote=origin
rcc=${RCC_BRANCH:-rcc2}

# A stopped stage 5 lives here: the worktree it kept, the buffer commit whose
# replay stopped, its base twin, and which half stopped -- `pick` or `carry`.
# Per series, so one stopped series never blocks the firing's other ones.
STATE="$(git rev-parse --git-dir)/series-advance-${S//\//-}"

if [ -n "$ABORT" ]; then
  if [ -f "$STATE" ]; then
    read -r awt _ _ _ < "$STATE"
    [ -d "$awt" ] && git worktree remove --force "$awt"
    rm -f "$STATE"
    echo "$S: stopped replay discarded; no ref was written"
  else
    echo "$S: nothing to abort"
  fi
  exit 0
fi

git fetch -q "$remote"
green="$remote/$S-green"; dev="$remote/$S-dev"; build="$remote/$S-build"; base="$remote/$S-build-base"
for r in "$green" "$dev" "$build" "$base"; do
  git rev-parse -q --verify "$r" >/dev/null || { echo "Error: missing ${r#"$remote"/}"; exit 1; }
done

# The first N lines, without closing the pipe on the writer. `head -n N` exits
# as soon as it has them, and the `git rev-list` feeding it dies of SIGPIPE --
# 141 through `pipefail`, which `set -e` turns into a silent abort of the whole
# stage. Only a buffer longer than the chunk ever reaches that, which is why it
# surfaced on main-fwd and on no other series.
first_n() { sed -n "1,${1}p"; }

state_of() {
  local rec
  # One record per commit, and only that; see scripts/rcc-lib.sh and the
  # identical helper in scripts/series-check.sh.
  rec=$(git show "$remote/$rcc:runs2.d/${1:0:2}/$1.ndjson" 2>/dev/null || true)
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

# Does this commit vendor? The subject decides, never the path -- the same rule
# the rest of this loop reads state by, and the same predicate series-port.sh
# classifies with. Matched without a pipe, so `pipefail` cannot turn a match
# into a miss when the reader closes first.
vendors() { # <repo> <commit>
  case "$(git -C "$1" log -1 --format=%s "$2")" in
    vendor:* | *duckdb/duckdb@[0-9a-f]*) return 0 ;;
    *) return 1 ;;
  esac
}

# Is $1 a strictly greater version than $2? Component-wise and numeric, so a
# rise the invariant allows is not mistaken for a freeze: a bump in any
# component counts, and the components are compared as numbers rather than as
# text (`10` is above `9`). A non-numeric component makes the answer unknown,
# which is a refusal, not a pass.
version_gt() { # <a> <b>
  local -a x y
  case "$1" in '' | *[!0-9.]*) return 2 ;; esac
  case "$2" in '' | *[!0-9.]*) return 2 ;; esac
  IFS=. read -r -a x <<<"$1"
  IFS=. read -r -a y <<<"$2"
  local i
  for i in 0 1 2 3 4; do
    (( ${x[i]:-0} > ${y[i]:-0} )) && return 0
    (( ${x[i]:-0} < ${y[i]:-0} )) && return 1
  done
  return 1
}

# Raise DESCRIPTION's fifth component to one above the parent's, on a commit
# that vendors. Every vendor commit must be strictly above its parent
# (.claude/skills/series-loop.md): gaps are fine, repeats are not, because
# r-universe installs by version and cannot tell a run of commits sharing one
# apart.
#
# The ours-version merge driver hands the pick our side of `Version:` whenever
# the two strands' `major.minor.patch` prefixes differ, which is what this
# repairs; where they agree, -build's own bump comes through and there is
# nothing to do.
restamp() { # <worktree> <buffer commit>
  local wt=$1 c=$2 parent cur new
  vendors . "$c" || return 0
  parent=$(git -C "$wt" show 'HEAD~1:DESCRIPTION' | sed -n 's/^Version: //p')
  cur=$(git -C "$wt" show 'HEAD:DESCRIPTION' | sed -n 's/^Version: //p')
  version_gt "$cur" "$parent" && return 0
  # The counter is the fifth component, and only a dev branch carries one; a
  # four-component version is a strand with no counter to raise, and inventing
  # one here would mint a version the series never chose.
  case "$parent" in
    *.*.*.*.*) ;;
    *) return 0 ;;
  esac
  new="${parent%.*}.$((${parent##*.} + 1))"
  # `-i.bak`, so the one edit works under both GNU and BSD sed.
  sed -i.bak "s/^Version: .*/Version: $new/" "$wt/DESCRIPTION"
  rm -f "$wt/DESCRIPTION.bak"
  git -C "$wt" add DESCRIPTION
  git -C "$wt" commit -q --amend --no-edit
}

# --- the base series' test-side fixes ----------------------------------------
#
# Only a forward series has a base to mine: `<S>-fwd` reads `<S>-dev`. A base
# series' own `-dev` is the thing being built, and after a cutover the ref is
# gone -- both answer empty here, and the stage then behaves exactly as it did
# before this existed.
base_dev=
case "$S" in
  *-fwd)
    if git rev-parse -q --verify "$remote/${S%-fwd}-dev" >/dev/null; then
      base_dev="$remote/${S%-fwd}-dev"
    fi
    ;;
esac

# Equivalence is by vendored upstream SHA, the key the rest of the loop reads
# state by. One walk, because the alternative is a walk per buffer commit.
declare -A TWIN=()
index_twins() {
  [ -n "$base_dev" ] || return 0
  local c subj sha
  while IFS=$'\t' read -r c subj; do
    case "$subj" in
      vendor:* | *duckdb/duckdb@[0-9a-f]*) ;;
      *) continue ;;
    esac
    sha=$(sed -rn 's|^.*duckdb/duckdb@([0-9a-f]+).*$|\1|p' <<<"$subj")
    [ -n "$sha" ] || continue
    # Oldest wins: a SHA appears once on a healthy series, and where a repair
    # left two, the first is the one the chain was verified on.
    [ -n "${TWIN[$sha]:-}" ] || TWIN[$sha]=$c
  done < <(git log --reverse --format='%H%x09%s' "$base_dev")
}

twin_of() { # <buffer commit> -> the base -dev commit for the same upstream SHA
  local sha
  sha=$(git log -1 --format=%s "$1" | sed -rn 's|^.*duckdb/duckdb@([0-9a-f]+).*$|\1|p')
  [ -n "$sha" ] || return 0
  echo "${TWIN[$sha]:-}"
}

# What the twin folded in beyond vendoring: the paths its own diff touches that
# its `-build` twin's does not, less the two kinds that are not a fix.
#
# The difference is the load-bearing part, and it is what lets `src/` through.
# The gate compiles the glue at every buffer commit, so whatever the buffer
# holds there is already enough to build; anything the `-dev` twin has *on top*
# of it in `src/` was demanded by something later than the compiler -- a test,
# a check, a platform r-universe reached and the gate did not. Those are
# legitimate and they carry. Taking the difference is also what stops the glue
# the buffer already has from being applied twice.
#
# Two kinds are excluded, and neither is a judgement about the fix:
#
#   * the buffer's own strand -- the vendored tree and the patch stack. A
#     forward regenerates `src/duckdb/` from its own `patch/`, so a difference
#     there is about which patches the two branches had, not about a fix
#     travelling. Missing compile fixes belong on the buffer, mirrored there.
#   * what vendoring regenerates -- `R/version.R`, `src/include/sources.mk`,
#     the Makevars, the logos under `man/figures/`. Those differ between any
#     two vendor runs of the same upstream SHA, which is noise wearing the
#     shape of a fix.
#
# Tooling is stage 4's, ported from `main` rather than carried sideways.
carry_paths() { # <buffer commit> <base -dev commit>
  comm -13 \
    <(git show --format= --name-only --no-renames "$1" | sort -u) \
    <(git show --format= --name-only --no-renames "$2" | sort -u) |
    grep -vE '^(src/duckdb/|patch/|\.github/|scripts/|\.claude/|man/figures/)' |
    grep -vxE 'DESCRIPTION|R/version\.R|src/include/sources\.mk|src/Makevars(\.win|\.in)?' ||
    true
}

# Glue among the carried paths. Carried like the rest -- the series needs it to
# go green -- but said out loud, because a glue fix the base `-dev` has and the
# base `-build` lacks is buffer drift: the fix was folded during a repair and
# never mirrored onto the buffer, so the next tree regenerated there still
# wants it (.claude/skills/series-loop.md, stage 2).
glue_paths() { # <buffer commit> <base -dev commit>
  carry_paths "$1" "$2" | grep -E '^src/' || true
}

# Check the counter rather than assume it: a replay that silently froze it
# looks exactly like one that did not. Returns non-zero and leaves the caller
# to clean up, so the worktree is removed on this path like every other.
verify_counter() { # <worktree> <ref the replay started from>
  local wt=$1 from=$2 sha parent cur rc=0
  while IFS= read -r sha; do
    vendors "$wt" "$sha" || continue
    parent=$(git -C "$wt" show "$sha~1:DESCRIPTION" | sed -n 's/^Version: //p')
    cur=$(git -C "$wt" show "$sha:DESCRIPTION" | sed -n 's/^Version: //p')
    version_gt "$cur" "$parent" && continue
    echo "Error: $(git -C "$wt" rev-parse --short "$sha") vendors at $cur," \
      "its parent is $parent — the version counter did not advance"
    rc=1
  done < <(git -C "$wt" rev-list --reverse "$from..HEAD")
  return "$rc"
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
      # Set, never advance. -build-base is the one ref of the four that is not
      # fast-forward only: nothing consumes it, and the match is recomputed
      # here from scratch every time, so where the ref sat before says nothing
      # this stage needs (.claude/skills/series-loop.md, stage 3). Force,
      # because a write from outside this loop -- a CI job committing onto the
      # branch it ran on -- can leave the ref past the match or beside the
      # buffer, and refusing that stopped stage 5 with it.
      if [ "$(git rev-parse "$base")" != "$eq" ]; then
        git push --force "$remote" "$eq:refs/heads/$S-build-base"
        echo "build-base -> $(git rev-parse --short "$eq")"
      fi
    fi
  fi
else
  echo "green unchanged at $(git rev-parse --short "$green")"
fi

# --- stage 5: extend -dev from the buffer ------------------------------------

# Finish a stopped replay before anything else, and refuse to start a second one
# beside it: the kept worktree holds a resolution someone made, and a fresh run
# would replay the same commits over the top of it and lose that work.
if [ -f "$STATE" ] && [ -z "$CONTINUE" ]; then
  read -r swt scommit _ _ < "$STATE"
  echo "Error: $S has a stopped replay at $(git rev-parse --short "$scommit")" >&2
  echo "  worktree: $swt" >&2
  echo "  Resolve it and rerun with --continue, or discard it with --abort." >&2
  exit 1
fi
if [ -n "$CONTINUE" ] && [ ! -f "$STATE" ]; then
  echo "Error: $S has no stopped replay to continue" >&2
  exit 1
fi

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
  # `vendored_sha` walks past commits that vendor nothing, and on a -dev that has
  # none of its own it walks past the seed too — answering with what the branch
  # the seed was cut from had vendored. That is every series on its first firing
  # once stage 4 has ported: -dev is the seed plus tooling picks, so the fast
  # path above no longer applies and this one reaches below the divergence.
  # The buffer starts at the merge base whatever -dev's newest vendor commit is.
  if git merge-base --is-ancestor "$anchor" "$mb"; then
    anchor=$mb
  fi
fi
ahead=$(git rev-list --count "$anchor..$build")
if [ "$ahead" -eq 0 ]; then
  echo "buffer empty — vendor"
  exit 0
fi
n=$((ahead < chunk ? ahead : chunk))

# Which commits in this chunk have a test-side fix waiting on the base series.
# Computed before anything is written, because it decides the route: a plain ref
# move cannot carry content, so one carry in the chunk makes the whole chunk a
# replay.
index_twins
declare -A CARRY=()
carries=0
glue_drift=()
if [ -n "$base_dev" ]; then
  for c in $(git rev-list --reverse "$anchor..$build" | first_n "$n"); do
    d=$(twin_of "$c")
    [ -n "$d" ] || continue
    [ -n "$(carry_paths "$c" "$d")" ] || continue
    CARRY[$c]=$d
    carries=$((carries + 1))
    g=$(glue_paths "$c" "$d" | tr '\n' ' ')
    [ -z "$g" ] || glue_drift+=("$(git rev-parse --short "$d") $g")
  done
  [ "$carries" -eq 0 ] ||
    echo "$carries of $n buffered commit(s) carry a fix from $base_dev"
  # Said rather than filtered: the glue travels, and the buffer it is missing
  # from is a separate repair for whoever reads this.
  if [ ${#glue_drift[@]} -gt 0 ]; then
    echo "  ${#glue_drift[@]} of them carry glue the base buffer does not have;" \
      "mirror it onto ${S%-fwd}-build:"
    printf '    %s\n' "${glue_drift[@]}"
  fi
fi

if [ "$anchor" = "$(git rev-parse "$dev")" ] && [ "$carries" -eq 0 ] && [ -z "$CONTINUE" ]; then
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

  # Where the run stops, and how it says so. The worktree is kept: it holds the
  # conflict, and whoever resolves it needs somewhere to do that. Nothing has
  # been pushed at this point, so a stop costs a rerun and no ref motion.
  stop() { # <worktree> <buffer commit> <twin or -> <pick|carry>
    printf '%s %s %s %s\n' "$1" "$2" "$3" "$4" > "$STATE"
    echo >&2
    if [ "$4" = carry ]; then
      echo "Error: $S — carrying the test-side fix from $(git rev-parse --short "$3") into" >&2
      echo "  $(git rev-parse --short "$2") conflicted: $(git log -1 --format=%s "$2")" >&2
      echo >&2
      echo "The buffer commit is picked and staged; what stopped is the fix the base" >&2
      echo "series folded in for this same upstream commit. Resolve toward this" >&2
      echo "series' own R side -- and read the whole set before deciding, because" >&2
      echo "upstream moves the same file repeatedly and only the last version of it" >&2
      echo "survives the range:" >&2
      echo >&2
      echo "  scripts/series-glue.sh $base_dev" >&2
    else
      echo "Error: $S — replaying $(git rev-parse --short "$2") conflicted:" >&2
      echo "  $(git log -1 --format=%s "$2")" >&2
    fi
    echo >&2
    git -C "$1" diff --name-only --diff-filter=U | sed 's/^/  /' >&2
    echo >&2
    echo "  cd $1" >&2
    echo "  # resolve, then: git add <paths>" >&2
    echo "  scripts/series-advance.sh $S --continue      # or --abort to discard" >&2
    echo >&2
    echo "No ref was written." >&2
    exit 1
  }

  # Fold the base series' test-side fix into the commit that needs it -- never
  # stacked above it, so every commit of -dev stays independently green and the
  # chain stays bisectable. Three-way, so the failure mode is a conflict in the
  # tree rather than a silent miss.
  #
  # The message comes from the twin: by the commit-message contract that is this
  # commit's own vendor message extended with what was adapted, so taking it
  # keeps the prose with the change it explains.
  apply_carry() { # <worktree> <buffer commit> <twin>
    local wt=$1 c=$2 d=$3 paths patch
    mapfile -t paths < <(carry_paths "$c" "$d")
    [ ${#paths[@]} -gt 0 ] || return 0
    patch=$wt/.series-advance-carry.patch
    git diff "$d^" "$d" -- "${paths[@]}" > "$patch"
    if [ ! -s "$patch" ]; then rm -f "$patch"; return 0; fi
    if ! git -C "$wt" apply --3way --index "$patch"; then
      rm -f "$patch"
      stop "$wt" "$c" "$d" carry
    fi
    rm -f "$patch"
    {
      git log -1 --format=%B "$d"
      echo "Carried from \`$base_dev\` at $(git rev-parse --short "$d"):"
      echo "the test-side fix folded there for this same upstream commit,"
      echo "so the forward starts from what the base series proved."
    } > "$wt/.series-advance-msg"
    git -C "$wt" commit -q --amend --no-verify \
      --author="$(git log -1 --format='%an <%ae>' "$d")" -F "$wt/.series-advance-msg"
    rm -f "$wt/.series-advance-msg"
  }

  if [ -n "$CONTINUE" ]; then
    read -r wt rc rd rstage < "$STATE"
    [ -d "$wt" ] || { echo "Error: the kept worktree $wt is gone — rerun with --abort" >&2; exit 1; }
    [ -z "$(git -C "$wt" diff --name-only --diff-filter=U)" ] ||
      stop "$wt" "$rc" "$rd" "$rstage"
    echo "$S: resuming at $(git rev-parse --short "$rc")"
    if [ "$rstage" = carry ]; then
      # The resolved tree holds the carry; finish it as one commit with the
      # twin's message, exactly as an unconflicted carry ends.
      {
        git log -1 --format=%B "$rd"
        echo "Carried from \`$base_dev\` at $(git rev-parse --short "$rd"):"
        echo "the test-side fix folded there for this same upstream commit,"
        echo "so the forward starts from what the base series proved."
      } > "$wt/.series-advance-msg"
      git -C "$wt" commit -q --amend --no-verify \
        --author="$(git log -1 --format='%an <%ae>' "$rd")" -F "$wt/.series-advance-msg"
      rm -f "$wt/.series-advance-msg"
    else
      git -C "$wt" -c core.editor=true cherry-pick --continue
      restamp "$wt" "$rc"
      [ -n "${CARRY[$rc]:-}" ] && apply_carry "$wt" "$rc" "${CARRY[$rc]}"
    fi
    rm -f "$STATE"
    # The rest of the same chunk, not a fresh one: nothing was pushed, so the
    # anchor is where it was, and the resumed commit is somewhere inside the
    # list this run already computed. Take what follows it.
    remaining=$(git rev-list --reverse "$anchor..$build" | first_n "$n" |
                  awk -v c="$rc" 'seen { print } $0 == c { seen = 1 }')
  else
    wt=$(mktemp -d)
    git worktree add --detach -q "$wt" "$dev"
    remaining=$(git rev-list --reverse "$anchor..$build" | first_n "$n")
  fi

  # `--empty=drop`, as series-port.sh already does: a buffer commit whose content
  # reached -dev by another route replays to nothing, and an empty pick stops the
  # sequencer. Stage 3 sends patch/ entries down both paths on purpose -- the port
  # carries one onto -dev, and the same fix is committed onto -build so the next
  # regenerated tree still has it -- so the redundancy is designed, not a mistake,
  # and it must not abort the extend.
  #
  # One commit at a time, because restamp runs between the picks and reads the
  # parent it is bumping from, and because a carry amends the commit just made.
  for c in $remaining; do
    before=$(git -C "$wt" rev-parse HEAD)
    if ! git -C "$wt" cherry-pick --empty=drop "$c"; then
      stop "$wt" "$c" "${CARRY[$c]:--}" pick
    fi
    [ "$(git -C "$wt" rev-parse HEAD)" = "$before" ] && continue
    restamp "$wt" "$c"
    [ -n "${CARRY[$c]:-}" ] && apply_carry "$wt" "$c" "${CARRY[$c]}"
  done
  next=$(git -C "$wt" rev-parse HEAD)
  if ! verify_counter "$wt" "$dev"; then
    git worktree remove --force "$wt"
    exit 1
  fi
  git worktree remove --force "$wt"
  rm -f "$STATE"
  git push "$remote" "$next:refs/heads/$S-dev"
fi
echo "dev -> $(git rev-parse --short "$next") (+$n)"
