#!/bin/sh
# Run grid.R once per policy, rebuilding the glue in between, into grid.md.
#
# The shipped tree is the `timestamp-rel` policy; the other three are the
# patches under patches/, applied with `git apply` and reverted after the run,
# so the working tree is where it started whether or not a build fails. The
# shipped tree is rebuilt at the end, because the last build installed was a
# patched one.
#
# Usage: DUCKDB_R_USE_SYSTEM_LIB=1 experiments/2026-08-09-rel-from-df-posixct/run.sh
#
# Needs a clean tree: the `baseline` policy checks R/ and src/ out at
# BASELINE_REV (default origin/main) and back, and the patches are context
# diffs against the committed files, reverted with `git apply -R`.

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(git rev-parse --show-toplevel)
out=$here/grid.md

build_and_run() {
  policy=$1
  printf 'running %s\n' "$policy" >&2
  (cd "$root" && R CMD INSTALL . --no-byte-compile >/dev/null 2>&1)
  {
    printf '\n## %s\n\n' "$policy"
    printf '```\n'
    POLICY="$policy" Rscript "$here/grid.R" 2>&1
    printf '```\n'
  } >>"$out"
}

{
  printf '# `rel_from_df()` POSIXct grid\n\n'
  printf 'Recorded by `run.sh`; what each column means is in `README.md`.\n'
} >"$out"

# The baseline is the tree without `posixct` at all: the row every other
# policy is compared against, measured rather than remembered.
git -C "$root" checkout -q "${BASELINE_REV:-origin/main}" -- R src
trap 'git -C "$root" checkout -q HEAD -- R src' EXIT INT TERM
build_and_run baseline
git -C "$root" checkout -q HEAD -- R src
trap - EXIT INT TERM

build_and_run timestamp-rel

for policy in follow session-tz relaxed; do
  patch=$here/patches/$policy.patch
  git -C "$root" apply "$patch"
  # shellcheck disable=SC2064
  trap "git -C '$root' apply -R '$patch'" EXIT INT TERM
  build_and_run "$policy"
  git -C "$root" apply -R "$patch"
  trap - EXIT INT TERM
done

printf 'rebuilding the shipped tree\n' >&2
(cd "$root" && R CMD INSTALL . --no-byte-compile >/dev/null 2>&1)
