#!/usr/bin/env bash
# Register repository-local git configuration that cannot live in versioned
# files. Run once per clone, and as the first step of any CI job that rebases,
# cherry-picks, or merges branches in this repo.
#
# The merge-driver *name -> command* mapping must live in .git/config; only the
# `DESCRIPTION merge=ours-version` attribute itself is committed (.gitattributes).
set -euo pipefail

cd "$(dirname "$0")/.."

git config merge.ours-version.name   "Combine DESCRIPTION version counters (see scripts/merge-version.sh)"
git config merge.ours-version.driver "scripts/merge-version.sh %O %A %B"

# Remember any genuine conflict resolutions across repeated rebases.
git config rerere.enabled true

# Merge drivers run under the merge backend (default since git 2.26); the
# patch/am backend bypasses them. Pin it so rebases honour the driver.
git config rebase.backend merge

echo "git configured: merge driver 'ours-version', rerere, rebase.backend=merge"
