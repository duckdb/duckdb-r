#!/bin/bash
# Check scripts/pull-request-base.sh, offline, against pull requests and file
# lists written here in the shape GitHub's API gives them, and declarations
# written beside them: no network, no fixtures on disk.
#
# The claim the script makes is that it fails a pull request to `main` unless
# its head is a forward merge's or a landing review's in the same repository,
# it carries the label `next-line-only`, or it changes nothing but the tooling,
# and that the failure names the oldest active release branch the declaration
# gives. Seven things are checked.
#
#   1. Anything but two readable files holding the API's JSON is a usage
#      error, exit 2.
#   2. A pull request to another base passes, whatever it changes.
#   3. A forward merge's head and a landing review's head pass, a review's
#      iteration suffix included; a head that only resembles one does not,
#      nor either one from another repository or from a fork deleted since.
#   4. The label `next-line-only` passes a pull request, and another label,
#      one that only contains it among them, does not.
#   5. A pull request that changes nothing but the tooling passes, across
#      pages; a path that only starts like a tooling directory, and a file
#      renamed out of somewhere else into the tooling, and `.github/README.md`,
#      which the port leaves out, do not count as tooling; a file list shorter
#      than the pull request's count is never read as tooling-only, and a pull
#      request that changes no file passes as one that changes none.
#   6. A failure names the oldest active release branch, by version and past
#      a stale row, lists ten files and counts the rest, and says so in the
#      step summary and an error annotation, with exit 1; with no active
#      release branch declared, the pull request passes.
#   7. With this repository's declaration, the branch named is its CRAN row's
#      `upstream`.
#
# Usage:
#   scripts/pull-request-base-test.sh
#
# Environment variables:
#   KEEP - if non-empty, do not delete the scratch directory

# shellcheck disable=SC2016  # the reports list paths as Markdown code spans
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
lacks() { case "$2" in *"$3"*) no "$1"; echo "       present: $3" ;; *) ok "$1" ;; esac; }

# --- the fixtures ----------------------------------------------------------
#
# A declaration whose active release branches are `v9.10-b`, a dev row's
# `releases_from`, and `v9.9-a`, the CRAN row's `upstream`, listed newest
# first so the order is the script's; `v9.8-z` is older and stale.

cat > "$SCRATCH/series.yaml" <<'YAML'
flavors:
  - flavor: duckdb.9.10.dev
    kind: dev
    upstream: v9.10-b
    series: v9.10-b
    releases_from: "v9.10-b"
  - flavor: duckdb
    kind: CRAN
    upstream: 'v9.9-a'
    publishes_from: main
  - flavor: duckdb.9.8.dev
    kind: dev
    upstream: v9.8-z
    series: v9.8-z
    releases_from: v9.8-z
    stale: true
  - flavor: duckdb.dev
    kind: dev
    upstream: main
    series: main
    releases_from: main
YAML
export SERIES_YAML=$SCRATCH/series.yaml GITHUB_STEP_SUMMARY=$SCRATCH/summary

# The pull request in test/repo: <base> <head> <changed files> [<label>...].
# HEAD_REPO names the head's repository, `null` for a fork deleted since.
pull() {
  local base=$1 head=$2 counted=$3
  shift 3
  jq -n --arg base "$base" --arg head "$head" --argjson n "$counted" --arg repo "${HEAD_REPO:-test/repo}" \
    '$ARGS.positional as $l | {
      number: 42, base: {ref: $base, repo: {full_name: "test/repo"}},
      head: {ref: $head, repo: (if $repo == "null" then null else {full_name: $repo} end)},
      changed_files: $n, labels: [$l[] | {name: .}]
    }' --args "$@" > "$SCRATCH/pull.json"
}
# Its files, one page per argument, each page's paths separated by spaces; `old>new` is a rename.
files() {
  local page
  : > "$SCRATCH/files.json"
  for page in "$@"; do
    # shellcheck disable=SC2086
    jq -n '[$ARGS.positional[] | split(">") |
      if length == 2 then {filename: .[1], previous_filename: .[0], status: "renamed"} else {filename: .[0]} end]' \
      --args $page >> "$SCRATCH/files.json"
  done
}
run() { "$HERE/pull-request-base.sh" "$SCRATCH/pull.json" "$SCRATCH/files.json" 2>&1 && echo "EXIT=0" || echo "EXIT=$?"; }

echo "=== 1. usage errors"
pull main fix 1
files "R/a.R"
out=$("$HERE/pull-request-base.sh" "$SCRATCH/pull.json" 2>&1 && echo "EXIT=0" || echo "EXIT=$?")
has "one argument is a usage error" "$out" "EXIT=2"
out=$("$HERE/pull-request-base.sh" "$SCRATCH/pull.json" "$SCRATCH/nope" 2>&1 && echo "EXIT=0" || echo "EXIT=$?")
has "a missing file is a usage error" "$out" "EXIT=2"
echo '{"message": "Not Found"}' > "$SCRATCH/files.json"
out=$(run)
has "files that are not the API's output are a usage error" "$out" "EXIT=2"
files "R/a.R"
echo '{"number": 42}' > "$SCRATCH/pull.json"
out=$(run)
has "a pull request without a base is a usage error" "$out" "holds no .base.ref"
has "with exit 2" "$out" "EXIT=2"

echo "=== 2. another base"
pull v9.9-a fix 1
files "R/a.R"
out=$(run)
has "a pull request to a release branch passes" "$out" "#42 targets v9.9-a, not main; nothing to check."
has "with exit 0" "$out" "EXIT=0"

echo "=== 3. a forward merge, a landing's review"
files "R/a.R src/b.cpp"
pull main forward/v9.9-a-1.2.3 2
out=$(run)
has "a forward merge's head passes" "$out" "its head forward/v9.9-a-1.2.3 is a forward merge's"
has "with exit 0" "$out" "EXIT=0"
pull main v9.10-b-land-review 2
has "a landing review's head passes" "$(run)" "its head v9.10-b-land-review is a landing's review"
pull main v9.10-b-land-review-v2 2
has "and so does its iteration" "$(run)" "EXIT=0"
pull main fix/forward/x 2
has "a head that only contains forward/ does not pass" "$(run)" "EXIT=1"
pull main land-reviewer 2
has "nor one that only resembles a review" "$(run)" "EXIT=1"
pull main v9.10-b-land-reviewer 2
has "nor one that only starts like a review" "$(run)" "EXIT=1"
pull main v9.10-b-land-review/x 2
has "nor one that continues past it without a dash" "$(run)" "EXIT=1"
HEAD_REPO=someone/fork pull main forward/v9.9-a-1.2.3 2
has "a forward merge's head from a fork does not pass" "$(run)" "EXIT=1"
HEAD_REPO=someone/fork pull main v9.10-b-land-review 2
has "nor a landing review's" "$(run)" "EXIT=1"
HEAD_REPO=null pull main forward/v9.9-a-1.2.3 2
out=$(run)
has "nor one from a fork deleted since" "$out" "EXIT=1"
has "which is not a usage error" "$out" "belongs on v9.9-a"

echo "=== 4. the label"
pull main fix 2 bug next-line-only
out=$(run)
has "the label passes a pull request" "$out" "it carries the label next-line-only"
has "with exit 0" "$out" "EXIT=0"
pull main fix 2 bug next-line not-next-line-only
has "another label, or one that only contains it, does not" "$(run)" "EXIT=1"

echo "=== 5. tooling only"
pull main fix 4
files ".github/workflows/x.yaml scripts/y.sh" ".claude/skills/z/SKILL.md scripts/sub/w.sh"
out=$(run)
has "tooling across pages passes" "$out" "it changes nothing but the tooling (.github scripts .claude)"
has "with exit 0" "$out" "EXIT=0"
pull main fix 3
files ".github/x.yaml .githubx/y.yaml scripts.md"
out=$(run)
has "a path that only starts like a tooling directory is not tooling" "$out" "EXIT=1"
has "and is listed" "$out" '  - `.githubx/y.yaml`'
has "as is a file at the root" "$out" '  - `scripts.md`'
lacks "the tooling is not listed" "$out" '`.github/x.yaml`'
pull main fix 1
files "R/a.R>scripts/a.R"
out=$(run)
has "a file renamed into the tooling counts at its old path" "$out" '  - `R/a.R`'
has "and fails" "$out" "EXIT=1"
pull main fix 2
files ".github/README.md scripts/a.sh"
out=$(run)
has ".github/README.md is not tooling" "$out" '  - `.github/README.md`'
has "and fails" "$out" "EXIT=1"
pull main fix 0
files ""
out=$(run)
has "a pull request that changes no file passes" "$out" "#42 may target main: it changes no file."
lacks "and is not called tooling" "$out" "nothing but the tooling"
pull main fix 3
files "scripts/a.sh scripts/b.sh"
out=$(run)
has "a file list shorter than the count is not tooling-only" "$out" \
  "GitHub lists 2 of its 3 changed files, so it cannot be read as tooling-only."
has "and fails" "$out" "EXIT=1"

echo "=== 6. the failure"
pull main fix 12
files "R/01.R R/02.R R/03.R R/04.R R/05.R R/06.R" "R/07.R R/08.R R/09.R R/10.R R/11.R scripts/a.sh"
: > "$GITHUB_STEP_SUMMARY"
out=$(run)
has "names the oldest active release branch" "$out" \
  "#42 targets main, but belongs on v9.9-a, the oldest active release branch (handbook/branches/model/README.md)."
has "counts the files outside the tooling" "$out" "It changes 11 file(s) outside the tooling"
has "lists the tenth" "$out" '  - `R/10.R`'
lacks "and not the eleventh" "$out" '`R/11.R`'
has "but counts it" "$out" "  - and 1 more"
has "says to retarget" "$out" "retarget it to v9.9-a"
has "or to split" "$out" "split it: the tooling in a pull request to main, the rest in one to v9.9-a"
has "or to label" "$out" "add the label next-line-only"
has "annotates the run" "$out" "::error title=pull-request-base::#42 targets main but belongs on v9.9-a"
has "with exit 1" "$out" "EXIT=1"
has "the summary says so" "$(cat "$GITHUB_STEP_SUMMARY")" "#42 targets main, but belongs on v9.9-a"
cp "$SERIES_YAML" "$SCRATCH/series.yaml.full"
printf 'flavors:\n  - flavor: duckdb\n    kind: CRAN\n    upstream: main\n' > "$SERIES_YAML"
out=$(run)
has "with no active release branch, it passes" "$out" "series.yaml declares no active release branch."
has "with exit 0" "$out" "EXIT=0"
mv "$SCRATCH/series.yaml.full" "$SERIES_YAML"
out=$(SERIES_YAML=$SCRATCH/nope run)
has "a declaration that cannot be read is an error" "$out" "cannot read the declaration"
has "with exit 2" "$out" "EXIT=2"

echo "=== 7. this repository's declaration"
cran=$(awk '/^  - / { k = "" } /^    kind:/ { k = $2 } /^    upstream:/ && k == "CRAN" { print $2 }' "$HERE/series.yaml" |
  tr -d "\"'")
pull main fix 1
files "R/a.R"
out=$(SERIES_YAML='' run)
if [ -n "$cran" ] && [ "$cran" != main ]; then
  has "the branch named is the CRAN row's upstream, $cran" "$out" "belongs on $cran, the oldest"
else
  ok "skipped: the CRAN row names no release branch"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
