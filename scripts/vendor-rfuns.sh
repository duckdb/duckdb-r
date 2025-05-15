#!/bin/sh

set -e
set -x

cd "$(dirname "$0")"/..

if [ -z "$1" ]; then
  upstream_dir=../duckdb-rfuns
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

  echo "Copy"
  cat "$upstream_dir"/src/*.cpp > src/rfuns.cpp
  cp "$upstream_dir"/src/include/* src/include/

  if [ $(git status --porcelain -- src/ | wc -l) -gt 0 ]; then
    message="chore: Update vendored sources to hannes/duckdb-rfuns@$commit"
    break
  fi
done

if [ "$message" = "" ]; then
  echo "No changes."
  git checkout -- src/
  exit 0
fi


git add .

(
  echo "$message"
  echo
  git -C "$upstream_dir" log --first-parent --format="%s" ${base}..${commit} | tee /dev/stderr | sed -r 's%(#[0-9]+)%duckdb/duckdb\1%g'
) | git commit --file /dev/stdin
