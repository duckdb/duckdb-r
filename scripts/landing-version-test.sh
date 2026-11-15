#!/bin/bash
# Check scripts/landing-version.sh, offline.
#
# The claim is that the bump goes one above the branch landed on, under the
# larger prefix of the branch and the series. Five things are checked:
#
#   1. `main`'s first landing of its own series opens the series' prefix:
#      `2.0.0.9000` under a series on `2.0.99.9000.12` gives `2.0.99.9000`.
#   2. A later landing takes the fourth component one up: `2.0.99.9001`.
#   3. A release branch landing short of a release does the same: `2.0.0.9001`.
#   4. A released branch opens its fourth at `.9000`, whether the series is
#      behind it or on it: `2.0.1` gives `2.0.1.9000`.
#   5. Anything but a version is refused.
#
# Usage:
#   scripts/landing-version-test.sh

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
next() { "$HERE/landing-version.sh" "$@" 2>&1 || echo "exit $?"; }

echo "== 1. main's first landing"
is "the series' prefix at .9000" "$(next 2.0.0.9000 2.0.99.9000.12)" 2.0.99.9000
echo "== 2. a later landing on main"
is "the fourth one up" "$(next 2.0.99.9000 2.0.99.9000.30)" 2.0.99.9001
echo "== 3. a release branch short of a release"
is "the fourth one up" "$(next 2.0.0.9000 2.0.0.9000.4)" 2.0.0.9001
echo "== 4. a released branch"
is "a series behind it opens the fourth at .9000" "$(next 2.0.1 2.0.0.9000.7)" 2.0.1.9000
is "so does one on it" "$(next 2.0.1 2.0.1.9000.2)" 2.0.1.9000
is "and a later landing counts up from there" "$(next 2.0.1.9000 2.0.0.9000.9)" 2.0.1.9001
echo "== 5. refusals"
is "a word is not a version" "$(next main 2.0.0)" "landing-version.sh: not a version: main
exit 2"
is "one argument is a usage error" "$(next 2.0.0)" "usage: landing-version.sh <branch version> <series version>
exit 2"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
