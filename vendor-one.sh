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

if [ "$upstream_basedir" != ".git/duckdb" ]; then
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

base=$(git log -n 3 --format="%s" -- src/duckdb | tee /dev/stderr | sed -nr '/^.*duckdb.duckdb@([0-9a-f]+)$/{s//\1/;p;}' | head -n 1)

message=

for commit in $(git -C "$upstream_dir" log --first-parent --reverse --format="%H" ${base}..HEAD); do
  echo "Importing commit $commit"

  git -C "$upstream_dir" checkout "$commit"

  rm -rf src/duckdb

  echo "R: configure"
  DUCKDB_PATH="$upstream_dir" python3 rconfigure.py

  for f in patch/*.patch; do
    if cat $f | patch -p1 --dry-run; then
      cat $f | patch -p1
    else
      echo "Patch $f does not apply, skipping it and remaining patches"
      break
    fi
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
  rm -rf "$upstream_dir"
  exit 0
fi

our_tag=$(git describe --tags --abbrev=0 | sed -r 's/-[0-9]$//')
upstream_tag=$(git -C "$upstream_dir" describe --tags --abbrev=0)

echo "Our tag: $our_tag"
echo "Upstream tag: $upstream_tag"

if [ "${our_tag#$upstream_tag}" == "$our_tag" ]; then
  echo "Not vendoring because our tag $our_tag does not start with upstream tag $upstream_tag"
  git checkout -- src/duckdb
  rm -rf "$upstream_dir"
  exit 0
fi

git add .

(
  echo "$message"
  echo
  git -C "$upstream_dir" log --first-parent --format="%s" ${base}..${commit} | tee /dev/stderr | sed -r 's%(#[0-9]+)%duckdb/duckdb\1%g'
) | git commit --file /dev/stdin

rm -rf "$upstream_dir"
