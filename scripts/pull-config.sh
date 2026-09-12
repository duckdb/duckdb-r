#!/bin/bash
# Read-only: does `.github/pull.yml` rule every mirror a badge measures against?
#
# A mirror exists because a comparison needs a base in the same repository
# (handbook/branches/mirrors/README.md), and the comparisons are the badges in
# `README.md`: shields.io counts two refs of `krlmlr/duckdb-r`, so a badge names
# its base there and the fork has to carry it. That makes the rule list a
# function of the badge table rather than a thing to remember, and this script
# is that function, evaluated against the file.
#
# It is wanted when a series changes -- one opened, one parked, one retired --
# because that is when the badge table moves and the rule list moves with it.
# A series is discovered from its refs and needs no configuration of its own
# (handbook/branches/model/README.md); the branch its *ahead* badge measures
# against is not one of those refs, and is exactly what this reads.
#
# What the fork must carry, derived:
#
#   * `main`, always. It is a badge base, and it is also what every series seeds
#     from and forward-ports from, so it is carried even when no badge reads it.
#   * every other badge base that is not a series' own ref -- the parked
#     `vX.Y-codename` baseline a line is measured against once it stops
#     releasing from `main`.
#   * the `-lts` companion of such a baseline, where a rule already carries one:
#     the LTS flavor publishes from it, which no badge shows.
#
# A series' own refs -- `-dev`, `-green`, `-build`, `-build-base` -- are never
# mirrors and never get a rule: every rule hard-resets, so one that reached a
# working ref would discard the loop's work (`.github/pull.yml` says the same
# where someone editing it will read it).
#
# This prints the rule to add; it does not write the file. `.github/pull.yml`
# carries comments that say why each rule is there, and a generator that owned
# the file would have to own those too.
#
# Usage: pull-config.sh [--check]
#   --check   exit 1 when the file and the badges disagree (default: exit 0,
#             report either way)

set -euo pipefail

cd "$(dirname "$0")/.."

check=
[ "${1:-}" = --check ] && check=1

readme=README.md
config=.github/pull.yml
fork_url=${FORK_URL:-https://github.com/krlmlr/duckdb-r}

# The refs a badge names in the fork. Both sides of every comparison, because a
# head that is a mirror needs carrying just as much as a base does; today every
# head is a series ref and only bases survive the filter below.
badge_refs() {
  grep -oE '[?&](base|head)=[A-Za-z0-9._-]+' "$readme" | cut -d= -f2 | sort -u
}

# A series' own refs, which are the fork's to move and never mirrors of
# anything. The suffix is what tells them apart -- the same test `pull.yml`
# relies on for the app never reaching one.
is_series_ref() {
  case "$1" in
    *-dev | *-green | *-build | *-build-base) return 0 ;;
    *) return 1 ;;
  esac
}

# `base:` of every rule, in file order, so the report can name what is there.
config_rules() {
  grep -oE '^[[:space:]]*-[[:space:]]+base:[[:space:]]*[A-Za-z0-9._-]+' "$config" |
    awk '{print $NF}'
}

mapfile -t rules < <(config_rules)

# The derivation, in the order the three bullets above give it.
wanted=("main")
while IFS= read -r r; do
  [ -n "$r" ] || continue
  is_series_ref "$r" && continue
  [ "$r" = main ] && continue
  wanted+=("$r")
done < <(badge_refs)

# The `-lts` companions, kept rather than derived: nothing in the tree points at
# one, so the file is the only evidence that the flavor publishes from it, and
# dropping a rule on the strength of not finding a reader is how a published
# branch stops being mirrored.
for r in "${rules[@]}"; do
  case "$r" in
    *-lts)
      base=${r%-lts}
      for w in "${wanted[@]}"; do
        [ "$w" = "$base" ] && wanted+=("$r") && break
      done
      ;;
  esac
done

contains() { # <needle> <haystack...>
  local n=$1; shift
  local h
  for h in "$@"; do [ "$h" = "$n" ] && return 0; done
  return 1
}

missing=()
for w in "${wanted[@]}"; do
  contains "$w" "${rules[@]}" || missing+=("$w")
done

unread=()
for r in "${rules[@]}"; do
  contains "$r" "${wanted[@]}" || unread+=("$r")
done

# Whether the fork has the branch at all. A rule whose base the fork lacks is
# skipped silently and forever, so the push comes first and the rule second;
# a reading that cannot be taken is reported as missing data, never as a pass.
fork_has() { # <branch> -> 0 yes, 1 no, 2 could not read
  local out
  out=$(git ls-remote --heads "$fork_url" "$1" 2>/dev/null) || return 2
  [ -n "$out" ]
}

status=0

if [ ${#missing[@]} -eq 0 ] && [ ${#unread[@]} -eq 0 ]; then
  echo "pull.yml: ${#rules[@]} rules, and the badge table asks for exactly those."
else
  status=1
fi

for w in "${missing[@]}"; do
  echo
  echo "pull.yml: no rule for $w, which a badge in $readme measures against."
  echo "          Without one the mirror stops at whatever it was last pushed at,"
  echo "          and the badge keeps rendering, counting commits already shipped."
  rc=0; fork_has "$w" || rc=$?
  case $rc in
    0) ;;
    2)
      echo "          Could not read $fork_url, so whether the fork carries $w"
      echo "          is unknown here. That is missing data, not a clean result."
      ;;
    *)
      echo "          The fork does not carry $w yet: push it once by hand FIRST."
      echo "          A rule whose base the fork lacks is skipped silently and forever,"
      echo "          so adding the rule never creates the mirror."
      ;;
  esac
  echo "          Add, beside the rules it belongs with:"
  echo
  echo "  - base: $w"
  echo "    upstream: duckdb:$w"
  echo "    mergeMethod: hardreset"
  echo "    mergeUnstable: true"
done

for r in "${unread[@]}"; do
  echo
  echo "pull.yml: the rule for $r, and no badge in $readme measures against it."
  echo "          Either the badge table lost a row it should have,"
  echo "          or the line retired and the rule outlived it. Read, do not delete:"
  echo "          a rule costs a sync, and a mirror nobody keeps costs a wrong badge."
done

if [ -n "$check" ]; then
  exit $status
fi
exit 0
