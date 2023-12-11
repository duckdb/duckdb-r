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
  exit 1
fi

if [ -n "$(git -C "$duckdir" status --porcelain)" ]; then
  echo "Warning: working directory $duckdir not clean"
fi

commit=$(git -C "$duckdir" rev-parse HEAD)
echo "Importing commit $commit"

base=$(git log -n 1 --format="%s" -- src/duckdb | sed 's#^.*duckdb/duckdb@##')

rm -rf src/duckdb

echo "R: configure"
python3 rconfigure.py

if [ $(git status --porcelain -- src/duckdb | wc -l) -le 1 ]; then
  echo "No changes."
  git checkout -- src/duckdb
  exit 0
fi

git add .

(
  echo "chore: Update vendored sources to duckdb/duckdb@$commit"
  echo
  git -C "$duckdir" log --first-parent --format="%s" ${base}..${commit} | sed -r 's%(#[0-9]+)%duckdb/duckdb\1%g'
) | git commit --file /dev/stdin
