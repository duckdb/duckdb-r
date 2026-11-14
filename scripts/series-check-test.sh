#!/bin/bash
# Check how scripts/series-check.sh classifies a red commit, offline, against a
# synthetic fork and verdict store built here: no network, no fixtures on disk.
#
# The claim is that the verdict line answers on what the commit's log contains,
# as stage 2's table answers it (.claude/skills/series-loop/SKILL.md): a tree
# row before any rerun, and a red from gate `warnings` never dropped. One log
# per case, each the only red in flight:
#
#   1. A vendored warning is a REPAIR by a patch on the vendor strand, not glue.
#   2. A glue warning is a REPAIR at origin.
#   3. Both scopes at once name both answers.
#   4. A vendored warning beside a refused download is a REPAIR, not a RETRY.
#   5. A test failure carries the warnings found beside it.
#   6. The gate's two harness failures are fixed on `main`, not in the commit.
#   7. A refused download on its own is still a RETRY.
#
# Usage:
#   scripts/series-check-test.sh
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
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3"; echo "        actual: $2" ;; esac; }
hasnt() { case "$2" in *"$3"*) no "$1"; echo "    unexpected: $3" ;; *) ok "$1" ;; esac; }

# --- the fixture -----------------------------------------------------------
#
# A series `v9.9-x` with one vendor commit in flight above its green, a store
# holding a failure record and a log for it, and an empty upstream, so the
# release-line and tag checks read a local repository rather than GitHub.

FORK=$SCRATCH/fork.git
UP=$SCRATCH/upstream.git
WORK=$SCRATCH/work
STORE=$SCRATCH/store
for r in "$FORK" "$UP"; do git init -q --bare -b main "$r"; done

identity() { git -C "$1" config user.name Test; git -C "$1" config user.email test@example.invalid
  git -C "$1" config commit.gpgsign false; }

git init -q -b main "$WORK"
identity "$WORK"
cd "$WORK"
git remote add origin "$FORK"
mkdir -p scripts src/duckdb
for s in series-check.sh series-lib.sh series-config.sh series-tests.sh; do
  cp "$HERE/$s" scripts/
done
echo 'engine 0' > src/duckdb/engine.cpp
git add -A
git commit -qm 'vendor: Update vendored sources to duckdb/duckdb@0000000 (#1)'
git commit -q --allow-empty -m 'chore: Add fifth version component'
SEED=$(git rev-parse HEAD)
echo 'engine aaaa111' > src/duckdb/engine.cpp
git commit -qam 'vendor: Update vendored sources to duckdb/duckdb@aaaa111'
RED=$(git rev-parse HEAD)
git push -q origin main "$RED:refs/heads/v9.9-x-dev" "$RED:refs/heads/v9.9-x-build" \
  "$RED:refs/heads/v9.9-x-vendor" "$SEED:refs/heads/v9.9-x-green" "$SEED:refs/heads/v9.9-x-build-base"

git init -q -b rcc2 "$STORE"
identity "$STORE"
git -C "$STORE" remote add origin "$FORK"

# store <failed stages, as JSON> <log>: publish the red commit's record and log,
# in the shapes scripts/each-shard.sh writes them.
store() {
  local at=${RED:0:2}
  mkdir -p "$STORE/runs2.d/$at" "$STORE/logs2.d/$at"
  printf '{"commit":"%s","status":{"context":"rcc","state":"failure"},"run":{"head_branch":"v9.9-x-dev"},"timing":{"shard":0,"duration_seconds":900,"exit_code":1,"failed_stages":%s}}\n' \
    "$RED" "$1" > "$STORE/runs2.d/$at/$RED.ndjson"
  printf '%s\n' "$2" > "$STORE/logs2.d/$at/$RED.log"
  git -C "$STORE" add -A
  git -C "$STORE" commit -qm "verdict for $RED" --allow-empty
  git -C "$STORE" push -q -f origin rcc2
}

# The verdict series-check.sh gives the red commit: its line and the one below.
verdict() {
  UPSTREAM_URL=$UP scripts/series-check.sh v9.9-x --canonical '' 2>&1 |
    grep -A1 -E '^  (REPAIR|RETRY|WAIT) '
}

# What scripts/rcc-one.sh and scripts/warnings.sh print, piece by piece. The
# gate's verdict is printed twice, as rcc-one.sh repeats it at the end.
vendored='-- vendored warnings (1):
   /tmp/pkg/src/duckdb/src/function/table/range.cpp:42:7: warning: '"'"'x'"'"' may be used uninitialized [-Wmaybe-uninitialized]
-- vendored: not clean. Fix the cause; handbook/build/warnings/ says where.'
glue_clean='== glue: 15 translation units
-- glue: clean'
glue_dirty='== glue: 15 translation units
-- glue warnings (1):
   rapi.cpp:10:5: warning: declaration of '"'"'n'"'"' shadows a member [-Wshadow]
-- glue: not clean. Fix the cause; handbook/build/warnings/ says where.'
network="Error in download.file(url, destfile): cannot open URL 'https://example.invalid/x'"
test_red="── Error ('test-sql.R:12:3'): queries run ──"
red_log() { # <warnings gate output> <later output> <summary rows>
  printf '::group::gate: warnings\n%s\n::endgroup::\n%s\n| Gate | Result |\n| --- | --- |\n%s\n\ngate warnings, repeated:\n%s\n' \
    "$1" "$2" "$3" "$1"
}

echo "=== 1. a vendored warning"
store '["warnings"]' "$(red_log "$vendored
$glue_clean" "" "| warnings | FAIL failure |")"
out=$(verdict)
has "is a REPAIR" "$out" "REPAIR $RED"
has "by a patch on the vendor strand" "$out" "vendored warning: a patch/ entry on the vendor strand, folded into this commit"
hasnt "not by the glue" "$out" "glue"

echo "=== 2. a glue warning"
store '["warnings"]' "$(red_log "$glue_dirty" "" "| warnings | FAIL failure |")"
out=$(verdict)
has "is a REPAIR" "$out" "REPAIR $RED"
has "at origin" "$out" "glue warning: fix the glue at origin"
hasnt "and names no patch" "$out" "patch/"

echo "=== 3. both scopes"
store '["warnings"]' "$(red_log "$vendored
$glue_dirty" "" "| warnings | FAIL failure |")"
out=$(verdict)
has "names both answers" "$out" "vendored warning: a patch/ entry on the vendor strand, folded into this commit; glue warning: fix the glue at origin"

echo "=== 4. a vendored warning beside a refused download"
store '["warnings","pkgdown"]' "$(red_log "$vendored
$glue_clean" "$network" "| warnings | FAIL failure |
| pkgdown | FAIL failure |")"
out=$(verdict)
has "is a REPAIR" "$out" "REPAIR $RED"
hasnt "not a RETRY" "$out" "RETRY"
has "by a patch on the vendor strand" "$out" "vendored warning: a patch/ entry on the vendor strand"

echo "=== 5. a test failure beside a vendored warning"
store '["warnings","check"]' "$(red_log "$vendored
$glue_clean" "$test_red" "| warnings | FAIL failure |
| check | FAIL failure |")"
out=$(verdict)
has "names the test" "$out" "test failure (Error ('test-sql.R:12:3'))"
has "and carries the warning" "$out" "; and vendored warning: a patch/ entry on the vendor strand"

echo "=== 6. the gate's harness failures"
store '["warnings"]' "$(red_log "warnings: no install log at /tmp/tmp.abc, so the vendored scope is not judged
$glue_clean" "" "| warnings | FAIL failure |")"
out=$(verdict)
has "a missing install log is a REPAIR" "$out" "REPAIR $RED"
has "on main" "$out" "gate warnings found no install log: fix scripts/rcc-one.sh or its job on main, not this commit"
store '["warnings"]' "$(red_log "-- vendored: clean
== glue: 15 translation units
-- glue does not compile:
   cc1plus: error: unrecognized command-line option '-fdiagnostics-plain-output'" "" "| warnings | FAIL failure |")"
out=$(verdict)
has "a scope that does not compile is a REPAIR" "$out" "REPAIR $RED"
has "on main" "$out" "gate warnings could not compile the glue scope the install built: fix scripts/warnings.sh on main, not this commit"
hasnt "and not the glue" "$out" "fix the glue"

echo "=== 7. a refused download on its own"
store '["pkgdown"]' "$(red_log "-- vendored: clean
$glue_clean" "$network" "| pkgdown | FAIL failure |")"
out=$(verdict)
has "is a RETRY" "$out" "RETRY  $RED"
has "for the gate that reached out" "$out" "network failure in the pkgdown gate"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
