#!/bin/sh
# Build duckdb from two git refs into two libraries and run probe.R against each.
# Usage: run.sh [ref-before] [ref-after]   (defaults: origin/main, HEAD)
#
# Linux/macOS only: it uses the DUCKDB_R_USE_SYSTEM_LIB fast path, so only the
# glue in src/ compiles and each build takes a minute rather than an hour.
# Run scripts/install-libduckdb.sh once first.
#
# Writes two worktrees and two libraries under a temporary directory, and
# removes them again. The repository is left untouched.
set -eu

before=${1:-origin/main}
after=${2:-HEAD}

repo=$(git rev-parse --show-toplevel)
probe="$(cd "$(dirname "$0")" && pwd)/probe.R"
tmp=$(mktemp -d)
trap 'git -C "$repo" worktree remove --force "$tmp/src-before" 2>/dev/null || true;
      git -C "$repo" worktree remove --force "$tmp/src-after"  2>/dev/null || true;
      rm -rf "$tmp"' EXIT

export DUCKDB_R_USE_SYSTEM_LIB=1
export MAKEFLAGS="-j$(nproc 2>/dev/null || sysctl -n hw.ncpu)"

for leg in before after; do
  eval "ref=\$$leg"
  git -C "$repo" worktree add --detach "$tmp/src-$leg" "$ref" >/dev/null
  mkdir -p "$tmp/lib-$leg"
  echo "building $leg ($ref)" >&2
  (cd "$tmp/src-$leg" && R CMD INSTALL . --no-byte-compile --library="$tmp/lib-$leg" >"$tmp/$leg.log" 2>&1) ||
    { echo "build failed, see $tmp/$leg.log" >&2; exit 1; }
done

for leg in before after; do
  eval "ref=\$$leg"
  echo
  echo "################ $leg ($ref)"
  Rscript --vanilla "$probe" "$tmp/lib-$leg" 2>&1 |
    grep -Ev '^(ℹ|duckdb is storing|This persists)'
done
