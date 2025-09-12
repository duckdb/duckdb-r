#!/bin/bash
# Vendors DuckDB sources commit-by-commit from upstream repository
# Used by CI automation (.github/workflows/vendor.yaml)
# See scripts/VENDORING.md for complete documentation
# https://unix.stackexchange.com/a/654932/19205
# Using bash for -o pipefail

set -e
set -x
set -o pipefail

cd "$(dirname "$0")"/..

project=duckdb
vendor_base_dir=src/duckdb
vendor_dir=${vendor_base_dir}
repo_org=${project}
repo_name=${project}


if [ -z "$1" ]; then
  upstream_basedir=../../../${project}
else
  upstream_basedir="$1"
fi

upstream_dir=.git/${project}

if [ "$upstream_basedir" != "$upstream_dir" ]; then
  rm -rf "$upstream_dir"
  git clone "$upstream_basedir" "$upstream_dir"
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working directory not clean"
  exit 1
fi

if [ -n "$(git -C "$upstream_dir" status --porcelain)" ]; then
  echo "Warning: working directory $upstream_dir not clean"
fi

base=$(git log -n 10 --format="%s" -- ${vendor_dir} | tee /dev/stderr | sed -nr '/^.*'${repo_org}.${repo_name}'@([0-9a-f]+)( .*)?$/{s//\1/;p;}' | head -n 1)

original=$(git -C "$upstream_dir" log --first-parent --reverse --format="%H" "${base}"..HEAD)

message=
is_tag=

for commit in $original; do
  echo "Importing commit $commit"

  git -C "$upstream_dir" checkout "$commit"

  rm -rf ${vendor_dir}

  echo "R: configure"
  DUCKDB_PATH="$upstream_dir" python3 scripts/rconfigure.py

  for f in patch/*.patch; do
    if patch -i "$f" -p1 --forward --dry-run; then
      patch -i "$f" -p1 --forward --no-backup-if-mismatch
    else
      echo "Removing patch $f"
      rm "$f"
    fi
  done

  # Always vendor tags
  if [ "$(git -C "$upstream_dir" describe --tags "$commit" | grep -c -- -)" -eq 0 ]; then
    message="vendor: Update vendored sources (tag $(git -C "$upstream_dir" describe --tags "$commit")) to ${repo_org}/${repo_name}@$commit"
    is_tag=true
    break
  fi

  # Expecting two changes even if nothing else changed.
  # Need at least three changed files to consider it a real update.
  if [ "$(git status --porcelain -- ${vendor_base_dir} | wc -l)" -gt 2 ]; then
    message="vendor: Update vendored sources to ${repo_org}/${repo_name}@$commit"
    break
  fi
done

if [ "$message" = "" ]; then
  echo "No changes."
  git checkout -- ${vendor_base_dir}
  rm -rf "$upstream_dir"
  exit 0
fi

our_tag=$(git describe --tags --abbrev=0 | sed -r 's/-[0-9]$//')
upstream_tag=$(git -C "$upstream_dir" describe --tags --abbrev=0)

if [ "$our_tag" = "v1.3.3" ]; then
  # Inofficial release v1.3.3
  our_tag="v1.3.2"
fi

echo "Our tag: $our_tag"
echo "Upstream tag: $upstream_tag"

if [ -z "${is_tag}" ] && [ "${our_tag#"$upstream_tag"}" == "$our_tag" ]; then
  echo "Not vendoring because our tag $our_tag does not start with upstream tag $upstream_tag"
  git checkout -- ${vendor_base_dir} R/version.R
  rm -rf "$upstream_dir"
  exit 0
fi

git add .

(
  echo "$message"
  echo
  git -C "$upstream_dir" log --first-parent --format="%s" "${base}".."${commit}" |
    tee /dev/stderr |
    sed -r 's%(#[0-9]+)%'${repo_org}/${repo_name}'\1%g'
) | git commit --file /dev/stdin

rm -rf "$upstream_dir"
