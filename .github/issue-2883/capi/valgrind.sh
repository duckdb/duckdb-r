#!/bin/bash
# Usage: capi/valgrind.sh <lib> <template> [query]
# Builds the C-API reproducer against the package's shared library in <lib> and runs it under valgrind
# on a fresh copy of <template>. The program prints icu's loaded state, then runs the query twice.
set -e
F=$(cd "$(dirname "$0")" && pwd); lib=$1; T=$2
q=${3:-"SELECT (epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00') + 2.5)::VARCHAR"}
so=$(cd "$lib/duckdb/libs" && pwd)/duckdb.so
bin=$(mktemp)
rlib="$(R RHOME)/lib"
cc -O0 -g -o "$bin" "$F/repro.c" "$so" -L"$rlib" -lR
export LD_LIBRARY_PATH="$rlib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
d=$(mktemp -d); cp -r "$T"/. "$d"/
valgrind --error-exitcode=0 "$bin" "$d" "$q" 2>&1 | grep -E "ERROR SUMMARY|^SELECT"
rm -rf "$d" "$bin"
