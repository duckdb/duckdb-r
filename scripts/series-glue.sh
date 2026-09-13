#!/bin/bash
# Every R-side glue adaptation a series carries, in one read.
#
# Vendoring adapts the glue commit by commit: `vendor-one.sh` stops at the first
# commit whose upstream change breaks `src/`, the fix is folded into it, and an
# `R-side fix` section records what was adapted (.claude/skills/series-loop/SKILL.md).
# The set of those adaptations is what a forward has to reproduce against a new
# base, and what a repair on a forward series should mine rather than rederive.
#
# Read it whole before touching any one of them. The commits are not
# independent: the same call site is adapted several times as upstream keeps
# moving it, and the last version is the one that survives. Fixing the first
# conflict a replay hits, in isolation, rederives work that a later commit in
# the same range already did -- and the two are only visibly the same file when
# the whole range is in front of you.
#
# Usage:
#   series-glue.sh <series>          # the series' whole span, oldest first
#   series-glue.sh <rev-range>       # an explicit range, e.g. main-fwd-build-base..main-fwd-build
#   series-glue.sh <what> --diff     # ... and the cumulative glue diff of it
#   series-glue.sh <what> --remote <name>
#
# --remote is spelled the same in every scripts/series-*.sh; see the shared
# contract in handbook/operations/vendoring/series-loop/README.md.
#
# Glue is `src/` without the vendored engine, plus `R/` and `NAMESPACE`.
# `R/version.R` and `DESCRIPTION` are excluded: they are
# version bookkeeping that `rconfigure.py` rewrites on every vendor commit, so
# leaving them in makes every commit look like a glue commit.

set -euo pipefail

usage='usage: series-glue.sh <series>|<rev-range> [--diff] [--remote <name>]'
argerr() { echo "$usage" >&2; exit 2; }
diff=
remote=${SERIES_REMOTE:-origin}
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --diff) diff=--diff; shift ;;
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
what=${args[0]}

# The tree to read, the same knob vendor-one.sh takes, so `main`'s copy of this
# script reads the worktree the caller is in rather than the one it lives in.
# `$(dirname "$0")/..` read its own repository whatever the caller had checked
# out, which is silently the wrong answer for every series but `main`'s. After
# the parsing, so `--help` and a usage error never touch git.
toplevel=${VENDOR_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || true)}
[ -n "$toplevel" ] || { echo "Error: $PWD is not a git worktree" >&2; exit 1; }
cd "$toplevel"

GLUE=(src R NAMESPACE
  ':(exclude)src/duckdb' ':(exclude)R/version.R' ':(exclude)DESCRIPTION')

# A series name resolves to its whole span: from where it left the mainline to
# the buffer tip, which is every vendor commit it has, verified or not. Anything
# containing `..` is taken as the range it looks like.
case "$what" in
  *..*) range=$what ;;
  *)
    build="$remote/$what-build"
    git rev-parse -q --verify "$build" >/dev/null ||
      { echo "Error: no $build, and '$what' is not a rev-range" >&2; exit 1; }
    range="$(git merge-base "$remote/main" "$build")..$build"
    ;;
esac

upstream_sha() { git log -1 --format=%s "$1" | sed -rn 's|^.*duckdb/duckdb@([0-9a-f]+).*$|\1|p'; }

mapfile -t commits < <(git log --reverse --format=%H "$range" -- "${GLUE[@]}")

echo "range: $range"
echo "glue commits: ${#commits[@]} of $(git rev-list --count "$range")"
echo

for c in "${commits[@]}"; do
  up=$(upstream_sha "$c")
  echo "--- $(git rev-parse --short "$c")${up:+  duckdb/duckdb@${up:0:9}}"
  git log -1 --format=%s "$c" | sed 's/^/    /'
  git show --stat=100 --format= "$c" -- "${GLUE[@]}" | sed '/^$/d; s/^/    /'
  # The prose the fold left behind: what upstream changed, and what the glue
  # had to do about it. Absent on a commit that touched glue for another
  # reason -- a cherry-pick from `main`, say -- and that absence is a signal.
  body=$(git log -1 --format=%b "$c" | sed -n '/^R-side fix:/,$p')
  [ -n "$body" ] && sed 's/^/    | /' <<<"$body"
  echo
done

# Which files the range keeps coming back to. A file with a high count is one
# upstream is actively moving under us, and the place a replay will conflict.
echo "files touched, most-adapted first:"
git log --format= --name-only "$range" -- "${GLUE[@]}" |
  grep . | sort | uniq -c | sort -rn | sed 's/^/  /'

if [ "$diff" = --diff ]; then
  echo
  echo "cumulative glue diff over $range:"
  git diff "${range%%..*}" "${range##*..}" -- "${GLUE[@]}"
fi
