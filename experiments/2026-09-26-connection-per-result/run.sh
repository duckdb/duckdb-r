#!/bin/sh
# Runs every case and prints the transcript. The R scripts need this tree's
# package installed on the fast path (handbook/build/fast-paths/) with nanoarrow
# and bench beside it; the C++ case compiles against the vendored headers and
# links the same libduckdb.
#
#   ./run.sh                          # the fast-path libduckdb (scripts/install-libduckdb.sh)
#   ./run.sh --lib DIR                # another build of the same commit
#
# ROWS sizes the C++ case's query (default 600000000).
set -eu

lib="${DUCKDB_R_LIB_DIR:-$HOME/.local/lib}"

while [ $# -gt 0 ]; do
  case "$1" in
    --lib) lib="$2"; shift 2 ;;
    *) echo "$0: unknown argument $1" >&2; exit 1 ;;
  esac
done

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
vendored="$here/../../src/duckdb/src/include"
build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT

for case in interleave session-state context-cost result-lifetime; do
  echo "=== $case.R ==="
  Rscript "$here/$case.R"
  echo
done

c++ -std=c++17 "$here/concurrent.cpp" -I"$vendored" -o "$build/concurrent" \
  -L"$lib" -lduckdb -Wl,-rpath,"$lib" -lpthread
echo "=== concurrent.cpp ==="
"$build/concurrent"
