#!/bin/sh
# Measure how far an LTS flavor branch has drifted from the baseline it renames.
# Usage: run.sh [stable-ref] [lts-ref]   (defaults: v1.4-andium, v1.4-andium-lts)
# Reads only; fetches nothing. Fetch the two refs first if they are not local.
set -eu

stable=${1:-v1.4-andium}
lts=${2:-v1.4-andium-lts}

echo "== whole tree"
git diff --stat "$stable" "$lts" | tail -1

echo
echo "== shipped surface (what survives .Rbuildignore)"
git diff --name-only "$stable" "$lts" -- \
  DESCRIPTION NAMESPACE R src inst man tests

echo
echo "== versions"
for ref in "$stable" "$lts"; do
  printf '%s: ' "$ref"
  git show "$ref:DESCRIPTION" | grep -E '^(Package|Version):' | tr '\n' ' '
  echo
done
