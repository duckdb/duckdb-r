#!/bin/sh
# Build each case and run it. Every source here is standalone -- one file, one
# main, no switches -- so any of them compiles and runs by hand against any
# libduckdb, with a compiler and nothing else.
#
#   ./run.sh                          # the fast-path libduckdb (scripts/install-libduckdb.sh)
#   ./run.sh --lib DIR                # another build, a patched one for instance
#   ./run.sh --lib DIR --include DIR
#
# TIMEOUT (default 15) bounds the two in-use cases, which never return against
# an unpatched engine. RACE_TIMEOUT (default 300) bounds the two race cases,
# which do return but pay DuckDB startup and teardown per round -- about 20 ms a
# round on the machine the README reports. ROUNDS (default 200) sets their
# length; lower it first when a race case runs past its budget, because the
# round counter is what tells being wedged from being slow.
set -eu

lib="${DUCKDB_R_LIB_DIR:-$HOME/.local/lib}"
include="${DUCKDB_R_INCLUDE_DIR:-$HOME/.local/include}"
timeout_s="${TIMEOUT:-15}"
race_timeout_s="${RACE_TIMEOUT:-300}"

while [ $# -gt 0 ]; do
  case "$1" in
    --lib)     lib="$2";     shift 2 ;;
    --include) include="$2"; shift 2 ;;
    *) echo "$0: unknown argument $1" >&2; exit 1 ;;
  esac
done

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT

for case in in-use-connection in-use-result shutdown-race; do
  cc "$here/$case.c" -I"$include" -o "$build/$case" \
    -L"$lib" -lduckdb -Wl,-rpath,"$lib" -lpthread
done

# The tight stager reaches for an internal header, which only the vendored tree
# carries; without it the three C cases still run.
vendored="$here/../../src/duckdb/src/include"
if [ -d "$vendored" ]; then
  c++ -std=c++17 "$here/shutdown-race-tight.cpp" -I"$vendored" -o "$build/shutdown-race-tight" \
    -L"$lib" -lduckdb -Wl,-rpath,"$lib" -lpthread
fi

run_case() {
  case=$1
  budget=$2
  [ -x "$build/$case" ] || return 0
  echo "=== $case ==="
  start=$(date +%s)
  if timeout -s KILL "$budget" "$build/$case"; then
    :
  else
    status=$?
    if [ "$status" -eq 137 ]; then
      echo "  did not return within ${budget}s, killed"
    else
      echo "  exited with status $status"
    fi
  fi
  echo "  ($(( $(date +%s) - start ))s)"
  echo
}

run_case in-use-connection "$timeout_s"
run_case in-use-result "$timeout_s"
run_case shutdown-race "$race_timeout_s"
run_case shutdown-race-tight "$race_timeout_s"
