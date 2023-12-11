#!/bin/sh

set -e
set -x

cd `dirname $0`

if [ -z "$1" ]; then
  duckdir=../duckdb
else
  duckdir="$1"
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working directory not clean"
fi

if [ -n "$(git -C "$duckdir" status --porcelain)" ]; then
  echo "Error: working directory $duckdir not clean"
fi

rm -rf src/duckdb

commit=$(git -C "$duckdir" rev-parse HEAD)
echo "Importing commit $commit"

echo "R: configure"
python3 rconfigure.py

if [ $(git status --porcelain | wc -l) -le 1 ]; then
  echo "No changes."
  exit 0
fi

git add .
git commit -m "chore: Update vendored sources to duckdb/duckdb@$commit"
