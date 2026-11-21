#!/bin/bash
# Check scripts/series-merge-forward.sh offline, against a release branch and
# a newer line built here: no network, no fixtures on disk.
#
# The claim is that a forward merge in progress comes out with `DESCRIPTION`
# and `NEWS.md` as the merge drivers mean them to, whether git ran the drivers
# or not, and with the development section's compare link naming the newer
# line. Seven things are checked:
#
#   1. The newer line has not touched either file since the merge base, so git
#      takes the release branch's copies without running a driver: the version
#      rises, the engine record stays off, and the link names the newer line
#      and the landing's tag (duckdb/duckdb-r#3056).
#   2. Across a release, the release branch has dropped the development
#      section and the interim section, and the newer line has moved its link:
#      the newer line's development section stays on top, the release's
#      history follows as the release branch has it, the link starts at the
#      release's tag, and the version stays the newer line's
#      (duckdb/duckdb-r#3068).
#   3. A link to a newer tag of the newer line's own is kept, and so is the
#      newer line's own section.
#   4. A genuine conflict in `DESCRIPTION` is left unmerged in the index,
#      with markers, for the hand to resolve.
#   5. A second run changes nothing.
#   6. Without a merge in progress, it refuses and changes nothing.
#   7. It is what the skill's step 8 runs after `git merge`.
#
# Usage:
#   scripts/series-merge-forward-test.sh
#
# Environment variables:
#   KEEP   - if non-empty, do not delete the scratch directory
#   SCRIPT - the script to check, default scripts/series-merge-forward.sh;
#            `true` shows what a merge without it leaves

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SCRIPT=${SCRIPT:-$HERE/series-merge-forward.sh}
SCRATCH=$(mktemp -d)
[ -n "${KEEP:-}" ] || trap 'rm -rf "$SCRATCH"' EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac; }
hasnt() { case "$2" in *"$3"*) no "$1"; echo "       present: $3" ;; *) ok "$1" ;; esac; }

URL=https://github.com/duckdb/duckdb-r/compare
REC='Config/duckdb/upstream: bfd838c07d2b84be03c6e1da3d2e0f47f2e0ff7d'
sec() { printf '# duckdb %s\n\n- %s\n\n\n' "$1" "${2:-Changes in $1.}"; }
dev() { printf '# duckdb (development version)\n\nCommits since %s: <%s/%s...%s>.\n\n\n' "$1" "$URL" "$1" "$2"; }
desc() { printf 'Package: duckdb\nVersion: %s\n%sImports: %s\n' "$1" "${2:+$2$'\n'}" "${3:-methods}"; }
headings() { sed -n 's/^# duckdb //p' NEWS.md | tr '\n' '|'; }
link() { grep '^Commits since' NEWS.md || true; }

# A repository on `main`, the drivers registered as scripts/setup-git.sh does,
# ready for the files each case writes.
repo() {
  cd "$SCRATCH"
  rm -rf "$1"
  git init -q -b main "$1"
  cd "$1"
  git config user.name Test
  git config user.email test@example.invalid
  git config commit.gpgsign false
  mkdir scripts
  cp "$HERE/setup-git.sh" "$HERE/merge-news.sh" "$HERE/merge-version.sh" scripts/
  printf 'DESCRIPTION merge=ours-version\nNEWS.md merge=news\n' > .gitattributes
  scripts/setup-git.sh >/dev/null
  git config rerere.enabled false
}
commit() { git add -A; git commit -qm "$1"; }
merge() { git merge -q --no-commit --no-ff rel >/dev/null 2>&1 || true; }
run() { "$SCRIPT" main 2>&1; }

echo "== 1. the drivers skipped (#3056)"
repo skipped
desc 2.0.0.9000 > DESCRIPTION
{ sec 2.0.0.9000 "Commits since 2.0.0."; sec 2.0.0; } > NEWS.md
echo r > R.R
commit base
git switch -q -c rel
desc 2.0.0.9001 "$REC" > DESCRIPTION
{ dev v2.0.0.9001 v2.0-cyanoptera; sec 2.0.0.9001; sec 2.0.0; } > NEWS.md
commit 'chore: Bump version to 2.0.0.9001'
git tag -a -m 'duckdb 2.0.0.9001' v2.0.0.9001
git switch -q main
echo main > R.R
commit 'main moves on'
merge
out=$(run) && st=0 || st=$?
is "it succeeds" "$st" 0
is "the version rises to the landing's" "$(sed -n 's/^Version: //p' DESCRIPTION)" 2.0.0.9001
hasnt "the release branch's engine record stays off" "$(cat DESCRIPTION)" "Config/duckdb/upstream:"
is "the sections in order" "$(headings)" "(development version)|2.0.0.9001|2.0.0|"
is "the link names the newer line and the landing's tag" "$(link)" "Commits since v2.0.0.9001: <$URL/v2.0.0.9001...main>."
is "nothing is left unmerged" "$(git diff --name-only --diff-filter=U)" ""
is "both files are staged as written" "$(git diff --name-only)" ""
has "it says what it did" "$out" "DESCRIPTION"

echo "== 5. a second run changes nothing"
before=$(git diff --cached | git hash-object --stdin)
run >/dev/null && st=0 || st=$?
is "it succeeds" "$st" 0
is "to the same index" "$(git diff --cached | git hash-object --stdin)" "$before"

echo "== 2. the NEWS.md driver conflicts across a release (#3068)"
repo release
desc 2.0.0.9001 "$REC" > DESCRIPTION
{ dev v2.0.0.9001 v2.0-cyanoptera; sec 2.0.0.9001; sec 2.0.0; } > NEWS.md
echo r > R.R
commit base
git tag -a -m 'duckdb 2.0.0.9001' v2.0.0.9001
git switch -q -c rel
desc 2.0.1 "Config/duckdb/upstream: 8d78114e90a53823803660bf821f6073ac87da8c" > DESCRIPTION
{ sec 2.0.1 "The release."; sec 2.0.0; } > NEWS.md
commit 'chore: Bump version to 2.0.1'
git tag -a -m 'duckdb 2.0.1.9900' v2.0.1.9900
git switch -q main
desc 2.0.0.9001 > DESCRIPTION
{ dev v2.0.0.9001 main; sec 2.0.0.9001; sec 2.0.0; } > NEWS.md
commit 'main: its own link and no engine record'
merge
out=$(run) && st=0 || st=$?
is "it succeeds" "$st" 0
is "the development section on top, then the release's history" "$(headings)" "(development version)|2.0.1|2.0.0|"
has "  as the release branch has it" "$(cat NEWS.md)" "- The release."
is "the link starts at the release's tag" "$(link)" "Commits since v2.0.1.9900: <$URL/v2.0.1.9900...main>."
is "the version stays the newer line's" "$(sed -n 's/^Version: //p' DESCRIPTION)" 2.0.0.9001
hasnt "  with no engine record" "$(cat DESCRIPTION)" "Config/duckdb/upstream:"
is "nothing is left unmerged" "$(git diff --name-only --diff-filter=U)" ""

echo "== 3. the newer line's own newer tag and section"
repo own
desc 2.0.0.9001 > DESCRIPTION
{ dev v2.0.0.9001 v2.0-cyanoptera; sec 2.0.0.9001; sec 2.0.0; } > NEWS.md
commit base
git switch -q -c rel
desc 2.0.1 "$REC" > DESCRIPTION
{ sec 2.0.1; sec 2.0.0; } > NEWS.md
commit 'chore: Bump version to 2.0.1'
git tag -a -m 'duckdb 2.0.1.9900' v2.0.1.9900
git switch -q main
desc 2.0.99.9001 > DESCRIPTION
{ dev v2.0.99.9001 main; sec 2.0.99.9001; sec 2.0.0.9001; sec 2.0.0; } > NEWS.md
commit 'chore: Bump version to 2.0.99.9001'
git tag -a -m 'duckdb 2.0.99.9001' v2.0.99.9001
merge
run >/dev/null && st=0 || st=$?
is "it succeeds" "$st" 0
is "the newer line's section kept, in order" "$(headings)" "(development version)|2.0.99.9001|2.0.1|2.0.0|"
is "the link keeps the newer tag" "$(link)" "Commits since v2.0.99.9001: <$URL/v2.0.99.9001...main>."
is "the version stays the newer line's" "$(sed -n 's/^Version: //p' DESCRIPTION)" 2.0.99.9001

echo "== 4. a genuine conflict in DESCRIPTION"
repo conflict
desc 2.0.0.9000 "" methods > DESCRIPTION
sec 2.0.0 > NEWS.md
commit base
git switch -q -c rel
desc 2.0.0.9001 "$REC" "methods, utils" > DESCRIPTION
commit rel
git tag -a -m 'duckdb 2.0.0.9001' v2.0.0.9001
git switch -q main
desc 2.0.0.9000 "" "methods, stats" > DESCRIPTION
commit main
merge
out=$(run) && st=0 || st=$?
is "it succeeds, the conflict being the hand's" "$st" 0
is "DESCRIPTION stays unmerged" "$(git diff --name-only --diff-filter=U)" DESCRIPTION
has "  with markers" "$(cat DESCRIPTION)" "<<<<<<< ours"
has "  and says so" "$out" "conflict"

echo "== 6. no merge in progress"
git merge --abort
before=$(git rev-parse HEAD; git status --porcelain)
out=$(run) && st=0 || st=$?
is "it refuses" "$st" 1
has "  saying why" "$out" "no merge in progress"
is "  and changes nothing" "$(git rev-parse HEAD; git status --porcelain)" "$before"

echo "== 7. the skill's step 8 runs it"
block=$(sed -n '/^## 8\./,/^## /p' "$HERE/../.claude/skills/series-land/SKILL.md")
has "after the merge" "$block" 'scripts/series-merge-forward.sh "$N"'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
