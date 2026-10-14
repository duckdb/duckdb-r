#!/bin/bash
# install.sh <worktree> <lib>: full R CMD INSTALL of the worktree into lib
set -euo pipefail
wt=$1 lib=$2
mkdir -p "$lib"
cd "$wt"
# R's make tracks no header dependencies: objects left from another commit would be linked as they are
git clean -qfdx src
MAKEFLAGS=-j4 R CMD INSTALL --no-byte-compile --no-test-load --library="$lib" . > "$lib.install.log" 2>&1 || { echo "INSTALL FAILED: $lib.install.log"; tail -30 "$lib.install.log"; exit 1; }
echo "installed $(git rev-parse --short HEAD) into $lib"
