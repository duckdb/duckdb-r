#!/bin/bash
# Check scripts/series-alpha.sh offline, against a synthetic remote and clone
# built here, with `curl` stubbed: no network, no fixtures on disk.
#
#   1. The stamp stands on the newest green commit carrying the alpha's engine,
#      the one under the next vendor commit, and changes the three version
#      lines upstream derives from the version, leaving `DUCKDB_SOURCE_ID`.
#   2. The unflavored twin, found by its `Unflavored-from:` trailer, gets the
#      same stamp as `<S>-rc-alpha`.
#   3. Without --push nothing is written and the exit is 1; with it both
#      strands are written, and a rerun mints the same SHAs and writes nothing.
#   4. A commit stacked on a stamp, as a revdep run adds its report, leaves the
#      strand aligned.
#   5. A newer alpha moves the strand, dropping what was stacked on it.
#   6. No pointer upstream, or an alpha whose commit green has not vendored,
#      is nothing to do: exit 0, no ref written.
#   7. An alpha missing an extension on a platform, or one of another release
#      than the engine's `-dev` version, stops the run before anything is written.
#   8. An rc strand with no twin of the base reports itself not aligned.
#
# Usage:
#   scripts/series-alpha-test.sh
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
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3"; echo "        in: $2" ;; esac; }

# --- the network -------------------------------------------------------------
#
# `curl` answers from two files: the pointer upstream writes for the series'
# branch, absent for a 404, and the extension paths that are missing.

NET=$SCRATCH/net
mkdir -p "$SCRATCH/bin" "$NET"
: >"$NET/missing"
cat >"$SCRATCH/bin/curl" <<'EOF'
#!/bin/bash
out=/dev/null url=
while [ $# -gt 0 ]; do
  case "$1" in
    -o) out=$2; shift 2 ;;
    -w | -m) shift 2 ;;
    http*) url=$1; shift ;;
    *) shift ;;
  esac
done
case "$url" in
  */release/*/latest_alpha_version.txt)
    if [ -f "$NET/pointer" ]; then cp "$NET/pointer" "$out"; echo 200; else echo 404; fi ;;
  https://extensions.duckdb.org/*)
    if grep -qxF "${url#https://extensions.duckdb.org/}" "$NET/missing"; then echo 404; else echo 200; fi ;;
  *) echo 500 ;;
esac
EOF
chmod +x "$SCRATCH/bin/curl"
export NET PATH="$SCRATCH/bin:$PATH"

# --- the fixture -------------------------------------------------------------
#
# One series, `v2.0-x`, whose green vendors three upstream commits with an R-side
# fix between the second and the third, and its unflavored rc strand.

REMOTE=$SCRATCH/remote.git
WORK=$SCRATCH/work
git init -q --bare -b main "$REMOTE"
git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$REMOTE"
mkdir -p scripts R src/duckdb/src/function/table/version
cp "$HERE/series-alpha.sh" "$HERE/series-lib.sh" scripts/

PRAGMA=src/duckdb/src/function/table/version/pragma_version.cpp
LOADER=src/duckdb/generated_extension_loader_package_build.cpp
full() { printf '%s%s' "$1" 000000000000000000000000000000; }

engine() { # <sha10> <dev n>
  printf '#ifndef DUCKDB_PATCH_VERSION\n#define DUCKDB_PATCH_VERSION "0-dev%s"\n#endif\n' "$2" >"$PRAGMA"
  printf '#ifndef DUCKDB_VERSION\n#define DUCKDB_VERSION "v2.0.0-dev%s"\n#endif\n' "$2" >>"$PRAGMA"
  printf '#ifndef DUCKDB_SOURCE_ID\n#define DUCKDB_SOURCE_ID "%s"\n#endif\n' "$1" >>"$PRAGMA"
  printf '\tdescriptor->api_version = "%s";\n\tdescriptor->api_version = "v1.2.0";\n' "$1" >"$LOADER"
  echo "duckdb_version <- \"2.0.0-dev$2\"" >R/version.R
  echo "engine $1" >src/duckdb/engine.cpp
  git add -A
  git commit -q -m "vendor: Update vendored sources to duckdb/duckdb@$(full "$1")"
}

printf 'Package: duckdb.2.0.dev\nVersion: 1.99.99.9000.1\n' >DESCRIPTION
engine aaaaaaaaaa 100
engine bbbbbbbbbb 101
echo 'fix <- TRUE' >R/fix.R
git add -A
git commit -q -m "fix: An R-side fix for engine bbbbbbbbbb"
FIX=$(git rev-parse HEAD)
engine cccccccccc 102
git push -q origin HEAD:refs/heads/v2.0-x-green HEAD:refs/heads/v2.0-x-dev

# The rc strand: each commit unflavored, with a trailer naming its source.
git checkout -q --orphan rc
git rm -q -r --cached . >/dev/null
for c in $(git rev-list --reverse main); do
  git read-tree "$c"
  blob=$(git show "$c:DESCRIPTION" | sed 's/^Package: .*/Package: duckdb/' | git hash-object -w --stdin)
  git update-index --cacheinfo "100644,$blob,DESCRIPTION"
  parent=$(git rev-parse -q --verify HEAD || true)
  rc=$(git log -1 --format=%B "$c" | git interpret-trailers --trailer "Unflavored-from: $c" |
    git commit-tree "$(git write-tree)" ${parent:+-p "$parent"})
  git update-ref refs/heads/rc "$rc"
done
RC_FIX=$(git log -1 --format=%H --grep="Unflavored-from: $FIX" rc)
git push -q origin rc:refs/heads/v2.0-x-rc-dev
git checkout -q -f main

run() { # <args...> -> output, then `exit <status>` as the last line
  set +e
  scripts/series-alpha.sh "$@" 2>&1
  echo "exit $?"
  set -e
}
remote_ref() { git ls-remote "$REMOTE" "refs/heads/$1" | cut -f1; }

# --- 1, 2, 3: the stamp, and alignment -------------------------------------

echo "== the stamp stands on the newest commit carrying the alpha's engine"
echo bbbbbbbbbb/v2.0.0-alpha500 >"$NET/pointer"
out=$(run v2.0-x)
has "it reports the flavored strand on the fix" "$out" "v2.0-x-alpha: "
has "and the rc strand on its twin" "$out" "v2.0-x-rc-alpha: "
has "and is not aligned without --push" "$out" "exit 1"
is "nothing is written without --push" "$(remote_ref v2.0-x-alpha)" ""

out=$(run v2.0-x --push)
has "--push exits 0" "$out" "exit 0"
A=$(remote_ref v2.0-x-alpha)
R=$(remote_ref v2.0-x-rc-alpha)
git fetch -q origin
is "the flavored stamp's parent is the fix under the next vendor commit" "$(git rev-parse "$A^")" "$FIX"
is "the rc stamp's parent is the fix's twin" "$(git rev-parse "$R^")" "$RC_FIX"
is "the stamp changes the three files upstream derives from the version" \
  "$(git diff --name-only "$A^" "$A" | tr '\n' ' ')" "R/version.R $LOADER $PRAGMA "
stamped=$(git show "$A:$PRAGMA")
has "DUCKDB_VERSION is the alpha" "$stamped" '#define DUCKDB_VERSION "v2.0.0-alpha500"'
has "DUCKDB_PATCH_VERSION carries the alpha" "$stamped" '#define DUCKDB_PATCH_VERSION "0-alpha500"'
has "DUCKDB_SOURCE_ID stays the commit" "$stamped" '#define DUCKDB_SOURCE_ID "bbbbbbbbbb"'
is "the C++ api_version is the alpha, the C API one untouched" "$(git show "$A:$LOADER" | tr -d '\t\n')" \
  'descriptor->api_version = "v2.0.0-alpha500";descriptor->api_version = "v1.2.0";'
is "R/version.R reports the alpha" "$(git show "$A:R/version.R")" 'duckdb_version <- "2.0.0-alpha500"'
has "the message names its parent" "$(git log -1 --format=%B "$A")" "Stamped-from: $FIX"
is "the stamp keeps the parent's dates" "$(git log -1 --format=%ad%cd "$A")" "$(git log -1 --format=%ad%cd "$FIX")"

out=$(run v2.0-x --push)
has "a rerun reports both strands aligned" "$out" "v2.0-x-rc-alpha: aligned"
has "and exits 0" "$out" "exit 0"
is "and writes nothing" "$(remote_ref v2.0-x-alpha)" "$A"

# --- 4, 5: stacked commits, and a newer alpha ------------------------------

echo
echo "== a stacked commit stays until a newer alpha moves the strand"
git checkout -q -b report "$R"
echo report >report.md
git add report.md
git commit -q -m "chore: Update revdep report"
git push -q origin HEAD:refs/heads/v2.0-x-rc-alpha
git checkout -q main
out=$(run v2.0-x)
has "a strand with a report on top is aligned" "$out" "v2.0-x-rc-alpha: aligned at $(git rev-parse --short "$R"), v2.0.0-alpha500, 1 commit(s) on top"
has "and exits 0" "$out" "exit 0"

echo cccccccccc/v2.0.0-alpha600 >"$NET/pointer"
out=$(run v2.0-x --push)
has "a newer alpha moves the strand" "$out" "exit 0"
A2=$(remote_ref v2.0-x-alpha)
is "onto green itself when nothing was vendored above it" "$(git rev-parse "$A2^")" \
  "$(git rev-parse refs/remotes/origin/v2.0-x-green)"
git fetch -q origin
is "and the report is gone with the old stamp" "$(git ls-tree --name-only "$(remote_ref v2.0-x-rc-alpha)" report.md)" ""

# --- 6: nothing to do ------------------------------------------------------

echo
echo "== no alpha, or one green has not reached, writes nothing"
rm "$NET/pointer"
out=$(run v2.0-x --push)
has "no pointer is nothing to stamp" "$out" "upstream publishes no alpha of v2.0-x"
has "and exits 0" "$out" "exit 0"
echo dddddddddd/v2.0.0-alpha700 >"$NET/pointer"
out=$(run v2.0-x --push)
has "an engine green has not vendored is nothing to stamp yet" "$out" "which v2.0-x-green has not vendored"
has "and exits 0" "$out" "exit 0"
is "the strand stays" "$(remote_ref v2.0-x-alpha)" "$A2"

# --- 7: refusals -----------------------------------------------------------

echo
echo "== a gap in the extensions, or another release, stops the run"
echo aaaaaaaaaa/v2.0.0-alpha400 >"$NET/pointer"
echo v2.0.0-alpha400/windows_amd64_mingw/httpfs.duckdb_extension.gz >"$NET/missing"
out=$(run v2.0-x --push)
has "a missing extension is named" "$out" "v2.0.0-alpha400 has no httpfs for windows_amd64_mingw"
has "and exits 1" "$out" "exit 1"
is "and writes nothing" "$(remote_ref v2.0-x-alpha)" "$A2"
: >"$NET/missing"
out=$(run v2.0-x --alpha aaaaaaaaaa/v2.1.0-alpha400 --push)
has "an alpha of another release is refused" "$out" "which is no v2.1.0-dev version"
has "and exits 1" "$out" "exit 1"
out=$(run v2.0-x --alpha aaaaaaaaaa/2.0.0 --push)
has "a malformed --alpha is refused" "$out" "is not <sha10>/vX.Y.Z-alphaN"

# --- 8: an rc strand behind ------------------------------------------------

echo
echo "== an rc strand with no twin of the base is not aligned"
git push -q --force origin "$RC_FIX:refs/heads/v2.0-x-rc-dev"
out=$(run v2.0-x --alpha cccccccccc/v2.0.0-alpha600)
has "it says to realign the rc strand" "$out" "v2.0-x-rc-dev has no twin of"
has "and exits 1" "$out" "exit 1"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
