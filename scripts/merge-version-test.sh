#!/bin/bash
# Check scripts/merge-version.sh, the DESCRIPTION merge driver, offline, on
# files and in a repository built here.
#
# The claim is that the driver resolves the two lines every strand writes on
# its own, and leaves every other line to a three-way merge. Four things are
# checked:
#
#   1. `Version:` takes the component-wise maximum under one prefix.
#   2. The engine record, `Config/duckdb/upstream:`, is always ours: theirs
#      never replaces it, a bump replayed included, and a side without one
#      gets none; a side without a `Version:` line keeps its record.
#   3. A port of a roxygen bump from `main` onto a branch whose engine record
#      differs applies cleanly, keeping the branch's record, below `Version:`.
#   4. Two sides that change another line differently still conflict.
#
# Usage:
#   scripts/merge-version-test.sh
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

cd "$SCRATCH"
# The engine record goes right below `Version:`, or last, right after the
# roxygen version, where an earlier recipe appended it, with END=1.
desc() { # <file> <version> [<engine>] [<roxygen>]
  {
    printf 'Package: duckdb\nVersion: %s\n' "$2"
    [ -z "${3:-}" ] || [ -n "${END:-}" ] || printf 'Config/duckdb/upstream: %s\n' "$3"
    printf 'Imports: DBI\nConfig/roxygen2/version: %s\n' "${4:-8.1.1}"
    [ -z "${3:-}" ] || [ -z "${END:-}" ] || printf 'Config/duckdb/upstream: %s\n' "$3"
  } > "$1"
}
merge() { "$HERE/merge-version.sh" O A B >/dev/null 2>&1 && echo 0 || echo $?; }
field() { sed -n "s|^$1: ||p" A; }

echo "== 1. the version"
desc O 2.0.99.9000; desc A 2.0.99.9000.5; desc B 2.0.99.9001
is "it merges" "$(merge)" 0
is "to the component-wise maximum" "$(field Version)" 2.0.99.9001.5

echo "== 2. the engine record"
desc O 2.0.99.9000 aaaa; desc A 2.0.99.9001 bbbb; desc B 2.0.99.9002 cccc
is "a bump replayed onto a branch that moved its own merges" "$(merge)" 0
is "  to ours" "$(field Config/duckdb/upstream)" bbbb
desc O 2.0.99.9000 aaaa; desc A 2.0.99.9000 bbbb; desc B 2.0.99.9000 aaaa
is "theirs leaving it alone merges" "$(merge)" 0
is "  to ours" "$(field Config/duckdb/upstream)" bbbb
desc O 2.0.99.9000; desc A 2.0.99.9000; desc B 2.0.99.9000 cccc
is "theirs adding one, a bump, merges" "$(merge)" 0
is "  and ours stays without" "$(grep -c '^Config/duckdb/upstream:' A || true)" 0
desc O 2.0.99.9000 aaaa; desc A 2.0.99.9000 bbbb; printf 'Package: duckdb\nVersion: 2.0.99.9000\nImports: DBI\nConfig/roxygen2/version: 8.1.1\n' > B
is "theirs dropping it merges" "$(merge)" 0
is "  and ours keeps it" "$(field Config/duckdb/upstream)" bbbb
printf 'Package: duckdb\nConfig/duckdb/upstream: bbbb\n' > O; cp O A; printf 'Package: duckdb\nImports: DBI\nConfig/duckdb/upstream: bbbb\n' > B
is "without a Version: line it merges" "$(merge)" 0
is "  keeping the record" "$(field Config/duckdb/upstream)" bbbb

echo "== 3. a port of a roxygen bump, the record appended right after it"
export END=1
git init -q -b main repo
cd repo
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
echo 'DESCRIPTION merge=ours-version' > .gitattributes
git config merge.ours-version.driver "$HERE/merge-version.sh %O %A %B"
desc DESCRIPTION 2.0.99.9000 aaaa000000000000000000000000000000000000 8.1.1
git add -A; git commit -qm base
git checkout -q -b rel
desc DESCRIPTION 2.0.0.9001 bbbb000000000000000000000000000000000000 8.1.1
git commit -qam 'chore: Bump version to 2.0.0.9001'
git checkout -q main
desc DESCRIPTION 2.0.99.9000 aaaa000000000000000000000000000000000000 8.2.0
git commit -qam 'chore: Bump roxygen'
R=$(git rev-parse HEAD)
git checkout -q rel
git cherry-pick -x "$R" >/dev/null 2>&1 && st=0 || st=$?
is "the pick applies cleanly" "$st" 0
is "taking roxygen's version" "$(sed -n 's/^Config\/roxygen2\/version: //p' DESCRIPTION)" 8.2.0
is "and keeping the branch's engine record" "$(sed -n 's/^Config\/duckdb\/upstream: //p' DESCRIPTION)" \
  bbbb000000000000000000000000000000000000
is "right below Version:" "$(grep -A1 '^Version:' DESCRIPTION | tail -n 1 | cut -d: -f1)" "Config/duckdb/upstream"
cd ..
unset END

echo "== 4. another line still conflicts"
desc O 2.0.99.9000 aaaa; desc A 2.0.99.9000 aaaa; desc B 2.0.99.9000 aaaa
sed -i 's/^Imports: .*/Imports: DBI, methods/' A
sed -i 's/^Imports: .*/Imports: DBI, utils/' B
is "two changes to Imports: conflict" "$(merge)" 1

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
