#!/bin/bash
# Check scripts/vendor-one.sh --strand offline, against a synthetic upstream and
# package built here: no network, no fixtures on disk, the generator stubbed in
# the copied configuration. What a strand commit is (handbook/branches/model/README.md):
#
#   1. Two upstream commits vendored onto the strand, each a commit named for
#      its upstream SHA, with the regenerated tree, the patch stack applied, what
#      the derived phase wrote, and nothing else: no counter, no byproduct the
#      generator left outside the vendor paths, and a clean tree afterwards.
#   2. A patch whose change upstream took is retired in that commit, leaving an
#      empty stack the next run and the staging survive.
#   3. A tagged upstream commit carries its marker, and the walk stops there.
#   4. An upstream commit that changes nothing under the vendor paths but the
#      stamp is skipped, and the run ends with the tree as it found it.

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)

SCRATCH=$(mktemp -d)
[ -n "${KEEP:-}" ] || trap 'rm -rf "$SCRATCH"' EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "       got:  $2"; echo "       want: $3"; fi; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac; }
hasnt() { case "$2" in *"$3"*) no "$1"; echo "     unexpected: $3" ;; *) ok "$1" ;; esac; }

# --- the upstream ----------------------------------------------------------

UP=$SCRATCH/upstream
git init -q -b main "$UP"
git -C "$UP" config user.name Upstream
git -C "$UP" config user.email up@example.invalid
git -C "$UP" config commit.gpgsign false
mkdir -p "$UP/src"
echo hello > "$UP/src/a.txt"
git -C "$UP" add -A && git -C "$UP" commit -qm 'upstream: first'
git -C "$UP" tag v1.0.0
U0=$(git -C "$UP" rev-parse HEAD)
echo world > "$UP/src/b.txt"
git -C "$UP" add -A && git -C "$UP" commit -qm 'upstream: add b'
U1=$(git -C "$UP" rev-parse HEAD)
echo 'hello patched' > "$UP/src/a.txt"
git -C "$UP" add -A && git -C "$UP" commit -qm 'upstream: take the patch'
git -C "$UP" tag v1.1.0
U2=$(git -C "$UP" rev-parse HEAD)
echo notes > "$UP/README.md"
git -C "$UP" add -A && git -C "$UP" commit -qm 'upstream: a readme, outside the tree'
# U3: a change outside the tree, which section 4 reads as nothing to vendor.

# --- the package, at the strand's foot --------------------------------------

WORK=$SCRATCH/work
git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
mkdir -p scripts src/duckdb/src/function/table/version src/include R patch
for s in vendor-one.sh vendor-lib.sh series-lib.sh series-config.sh; do cp "$HERE/$s" scripts/; done
chmod +x scripts/*.sh
# The generator, stubbed: the tree phase copies the checkout's `src/` in,
# stamps the engine and the version, and leaves a byproduct outside the vendor
# paths; the derived phase writes one file under them.
cat >> scripts/series-config.sh <<'EOF'
series_generate_tree() {
  rm -rf src/duckdb/src
  mkdir -p src/duckdb/src/function/table/version src/include R
  cp -R "$1"/src/. src/duckdb/src/
  printf '#define DUCKDB_SOURCE_ID "%s"\n' "$(git -C "$1" rev-parse --short=10 HEAD)" \
    > src/duckdb/src/function/table/version/pragma_version.cpp
  printf 'duckdb_version <- "1.0.0-dev%s"\n' "$(git -C "$1" rev-list --count HEAD)" > R/version.R
  echo "SOURCES=$(cd src/duckdb/src && ls *.txt | tr '\n' ' ')" > src/include/sources.mk
  echo generated > src/glue-generated.txt
}
series_generate_derived() { echo "derived for $1" > src/duckdb/derived.txt; }
EOF
echo '/duckdb' > .gitignore
printf 'Package: duckdb\nVersion: 1.0.0.9000.0\n' > DESCRIPTION
echo 'hello patched' > src/duckdb/src/a.txt
printf '#define DUCKDB_SOURCE_ID "%s"\n' "${U0:0:10}" > src/duckdb/src/function/table/version/pragma_version.cpp
echo 'duckdb_version <- "1.0.0-dev1"' > R/version.R
echo 'SOURCES=a.txt ' > src/include/sources.mk
printf -- '--- a/src/duckdb/src/a.txt\n+++ b/src/duckdb/src/a.txt\n@@ -1 +1 @@\n-hello\n+hello patched\n' > patch/0001-hello.patch
echo 'glue' > src/glue.cpp
git add -A
# The foot carries the tag's marker, so the first run re-stamps nothing.
git commit -qm "vendor: Update vendored sources (tag v1.0.0) to duckdb/duckdb@$U0"
git tag v1.0.0
FOOT=$(git rev-parse HEAD)

runs=0
# Not in a subshell, so the per-run logs count up; the status goes to a file.
run() { set +e; runs=$((runs + 1)); scripts/vendor-one.sh "$@" > "$SCRATCH/run-$runs.log" 2>&1; echo "EXIT=$?" > "$SCRATCH/exit"; set -e; }
log() { tr -d '\0' < "$SCRATCH/run-$runs.log"; }
vendored() { git show "$1:src/duckdb/src/function/table/version/pragma_version.cpp" | sed -n 's/.*"\(.*\)".*/\1/p'; }

echo "=== 1. two upstream commits onto the strand"
run --strand --commits 3 "$UP"; out=$(cat "$SCRATCH/exit")
[ -z "${KEEP:-}" ] || log | tail -n 40
is "it exits 0" "$out" "EXIT=0"
has "and stops at the tag" "$(log)" "Vendored a tag. Stopping."
is "two commits above the foot" "$(git rev-list --count "$FOOT..HEAD")" 2
is "the first names the first upstream commit" "$(git log -1 --format=%s HEAD~1)" "vendor: Update vendored sources to duckdb/duckdb@$U1"
is "and vendors it" "$(vendored HEAD~1)" "${U1:0:10}"
is "the counter stays at the foot's" "$(git show HEAD~1:DESCRIPTION | sed -n 's/^Version: //p')" 1.0.0.9000.0
is "the new file is in" "$(git show HEAD~1:src/duckdb/src/b.txt)" world
is "the patch is applied" "$(git show HEAD~1:src/duckdb/src/a.txt)" "hello patched"
is "and the entry kept" "$(git cat-file -t HEAD~1:patch/0001-hello.patch)" blob
is "the derived phase wrote the strand" "$(git show HEAD~1:src/duckdb/derived.txt)" "derived for strand"
is "the version stamp travels" "$(git show HEAD~1:R/version.R)" 'duckdb_version <- "1.0.0-dev2"'
is "the byproduct outside the vendor paths is not committed" "$(git ls-tree --name-only HEAD~1 src/glue-generated.txt | wc -l)" 0
is "nor is the glue touched" "$(git show HEAD~1:src/glue.cpp)" glue
is "the tree is clean afterwards" "$(git status --porcelain | wc -l)" 0
is "and the clone is gone" "$([ -d duckdb ] && echo kept || echo gone)" gone

echo
echo "=== 2. the patch upstream took is retired, and the stack is empty"
has "the retirement is said" "$(log)" "Removing patch patch/0001-hello.patch"
is "the second commit vendors the second upstream commit" "$(vendored HEAD)" "${U2:0:10}"
is "its tree has upstream's line" "$(git show HEAD:src/duckdb/src/a.txt)" "hello patched"
is "and no patch entry" "$(git ls-tree --name-only HEAD patch/ | wc -l)" 0

echo
echo "=== 3. the tagged commit carries its marker"
is "the subject names the tag" "$(git log -1 --format=%s HEAD)" "vendor: Update vendored sources (tag v1.1.0) to duckdb/duckdb@$U2"

echo
echo "=== 4. a commit that changes nothing under the vendor paths is skipped"
TIP=$(git rev-parse HEAD)
run --strand --commits 1 "$UP"; out=$(cat "$SCRATCH/exit")
[ -z "${KEEP:-}" ] || log | tail -n 20
is "it exits 0" "$out" "EXIT=0"
has "with nothing to vendor" "$(log)" "No changes found. Done."
is "the strand did not move" "$(git rev-parse HEAD)" "$TIP"
is "the tree is clean" "$(git status --porcelain | wc -l)" 0
is "the base scan still reads the strand" "$(git log -1 --format=%s | grep -c "@$U2")" 1

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
