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
#   9. FORWARD-PORT counts the commits of each active release branch not
#      yet merged forward into the next newer line, the newest into `main`:
#      vendor commits and release paperwork by number, each R-side commit
#      listed, a bump among them whose alpha stamp is not one alpha line for
#      each stamp line it replaces; none once the branch is merged forward. Nothing before a branch
#      is cut or for a stale line, a quoted declaration reads the same, three
#      lines chain oldest to newest, and a branch it cannot read, without a
#      canonical remote or with no merge base, is reported as missing data.
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

echo "=== 9. what is not yet merged forward"
CANON=$SCRATCH/canonical.git
git init -q --bare -b main "$CANON"
git remote add canon "$CANON"
fwd() { UPSTREAM_URL=$UP scripts/series-check.sh v9.9-x --canonical canon 2>&1 | sed -n '/^FORWARD-PORT/,$p'; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
git checkout -q -b cmain main
printf 'flavors:\n  - flavor: duckdb\n    kind: CRAN\n    upstream: "rel"\n    publishes_from: main\n  - flavor: duckdb.old.dev\n    kind: dev\n    series: old\n    releases_from: old\n    stale: true\n' > scripts/series.yaml
# The `-dev` stamp an alpha stamp replaces, in the engine file and the R side.
PRAGMA=src/duckdb/src/function/table/version/pragma_version.cpp
mkdir -p "$(dirname "$PRAGMA")" R
echo '#define DUCKDB_VERSION "v9.9.0-dev1"' > "$PRAGMA"
echo 'duckdb_version <- "9.9.0-dev1"' > R/version.R
git add -A; git commit -qm 'chore: Declare the flavors'
git push -q canon cmain:main
is "nothing before the line's branch is cut, and nothing for a stale line" "$(fwd)" ""

git push -q -f origin cmain:main
out=$(UPSTREAM_URL=$UP scripts/series-check.sh v9.9-x --canonical '' 2>&1 | sed -n '/^FORWARD-PORT/,$p')
has "without a canonical remote or a mirror, it says it could not read" "$out" "could not read rel beside main"

git checkout -q -b rel cmain
for e in bbbb222 bbbb223 bbbb224; do
  echo "engine $e" > src/duckdb/engine.cpp
  git commit -qam "vendor: Update vendored sources to duckdb/duckdb@$e"
done
echo 'Version: 9.9.0.9001' > DESCRIPTION; echo '# duckdb 9.9.0.9001' > NEWS.md
echo 'duckdb_version <- "9.9.0-alpha1"' > R/version.R
git add -A; git commit -qm 'chore: Bump version to 9.9.0.9001'
printf 'Version: 9.9.0.9001\nImports: DBI (>= 1.2)\n' > DESCRIPTION
git add -A; git commit -qm 'fix: Require DBI >= 1.2'
DBI=$(git rev-parse HEAD)
printf 'Version: 9.9.0.9002\nImports: DBI (>= 1.2)\n' > DESCRIPTION; echo '# duckdb 9.9.0.9002' > NEWS.md
git add -A; git commit -qm 'Increment version number'
printf 'Version: 9.9.0.9003\nImports: DBI (>= 1.2)\n' > DESCRIPTION; echo 'synced' > sync.R
git add -A; git commit -qm 'chore: Bump version to 9.9.0.9003'
SYNC=$(git rev-parse HEAD)
echo 'fix c' > c.R; git add -A; git commit -qm 'fix: C, written on the release branch'
C=$(git rev-parse HEAD)
printf 'Version: 9.9.0.9004\nImports: DBI (>= 1.2)\n' > DESCRIPTION
printf 'duckdb_version <- "9.9.0-alpha2"\nduckdb_extra <- TRUE\n' > R/version.R
git add -A; git commit -qm 'chore: Bump version to 9.9.0.9004'
EXTRA=$(git rev-parse HEAD)
# Beside a moved version: a `-dev` stamped again, a stamp line added beside the
# one it replaces, and one deleted. None is an alpha stamp.
printf 'Version: 9.9.0.9005\nImports: DBI (>= 1.2)\n' > DESCRIPTION
sed -i 's/v9.9.0-dev1/v9.9.0-dev2/' "$PRAGMA"
git add -A; git commit -qm 'chore: Bump version to 9.9.0.9005'
RESTAMP=$(git rev-parse HEAD)
printf 'Version: 9.9.0.9006\nImports: DBI (>= 1.2)\n' > DESCRIPTION
echo '#define DUCKDB_VERSION "v9.9.0-alpha3"' >> "$PRAGMA"
git add -A; git commit -qm 'chore: Bump version to 9.9.0.9006'
DUP=$(git rev-parse HEAD)
printf 'Version: 9.9.0.9007\nImports: DBI (>= 1.2)\n' > DESCRIPTION
sed -i '/v9.9.0-dev2/d' "$PRAGMA"
git add -A; git commit -qm 'chore: Bump version to 9.9.0.9007'
DEL=$(git rev-parse HEAD)
git push -q canon rel
git checkout -q main
out=$(fwd)
has "it counts what is not yet merged forward" "$out" "rel has 12 commit(s) not yet merged forward into main:"
has "vendor commits and paperwork by number, the R side listed" "$out" "3 vendor, 2 release paperwork, 7 R-side"
has "a bump that also carries R-side files is listed" "$out" "$(git rev-parse --short "$SYNC") chore: Bump version to 9.9.0.9003"
has "a DESCRIPTION change beyond the version is R-side" "$out" "$(git rev-parse --short "$DBI") fix: Require DBI >= 1.2"
has "and so is an ordinary fix" "$out" "$(git rev-parse --short "$C") fix: C, written on the release branch"
hasnt "a version-only change under another subject is paperwork" "$out" "Increment version number"
hasnt "vendor commits are not listed one by one" "$out" "bbbb22"
hasnt "nor a bump that is only paperwork, its alpha stamp included" "$out" "Bump version to 9.9.0.9001"
has "a bump whose stamp file changes beyond the stamp is listed" "$out" "$(git rev-parse --short "$EXTRA") chore: Bump version to 9.9.0.9004"
has "so is one that stamps a -dev again" "$out" "$(git rev-parse --short "$RESTAMP") chore: Bump version to 9.9.0.9005"
has "or adds a DUCKDB_VERSION beside the one it replaces" "$out" "$(git rev-parse --short "$DUP") chore: Bump version to 9.9.0.9006"
has "or deletes one" "$out" "$(git rev-parse --short "$DEL") chore: Bump version to 9.9.0.9007"
git push -q -f origin cmain:main rel:rel
has "without a canonical remote it reads the fork's mirrors" \
  "$(UPSTREAM_URL=$UP scripts/series-check.sh v9.9-x --canonical '' 2>&1 | sed -n '/^FORWARD-PORT/,$p')" "rel has 12 commit(s)"

# The forward merge, keeping main's engine.
git checkout -q cmain
git merge -q --no-commit --no-ff rel >/dev/null 2>&1 || true
git checkout HEAD -- src/duckdb
for f in DESCRIPTION NEWS.md; do git checkout HEAD -- "$f" 2>/dev/null || git rm -qf "$f"; done
git add -A
git commit -qm 'Merge rel forward into main'
git push -q canon cmain:main
git checkout -q main
# A copy of main fetched before the merge is refreshed, not read stale.
git update-ref "refs/remotes/canon/main" "$(git rev-parse cmain^1)"
is "nothing once main has merged the branch forward" "$(fwd)" ""

git checkout -q rel
echo 'fix e' > e.R; git add -A; git commit -qm 'fix: E, after the merge'
git push -q canon rel
git checkout -q main
out=$(fwd)
has "a commit after the merge is listed alone" "$out" "rel has 1 commit(s) not yet merged forward into main:"
hasnt "and nothing the merge took" "$out" "fix: C"

# A third line: `rel` is merged forward into the newer release branch `rel2`,
# and `rel2` into main.
git checkout -q -b rel2 cmain
echo 'fix g' > g.R; git add -A; git commit -qm 'fix: G, on the newer release branch'
git push -q canon rel2
git checkout -q cmain
printf '  - flavor: duckdb.rel2.dev\n    kind: dev\n    series: rel2\n    releases_from: rel2\n' >> scripts/series.yaml
git commit -qam 'chore: Declare the newer line'
git push -q canon cmain:main
git checkout -q main
out=$(fwd)
has "the older line is merged into the newer one" "$out" "rel has 1 commit(s) not yet merged forward into rel2:"
has "and the newer one into main" "$out" "rel2 has 1 commit(s) not yet merged forward into main:"
hasnt "and not the older one into main" "$out" "rel has 1 commit(s) not yet merged forward into main"

git checkout -q --orphan lone
git rm -rqf .
echo 'unrelated' > u.R; git add -A; git commit -qm 'fix: On a history of its own'
git push -q -f canon lone:rel2
git checkout -q -f main
out=$(fwd)
has "a branch with no merge base is missing data" "$out" "could not read rel2 beside main, or their merge base"
hasnt "rather than owing all of it" "$out" "On a history of its own"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
