#!/bin/bash
# Every R-side glue adaptation a series carries, in one read.
#
# Vendoring adapts the glue commit by commit: `vendor-one.sh` stops at the first
# commit whose upstream change breaks `src/`, the fix is folded into it, and an
# `R-side fix` section records what was adapted (.claude/skills/series-loop.md).
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
#
# Glue is `src/` without the vendored engine, plus `R/`, `NAMESPACE` and
# `inst/include/`. `R/version.R` and `DESCRIPTION` are excluded: they are
# version bookkeeping that `rconfigure.py` rewrites on every vendor commit, so
# leaving them in makes every commit look like a glue commit.

set -euo pipefail

cd "$(dirname "$0")/.."

what=${1:?usage: series-glue.sh <series>|<rev-range> [--diff]}
diff=${2:-}
remote=origin

GLUE=(src R NAMESPACE inst/include
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
