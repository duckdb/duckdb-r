#!/bin/sh
# How much a forward series' stage-5 carry has to move, and how it classifies.
#
# Read-only. Run in a clone that has both series' refs (krlmlr/duckdb-r), with
# full history: every commit's own diff is read.
#
#   sh run.sh <buffer-ref> <base-dev-ref> [<range-base-ref>]
#
# <range-base-ref> bounds the walk to part of the buffer -- pass a series'
# `-build-base` to measure only what it has left to consume. Omit it to walk
# the whole buffer.
set -eu

BUILD=${1:?usage: run.sh <buffer-ref> <base-dev-ref> [<range-base-ref>]}
DEV=${2:?usage: run.sh <buffer-ref> <base-dev-ref> [<range-base-ref>]}
FROM=${3:-}
RANGE=$BUILD
[ -z "$FROM" ] || RANGE="$FROM..$BUILD"

# The same two exclusions scripts/series-advance.sh applies: the buffer's own
# strand, and what vendoring regenerates.
EXCL_DIR='^(src/duckdb/|patch/|\.github/|scripts/|\.claude/|man/figures/)'
EXCL_FILE='DESCRIPTION|R/version\.R|src/include/sources\.mk|src/Makevars(\.win|\.in)?'

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# The base -dev indexed by vendored upstream SHA, oldest wins -- the key the
# series loop reads state by.
git log --reverse --format='%H%x09%s' "$DEV" |
  sed -nr 's|^([0-9a-f]+)\t.*duckdb/duckdb@([0-9a-f]+).*$|\2 \1|p' |
  awk '!seen[$1]++' | sort > "$tmp/twins"

total=0; twinned=0; carry=0; glue=0; excluded_only=0
: > "$tmp/files"
git log --reverse --format='%H%x09%s' "$RANGE" |
  sed -nr 's|^([0-9a-f]+)\t(vendor:.*duckdb/duckdb@([0-9a-f]+).*)$|\1 \3|p' > "$tmp/buffer"

while read -r c sha; do
  total=$((total + 1))
  d=$(awk -v s="$sha" '$1 == s { print $2; exit }' "$tmp/twins")
  [ -n "$d" ] || continue
  twinned=$((twinned + 1))
  git show --format= --name-only --no-renames "$c" | sort -u > "$tmp/b"
  git show --format= --name-only --no-renames "$d" | sort -u > "$tmp/d"
  raw=$(comm -13 "$tmp/b" "$tmp/d")
  [ -n "$raw" ] || continue
  kept=$(printf '%s\n' "$raw" | grep -vE "$EXCL_DIR" | grep -vxE "$EXCL_FILE" || true)
  if [ -z "$kept" ]; then excluded_only=$((excluded_only + 1)); continue; fi
  carry=$((carry + 1))
  printf '%s\n' "$kept" >> "$tmp/files"
  printf '%s\n' "$kept" | grep -qE '^src/' && glue=$((glue + 1)) || true
done < "$tmp/buffer"

echo "range:            $RANGE"
echo "base -dev:        $DEV"
echo
echo "vendor commits:   $total"
echo "  with a twin:    $twinned"
echo "  carrying:       $carry"
echo "    incl. glue:   $glue"
echo "  excluded only:  $excluded_only  (difference was buffer strand or regenerated files)"
echo
echo "files carried, ranked:"
sort "$tmp/files" | uniq -c | sort -rn | sed 's/^/  /'
