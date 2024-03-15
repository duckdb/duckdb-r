#!/bin/bash
# https://unix.stackexchange.com/a/654932/19205
# Using bash for -o pipefail

set -e
set -x
set -o pipefail

cd `dirname $0`

if [ -z "$1" ]; then
  upstream_dir=../duckdb
else
  upstream_dir="$1"
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working directory not clean"
  exit 1
fi

if [ -n "$(git -C "$upstream_dir" status --porcelain)" ]; then
  echo "Warning: working directory $upstream_dir not clean"
fi

commit=$(git -C "$upstream_dir" rev-parse HEAD)
echo "Importing commit $commit"

base=$(git log -n 3 --format="%s" -- src/duckdb | tee /dev/stderr | sed -nr '/^.*duckdb.duckdb@/{s///;p;}' | head -n 1)

rm -rf src/duckdb

echo "R: configure"
DUCKDB_PATH="$upstream_dir" python3 rconfigure.py

if [ $(git status --porcelain -- src/duckdb | wc -l) -le 1 ]; then
  echo "No changes."
  git checkout -- src/duckdb
  exit 0
fi

git add .

(
  echo "chore: Update vendored sources to duckdb/duckdb@$commit"
  echo
  git -C "$upstream_dir" log --first-parent --format="%s" ${base}..${commit} | sed -r 's%(#[0-9]+)%duckdb/duckdb\1%g'
) | git commit --file /dev/stdin
