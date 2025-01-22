#!/bin/sh

set -e
set -x

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

base=$(git log -n 3 --format="%s" -- src/duckdb | tee /dev/stderr | sed -nr '/^.*duckdb.duckdb@([0-9a-f]+)$/{s//\1/;p;}' | head -n 1)

message=

for commit in $commit; do
  echo "Importing commit $commit"

  rm -rf src/duckdb

  echo "R: configure"
  python3 rconfigure.py

  for f in patch/*.patch; do
    # cat $f | patch -p1 --dry-run
    cat $f | patch -p1
  done

  # Always vendor tags
  if [ $(git -C "$upstream_dir" describe --tags "$commit" | grep -c -- -) -eq 0 ]; then
    message="chore: Update vendored sources (tag $(git -C "$upstream_dir" describe --tags "$commit")) to duckdb/duckdb@$commit"
    break
  fi

  if [ $(git status --porcelain -- src/duckdb | wc -l) -gt 1 ]; then
    message="chore: Update vendored sources to duckdb/duckdb@$commit"
    break
  fi
done

if [ "$message" = "" ]; then
  echo "No changes."
  git checkout -- src/duckdb
  exit 0
fi


git add .

(
  echo "$message"
  echo
  git -C "$upstream_dir" log --first-parent --format="%s" ${base}..${commit} | tee /dev/stderr | sed -r 's%(#[0-9]+)%duckdb/duckdb\1%g'
) | git commit --file /dev/stdin
