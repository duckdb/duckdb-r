#!/bin/sh

set -e
set -x

cd `dirname $0`

duckdir=../duckdb

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working directory not clean"
fi

if [ -n "$(git -C $duckdir status --porcelain)" ]; then
  echo "Error: working directory $duckdir not clean"
fi

commit=$(git -C $duckdir rev-parse HEAD)
echo "Importing commit $commit"

echo "R: configure"
python3 rconfigure.py

git add .
git commit -m "Update vendored sources to duckdb/duckdb@$commit"
