#!/bin/bash
# Vendors DuckDB sources from upstream repository (manual vendoring)
# For manual testing and development use
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

upstream_dir=${project}

if [ "$upstream_basedir" != "$upstream_dir" ]; then
  git clone "$upstream_basedir" "$upstream_dir"
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working directory not clean"
  exit 1
fi

if [ -n "$(git -C "$upstream_dir" status --porcelain)" ]; then
  echo "Warning: working directory $upstream_dir not clean"
fi

# The upstream SHA the branch has vendored. The pathspec narrows the walk, the
# subject decides: the patch stack is applied to the vendored tree in place, so
# commits land under ${vendor_dir} carrying no upstream SHA, and this looks past
# them -- bounded, so git ends the walk itself.
#
# Answering empty is not an option here, which is why this refuses instead: an
# empty base makes the message body below read `${base}..${commit}` with a
# missing left side, which git resolves to the clone's HEAD and which writes a
# changelog nobody chose. The same rule, and the same bound, as vendored_sha()
# in scripts/series-advance.sh; scripts/vendor-one.sh has its own copy.
base_scan_depth="${BASE_SCAN_DEPTH:-20}"
subjects=$(git log -n "${base_scan_depth}" --format="%s" -- ${vendor_dir} | tee /dev/stderr)
base=$(sed -nr '/^.*'${repo_org}.${repo_name}'@([0-9a-f]+)( .*)?$/{s//\1/;p;}' <<<"$subjects" | head -n 1)
if [ -z "$base" ]; then
  n=$(grep -c . <<<"$subjects" || true)
  echo "Error: no ${repo_org}/${repo_name}@ subject among the newest $n ${vendor_dir} commit(s)" >&2
  if [ "$n" -ge "${base_scan_depth}" ]; then
    echo "  the scan is bounded at ${base_scan_depth}; if that is genuinely too shallow, raise BASE_SCAN_DEPTH" >&2
  fi
  exit 1
fi

original=$(git -C "$upstream_dir" rev-parse --verify HEAD)

message=
is_tag=

for commit in $original; do
  echo "Importing commit $commit"

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

  # Expecting one change under ${vendor_base_dir} (and other changes) even if nothing else changed.
  # Need at least three changed files to consider it a real update.
  if [ "$(git status --porcelain -- ${vendor_base_dir} | wc -l)" -gt 1 ]; then
    message="vendor: Update vendored sources to ${repo_org}/${repo_name}@$commit"
    break
  fi
done

if [ "$message" = "" ]; then
  echo "No changes."
  git checkout -- ${vendor_base_dir} R/version.R
  rm -rf "$upstream_dir"
  exit 0
fi

git add .

(
  echo "$message"
  echo
  git -C "$upstream_dir" log -1 --format="Date: %ai" "${commit}"
  echo
  git -C "$upstream_dir" log --first-parent --format="%s" "${base}".."${commit}" |
    tee /dev/stderr |
    sed -r 's%#([0-9]+)%https://redirect.github.com/'${repo_org}/${repo_name}'/pull/\1%g'
) | git commit --file /dev/stdin

rm -rf "$upstream_dir"

# Remove "unused" warnings
# Keep the variable for consistency between vendor.sh and vendor-one.sh
true "${is_tag}"
