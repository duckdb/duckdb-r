#!/bin/sh
# Run defaults-grid.R for the shipped tree and for pin-session, over three
# machine zones, into defaults.md.
#
# Separate from run.sh because it asks a different question: run.sh sets the
# session zone in every cell and compares check policies; this one sets
# nothing and asks whether the answer moves with the machine.
#
# Usage: DUCKDB_R_USE_SYSTEM_LIB=1 experiments/2026-08-09-rel-from-df-posixct/run-defaults.sh
#
# Needs a clean tree: pin-session.patch is a context diff against the
# committed files, reverted with `git apply -R`.

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(git rev-parse --show-toplevel)
out=$here/defaults.md
patch=$here/patches/pin-session.patch

run() {
  policy=$1
  printf 'running %s\n' "$policy" >&2
  (cd "$root" && R CMD INSTALL . --no-byte-compile >/dev/null 2>&1)
  {
    printf '\n## %s\n\n' "$policy"
    printf '```\n'
    for tz in UTC Etc/UTC Europe/Zurich; do
      TZ=$tz POLICY="$policy" Rscript "$here/defaults-grid.R" 2>&1 |
        grep -v '^Loading required'
    done
    printf '```\n'
  } >>"$out"
}

{
  printf '# What the defaults do, per machine zone\n\n'
  printf 'Recorded by `run-defaults.sh`; `README.md` says what the columns\n'
  printf 'mean. `rel` is `rel_from_df()` then `rel_to_altrep()`; `dbi` is\n'
  printf '`dbWriteTable()` then `dbReadTable()`. Nothing calls `SET TimeZone`.\n'
} >"$out"

run shipped

git -C "$root" apply "$patch"
# shellcheck disable=SC2064
trap "git -C '$root' apply -R '$patch'" EXIT INT TERM
run pin-session
git -C "$root" apply -R "$patch"
trap - EXIT INT TERM

printf 'rebuilding the shipped tree\n' >&2
(cd "$root" && R CMD INSTALL . --no-byte-compile >/dev/null 2>&1)
