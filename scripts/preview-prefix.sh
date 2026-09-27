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
# **It is owed at a branch cut, by both series.** When upstream cuts a release
# branch, `main` starts previewing the *next* line the same week, so the series
# tracking it carries the version of a line it has stopped previewing. The new
# series has the opposite problem and the same fix: the cut hands it the
# parent's tree, prefix included, so it carries a line it never previewed.
# Either way a strand names a foreign line and its pair drifts apart with it --
# the misalignment `versioning/` describes, where the two strands' prefixes
# differ and the `DESCRIPTION` merge driver stops resolving them
# (.claude/skills/series-open/SKILL.md step 3).
#
# **A line a released version already names is not a preview line**, whatever
# branch the series tracks, so it is owed no prefix and reports none: the seed
# took its version from `main` and keeps it. `v1.5-variegata` and `v1.4-andium`
# are the two in that state today.
#
# Run it on the two `-build`/`-dev` strands of each; `-green` is fast-forward
# only and takes the stamp when the loop advances over it.
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
#
# The same string says whether that line is a preview line at all, which is the
# test the prefix hangs on: a released version already naming the line means the
# seed took its version from `main` and no prefix is owed
# (handbook/operations/releases/versioning/README.md). The patch component
# carries it -- `2.1.0-dev…` names a line nothing has shipped, while
# `1.5.6-dev…` says `1.5.5` did -- so this needs no tag lookup and stays
# readable from the tree it stamps. An explicit --line is never second-guessed.
released=
if [ -z "$line" ]; then
  [ -e R/version.R ] ||
    { echo "Error: no R/version.R to read the line from; pass --line <a.b>" >&2; exit 1; }
  engine=$("$gnu_sed" -rn 's/^duckdb_version <- "([0-9]+\.[0-9]+\.[0-9]+).*$/\1/p' R/version.R)
  [ -n "$engine" ] ||
    { echo "Error: R/version.R names no version; pass --line <a.b>" >&2; exit 1; }
  line=${engine%.*}
  [ "${engine##*.}" = 0 ] || released=1
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

# A released line keeps the version it was seeded with, and the prefix owed to a
# preview line would be a downgrade here -- `1.5.5.9020.47` reporting as owing
# `1.4.99.9000.47`, which the stamp below would then refuse for not rising.
if [ -n "$released" ]; then
  echo "line          $line, released"
  echo "version       $cur"
  echo "no prefix owed"
  exit 0
fi

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
