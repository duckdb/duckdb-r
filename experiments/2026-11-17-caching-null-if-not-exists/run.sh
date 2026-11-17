#!/bin/sh
# Builds repro.cpp against two engine versions and runs every variant the
# record names, printing what each prints. The record is the README.md beside
# this file.
#
# Usage: run.sh [WORK]
#   WORK  a scratch directory (default: a new one under ${TMPDIR:-/tmp});
#         a second run with the same WORK reuses its builds.
#
# Needs git, g++, make, python3 with venv, curl, and network access to
# GitHub, PyPI and extensions.duckdb.org. ccache is used when present.

set -u

here=$(cd "$(dirname "$0")" && pwd)
repo=$(git -C "$here" rev-parse --show-toplevel)
work=${1:-$(mktemp -d)}
mkdir -p "$work"
work=$(cd "$work" && pwd)
echo "work directory: $work"

# The commits whose vendored engine each version runs:
# v2.0.0 (d54cbbe3df) on main, v2.1.0-dev92210 (09456f1ce0) on main-green.
v20_commit=73ead8b6
v21_commit=8edee523

cxx="g++"
command -v ccache > /dev/null && cxx="ccache g++"

checkout() { # <dir> <commit>
  [ -d "$1" ] && return 0
  git -C "$repo" fetch -q origin main main-green
  git -C "$repo" worktree add -q --detach "$1" "$2"
}

# v2.0: the prebuilt library of that release, with the vendored headers.
checkout "$work/src-v2.0" "$v20_commit"
if [ ! -f "$work/v2.0/lib/libduckdb.so" ]; then
  "$work/src-v2.0/scripts/install-libduckdb.sh" --prefix "$work/v2.0" > /dev/null
fi

# v2.1: no prebuilt exists for a -dev build, so the vendored engine is compiled
# with the flags the package's src/Makevars passes it.
checkout "$work/src-v2.1" "$v21_commit"
if [ ! -f "$work/v2.1/libduckdb.so" ]; then
  make -s -f "$here/engine.mk" SRC="$work/src-v2.1/src" OUT="$work/v2.1" -j"$(nproc)" || exit 1
fi

$cxx -std=c++17 -O1 -w -I"$work/src-v2.0/src/duckdb/src/include" "$here/repro.cpp" -o "$work/repro-v2.0" \
  -L"$work/v2.0/lib" -lduckdb -Wl,-rpath,"$work/v2.0/lib" || exit 1
$cxx -std=c++17 -O1 -w -I"$work/src-v2.1/src/duckdb/src/include" "$here/repro.cpp" -o "$work/repro-v2.1" \
  -L"$work/v2.1" -lduckdb -Wl,-rpath,"$work/v2.1" || exit 1

# A plain HTTP server and a moto S3 server, both serving nothing at the path asked.
mkdir -p "$work/www" "$work/ext"
if [ ! -x "$work/venv/bin/moto_server" ]; then
  python3 -m venv "$work/venv" && "$work/venv/bin/pip" install -q 'moto[server]' || exit 1
fi
python3 -m http.server 8765 --bind 127.0.0.1 --directory "$work/www" > "$work/http.log" 2>&1 &
http_pid=$!
"$work/venv/bin/moto_server" -p 5555 > "$work/moto.log" 2>&1 &
moto_pid=$!
trap 'kill $http_pid $moto_pid 2> /dev/null' EXIT
sleep 3
curl -sf -X PUT http://127.0.0.1:5555/bucket > /dev/null || exit 1

ext="SET extension_directory = '$work/ext'"
secret="CREATE SECRET s3 (TYPE s3, KEY_ID 'test', SECRET 'test', REGION 'us-east-1',
  ENDPOINT '127.0.0.1:5555', USE_SSL false, URL_STYLE 'path')"

for version in v2.0 v2.1; do
  repro="$work/repro-$version"
  for mode in none always remote; do
    echo "--- $version, local, $mode"
    "$repro" "$work/www/missing.bin" "$mode"
    echo "exit status: $?"
  done
  for mode in none remote; do
    echo "--- $version, http, $mode"
    "$repro" http://127.0.0.1:8765/missing.bin "$mode" "$ext" "INSTALL httpfs" "LOAD httpfs"
    echo "exit status: $?"
    echo "--- $version, s3, $mode"
    "$repro" s3://bucket/missing.bin "$mode" "$ext" "INSTALL httpfs" "LOAD httpfs" "$secret"
    echo "exit status: $?"
  done
done
