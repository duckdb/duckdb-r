#!/bin/bash
# Check the version vendoring stamps the engine with, offline:
# series_upstream_version() and series_generate_tree() in
# scripts/series-config.sh, against a synthetic upstream built here, with
# upstream's scripts/ci/version.py and the package's scripts/rconfigure.py
# stubbed. The stub of version.py resolves a version the way upstream's does:
# the line from scripts/ci/release_version.txt, the patch number one above the
# line's newest tag below HEAD, the commit count as the `-dev` number.
#
# What is checked:
#   1. A line that has released is stamped with the next patch number, a line
#      that has not with patch 0, as version.py answers, and the generator is
#      handed that version.
#   2. A commit tagged as a release is stamped as its tag, whatever version.py
#      answers, and a tag that names no release is not read as one.
#   3. A caller's DUCKDB_VERSION, else its OVERRIDE_GIT_DESCRIBE, wins.
#   4. A checkout without version.py, a line older than v2.0, answers empty,
#      and the generator keeps its own stamp; its generator reads only
#      OVERRIDE_GIT_DESCRIBE, so only that one spares a tagless clone of it.
#   5. A version.py that fails, or answers no `-dev` version, stops the
#      generator before it writes, also where errexit is off, as it is under
#      the `||` scripts/vendor-one.sh and scripts/vendor.sh call it with.
#   6. A clone without tags, and a shallow clone, are refused with the reason,
#      and the generator writes nothing for them.
#
# Usage:
#   scripts/series-stamp-test.sh
#
# Environment variables:
#   KEEP - if non-empty, do not delete the scratch directory

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=series-config.sh
. "$HERE/series-config.sh"
unset DUCKDB_VERSION OVERRIDE_GIT_DESCRIBE

SCRATCH=$(mktemp -d)
[ -n "${KEEP:-}" ] || trap 'rm -rf "$SCRATCH"' EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "       got:  $2"; echo "       want: $3"; fi; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac; }

# --- the upstream ------------------------------------------------------------

UP=$SCRATCH/upstream
git init -q -b main "$UP"
git -C "$UP" config user.name Upstream
git -C "$UP" config user.email up@example.invalid
git -C "$UP" config commit.gpgsign false
mkdir -p "$UP/scripts/ci"
commit() { # <message>: commit everything in the upstream, print the SHA
  git -C "$UP" add -A
  git -C "$UP" commit -qm "$1" --allow-empty
  git -C "$UP" rev-parse HEAD
}
echo 1.9 > "$UP/scripts/ci/release_version.txt"
commit 'upstream: the 1.9 line' > /dev/null
git -C "$UP" tag v1.9.0
OLD=$(commit 'upstream: a commit on a line without version.py')
cat > "$UP/scripts/ci/version.py" <<'EOF'
import pathlib, re, subprocess
base = pathlib.Path(__file__).with_name("release_version.txt").read_text().strip()
if re.fullmatch(r"[0-9]+\.[0-9]+", base) is None:
    raise ValueError(f"Invalid release version '{base}'")
tags = subprocess.check_output(["git", "tag", "--merged", "HEAD", "--list", f"v{base}.*"], text=True).split()
patches = [int(m.group(1)) for m in (re.fullmatch(rf"v{re.escape(base)}\.([0-9]+)", t) for t in tags) if m]
count = subprocess.check_output(["git", "rev-list", "--count", "HEAD"], text=True).strip()
print(f"v{base}.{max(patches, default=-1) + 1}-dev{count}")
EOF
echo 2.0 > "$UP/scripts/ci/release_version.txt"
UNRELEASED=$(commit 'upstream: the 2.0 line, with version.py')
RELEASE=$(commit 'upstream: release 2.0.0')
git -C "$UP" tag v2.0.0
AFTER=$(commit 'upstream: a fix after the release')
git -C "$UP" tag nightly
git -C "$UP" tag v2.0.1-rc1
echo 2.x > "$UP/scripts/ci/release_version.txt"
BROKEN=$(commit 'upstream: a release version version.py cannot read')
echo 2.0 > "$UP/scripts/ci/release_version.txt"
echo 'print("2.0.1")' > "$UP/scripts/ci/version.py"
ODD=$(commit 'upstream: a version.py that answers no -dev version')
at() { git -C "$UP" checkout -q --detach "$1"; } # <commit>: check the upstream out there

# --- the package, with the generator's script stubbed ------------------------

PKG=$SCRATCH/pkg
mkdir -p "$PKG/scripts"
cat > "$PKG/scripts/rconfigure.py" <<'EOF'
import os
with open("generated.txt", "w") as f:
    f.write(os.environ.get("DUCKDB_VERSION", "<unset>") + "\n")
EOF
# <checkout>: run the generator the way vendor-one.sh does, under `||`, and
# print its status and the version rconfigure.py was handed, or `nothing`.
generate() {
  local status=0
  rm -f "$PKG/generated.txt"
  (cd "$PKG" && series_generate_tree "$1") 2> "$SCRATCH/stderr" || status=$?
  echo "$status $(cat "$PKG/generated.txt" 2>/dev/null || echo nothing)"
}
# <checkout>: the version, or `refused: <reason>`
version() {
  series_upstream_version "$1" 2> "$SCRATCH/stderr" || echo "refused: $(cat "$SCRATCH/stderr")"
}

echo "=== 1. the next patch number on a line that has released, patch 0 before"
at "$AFTER"
is "a commit after v2.0.0 is the next patch" "$(version "$UP")" "v2.0.1-dev$(git -C "$UP" rev-list --count HEAD)"
is "and the generator is handed it" "$(generate "$UP")" "0 v2.0.1-dev$(git -C "$UP" rev-list --count HEAD)"
at "$UNRELEASED"
is "a commit on a line not yet released is patch 0" "$(version "$UP")" "v2.0.0-dev$(git -C "$UP" rev-list --count HEAD)"

echo
echo "=== 2. a release is stamped as its tag"
at "$RELEASE"
is "the tagged commit is its tag" "$(version "$UP")" v2.0.0
is "and the generator is handed it" "$(generate "$UP")" "0 v2.0.0"
at "$AFTER"
has "a tag that names no release is not read as one" "$(version "$UP")" -dev
is "nor is one that names a release otherwise" "$(series_release_tag "$UP" "$AFTER")" ""
is "while the release tag is" "$(series_release_tag "$UP" "$RELEASE")" v2.0.0

echo
echo "=== 3. a caller's version wins"
at "$AFTER"
is "DUCKDB_VERSION" "$(DUCKDB_VERSION=v2.0.1-alpha7 version "$UP")" v2.0.1-alpha7
is "OVERRIDE_GIT_DESCRIBE" "$(OVERRIDE_GIT_DESCRIBE=v2.0.1-rc1 version "$UP")" v2.0.1-rc1
is "DUCKDB_VERSION before OVERRIDE_GIT_DESCRIBE" \
  "$(DUCKDB_VERSION=v2.0.1-alpha7 OVERRIDE_GIT_DESCRIBE=v2.0.1-rc1 version "$UP")" v2.0.1-alpha7
at "$RELEASE"
is "also on a tagged commit" "$(DUCKDB_VERSION=v2.0.1-alpha7 generate "$UP")" "0 v2.0.1-alpha7"

echo
echo "=== 4. a line without version.py keeps the generator's own stamp"
at "$OLD"
is "it answers empty" "$(version "$UP")" ""
is "and the generator is handed no version" "$(generate "$UP")" "0 "
git -c advice.detachedHead=false clone -q --no-tags "$UP" "$SCRATCH/tagless-old"
git -C "$SCRATCH/tagless-old" checkout -q --detach "$OLD"
has "DUCKDB_VERSION, which it never reads, spares no tagless clone" \
  "$(DUCKDB_VERSION=v1.9.1-dev1 version "$SCRATCH/tagless-old")" "has no release tag below HEAD"
is "OVERRIDE_GIT_DESCRIBE, which it reads, does" "$(OVERRIDE_GIT_DESCRIBE=v1.9.1 version "$SCRATCH/tagless-old")" ""

echo
echo "=== 5. a version.py that cannot answer stops the generator"
at "$BROKEN"
has "a failure is refused" "$(version "$UP")" "refused: "
is "and the generator writes nothing, errexit off" "$(generate "$UP")" "1 nothing"
has "saying so" "$(cat "$SCRATCH/stderr")" "scripts/ci/version.py failed"
at "$ODD"
has "an answer without -dev is refused" "$(version "$UP")" "answered '2.0.1', no -dev version"
is "and the generator writes nothing" "$(generate "$UP")" "1 nothing"

echo
echo "=== 6. a clone that cannot name the version is refused"
git -c advice.detachedHead=false clone -q --no-tags "$UP" "$SCRATCH/tagless"
git -C "$SCRATCH/tagless" checkout -q --detach "$AFTER"
has "a clone without tags" "$(version "$SCRATCH/tagless")" "has no release tag below HEAD"
is "and the generator writes nothing" "$(generate "$SCRATCH/tagless")" "1 nothing"
git -c advice.detachedHead=false clone -q --depth 1 "file://$UP" "$SCRATCH/shallow"
has "a shallow clone" "$(version "$SCRATCH/shallow")" "is shallow"
is "and the generator writes nothing" "$(generate "$SCRATCH/shallow")" "1 nothing"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
