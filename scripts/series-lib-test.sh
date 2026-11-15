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
#   3. The release a stamp precedes, and the version ordering the suite's
#      `engine_before()` makes.
#   4. The strand, the regenerated files, the carry filter and the tooling
#      expression, read from the configured paths rather than from literals.
#   5. On a repository: the seed, whether a green stands above it, which ref
#      tells a forward swapped in, the base scan past a non-vendor commit in
#      the scan directory, its bound, the `-build` equivalent of a re-stamped
#      commit, and the engine and the stamp read off a tree; the second parent of
#      a merge that keeps the engine never answers the base scan.
#   6. The GitHub repository a remote names, whatever user, token or port its
#      URL carries, and the command that deletes one of its branches: the
#      dispatch of the deletion workflow, with no pull request for a forward's
#      branch at its twin's tip, else naming the lowest-numbered pull request
#      whose head is the branch's tip and listing them all where there are
#      several, or a tip-checked `gh api -X DELETE` where neither holds.
#   7. A forward merge that conflicts in the engine, the version file and the
#      Makevars, adds an engine file and deletes a patch the other side changed
#      keeps this side's engine byte for byte, and merges the R side.
#
# The engine's own formats are the block right below the helpers: what a tree
# holds for `series_engine_of()` and `series_stamped_version()` to read, where
# those files live, and the version pairs whose ordering section 3 asserts. A
# repository whose configuration reads another engine rewrites that block and
# nothing else.

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
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac; }
yes() { if "${@:2}"; then ok "$1"; else no "$1"; fi; }
not() { if "${@:2}"; then no "$1"; else ok "$1"; fi; }

# --- the engine's formats ----------------------------------------------------
#
# engine_tree <sha> <version> [tag]: write what a tree vendoring <sha> at
# <version> holds, in the current directory, as the configured readers read it;
# a re-stamp for <tag> rewrites the engine file as well, because a vendor run
# regenerates the tree and the scan directory must see it.
engine_tree() {
  printf '#define DUCKDB_SOURCE_ID "%s"\n' "$1" > "$series_engine_file"
  [ -z "${3:-}" ] || printf '#define DUCKDB_VERSION "%s"\n' "$3" >> "$series_engine_file"
  printf 'duckdb_version <- "%s"\n' "$2" > "$series_stamp_file"
}
engine_dirs=("$(dirname "$series_engine_file")" "$(dirname "$series_stamp_file")")
snapshot=1.4.0-dev123       # a development stamp, which precedes the release it names
release=1.4.0
later_snapshot=1.4.0-dev124
# The ordering: pairs `series_version_before` answers yes to, and pairs it
# answers no to, as `engine_before()` in the suite reads this engine's versions.
before=("$snapshot $release" "$snapshot 1.5.0" "$snapshot $later_snapshot")
not_before=("$snapshot 1.3.9" "$release 1.5.0" "main 1.5.0")

repo=$series_upstream_repo
sha=0123456789abcdef
v="vendor: Update vendored sources to $repo@$sha"
vt="vendor: Update vendored sources (tag $(series_tag_of_release 1.2.3)) to $repo@$sha"

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
is "the marker, as the subject spells it" "$(series_marker_of "$vt")" "$repo@$sha"
is "one marker for a subject naming two" "$(series_marker_of "$v, after $repo@abc")" "$repo@$sha"

echo "--- 3. versions"
if declare -F series_release_of_stamp >/dev/null; then
  is "the release a snapshot precedes" "$(series_release_of_stamp "$snapshot")" "$release"
  is "none for a release" "$(series_release_of_stamp "$release")" ""
  is "the tag of that release is spelled" "$([ -n "$(series_tag_of_release "$release")" ] && echo yes)" yes
else
  echo "  --   no series_release_of_stamp: the late-tag check asks the vendor commits instead"
fi
for pair in "${before[@]}"; do
  # shellcheck disable=SC2086
  yes "$pair: before" series_version_before $pair
done
for pair in "${not_before[@]}"; do
  # shellcheck disable=SC2086
  not "$pair: not before" series_version_before $pair
done

echo "--- 4. the paths"
yes "the vendored tree is on the strand" series_in_strand "$series_vendor_dir/src/a.cpp"
[ ${#series_makevars[@]} -eq 0 ] || yes "so is a Makevars" series_in_strand "${series_makevars[0]}"
not "DESCRIPTION is not" series_in_strand DESCRIPTION
[ ${#series_regenerated[@]} -eq 0 ] || {
  yes "a regenerated file is regenerated" series_is_regenerated "${series_regenerated[0]}"
  not "a path under it is not" series_is_regenerated "${series_regenerated[0]}/x"
}
# One path of each kind the filter drops, and two it keeps.
dropped=("$series_vendor_dir/src/a.cpp" DESCRIPTION)
for p in "${series_strand[@]}"; do dropped+=("$p/x" "$p"); done
for p in "${series_tooling[@]}" "${series_regenerated_dirs[@]}"; do dropped+=("$p/x"); done
dropped+=("${series_regenerated[@]}")
carried=$(printf '%s\n' "${dropped[@]}" src/glue.cpp tests/testthat/test-a.R | series_carry_filter | tr '\n' ' ')
is "the carry filter keeps the fix and drops the rest" "$carried" "src/glue.cpp tests/testthat/test-a.R "
is "nothing to carry is not an error" "$(printf '%s\n' DESCRIPTION | series_carry_filter; echo "rc=$?")" "rc=0"
is "a glob in a configured path matches as a pathspec does" \
  "$(series_strand=('R/aaa-*.R'); series_in_strand R/aaa-two.R && echo yes)" yes
# shellcheck disable=SC2030  # a subshell's own configuration, on purpose
is "and not beyond its directory" \
  "$(series_strand=('R/aaa-*.R'); series_in_strand src/R/aaa-two.R || echo no)" no
tooling_re=$(series_tooling_re)
yes "the tooling expression matches a tooling path" grep -qE "$tooling_re" <<<"${series_tooling[0]}/x"
not "and not another" grep -qE "$tooling_re" <<<"R/x.R"

echo "--- 5. on a repository"
cd "$SCRATCH"
git init -q -b main .
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
mkdir -p "${engine_dirs[@]}" "$series_scan_dir"
c() { git add -A; git commit -q --allow-empty -m "$1"; git rev-parse HEAD; }
echo 'Package: x' > DESCRIPTION
c "chore: Update flavor patch to x" > /dev/null
seed=$(c "$series_seed_subject")
echo 'a' > "$series_scan_dir/a"
engine_tree aaaaaaaaaa "$snapshot"
v1=$(c "vendor: Update vendored sources to $repo@aaaaaaaaaa")
echo 'b' > "$series_scan_dir/a"
engine_tree bbbbbbbbbb "$later_snapshot"
v2=$(c "vendor: Update vendored sources to $repo@bbbbbbbbbb")
echo 'c' > "$series_scan_dir/a"
fix=$(c "fix: a patch applied in the vendored tree")
is "the seed" "$(series_seed_of HEAD)" "$seed"
is "no seed below it" "$(series_seed_of "$seed~1")" ""
is "a green above its seed stands on it" "$(series_green_seeded "$v1" HEAD && echo yes)" yes
is "one below its seed, as at a forward's birth, does not" "$(series_green_seeded "$seed~1" HEAD || echo no)" no
is "and a -dev with no seed asks for none" "$(series_green_seeded "$seed~1" "$seed~1" && echo yes)" yes
# A forward whose -dev is HEAD, read against a series' green and -dev: which ref answers, and whether it was swapped in.
swapped() { local by; if by=$(series_fwd_swapped "$@"); then echo "$by, swapped in"; else echo "$by, live"; fi; }
is "a green above its seed answers, reached by the series' green" "$(swapped "$v1" HEAD "$v2" "$seed~1")" "green, swapped in"
is "or not" "$(swapped "$v2" HEAD "$v1" HEAD)" "green, live"
is "a green below its seed leaves it to -dev, reached by the series' -dev" "$(swapped "$seed~1" HEAD "$seed~1" HEAD)" "dev, swapped in"
is "or not, whatever the series' green reaches" "$(swapped "$seed~1" HEAD HEAD "$v2")" "dev, live"
is "so does no green" "$(swapped '' HEAD HEAD HEAD)" "dev, swapped in"
is "a green with no -dev answers alone" "$(swapped "$seed~1" '' "$seed~1" "$seed~1")" "green, swapped in"
is "and with neither, whatever is named for it is litter" "$(swapped '' '' "$seed~1" "$seed~1")" "none, swapped in"
is "the base scan looks past a non-vendor commit in the scan directory" "$(series_vendored_sha HEAD 2>/dev/null)" "bbbbbbbbbb"
is "and says so when the bound is reached" \
  "$(base_scan_depth=1 series_vendored_sha HEAD 2>&1 >/dev/null | head -n 1)" \
  "vendored_sha: 1 $series_scan_dir commits on HEAD, none of them vendoring;"
is "the engine a tree records" "$(series_engine_of "$v1")" "aaaaaaaaaa"
is "none where the tree has no engine" "$(series_engine_of "$seed")" ""
is "the stamp a tree carries" "$(series_stamped_version "$v2")" "$later_snapshot"
# A re-stamp above the fix: the equivalent of the plain commit is the plain one.
git branch -q build
tag=$(series_tag_of_release "$release")
engine_tree bbbbbbbbbb "$release" "$tag"
v2t=$(c "vendor: Update vendored sources (tag $tag) to $repo@bbbbbbbbbb")
is "the equivalent of a plain vendor commit is the plain one" "$(series_build_equivalent HEAD build bbbbbbbbbb)" "$v2"
is "and of a re-stamp the re-stamp" "$(series_build_equivalent HEAD HEAD bbbbbbbbbb)" "$v2t"
is "the fix is not a vendor commit" "$(series_is_vendor "$(git log -1 --format=%s "$fix")" && echo yes || echo no)" no
# A forward merge: a release branch's newer vendor commit merged keeping the
# first parent's engine, so the base scan never reads the second's.
git checkout -q -b rel
echo 'r' > "$series_scan_dir/a"
GIT_COMMITTER_DATE='2099-01-01 00:00:00 +0000' GIT_AUTHOR_DATE='2099-01-01 00:00:00 +0000' \
  c "vendor: Update vendored sources to $repo@cccccccccc" > /dev/null
git checkout -q main
git merge -q -s ours --no-edit rel
is "the base scan follows the first parent of a merge that keeps the engine" "$(series_vendored_sha HEAD 2>/dev/null)" "bbbbbbbbbb"

echo "--- 6. the GitHub repository a remote names"
# Offline: a remote that is not a local path is refused by git at once, rather than looked up.
export GIT_ALLOW_PROTOCOL=file
for url in https://github.com/o/r https://github.com/o/r.git https://github.com/o/r/ git@github.com:o/r.git ssh://git@github.com/o/r \
  https://user@github.com/o/r.git https://github.com:443/o/r.git ssh://git@github.com:22/o/r.git; do
  git remote add gh-url "$url"
  is "$url names o/r" "$(series_github_slug gh-url)" o/r
  git remote remove gh-url
done
# A token in the URL names the repository as the bare URL does, and is never printed.
git remote add gh-url https://x-access-token:s3cr3t@github.com:443/o/r.git
unread="git ls-remote gh-url refs/heads/b-fwd-dev  # b-fwd-dev is not on gh-url or could not be read: once this reads it, rerun for the line that deletes it"
dispatch="gh api -X POST repos/o/r/actions/workflows/delete-branch.yaml/dispatches -f ref=main -f 'inputs[branch]="
is "a URL with a user, a token and a port names o/r" "$(series_github_slug gh-url)" o/r
is "and the token is in neither of its lines" "$(series_github_slug gh-url; series_delete_line gh-url b-fwd-dev)" \
  "$(printf 'o/r\n%s' "$unread")"
git remote remove gh-url
for url in https://github.com.example.invalid/o/r https://github.com@example.invalid/o/r https://github.com/o/r/extra git@github.com:22/o/r \
  'https://github.com/o/r?t=s3cr3t' 'https://github.com/o/r.git#s3cr3t' 'https://github.com/o?t=s3cr3t/r' 'git@github.com:o/r?t=s3cr3t'; do
  git remote add gh-url "$url"
  is "$url names nothing" "$(series_github_slug gh-url)" ""
  git remote remove gh-url
done
git remote add proxied http://proxy@127.0.0.1:1/git/o/r
is "a URL that is not GitHub's names nothing" "$(series_github_slug proxied)" ""
is "and a branch whose tip it cannot read gets the read, which deletes nothing" "$(series_delete_line proxied b-fwd-dev)" \
  "git ls-remote proxied refs/heads/b-fwd-dev  # b-fwd-dev is not on proxied or could not be read: once this reads it, rerun for the line that deletes it"
is "one whose tip the caller read is deleted with git, leased on that tip" "$(series_delete_line proxied b-fwd-dev "$(git rev-parse HEAD)")" \
  "git push --force-with-lease=refs/heads/b-fwd-dev:$(git rev-parse HEAD) proxied :refs/heads/b-fwd-dev"
git config remote.proxied.github o/r
is "unless the configuration names the repository" "$(series_github_slug proxied)" o/r
is "and then, for a remote it cannot read, with the read that deletes nothing" "$(series_delete_line proxied b-fwd-dev)" "${unread//gh-url/proxied}"
# A remote it can read: the pull request is the lowest-numbered one whose head is the tip.
git init -q --bare "$SCRATCH/gh.git"
tipc=$(git rev-parse HEAD)
other=$(git rev-parse HEAD~1)
git push -q "$SCRATCH/gh.git" "$tipc:refs/heads/b-fwd-dev" "$other:refs/heads/litter"
for p in "9 $tipc" "10 $tipc" "2 $other" "12 $tipc"; do
  read -r n sha <<<"$p"
  git -C "$SCRATCH/gh.git" update-ref "refs/pull/$n/head" "$sha"
done
git -C "$SCRATCH/gh.git" update-ref refs/heads/unpinned "$(git rev-parse HEAD~2)"
git remote add readable "$SCRATCH/gh.git"
git config remote.readable.github o/r
is "a branch at several pull requests' heads names the lowest-numbered" "$(series_delete_line readable b-fwd-dev)" \
  "${dispatch}b-fwd-dev' -f 'inputs[pr]=9'  # pull requests whose head is this tip: 9 10 12; name a closed one"
is "and one at a single head names that one" "$(series_delete_line readable litter)" "${dispatch}litter' -f 'inputs[pr]=2'"
u=$(git rev-parse HEAD~2)
# shellcheck disable=SC2016  # the command as it is printed
is "a branch no pull request's head is at gets a tip-checked deletion, for a maintainer" "$(series_delete_line readable unpinned)" \
  "$(printf 'if [ "$(gh api repos/o/r/git/ref/heads/unpinned --jq .object.sha)" = %s ]; then gh api -X DELETE repos/o/r/git/refs/heads/unpinned; else echo %s; fi  # for a maintainer%ss shell: no pull request%ss head is at %s, so the workflow cannot pin it' \
    "$u" "'unpinned is not at ${u:0:12}: read what moved before deleting it'" "'" "'" "${u:0:12}")"
# A tip the caller read and checked wins over the one the remote holds now, so a ref that moved since is refused by the line.
is "a branch that moved since the caller read it is dispatched for the tip read" "$(series_delete_line readable b-fwd-dev "$other")" \
  "${dispatch}b-fwd-dev' -f 'inputs[pr]=2'"
has "and one no pull request pins is checked against the tip read" "$(series_delete_line readable b-fwd-dev "$u")" \
  "= $u ]; then gh api -X DELETE repos/o/r/git/refs/heads/b-fwd-dev;"
series_delete_listing readable
git -C "$SCRATCH/gh.git" update-ref -d refs/pull/2/head
is "a listing loaded once is read instead of the remote" "$(series_delete_line readable litter)" "${dispatch}litter' -f 'inputs[pr]=2'"
# A forward's branch whose twin, the name without its `fwd-`, is at the same tip needs no pull request,
# and that proof comes before a pull request's, read from the listing or from the remote alike.
git push -q "$SCRATCH/gh.git" "$tipc:refs/heads/b-dev" "$u:refs/heads/v2.0-x-fwd-green" "$other:refs/heads/v2.0-x-green" \
  "$u:refs/heads/main-fwd-green" "$u:refs/heads/main-green" "$u:refs/heads/a-fwd-b-fwd-c" "$u:refs/heads/a-b-fwd-c"
unset 'series_delete_cache[readable]'
is "a forward's branch at its twin's tip is dispatched without a pull request" "$(series_delete_line readable b-fwd-dev)" \
  "${dispatch}b-fwd-dev'"
is "main-fwd-green's twin is main-green" "$(series_delete_line readable main-fwd-green)" "${dispatch}main-fwd-green'"
series_delete_listing readable
is "and the loaded listing holds the twin" "$(series_delete_line readable main-fwd-green)" "${dispatch}main-fwd-green'"
has "a twin at another tip proves nothing" "$(series_delete_line readable v2.0-x-fwd-green)" "for a maintainer's shell"
has "nor does a name with -fwd- twice" "$(series_delete_line readable a-fwd-b-fwd-c)" "for a maintainer's shell"
git push -q "$SCRATCH/gh.git" "$u:refs/heads/a-fwd-fwd-b" "$u:refs/heads/a-fwd-b"
unset 'series_delete_cache[readable]'
has "nor one with -fwd- twice, overlapping" "$(series_delete_line readable a-fwd-fwd-b)" "for a maintainer's shell"
has "a tip the caller read that the twin is not at falls back to the other proofs" "$(series_delete_line readable b-fwd-dev "$other")" \
  "if [ \"\$(gh api repos/o/r/git/ref/heads/b-fwd-dev --jq .object.sha)\" = $other ]"
unset GIT_ALLOW_PROTOCOL

echo "--- 7. a forward merge keeps this side's engine"
KE=$SCRATCH/keep-engine
git init -q -b main "$KE"
cd "$KE"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
mkdir -p src/duckdb patch R src/include
printf 'engine base\n' > src/duckdb/a.cpp
printf 'a file the release branch renames\n' > src/duckdb/old.cpp
printf 'patch base\n' > patch/0001-fix.patch
printf 'duckdb_version <- "base"\n' > R/version.R
printf 'SOURCES = base\n' > src/include/sources.mk
printf 'OBJECTS = base\n' > src/Makevars
printf 'f <- 1\n' > R/f.R
git add -A; git commit -qm base
git checkout -q -b rel
printf 'engine rel\n' > src/duckdb/a.cpp
printf 'added by rel\n' > src/duckdb/new.cpp
git mv src/duckdb/old.cpp src/duckdb/renamed.cpp
git rm -q patch/0001-fix.patch
printf 'duckdb_version <- "rel"\n' > R/version.R
printf 'OBJECTS = rel\n' > src/Makevars
printf 'f <- 2\n' > R/f.R
git add -A; git commit -qm 'vendor and fix on the release branch'
git checkout -q main
printf 'engine main\n' > src/duckdb/a.cpp
printf 'patch main\n' > patch/0001-fix.patch
printf 'duckdb_version <- "main"\n' > R/version.R
printf 'OBJECTS = main\n' > src/Makevars
git add -A; git commit -qm 'main moves its engine'
# shellcheck disable=SC2031  # the array is the configuration's, unchanged here
engine_before=$(git ls-tree -r HEAD -- "${series_strand[@]}" "${series_makevars[@]}")
printf 'a scratch file of the user\n' > src/duckdb/mine.txt
git merge -q --no-commit --no-ff rel >/dev/null 2>&1 || true
is "the merge stops on conflicts" "$(git diff --name-only --diff-filter=U | sort | tr '\n' ' ')" \
  "R/version.R patch/0001-fix.patch src/Makevars src/duckdb/a.cpp "
series_keep_engine && st=0 || st=$?
is "keeping the engine succeeds" "$st" 0
is "and leaves nothing unmerged" "$(git diff --name-only --diff-filter=U | wc -l)" 0
is "nor the file the release branch added" "$( [ -e src/duckdb/new.cpp ] && echo there || echo gone)" gone
is "nor the name the release branch renamed a file to" "$( [ -e src/duckdb/renamed.cpp ] && echo there || echo gone)" gone
is "  and the file is back under its old name" "$(cat src/duckdb/old.cpp)" 'a file the release branch renames'
is "and an untracked file of the user's is kept" "$(cat src/duckdb/mine.txt)" 'a scratch file of the user'
rm src/duckdb/mine.txt
is "while the R side is merged" "$(git diff --cached --name-only)" "R/f.R"
git commit -qm 'Merge rel forward'
# shellcheck disable=SC2031
is "the engine is byte for byte this side's" "$(git ls-tree -r HEAD -- "${series_strand[@]}" "${series_makevars[@]}")" "$engine_before"
is "and the merge has both parents" "$(git rev-list --parents -n 1 HEAD | wc -w)" 3
cd "$SCRATCH"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
