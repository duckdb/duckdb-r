#!/bin/bash
# Open a new series by cutting its parent's strands at the fork point: compute
# the fork point, find the commit on each strand that vendors it, and write the
# four refs there (.claude/skills/series-open/SKILL.md).
#
# Everything this does is derivable, which is why it is a script: the fork point
# is a function of two upstream branches, each strand's cut is a function of that
# fork point and the strand, and the four refs are a function of the two cuts.
# What is left to judgement -- the codename, the flavor, when to push -- this
# does not touch.
#
# It writes local refs only. The push is the caller's, after the reflavor, and
# `--next` prints the exact remaining commands with this series' names filled in,
# for both the new series and its parent: a cut leaves each carrying a version
# prefix that names a line it does not preview.
#
# Usage: series-cut.sh <series> [--parent <series>] [--remote <name>]
#                      [--upstream <path>] [--flavor <name>] [--check] [--next]
#   series-cut.sh v2.0-cyanoptera --upstream ../../../duckdb --flavor 2.0.dev
#
#   <series>          the new series, named for the upstream branch it tracks.
#   --parent <series> the series whose line the new branch was cut from.
#                     Default `main`. Its own upstream branch is its name.
#   --flavor <name>   the dev flavor, for the commands --next prints. Default is
#                     the version in <series> with `.dev` -- `v2.0-x` gives
#                     `2.0.dev`. A series whose name carries no version needs it.
#   --check           compute and report, write nothing. Exit 1 if the refs exist
#                     already and disagree with what this would write.
#   --next            print the commands that follow the cut, filled in.
# --remote and --upstream are spelled as in every scripts/series-*.sh; see the
# shared contract in handbook/operations/vendoring/series-loop/README.md.

set -euo pipefail

usage='usage: series-cut.sh <series> [--parent <series>] [--remote <name>] [--upstream <path>] [--flavor <name>] [--check] [--next]'
argerr() { echo "$usage" >&2; exit 2; }

remote=${SERIES_REMOTE:-origin}
upstream=${UPSTREAM_CLONE:-../../../duckdb}
parent=main
flavor=
check=
next=
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --parent) [ $# -ge 2 ] || argerr; parent=$2; shift 2 ;;
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --upstream) [ $# -ge 2 ] || argerr; upstream=$2; shift 2 ;;
    --flavor) [ $# -ge 2 ] || argerr; flavor=$2; shift 2 ;;
    --check) check=1; shift ;;
    --next) next=1; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
S=${args[0]}

toplevel=${VENDOR_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || true)}
[ -n "$toplevel" ] || { echo "Error: $PWD is not a git worktree" >&2; exit 1; }
cd "$toplevel"

# `-e` rather than `-d`: in a linked worktree `.git` is a file naming the real one.
[ -e "$upstream/.git" ] ||
  { echo "Error: $upstream is not a duckdb/duckdb checkout (--upstream)" >&2; exit 1; }

# The new series is named for the branch it tracks, and so is its parent.
U=$S
PU=$parent

# The default flavor: the version in the series name, plus `.dev`. `v2.0-x` is
# `2.0.dev`; a parent named `main` has no version and needs --flavor.
if [ -z "$flavor" ]; then
  v=$(printf '%s\n' "$S" | sed -rn 's/^v([0-9]+\.[0-9]+).*$/\1/p')
  [ -n "$v" ] && flavor="$v.dev"
fi
[ "$S" != "$parent" ] ||
  { echo "Error: <series> and --parent are both '$S'; a series cannot cut itself." >&2; exit 1; }

ups() { git -C "$upstream" "$@"; }
for b in "$U" "$PU"; do
  ups rev-parse -q --verify "refs/remotes/origin/$b" >/dev/null ||
    { echo "Error: $upstream has no origin/$b -- fetch it first" >&2; exit 1; }
done

# --- the fork point ----------------------------------------------------------
# The newest commit on the first-parent chain of *both* branches. Not
# `git merge-base`, which upstream's back-merges of a release branch into `main`
# drag forward -- opening v2.0 measured the two a week apart
# (handbook/operations/vendoring/model/README.md).
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Every commit on each branch's first-parent chain. `$U`'s is kept: the strand
# lookups below ask it the same question once per candidate commit.
# Written to files rather than piped: every lookup below stops at its first
# match, and an `exit` in awk closes the pipe under the feet of a `git rev-list`
# with thousands of commits still to print -- which `pipefail` then reports as a
# failure of the whole line.
ups rev-list --first-parent "origin/$PU" | sort -u > "$work/pu"
ups rev-list --first-parent "origin/$U"  > "$work/u"
sort -u "$work/u" > "$work/chain"
chain=$work/chain

fork=$(awk 'NR==FNR{a[$0];next} $0 in a{print; exit}' "$work/pu" "$work/u")
[ -n "$fork" ] ||
  { echo "Error: $U and $PU share no first-parent commit" >&2; exit 1; }

# --- each strand's cut -------------------------------------------------------
# A strand's cut is its newest commit whose `duckdb/duckdb@<sha>` subject names a
# commit on the new branch's first-parent chain. Below it the two lines are one
# history, so everything there is already vendored, glued and judged.
cut_of() { # <strand ref> -> sha
  git log --format='%H|%s' "$1" > "$work/strand"
  # `sources .*@` rather than `sources to @`: a commit vendoring a tagged upstream
  # commit reads `vendor: Update vendored sources (tag v1.5.5) to duckdb/duckdb@`,
  # and a release branch is cut precisely around a tag. `main-dev` carries 19 of
  # them; anchoring on `to ` would step the cut silently past one.
  awk -F'|' '$2 ~ /^vendor: Update vendored sources .*duckdb\/duckdb@/ {
    n = split($2, a, "@"); print $1, a[n] }' "$work/strand" > "$work/vendored"
  awk 'NR==FNR{c[$0];next} ($2 in c){print $1; exit}' "$chain" "$work/vendored"
}

for r in build dev; do
  git rev-parse -q --verify "refs/remotes/$remote/$parent-$r" >/dev/null ||
    { echo "Error: no $remote/$parent-$r -- fetch the parent series first" >&2; exit 1; }
done

cut_build=$(cut_of "$remote/$parent-build")
cut_dev=$(cut_of "$remote/$parent-dev")
for c in "$cut_build" "$cut_dev"; do
  [ -n "$c" ] ||
    { echo "Error: $parent has no vendor commit on $U's chain" >&2; exit 1; }
done

printf 'fork point    %s\n' "$(ups log -1 --format='%h %ad %s' --date=short "$fork" | cut -c1-70)"
for r in build dev; do
  eval "c=\$cut_$r"
  printf '%-20s %s  %s above it\n' "$parent-$r cut" \
    "$(git log -1 --format='%h %ad' --date=short "$c")" \
    "$(git rev-list --count "$c..$remote/$parent-$r")"
done
# The loop's backlog once the refs are pushed, not a task for the caller.
echo "loop backlog $(ups rev-list --count "$fork..origin/$U") commits of $U above the fork point"

# --- the four refs -----------------------------------------------------------
declare -A want=(
  ["$S-build"]=$cut_build ["$S-build-base"]=$cut_build
  ["$S-dev"]=$cut_dev     ["$S-green"]=$cut_dev
)

# In ref order rather than hash order, so the report reads the same every run and
# a refusal leaves the same refs behind on any machine.
order=("$S-build" "$S-build-base" "$S-dev" "$S-green")

# Both sides are read: `refs/heads/` is what this writes, and `$remote/` is what
# step 3 pushes and the loop serves. A fresh clone has no local branches at all,
# so checking only the former gives an unconditional all-clear on a series that
# is already open.
status=0
conflicts=()
for ref in "${order[@]}"; do
  w=${want[$ref]}
  for side in "refs/heads/$ref" "refs/remotes/$remote/$ref"; do
    have=$(git rev-parse -q --verify "$side") || continue
    where=${side#refs/}
    if [ "$have" = "$w" ]; then
      [ -n "$check" ] && echo "agrees        $where"
    elif git merge-base --is-ancestor "$w" "$have" 2>/dev/null; then
      # The series has advanced past its own cut, which is the loop working.
      [ -n "$check" ] &&
        echo "advanced      $where is $(git rev-parse --short "$have"), $(git rev-list --count "$w..$have") above the cut"
    else
      echo "DISAGREES     $where is $(git rev-parse --short "$have"), cut says $(git rev-parse --short "$w")" >&2
      status=1
      [ "$side" = "refs/heads/$ref" ] && conflicts+=("$ref")
    fi
  done
done

if [ -n "$check" ]; then
  for ref in "${order[@]}"; do
    git rev-parse -q --verify "refs/heads/$ref" >/dev/null ||
      echo "would create  heads/$ref -> $(git rev-parse --short "${want[$ref]}")"
  done
else
  # Nothing is written until every ref has been judged: a refusal halfway leaves
  # a partial cut, and which half depends on the order the refs were visited.
  if [ ${#conflicts[@]} -gt 0 ]; then
    echo "Error: ${#conflicts[@]} local ref(s) exist and are not the cut: ${conflicts[*]}" >&2
    echo "  Nothing was written. Delete them, or run --check to see every side." >&2
    exit 1
  fi
  for ref in "${order[@]}"; do
    git branch -f "$ref" "${want[$ref]}"
    echo "wrote         $ref -> $(git rev-parse --short "${want[$ref]}")"
  done
fi

if [ -n "$next" ]; then
  F=${flavor:-<F>}
  cat <<NEXT

Next, in order -- the cut is not complete until the rename is in:

  # 1. Reflavor each strand, one commit above its cut, and stamp the prefix of
  #    the line it previews. Run *this* checkout's copies of both scripts:
  #    neither strand carries scripts/, a buffer takes no ports, and the cut
  #    predates them in any case.
  git worktree add ../wt-$S-build $S-build && (cd ../wt-$S-build && $PWD/scripts/reflavor.sh $F && $PWD/scripts/preview-prefix.sh)
  git worktree add ../wt-$S-dev   $S-dev   && (cd ../wt-$S-dev   && $PWD/scripts/reflavor.sh $F && $PWD/scripts/preview-prefix.sh)

  # 1b. $parent previews the *next* line from today, so its strands owe the
  #     stamp as well -- and no reflavor: its flavor names the branch it
  #     tracks, not the version (series-open/SKILL.md step 3).
  git worktree add ../wt-$parent-build $parent-build && (cd ../wt-$parent-build && $PWD/scripts/preview-prefix.sh)
  git worktree add ../wt-$parent-dev   $parent-dev   && (cd ../wt-$parent-dev   && $PWD/scripts/preview-prefix.sh)

  # 2. Push all four together; a ref landing alone invites a half-built firing.
  #    $parent's two stamped strands go with them, in the same push: the pair
  #    has to move together or the merge driver sees prefixes that differ.
  git push --atomic $remote \\
    $S-build:refs/heads/$S-build $S-build-base:refs/heads/$S-build-base \\
    $S-dev:refs/heads/$S-dev     $S-green:refs/heads/$S-green \\
    $parent-build:refs/heads/$parent-build $parent-dev:refs/heads/$parent-dev

  # 3. Open both forwards -- series-forward/SKILL.md, twice, neither waiting
  #    on the other:
  #      series $S: onto current main, ordinary regenerated seed
  #      series $parent: onto current main, grafted per strand --
  #        $parent-fwd-build at $(git rev-parse --short "$cut_build"), $parent-fwd-dev at $(git rev-parse --short "$cut_dev").
  #        Each strand grafts its own cut; everything below is $S's now.

  # 4. Declare the flavor $F -- one entry in scripts/series.yaml -- then
  #    scripts/series-table.R and a README render write both tables from it,
  #    and scripts/pull-config.sh --check holds the mirror rules against it.
NEXT
fi

exit $status
