#!/bin/sh
# Compile probe.c against a libduckdb and run each scenario under a watchdog.
# Needs a C compiler, a libduckdb and the matching duckdb.h -- no container, and
# nothing that is not already on a machine that builds this package.
#
#   ./run.sh                     # the fast-path libduckdb (scripts/install-libduckdb.sh)
#   ./run.sh --lib DIR           # another build, a patched one for instance
#   ./run.sh --lib DIR --include DIR
#
# Scenarios that reach an unpatched engine do not return; TIMEOUT bounds them.
set -eu

lib="${DUCKDB_R_LIB_DIR:-$HOME/.local/lib}"
include="${DUCKDB_R_INCLUDE_DIR:-$HOME/.local/include}"
timeout_s="${TIMEOUT:-15}"

while [ $# -gt 0 ]; do
  case "$1" in
    --lib)     lib="$2";     shift 2 ;;
    --include) include="$2"; shift 2 ;;
    --timeout) timeout_s="$2"; shift 2 ;;
    *) echo "$0: unknown argument $1" >&2; exit 1 ;;
  esac
done

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
probe="$(mktemp -d)/probe"
trap 'rm -rf "$(dirname "$probe")"' EXIT

cc "$here/probe.c" -I"$include" -o "$probe" -L"$lib" -lduckdb -Wl,-rpath,"$lib" -lpthread

# race.cpp reaches for an internal header, which only the vendored tree carries.
race="$(dirname "$probe")/race"
vendored="$here/../../src/duckdb/src/include"
if [ -d "$vendored" ]; then
  c++ -std=c++17 "$here/race.cpp" -I"$vendored" -o "$race" -L"$lib" -lduckdb -Wl,-rpath,"$lib" -lpthread
else
  race=""
fi

for scenario in in-use-connection in-use-result shutdown-race; do
  echo "=== $scenario ==="
  start=$(date +%s)
  if timeout -s KILL "$timeout_s" "$probe" "$scenario"; then
    :
  else
    status=$?
    if [ "$status" -eq 137 ]; then
      echo "  HUNG: still spinning after ${timeout_s}s, killed"
    else
      echo "  exited with status $status"
    fi
  fi
  echo "  ($(( $(date +%s) - start ))s)"
  echo
done

if [ -n "$race" ]; then
  echo "=== shutdown-race, staged tightly ==="
  start=$(date +%s)
  "$race" || echo "  exited with status $?"
  echo "  ($(( $(date +%s) - start ))s)"
fi
