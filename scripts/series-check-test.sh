#!/bin/bash
# Check how scripts/series-check.sh classifies a red commit, offline, against a
# synthetic fork and verdict store built here: no network, no fixtures on disk.
#
# The claim is that the verdict line answers on what the commit's log contains,
# as stage 2's table answers it (.claude/skills/series-loop/SKILL.md): a tree
# or harness row before any rerun, and neither a red from gate `warnings` nor
# its harness ever dropped. One log per case, each the only red in flight:
#
#   1. A vendored warning is a REPAIR by a patch on the vendor strand, not glue.
#   2. A glue warning is a REPAIR at origin.
#   3. Both scopes at once name both answers.
#   4. A vendored warning beside a refused download is a REPAIR, not a RETRY.
#   5. A test failure carries the warnings found beside it.
#   6. The gate's harness failures, each signature and a record naming the gate
#      alone, are folded into the commit and sent to `main`, never glue.
#   7. A harness failure is carried beside a warning or a test failure.
#   8. A refused download on its own is still a RETRY, and so is one beside a
#      listing the install printed while the gate was deselected.
#
# And one report about branches rather than a red commit:
#
#   9. FORWARD-PORT counts the commits of the CRAN line's release branch that
#      `main` has not grafted: vendor commits and release paperwork by number,
#      each R-side commit listed as picked (by patch-id or a `cherry picked from
#      commit` trailer either way) or not yet; none once `main` has grafted the
#      branch, a graft's second parent never counting as `main`'s own. Nothing
#      before the branch is cut, a quoted declaration reads the same, and a
#      branch it cannot read, without a canonical remote or with no merge base
#      with `main`, is reported as missing data.
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

# What scripts/rcc-one.sh and scripts/warnings.sh print, piece by piece. A real
# log carries a vendored listing three times: the install the scope rides scans
# its own log, the gate scans it again, and rcc-one.sh repeats the gate's verdict
# at the end.
vendored='-- vendored warnings (1):
   /tmp/pkg/src/duckdb/src/function/table/range.cpp:42:7: warning: '"'"'x'"'"' may be used uninitialized [-Wmaybe-uninitialized]
-- vendored: not clean. Fix the cause; handbook/build/warnings/ says where.'
glue_clean='== glue: 15 translation units
-- glue: clean'
glue_dirty='== glue: 15 translation units
-- glue warnings (1):
   rapi.cpp:10:5: warning: declaration of '"'"'n'"'"' shadows a member [-Wshadow]
-- glue: not clean. Fix the cause; handbook/build/warnings/ says where.'
glue_broken='== glue: 15 translation units
-- glue does not compile:
   cc1plus: error: unrecognized command-line option '"'"'-fdiagnostics-plain-output'"'"''
no_log='warnings: no install log at /tmp/tmp.abc, so the vendored scope is not judged'
network="Error in download.file(url, destfile): cannot open URL 'https://example.invalid/x'"
test_red="── Error ('test-sql.R:12:3'): queries run ──"
red_log() { # <install scan> <warnings gate output> <later output> <summary rows>
  printf '::group::install\n%s\n* DONE (duckdb)\n::endgroup::\n::group::gate: warnings\n%s\n::endgroup::\n%s\n| Gate | Result |\n| --- | --- |\n%s\n\ngate warnings, repeated:\n%s\n' \
    "$1" "$2" "$3" "$4" "$2"
}
gate_red='| warnings | FAIL failure |'

echo "=== 1. a vendored warning"
store '["warnings"]' "$(red_log "$vendored" "$vendored
$glue_clean" "" "$gate_red")"
out=$(verdict)
has "is a REPAIR" "$out" "REPAIR $RED"
has "by a patch on the vendor strand" "$out" "vendored warning: a patch/ entry on the vendor strand, folded into this commit"
hasnt "not by the glue" "$out" "glue"

echo "=== 2. a glue warning"
store '["warnings"]' "$(red_log "-- vendored: clean" "$glue_dirty" "" "$gate_red")"
out=$(verdict)
has "is a REPAIR" "$out" "REPAIR $RED"
has "at origin" "$out" "glue warning: fix the glue at origin"
hasnt "and names no patch" "$out" "patch/"

echo "=== 3. both scopes"
store '["warnings"]' "$(red_log "$vendored" "$vendored
$glue_dirty" "" "$gate_red")"
out=$(verdict)
has "names both answers" "$out" "vendored warning: a patch/ entry on the vendor strand, folded into this commit; glue warning: fix the glue at origin"

echo "=== 4. a vendored warning beside a refused download"
store '["warnings","pkgdown"]' "$(red_log "$vendored" "$vendored
$glue_clean" "$network" "$gate_red
| pkgdown | FAIL failure |")"
out=$(verdict)
has "is a REPAIR" "$out" "REPAIR $RED"
hasnt "not a RETRY" "$out" "RETRY"
has "by a patch on the vendor strand" "$out" "vendored warning: a patch/ entry on the vendor strand"

echo "=== 5. a test failure beside a vendored warning"
store '["warnings","check"]' "$(red_log "$vendored" "$vendored
$glue_clean" "$test_red" "$gate_red
| check | FAIL failure |")"
out=$(verdict)
has "names the test" "$out" "test failure (Error ('test-sql.R:12:3'))"
has "and carries the warning" "$out" "; and vendored warning: a patch/ entry on the vendor strand"

echo "=== 6. the gate's harness failures"
fold="fold the fix into this commit, which its own scripts judge, and send it to main (stage 7)"
store '["warnings"]' "$(red_log "-- vendored: clean" "$no_log
$glue_clean" "" "$gate_red")"
out=$(verdict)
has "a missing install log is a REPAIR" "$out" "REPAIR $RED"
has "of rcc-one.sh, folded and sent to main" "$out" "gate warnings found no install log, so fix scripts/rcc-one.sh, $fold"
store '["warnings"]' "$(red_log "-- vendored: clean" "-- vendored: clean
$glue_broken" "" "$gate_red")"
out=$(verdict)
has "a scope that does not compile is a REPAIR" "$out" "REPAIR $RED"
has "of warnings.sh, folded and sent to main" "$out" "gate warnings could not compile the glue scope the install built, so fix scripts/warnings.sh, $fold"
hasnt "and not the glue" "$out" "fix the glue"
store '["warnings"]' "$(red_log "-- vendored: clean" "-- vendored: clean
Error: could not compose the compile flags.
       R CMD config CXX17 said: (nothing)" "" "$gate_red")"
out=$(verdict)
has "flags it cannot compose are the harness's" "$out" "gate warnings could not compose its compile flags, so fix scripts/warnings.sh, $fold"
hasnt "not a failed stage" "$out" "did not run"
store '["warnings"]' "$(red_log "-- vendored: clean" "-- vendored: clean
scripts/warnings.sh: line 1: mktemp: command not found" "" "$gate_red")"
out=$(verdict)
has "a record naming the gate alone is the harness's" "$out" "gate warnings failed without a verdict on the tree, so fix its scripts, $fold"
hasnt "never the glue" "$out" "glue"

echo "=== 7. a harness failure beside a warning or a test failure"
store '["warnings"]' "$(red_log "$vendored" "$vendored
$glue_broken" "" "$gate_red")"
out=$(verdict)
has "the warning leads" "$out" "vendored warning: a patch/ entry on the vendor strand"
has "and carries the harness" "$out" "; and harness: gate warnings could not compile the glue scope the install built"
store '["warnings","check"]' "$(red_log "-- vendored: clean" "$no_log
$glue_clean" "$test_red" "$gate_red
| check | FAIL failure |")"
out=$(verdict)
has "the test leads" "$out" "test failure (Error ('test-sql.R:12:3'))"
has "and carries the harness" "$out" "; and harness: gate warnings found no install log"

echo "=== 8. a refused download on its own"
store '["pkgdown"]' "$(red_log "-- vendored: clean" "-- vendored: clean
$glue_clean" "$network" "| warnings | OK success |
| pkgdown | FAIL failure |")"
out=$(verdict)
has "is a RETRY" "$out" "RETRY  $RED"
has "for the gate that reached out" "$out" "network failure in the pkgdown gate"
store '["pkgdown"]' "$(printf '::group::install\n%s\n* DONE (duckdb)\n::endgroup::\n%s\n| Gate | Result |\n| --- | --- |\n%s\n' \
  "$vendored" "$network" "| warnings | -- skipped |
| pkgdown | FAIL failure |")"
out=$(verdict)
has "beside the install's own listing, with the gate deselected" "$out" "RETRY  $RED"
hasnt "which is no warning" "$out" "vendored warning"

echo "=== 9. what main has not grafted of the CRAN line"
CANON=$SCRATCH/canonical.git
git init -q --bare -b main "$CANON"
git remote add canon "$CANON"
fwd() { UPSTREAM_URL=$UP scripts/series-check.sh v9.9-x --canonical canon 2>&1 | sed -n '/^FORWARD-PORT/,$p'; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
git checkout -q -b cmain main
printf 'flavors:\n  - flavor: duckdb\n    kind: CRAN\n    upstream: "rel"\n    publishes_from: main\n' > scripts/series.yaml
git add -A; git commit -qm 'chore: Declare the flavors'
git push -q canon cmain:main
is "nothing before the line's branch is cut" "$(fwd)" ""

git push -q -f origin cmain:main
out=$(UPSTREAM_URL=$UP scripts/series-check.sh v9.9-x --canonical '' 2>&1 | sed -n '/^FORWARD-PORT/,$p')
has "without a canonical remote or a mirror, it says it could not read" "$out" "could not read rel beside main"

git checkout -q -b rel cmain
for e in bbbb222 bbbb223 bbbb224; do
  echo "engine $e" > src/duckdb/engine.cpp
  git commit -qam "vendor: Update vendored sources to duckdb/duckdb@$e"
done
echo 'Version: 9.9.0.9001' > DESCRIPTION; echo '# duckdb 9.9.0.9001' > NEWS.md
git add -A; git commit -qm 'chore: Bump version to 9.9.0.9001'
printf 'Version: 9.9.0.9001\nImports: DBI (>= 1.2)\n' > DESCRIPTION
git add -A; git commit -qm 'fix: Require DBI >= 1.2'
DBI=$(git rev-parse HEAD)
printf 'Version: 9.9.0.9002\nImports: DBI (>= 1.2)\n' > DESCRIPTION; echo '# duckdb 9.9.0.9002' > NEWS.md
git add -A; git commit -qm 'Increment version number'
printf 'Version: 9.9.0.9003\nImports: DBI (>= 1.2)\n' > DESCRIPTION; echo 'synced' > sync.R
git add -A; git commit -qm 'chore: Bump version to 9.9.0.9003'
SYNC=$(git rev-parse HEAD)
echo 'fix a' > a.R; git add -A; git commit -qm 'fix: A, picked onto main'
A=$(git rev-parse HEAD)
echo 'fix b' > b.R; git add -A; git commit -qm 'fix: B, the same patch on main'
echo 'fix c' > c.R; git add -A; git commit -qm 'fix: C, not picked yet'
C=$(git rev-parse HEAD)
git checkout -q cmain
echo 'fix d' > d.R; git add -A; git commit -qm 'fix: D, born on main'
D=$(git rev-parse HEAD)
git cherry-pick -x "$A" >/dev/null
echo 'fix a, edited' > a.R; git commit -q --amend -a --no-edit
echo 'fix b' > b.R; git add -A; git commit -qm 'fix: B, written again on main'
git checkout -q rel
git cherry-pick -x "$D" >/dev/null
echo 'fix d, as rel needs it' > d.R; git commit -q --amend -a --no-edit
git push -q canon cmain:main rel
git checkout -q main
out=$(fwd)
has "it counts what main has not grafted" "$out" "rel has 11 commit(s) main has not grafted: 3 vendor, 2 release paperwork,"
has "and the R-side commits" "$out" "6 R-side, 3 of them not yet picked"
has "a bump that also carries R-side files is listed" "$out" "$(git rev-parse --short "$SYNC") not yet  chore: Bump version to 9.9.0.9003"
has "a DESCRIPTION change beyond the version is R-side" "$out" "$(git rev-parse --short "$DBI") not yet  fix: Require DBI >= 1.2"
hasnt "a version-only change under another subject is paperwork" "$out" "Increment version number"
has "a pick with -x, edited, is picked" "$out" "picked   fix: A"
has "the same patch is picked" "$out" "picked   fix: B"
has "a backport from main is picked" "$out" "picked   fix: D"
hasnt "vendor commits are not listed one by one" "$out" "bbbb22"
hasnt "nor a bump that is only paperwork" "$out" "Bump version to 9.9.0.9001"
has "the rest is not yet" "$out" "$(git rev-parse --short "$C") not yet  fix: C"
git push -q -f origin cmain:main rel:rel
has "without a canonical remote it reads the fork's mirrors" \
  "$(UPSTREAM_URL=$UP scripts/series-check.sh v9.9-x --canonical '' 2>&1 | sed -n '/^FORWARD-PORT/,$p')" "rel has 11 commit(s)"

git checkout -q cmain
git cherry-pick -x "$C" >/dev/null
git merge -q -s ours --no-edit -m 'Graft rel

Declined: the vendor commit, the engine main takes from upstream main.' rel
git push -q canon cmain:main
git checkout -q main
# A copy of main fetched before the graft is refreshed, not read stale.
git update-ref "refs/remotes/canon/main" "$(git rev-parse cmain^1)"
is "nothing once main has grafted the branch" "$(fwd)" ""

git checkout -q rel
echo 'fix e' > e.R; git add -A; git commit -qm 'fix: E, after the graft'
git push -q canon rel
git checkout -q cmain
echo 'fix f' > f.R; git add -A; git commit -qm 'fix: F, main after the graft'
git push -q canon cmain:main
git checkout -q main
out=$(fwd)
has "a commit after the graft is listed alone" "$out" "rel has 1 commit(s) main has not grafted: 0 vendor, 0 release paperwork,"
hasnt "and nothing the graft took" "$out" "fix: C"

git checkout -q --orphan lone
git rm -rqf .
echo 'unrelated' > u.R; git add -A; git commit -qm 'fix: On a history of its own'
git push -q -f canon lone:rel
git checkout -q -f main
out=$(fwd)
has "a branch with no merge base is missing data" "$out" "could not read rel beside main, or their merge base"
hasnt "rather than owing all of it" "$out" "On a history of its own"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
