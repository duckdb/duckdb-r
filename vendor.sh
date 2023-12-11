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

commit=$(git -C "$duckdir" rev-parse HEAD)
echo "Importing commit $commit"

base=$(git log -n 1 --format="%s" -- src/duckdb | sed 's#^.*duckdb/duckdb@##')

rm -rf src/duckdb

echo "R: configure"
python3 rconfigure.py

if [ $(git status --porcelain | wc -l) -le 1 ]; then
  echo "No changes."
  exit 0
fi

git add .

(
  echo "chore: Update vendored sources to duckdb/duckdb@$commit"
  echo
  git -C "$duckdir" log --first-parent --format="%s" ${base}..${commit} | sed -r 's%(#[0-9]+)%duckdb/duckdb\1%g'
) | git commit --file /dev/stdin
