#!/bin/bash
# Check scripts/preview-prefix.sh, offline, in a repository built here.
#
# The claim is that a strand is owed the prefix of the line it previews, read
# from the engine it vendors, and that a fourth component above `.9000` under
# that prefix, the counter `main` advances once it carries the prefix itself,
# counts as stamped. Four things are checked:
#
#   1. A strand on a released line's version is stamped with the preview
#      prefix, the vendor counter kept.
#   2. A strand already on the prefix is left alone.
#   3. A strand on `main`'s landing counter under the prefix is left alone, and
#      --check passes on it.
#   4. A released line is owed nothing.
#
# Usage:
#   scripts/preview-prefix-test.sh
#
# Environment variables:
#   KEEP - if non-empty, do not delete the scratch directory

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SCRATCH=$(mktemp -d)
[ -n "${KEEP:-}" ] || trap 'rm -rf "$SCRATCH"' EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac; }

cd "$SCRATCH"
git init -q -b main .
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
mkdir R

strand() { # <engine> <version>: a strand vendoring <engine>, at <version>
  echo "duckdb_version <- \"$1\"" > R/version.R
  printf 'Package: duckdb\nVersion: %s\n' "$2" > DESCRIPTION
  git add -A
  git commit -qm "strand at $2" --allow-empty
}
version() { sed -n 's/^Version: //p' DESCRIPTION; }
run() { "$HERE/preview-prefix.sh" "$@" 2>&1; }

echo "== a strand on a released line's version takes the prefix"
strand 2.1.0-dev100 2.0.0.9000.12
out=$(run) || true
has "it names the line previewed" "$out" "previews      2.1"
is "the prefix is stamped, the counter kept" "$(version)" 2.0.99.9000.12
is "in a commit of its own" "$(git log -1 --format=%s)" "chore: Take the 2.1 preview prefix"

echo "== a strand on the prefix is left alone"
out=$(run) || true
has "it says so" "$out" "already stamped"
is "and commits nothing" "$(git log -1 --format=%s)" "chore: Take the 2.1 preview prefix"

echo "== main's landing counter under the prefix is the prefix"
strand 2.1.0-dev200 2.0.99.9004.0
out=$(run) || true
has "it says so" "$out" "already stamped"
is "and keeps the counter" "$(version)" 2.0.99.9004.0
run --check >/dev/null && st=0 || st=$?
is "--check passes" "$st" 0
strand 2.1.0-dev200 2.0.99.9004
run --check >/dev/null && st=0 || st=$?
is "four components as well" "$st" 0
strand 2.1.0-dev200 2.0.98.9004.3
run --check >/dev/null && st=0 || st=$?
is "but not under another prefix" "$st" 1

echo "== a released line is owed nothing"
strand 2.0.1-dev5 2.0.0.9001.3
out=$(run) || true
has "it says so" "$out" "no prefix owed"
is "and keeps the version" "$(version)" 2.0.0.9001.3

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
