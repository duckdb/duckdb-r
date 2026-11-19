#!/bin/bash
# Check scripts/merge-news.sh, the NEWS.md merge driver, offline, on files and
# in a repository built here.
#
# The claim is that NEWS.md merges section by section and comes out newest
# version first, whichever side a section came from. Seventeen things are checked:
#
#   1. A forward merge: the release branch adds `2.0.0.9001` and `2.0.1`, the
#      newer line `2.0.99.9001`; the result runs 2.0.99.9001, 2.0.99.9000,
#      2.0.1, 2.0.0.9001, 2.0.0, without a conflict.
#   2. The same with the sides swapped gives the same file.
#   3. An edit to one existing section on one side is taken.
#   4. An edit to one section on both sides that conflicts is a conflict, with
#      the other sections merged and in order.
#   5. A section deleted on one side and left alone on the other is deleted.
#   6. Registered by scripts/setup-git.sh, the driver is what a `git merge`
#      of NEWS.md runs.
#   7. A heading renamed on one side, with its section edited on the other,
#      merges line by line, cleanly, and stays in order.
#   8. A heading with a date or a note after the version orders by the version.
#   9. Without python3, the file is merged line by line, conflict markers and
#      all, with a warning.
#  10. A release renaming `2.0.0.9000` to `2.0.1` while the newer line adds
#      `2.0.99.9001` merges section by section, cleanly and in order, on both
#      sides; without python3 it stays a line merge and conflicts.
#  11. The development section, `# duckdb (development version)`, stays above
#      every version, and its compare link, changed on both sides, is ours.
#  12. Ours moves the development section's link and theirs adds a line to it:
#      the merge is clean, with our link and their line.
#  13. Both sides change the same other line of the development section
#      differently: a conflict.
#  14. A heading with no version that is not `# duckdb (development version)`
#      sorts below every version, with a warning, given once.
#  15. Ours moves the development section's link and theirs deletes it: a
#      conflict, not our link lost.
#  16. A CRLF file comes out CRLF, the development section merged three-way
#      included.
#  17. An LF file that takes one CRLF line from theirs in another section
#      gets no blank lines, CR or not, added after its LF sections.
#
# Usage:
#   scripts/merge-news-test.sh
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
sec() { printf '# duckdb %s\n\n- %s\n\n\n' "$1" "${2:-Changes in $1.}"; }
news() { local v; for v in "$@"; do sec "$v"; done; }
headings() { sed -n 's/^# duckdb //p' "$1" | tr '\n' ' '; }
merge() { "$HERE/merge-news.sh" O A B >/dev/null 2>&1 && echo 0 || echo $?; }

echo "== 1. a forward merge"
news 2.0.99.9000 2.0.0 > O
{ sec 2.0.99.9001; news 2.0.99.9000 2.0.0; } > A
{ sec 2.0.1; sec 2.0.0.9001; news 2.0.99.9000 2.0.0; } > B
is "it merges cleanly" "$(merge)" 0
is "newest first, from both sides" "$(headings A)" "2.0.99.9001 2.0.99.9000 2.0.1 2.0.0.9001 2.0.0 "
has "each section keeps its body" "$(cat A)" "- Changes in 2.0.0.9001."
cp A forward

echo "== 2. the sides swapped"
news 2.0.99.9000 2.0.0 > O
{ sec 2.0.1; sec 2.0.0.9001; news 2.0.99.9000 2.0.0; } > A
{ sec 2.0.99.9001; news 2.0.99.9000 2.0.0; } > B
is "it merges cleanly" "$(merge)" 0
is "to the same file" "$(cat A)" "$(cat forward)"

echo "== 3. an edit on one side"
news 2.0.99.9000 2.0.0 > O
{ sec 2.0.99.9000 'Edited on ours.'; sec 2.0.0; } > A
{ sec 2.0.1; news 2.0.99.9000 2.0.0; } > B
is "it merges cleanly" "$(merge)" 0
has "the edit is kept" "$(cat A)" "- Edited on ours."
is "beside theirs' new section, in order" "$(headings A)" "2.0.99.9000 2.0.1 2.0.0 "

echo "== 4. an edit on both sides"
news 2.0.99.9000 2.0.0 > O
{ sec 2.0.99.9001; sec 2.0.99.9000; sec 2.0.0 'Ours says this.'; } > A
{ sec 2.0.1; sec 2.0.99.9000; sec 2.0.0 'Theirs says that.'; } > B
is "it conflicts" "$(merge)" 1
has "with the conflict marked in that section" "$(cat A)" "<<<<<<< ours"
is "and the rest merged, in order" "$(headings A)" "2.0.99.9001 2.0.99.9000 2.0.1 2.0.0 "

echo "== 5. a section deleted on one side"
news 2.0.99.9000 2.0.0.9001 2.0.0 > O
news 2.0.99.9000 2.0.0 > A
news 2.0.99.9000 2.0.0.9001 2.0.0 > B
is "it merges cleanly" "$(merge)" 0
is "without the section" "$(headings A)" "2.0.99.9000 2.0.0 "

echo "== 6. registered, a git merge runs it"
git init -q -b main repo
cd repo
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
mkdir scripts
cp "$HERE/setup-git.sh" "$HERE/merge-news.sh" "$HERE/merge-version.sh" scripts/
printf 'DESCRIPTION merge=ours-version\nNEWS.md merge=news\n' > .gitattributes
scripts/setup-git.sh >/dev/null
news 2.0.99.9000 2.0.0 > NEWS.md
git add -A; git commit -qm base
git checkout -q -b rel
{ sec 2.0.1; sec 2.0.0.9001; news 2.0.99.9000 2.0.0; } > NEWS.md
git commit -qam 'release branch'
git checkout -q main
{ sec 2.0.99.9001; news 2.0.99.9000 2.0.0; } > NEWS.md
git commit -qam 'main'
git merge -q --no-edit rel >/dev/null 2>&1 && st=0 || st=$?
is "the merge succeeds" "$st" 0
is "NEWS.md newest first" "$(headings NEWS.md)" "2.0.99.9001 2.0.99.9000 2.0.1 2.0.0.9001 2.0.0 "

echo "== 7. a heading renamed on one side, its section edited on the other"
printf '# duckdb 2.0.99.9000\n\n- a\n\n\n# duckdb 2.0.0\n\n- old\n' > O
printf '# duckdb 2.0.99.9001\n\n- a\n\n\n# duckdb 2.0.0\n\n- old\n' > A
printf '# duckdb 2.0.99.9000\n\n- a\n- b\n\n\n# duckdb 2.0.0\n\n- old\n' > B
is "it merges cleanly, line by line" "$(merge)" 0
is "under the renamed heading" "$(headings A)" "2.0.99.9001 2.0.0 "
has "with the other side's bullet" "$(cat A)" "- a
- b"

echo "== 8. a heading with a date or a note after the version"
printf '# duckdb 2.0.0 (2026-01-01)\n\n- old\n' > O
printf '# duckdb 2.0.99.9001 - a note\n\n- new\n\n\n# duckdb 2.0.0 (2026-01-01)\n\n- old\n' > A
printf '# duckdb 2.0.1 (2026-11-15)\n\n- fix\n\n\n# duckdb 2.0.0 (2026-01-01)\n\n- old\n' > B
is "it merges cleanly" "$(merge)" 0
is "ordered by the version alone" "$(sed -n 's/^# duckdb //p' A | tr '\n' '|')" "2.0.99.9001 - a note|2.0.1 (2026-11-15)|2.0.0 (2026-01-01)|"

echo "== 9. without python3, a line merge with markers"
news 2.0.99.9000 2.0.0 > O
{ sec 2.0.99.9001; news 2.0.99.9000 2.0.0; } > A
{ sec 2.0.1; news 2.0.99.9000 2.0.0; } > B
mkdir -p nopy
for t in git bash dirname sed cat; do ln -sf "$(command -v "$t")" "nopy/$t"; done
out=$(PATH=$PWD/nopy "$HERE/merge-news.sh" O A B 2>&1) && st=0 || st=$?
is "it reports the conflict" "$st" 1
has "and says why it merged by line" "$out" "no python3"
has "with conflict markers in place" "$(cat A)" "<<<<<<< ours"

echo "== 10. a release renames its development section"
rename_case() {
  news 2.0.0.9000 2.0.0 > O
  { sec 2.0.99.9001; news 2.0.0.9000 2.0.0; } > "$1"
  { sec 2.0.1 "Changes in 2.0.0.9000."; sec 2.0.0; } > "$2"
}
rename_case A B
is "it merges cleanly" "$(merge)" 0
is "newest first, the renamed section under its new heading" "$(headings A)" "2.0.99.9001 2.0.1 2.0.0 "
rename_case B A
is "the sides swapped, it merges cleanly" "$(merge)" 0
is "  and to the same headings" "$(headings A)" "2.0.99.9001 2.0.1 2.0.0 "
rename_case A B
out=$(PATH=$PWD/nopy "$HERE/merge-news.sh" O A B 2>&1) && st=0 || st=$?
is "without python3 it stays a line merge and conflicts" "$st" 1

echo "== 11. the development section stays on top, and ours"
dev() { printf '# duckdb (development version)\n\nCommits since %s: <https://github.com/duckdb/duckdb-r/compare/%s...%s>.\n\n\n' "$1" "$1" "$2"; }
{ dev v2.0.99.9000 main; sec 2.0.99.9000; sec 2.0.0; } > O
{ dev v2.0.99.9001 main; sec 2.0.99.9001; sec 2.0.99.9000; sec 2.0.0; } > A
{ dev v2.0.1 v2.0-x; sec 2.0.1; sec 2.0.99.9000; sec 2.0.0; } > B
is "a forward merge of both sides' landings merges cleanly" "$(merge)" 0
is "the development section first, then newest first" "$(headings A)" "(development version) 2.0.99.9001 2.0.99.9000 2.0.1 2.0.0 "
has "with our compare link" "$(cat A)" "compare/v2.0.99.9001...main>"

echo "== 12. the link moved on ours, a line added on theirs"
{ dev v2.0.99.9000 main; sec 2.0.99.9000; } > O
{ dev v2.0.99.9001 main; sec 2.0.99.9001; sec 2.0.99.9000; } > A
{ dev v2.0.99.9000 main | sed '3a\
\
- A bullet of theirs.'; sec 2.0.99.9000; } > B
is "it merges cleanly" "$(merge)" 0
has "with our link" "$(cat A)" "compare/v2.0.99.9001...main>"
has "and their line" "$(cat A)" "- A bullet of theirs."
is "and no other link" "$(grep -c 'Commits since' A)" 1

echo "== 13. another line of the development section changed on both sides"
{ dev v2.0.99.9000 main | sed '3a\
\
- Base.'; sec 2.0.99.9000; } > O
{ dev v2.0.99.9001 main | sed '3a\
\
- Ours.'; sec 2.0.99.9001; sec 2.0.99.9000; } > A
{ dev v2.0.99.9000 main | sed '3a\
\
- Theirs.'; sec 2.0.99.9000; } > B
is "it conflicts" "$(merge)" 1
has "with the conflict marked" "$(cat A)" "<<<<<<< ours"
has "keeping their line" "$(cat A)" "- Theirs."

echo "== 14. a heading with no version that is not the development section"
news 2.0.0 > O
{ printf '# duckdb unreleased\n\n- x\n\n\n'; news 2.0.0; } > A
{ sec 2.0.1; news 2.0.0; } > B
err=$("$HERE/merge-news.sh" O A B 2>&1 >/dev/null) && st=0 || st=$?
is "it merges cleanly" "$st" 0
is "below every version" "$(headings A)" "2.0.1 2.0.0 unreleased "
has "with a warning" "$err" "names no version"
is "  given once" "$(grep -c 'names no version' <<<"$err")" 1

echo "== 15. ours moves the development section's link, theirs deletes it"
{ dev v2.0.99.9000 main; sec 2.0.99.9000; } > O
{ dev v2.0.99.9001 main; sec 2.0.99.9001; sec 2.0.99.9000; } > A
{ printf '# duckdb (development version)\n\n- A bullet of theirs.\n\n\n'; sec 2.0.99.9000; } > B
is "it conflicts" "$(merge)" 1
has "keeping our link" "$(cat A)" "compare/v2.0.99.9001...main>"
has "and their line" "$(cat A)" "- A bullet of theirs."

echo "== 16. a CRLF file keeps its line endings"
crlf() { sed 's/$/\r/'; }
{ dev v2.0.99.9000 main; sec 2.0.99.9000; } | crlf > O
{ dev v2.0.99.9001 main; sec 2.0.99.9001; sec 2.0.99.9000; } | crlf > A
{ dev v2.0.99.9000 main | sed '3a\
\
- A bullet of theirs.'; sec 2.0.99.9000; } | crlf > B
is "it merges cleanly" "$(merge)" 0
has "with their line" "$(cat A)" "- A bullet of theirs."
is "and no line without CR" "$(grep -vc $'\r$' A || true)" 0

echo "== 17. an LF file takes one CRLF line from theirs"
sec 2.0.99.9000 > O
news 2.0.99.9001 2.0.99.9000 > A
printf '# duckdb 2.0.99.9000\n\n- Changes in 2.0.99.9000.\n- Theirs.\r\n\n\n' > B
is "it merges cleanly" "$(merge)" 0
is "with no blank lines added" "$(sed -n 6p A)" "# duckdb 2.0.99.9000"
is "  and no CR line but theirs" "$(grep -c $'\r$' A || true)" 1

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
