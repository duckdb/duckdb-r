#!/usr/bin/env bash
# Finish `DESCRIPTION` and `NEWS.md` of a forward merge in progress, a release
# branch merged into a newer line (.claude/skills/series-land/SKILL.md, step 8),
# as the merge drivers mean them, whether git ran the drivers or not.
#
# git runs a merge driver only where both sides changed a file. Where the newer
# line left `DESCRIPTION` or `NEWS.md` alone since the merge base, git takes the
# release branch's copy as it stands, its `Config/duckdb/upstream:` record and
# its development section's link among it (duckdb/duckdb-r#3056). So this runs
# both drivers again, on the merge base, ours (`HEAD`) and theirs
# (`MERGE_HEAD`), and writes their output whatever git did.
#
# Two things the drivers cannot know are settled here first:
#
#   * a release drops the development section, `# duckdb (development
#     version)`, on the release branch, while the newer line has moved its link:
#     a section gone from one side and edited on the other, which the `NEWS.md`
#     driver merges line by line, and which conflicts (duckdb/duckdb-r#3068).
#     The newer line keeps its development section, so where theirs has none
#     and ours and the base have one, theirs is given the base's before the
#     driver runs, and ours is taken. The release's history then merges by
#     section: what the release branch dropped since the base, an interim
#     section such as `2.0.0.9001`, is dropped, and the newer line's own
#     sections are kept;
#   * the development section's link compares the branch's newest tag with the
#     branch (handbook/operations/releases/versioning/README.md). After the
#     merge it names the newer line given as the argument, and starts at the
#     highest version among the tag it names and the tags theirs reaches,
#     which need not be the tag closest to theirs.
#
# A file the driver leaves conflicted is written with its markers and left
# unmerged in the index, the three sides as stages 1 to 3, for the hand, and
# recorded with the merge's MERGE_HEAD in the git directory, so that a second
# run leaves a file already resolved by hand as it is.
#
# Usage:
#   scripts/series-merge-forward.sh <newer line>
#
# Exits 1 without a merge in progress, or with more than one merge base,
# before changing anything; a conflict left for the hand is no failure.
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: series-merge-forward.sh <newer line>" >&2; exit 2; }
N=$1
HERE=$(cd "$(dirname "$0")" && pwd)

git rev-parse -q --verify MERGE_HEAD >/dev/null || {
  echo "series-merge-forward.sh: no merge in progress: run it after 'git merge --no-commit'" >&2
  exit 1
}
mapfile -t bases < <(git merge-base --all HEAD MERGE_HEAD)
[ "${#bases[@]}" -eq 1 ] || {
  echo "series-merge-forward.sh: ${#bases[@]} merge bases, not one: merge DESCRIPTION and NEWS.md by hand" >&2
  exit 1
}
BASE=${bases[0]}
cd "$(git rev-parse --show-toplevel)"

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

DEV='# duckdb (development version)'
# The development section of a NEWS.md: its heading up to the next heading.
dev_section() { awk -v dev="$DEV" '/^# duckdb / { on = ($0 == dev) } on' "$1"; }

# Give <file> the development section in <section file>, before its first
# heading.
add_dev() {
  awk -v sec="$2" '
    !done && /^# duckdb / { while ((getline l < sec) > 0) print l; done = 1 }
    { print }
    END { if (!done) while ((getline l < sec) > 0) print l }' "$1" > "$1.new"
  mv "$1.new" "$1"
}

# The development section's link in <file>: names <N>, from the newer of the
# tag it names and <tag>.
fix_link() {
  local file=$1 tag=$2 old new
  old=$(dev_section "$file" | sed -n -E 's/^(- )?Commits since ([^:]+): <.*$/\2/p' | head -n 1)
  [ -n "$old" ] || return 0
  new=$old
  if [ -n "$tag" ] && [ "$(printf '%s\n%s\n' "$old" "$tag" | sort -V | tail -n 1)" = "$tag" ]; then
    new=$tag
  fi
  awk -v dev="$DEV" -v tag="$new" -v n="$N" '
    /^# duckdb / { on = ($0 == dev) }
    on && !done && match($0, /^(- )?Commits since [^:]+: <[^>]*\/compare\//) {
      pre = substr($0, 1, RLENGTH)
      sub(/Commits since [^:]+:/, "Commits since " tag ":", pre)
      end = ($0 ~ /\.$/) ? "." : ""
      print pre tag "..." n ">" end
      done = 1
      next
    }
    { print }' "$file" > "$file.new"
  mv "$file.new" "$file"
}

# Stage <path> as unmerged, from the three commits' blobs.
unmerge() {
  local path=$1 stage rev blob mode
  {
    printf '0 %040d\t%s\n' 0 "$path"
    for stage in 1 2 3; do
      case $stage in 1) rev=$BASE ;; 2) rev=HEAD ;; 3) rev=MERGE_HEAD ;; esac
      blob=$(git rev-parse -q --verify "$rev:$path" 2>/dev/null) || continue
      mode=$(git ls-tree "$rev" -- "$path" | cut -d ' ' -f 1)
      printf '%s %s %s\t%s\n' "$mode" "$blob" "$stage" "$path"
    done
  } | git update-index --index-info
}

theirs_tag=$(git tag --merged MERGE_HEAD --list 'v[0-9]*' | sort -V | tail -n 1)

# The files an earlier run of this merge left conflicted, one `<MERGE_HEAD>
# <path>` per line; those of another merge are dropped.
STATE=$(git rev-parse --git-path series-merge-forward)
head=$(git rev-parse MERGE_HEAD)
left=$(grep -s "^$head " "$STATE" || true)
: > "$STATE"

for path in DESCRIPTION NEWS.md; do
  case $path in
    DESCRIPTION) driver=$HERE/merge-version.sh ;;
    NEWS.md) driver=$HERE/merge-news.sh ;;
  esac
  if grep -qxF "$head $path" <<<"$left" && [ -z "$(git ls-files -u -- "$path")" ]; then
    echo "$path: resolved by hand since the last run, left as it is"
    echo "$head $path" >> "$STATE"
    continue
  fi
  missing=
  for side in O:$BASE A:HEAD B:MERGE_HEAD; do
    git show "${side#*:}:$path" > "$T/${side%%:*}" 2>/dev/null || missing=1
  done
  if [ -n "$missing" ]; then
    echo "$path: not on all three sides, left as git merged it"
    continue
  fi
  if [ "$path" = NEWS.md ] && [ -z "$(dev_section "$T/B")" ] &&
    [ -n "$(dev_section "$T/A")" ] && [ -n "$(dev_section "$T/O")" ]; then
    dev_section "$T/O" > "$T/dev"
    add_dev "$T/B" "$T/dev"
  fi
  if "$driver" "$T/O" "$T/A" "$T/B"; then
    [ "$path" = NEWS.md ] && fix_link "$T/A" "$theirs_tag"
    cat "$T/A" > "$path"
    git add -- "$path"
    echo "$path: merged by scripts/${driver##*/}"
  else
    st=$?
    [ "$st" -eq 1 ] || { echo "$path: scripts/${driver##*/} failed with status $st" >&2; exit 1; }
    cat "$T/A" > "$path"
    unmerge "$path"
    echo "$head $path" >> "$STATE"
    echo "$path: a conflict scripts/${driver##*/} leaves for the hand: resolve it, and git add"
  fi
done
