#!/bin/bash
# https://unix.stackexchange.com/a/654932/19205
# Using bash for -o pipefail

set -e
set -x
set -o pipefail

cd `dirname $0`

if [ -z "$1" ]; then
  upstream_basedir=../duckdb
else
  upstream_basedir="$1"
fi

upstream_dir=.git/duckdb

if [ "$upstream_base_dir" != "../duckdb" ]; then
  git clone "$upstream_basedir" "$upstream_dir"
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working directory not clean"
  exit 1
fi

if [ -n "$(git -C "$upstream_dir" status --porcelain)" ]; then
  echo "Warning: working directory $upstream_dir not clean"
fi

original=$(git -C "$upstream_dir" rev-parse --verify HEAD)

base=$(git log -n 3 --format="%s" -- src/duckdb | tee /dev/stderr | sed -nr '/^.*duckdb.duckdb@/{s///;p;}' | head -n 1)

for commit in $(git -C "$upstream_dir" log --first-parent --reverse --format="%H" ${base}..HEAD); do
  echo "Importing commit $commit"

  git -C "$upstream_dir" checkout "$commit"

  rm -rf src/duckdb

  echo "R: configure"
  DUCKDB_PATH="$upstream_dir" python3 rconfigure.py

  if [ $(git status --porcelain -- src/duckdb | wc -l) -gt 1 ]; then
    break
  fi
done

if [ $(git status --porcelain -- src/duckdb | wc -l) -le 1 ]; then
  echo "No changes."
  git checkout -- src/duckdb
  rm -rf "$upstream_dir"
  exit 0
fi

git add .

(
  echo "chore: Update vendored sources to duckdb/duckdb@$commit"
  echo
  git -C "$upstream_dir" log --first-parent --format="%s" ${base}..${commit} | sed -r 's%(#[0-9]+)%duckdb/duckdb\1%g'
) | git commit --file /dev/stdin

rm -rf "$upstream_dir"
