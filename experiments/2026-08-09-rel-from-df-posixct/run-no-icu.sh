#!/bin/sh
# Build the vendored engine from source in a throwaway worktree and run
# no-icu.R against it, into no-icu.md.
#
# The fast path links a release `libduckdb`, which has icu in it, so icu's
# absence cannot be produced there. A source build links `parquet` and
# `core_functions` and nothing else. It installs into its own library so the
# fast-path build stays where it is.
#
# Usage: experiments/2026-08-09-rel-from-df-posixct/run-no-icu.sh
#
# Takes as long as a full engine build -- tens of minutes cold. Reuses the
# worktree and the library if they are already there.

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(git rev-parse --show-toplevel)
tree=${NOICU_TREE:-$root/../duckdb-r-noicu}
lib=${NOICU_LIB:-$HOME/R-noicu}
out=$here/no-icu.md

if [ ! -d "$tree" ]; then
  git -C "$root" worktree add --detach "$tree" HEAD
fi
mkdir -p "$lib"

printf 'building from source in %s\n' "$tree" >&2
(
  cd "$tree" &&
    env -u DUCKDB_R_USE_SYSTEM_LIB MAKEFLAGS="${MAKEFLAGS:--j4}" NOT_CRAN=true \
      R CMD INSTALL . --library="$lib" --no-byte-compile >/dev/null 2>&1
)

{
  printf '# Timestamps on a build with no icu\n\n'
  printf 'Recorded by `run-no-icu.sh`; `README.md` says what it asks.\n\n'
  printf '```\n'
  for tz in UTC Europe/Zurich; do
    R_LIBS="$lib" TZ=$tz Rscript "$here/no-icu.R" 2>&1 |
      grep -vE '^(Loading required|ℹ|duckdb is storing|This persists)'
    printf '\n'
  done
  printf '```\n'
} >"$out"

printf 'wrote %s\n' "$out" >&2
