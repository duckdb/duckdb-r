#!/bin/bash
# Stamp a preview line's version prefix onto the strand checked out here: the
# prefix of the line it *previews*, not the one it was seeded from
# (handbook/operations/releases/versioning/README.md).
#
# A series previewing an unreleased line takes fledge's prefix for that line --
# `a.b.99` before a minor release, `a.99.99` before a major one -- so previewing
# 2.1 is `2.0.99.9000` and previewing 2.0 is `1.99.99.9000`. Which line is being
# previewed is read from the engine the strand vendors, so this needs no input
# and cannot drift from the tree it stamps.
#
# **It is owed at a branch cut.** When upstream cuts a release branch, `main`
# starts previewing the *next* line the same week, and until this is stamped the
# series carries the version of a line it has stopped previewing -- the
# misalignment `versioning/` describes, where the two strands' prefixes differ
# and the `DESCRIPTION` merge driver stops resolving them
# (.claude/skills/series-open/SKILL.md).
#
# The vendor counter is kept: the chain does not restart, so the fifth component
# carries over and the version still rises.
#
# Usage: preview-prefix.sh [--line <a.b>] [--check]
#   --line <a.b>  the line being previewed, where the engine cannot say.
#   --check       report and write nothing; exit 1 if the prefix is not stamped.

set -euo pipefail

usage='usage: preview-prefix.sh [--line <a.b>] [--check]'
argerr() { echo "$usage" >&2; exit 2; }

line=
check=
while [ $# -gt 0 ]; do
  case "$1" in
    --line) [ $# -ge 2 ] || argerr; line=$2; shift 2 ;;
    --check) check=1; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    *) argerr ;;
  esac
done

toplevel=${VENDOR_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || true)}
[ -n "$toplevel" ] || { echo "Error: $PWD is not a git worktree" >&2; exit 1; }
cd "$toplevel"

if command -v gsed >/dev/null 2>&1; then gnu_sed=gsed; else gnu_sed=sed; fi
case "$("$gnu_sed" --version 2>/dev/null || true)" in
*"GNU sed"*) ;;
*) echo "$0: '$gnu_sed' is not GNU sed." >&2; exit 1 ;;
esac

# The line previewed, from the engine this strand vendors: `2.1.0-dev84198` is
# upstream `main` declaring 2.1, which is what a series tracking it previews.
if [ -z "$line" ]; then
  [ -e R/version.R ] ||
    { echo "Error: no R/version.R to read the line from; pass --line <a.b>" >&2; exit 1; }
  line=$("$gnu_sed" -rn 's/^duckdb_version <- "([0-9]+\.[0-9]+)\..*$/\1/p' R/version.R)
  [ -n "$line" ] ||
    { echo "Error: R/version.R names no version; pass --line <a.b>" >&2; exit 1; }
fi

case "$line" in
  [0-9]*.[0-9]*) ;;
  *) echo "Error: --line takes <major>.<minor>, not '$line'" >&2; exit 1 ;;
esac
major=${line%%.*}
minor=${line#*.}

# fledge's own bumps: pre-minor keeps the major and pins the minor at 99;
# pre-major pins both, one major down.
if [ "$minor" -gt 0 ]; then
  prefix="$major.$((minor - 1)).99.9000"
else
  prefix="$((major - 1)).99.99.9000"
fi

cur=$("$gnu_sed" -rn 's/^Version: (.*)$/\1/p' DESCRIPTION)
counter=$(printf '%s\n' "$cur" | "$gnu_sed" -rn 's/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\.([0-9]+)$/\1/p')
want=$prefix${counter:+.$counter}

echo "previews      $line"
echo "version       $cur"
echo "prefix owed   $want"

if [ "$cur" = "$want" ]; then
  echo "already stamped"
  exit 0
fi
if [ -n "$check" ]; then
  echo "NOT STAMPED   $cur should be $want" >&2
  exit 1
fi

# A version that would not rise is a version r-universe will not publish over,
# and the loop's own gate refuses a counter that did not increase.
older=$(printf '%s\n%s\n' "$cur" "$want" | sort -V | head -1)
[ "$older" = "$cur" ] ||
  { echo "Error: $want does not rise above $cur; refusing to stamp." >&2; exit 1; }

[ -z "$(git status --porcelain)" ] ||
  { echo "$0: the working tree is not clean; commit or stash first." >&2; exit 1; }

"$gnu_sed" -i -r "s/^Version: .*$/Version: $want/" DESCRIPTION
git add DESCRIPTION
git commit -q -m "chore: Take the $line preview prefix"
echo "stamped       $want"
