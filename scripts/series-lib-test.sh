#!/bin/bash
# Check scripts/series-lib.sh against scripts/series-config.sh, offline: the
# vendor predicate, the markers, the version ordering, the path filters, and
# the walks, against a synthetic repository built here. A repository that
# changes the configuration runs this first, because every series script reads
# the engine through these helpers and nothing else.
#
# What is checked:
#   1. The vendor predicate: a `vendor:` subject, a bare marker, an ordinary one.
#   2. The SHA a subject names, and the twin key with its `+tag` suffix.
#   3. The release a `-dev` stamp precedes, and the version ordering the suite's
#      `engine_before()` makes.
#   4. The strand, the regenerated files, the carry filter and the tooling
#      expression, read from the configured paths rather than from literals.
#   5. On a repository: the seed, the base scan past a non-vendor commit in the
#      scan directory, its bound, the `-build` equivalent of a re-stamped
#      commit, and the engine and the stamp read off a tree.

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=series-lib.sh
. "$HERE/series-lib.sh"

SCRATCH=$(mktemp -d)
[ -n "${KEEP:-}" ] || trap 'rm -rf "$SCRATCH"' EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "       got:  $2"; echo "       want: $3"; fi; }
yes() { if "${@:2}"; then ok "$1"; else no "$1"; fi; }
not() { if "${@:2}"; then no "$1"; else ok "$1"; fi; }

repo=$series_upstream_repo
sha=0123456789abcdef
v="vendor: Update vendored sources to $repo@$sha"
vt="vendor: Update vendored sources (tag v1.2.3) to $repo@$sha"

echo "--- 1. the vendor predicate"
yes "a vendor: subject vendors" series_is_vendor "$v"
yes "a bare marker vendors" series_is_vendor "chore: bump to $repo@$sha"
not "an ordinary subject does not" series_is_vendor "fix: the glue reads two"
not "the repository name alone does not" series_is_vendor "docs: $repo is upstream"

echo "--- 2. the SHA and the twin key"
is "the SHA a subject names" "$(series_sha_of "$v")" "$sha"
is "none for an ordinary subject" "$(series_sha_of "fix: the glue")" ""
is "the twin key" "$(series_twin_key "$v")" "$sha"
is "the twin key of a re-stamp" "$(series_twin_key "$vt")" "$sha+tag"
is "no key for an ordinary subject" "$(series_twin_key "fix: the glue")" ""

echo "--- 3. versions"
is "the release a -dev stamp precedes" "$(series_release_of_stamp 1.4.0-dev123)" "1.4.0"
is "none for a release" "$(series_release_of_stamp 1.4.0)" ""
yes "a -dev snapshot precedes its release" series_version_before 1.4.0-dev123 1.4.0
yes "and a later release" series_version_before 1.4.0-dev123 1.5.0
yes "and a later snapshot" series_version_before 1.4.0-dev123 1.4.0-dev124
not "not an earlier release" series_version_before 1.4.0-dev123 1.3.9
not "a release precedes nothing" series_version_before 1.4.0 1.5.0
not "nor does a string that is no version" series_version_before main 1.5.0

echo "--- 4. the paths"
yes "the vendored tree is on the strand" series_in_strand "$series_vendor_dir/src/a.cpp"
yes "so is a Makevars" series_in_strand "${series_makevars[0]}"
not "DESCRIPTION is not" series_in_strand DESCRIPTION
yes "a regenerated file is regenerated" series_is_regenerated "${series_regenerated[0]}"
not "a path under it is not" series_is_regenerated "${series_regenerated[0]}/x"
carried=$(printf '%s\n' "$series_vendor_dir/src/a.cpp" "patch/0001.patch" "${series_tooling[0]}/x" \
  "${series_regenerated[0]}" "${series_regenerated_dirs[0]}/logo.png" DESCRIPTION src/glue.cpp tests/testthat/test-a.R |
  series_carry_filter | tr '\n' ' ')
is "the carry filter keeps the fix and drops the rest" "$carried" "src/glue.cpp tests/testthat/test-a.R "
is "nothing to carry is not an error" "$(printf '%s\n' DESCRIPTION | series_carry_filter; echo "rc=$?")" "rc=0"
tooling_re=$(series_tooling_re)
yes "the tooling expression matches a tooling path" grep -qE "$tooling_re" <<<"${series_tooling[0]}/x"
not "and not another" grep -qE "$tooling_re" <<<"R/x.R"

echo "--- 5. on a repository"
cd "$SCRATCH"
git init -q -b main .
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
mkdir -p "$(dirname "$series_engine_file")" "$(dirname "$series_stamp_file")" "$series_scan_dir"
c() { git add -A; git commit -q --allow-empty -m "$1"; git rev-parse HEAD; }
echo 'Package: x' > DESCRIPTION
c "chore: Update flavor patch to x" > /dev/null
seed=$(c "$series_seed_subject")
echo 'a' > "$series_scan_dir/a"
echo '#define DUCKDB_SOURCE_ID "aaaaaaaaaa"' > "$series_engine_file"
echo 'duckdb_version <- "1.4.0-dev100"' > "$series_stamp_file"
v1=$(c "vendor: Update vendored sources to $repo@aaaaaaaaaa")
echo 'b' > "$series_scan_dir/a"
echo '#define DUCKDB_SOURCE_ID "bbbbbbbbbb"' > "$series_engine_file"
echo 'duckdb_version <- "1.4.0-dev101"' > "$series_stamp_file"
v2=$(c "vendor: Update vendored sources to $repo@bbbbbbbbbb")
echo 'c' > "$series_scan_dir/a"
fix=$(c "fix: a patch applied in the vendored tree")
is "the seed" "$(series_seed_of HEAD)" "$seed"
is "no seed below it" "$(series_seed_of "$seed~1")" ""
is "the base scan looks past a non-vendor commit in the scan directory" "$(series_vendored_sha HEAD 2>/dev/null)" "bbbbbbbbbb"
is "and says so when the bound is reached" \
  "$(base_scan_depth=1 series_vendored_sha HEAD 2>&1 >/dev/null | head -n 1)" \
  "vendored_sha: 1 $series_scan_dir commits on HEAD, none of them vendoring;"
is "the engine a tree records" "$(series_engine_of "$v1")" "aaaaaaaaaa"
is "none where the tree has no engine" "$(series_engine_of "$seed")" ""
is "the stamp a tree carries" "$(series_stamped_version "$v2")" "1.4.0-dev101"
# A re-stamp above the fix, which re-vendors the tree and so touches the scan
# directory: the equivalent of the plain commit is the plain one.
git branch -q build
echo 'duckdb_version <- "1.4.0"' > "$series_stamp_file"
echo '#define DUCKDB_VERSION "v1.4.0"' >> "$series_engine_file"
v2t=$(c "vendor: Update vendored sources (tag v1.4.0) to $repo@bbbbbbbbbb")
is "the equivalent of a plain vendor commit is the plain one" "$(series_build_equivalent HEAD build bbbbbbbbbb)" "$v2"
is "and of a re-stamp the re-stamp" "$(series_build_equivalent HEAD HEAD bbbbbbbbbb)" "$v2t"
is "the fix is not a vendor commit" "$(series_is_vendor "$(git log -1 --format=%s "$fix")" && echo yes || echo no)" no

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
