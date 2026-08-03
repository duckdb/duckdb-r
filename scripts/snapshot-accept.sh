#!/bin/bash
# Rebuild a commit, run the suite, accept the named snapshots, re-run to
# confirm they hold. The fallback for snapshot repair when no
# snapshot-<sha>-rcc-smoke-null branch exists, or when its diff does not
# survive review (.claude/skills/series-loop.md).
# Explained in handbook/testing/snapshots/README.md.
#
# Usage: snapshot-accept.sh <commit-ish> <snapshot-name>...
#   snapshot-accept.sh abc1234 sql types
#
# Leaves the corrected files under tests/testthat/_snaps/ in the working tree
# and prints them; folding them into the offending commit is the caller's job.

set -euo pipefail

c=${1:?usage: snapshot-accept.sh <commit-ish> <snapshot-name>...}
shift
[ $# -gt 0 ] || { echo "Error: no snapshot names given"; exit 1; }

cd "$(dirname "$0")/.."
export NOT_CRAN=true DUCKDB_R_RUN_TESTS=true

# Detached on purpose: a probe must never move a branch ref.
git checkout --detach "$c"

# Every stale build product, not just objects: a stale object for a source
# upstream folded into a unity file links as a duplicate-symbol error.
git clean -fdx -- src/

R CMD INSTALL . --no-byte-compile
R -q -e 'testthat::test_local(reporter = "summary")' || true
for n in "$@"; do
  R -q -e "testthat::snapshot_accept('${n%.md}')"
done

echo "=== re-run to confirm the accepted snapshots hold ==="
R -q -e 'testthat::test_local(reporter = "summary")'

echo "=== corrected files ==="
git status --porcelain tests/testthat/_snaps/
