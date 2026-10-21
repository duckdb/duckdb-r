#!/bin/bash
# Derive the alpha strand of a series: `<S>-alpha`, a green commit stamped with
# the version of upstream's alpha build of its engine, so that `INSTALL` finds
# the extensions upstream published for it (.claude/skills/series-alpha/SKILL.md).
#
# Upstream names a build it dispatches by hand `vX.Y.Z-alpha<run number>` and
# publishes extensions under that name; a `-dev` stamp makes the engine look
# under the commit hash instead, where nothing is published. When such a build
# on its default branch has deployed its extensions, upstream writes
# `<sha10>/<version>` to `release/<branch>/latest_alpha_version.txt` on its
# staging host, and that pointer is all this reads to choose one.
#
# The stamp stands on the newest `<S>-green` commit that carries that engine:
# the commit under the next vendor commit, or green itself. It rewrites what
# upstream's build derives from the version, as `DUCKDB_VERSION=<version>`
# would have: `DUCKDB_VERSION` and `DUCKDB_PATCH_VERSION` in
# pragma_version.cpp, the C++ `api_version` of the linked extensions, and
# `R/version.R`. `DUCKDB_SOURCE_ID` stays the commit. The message, author and
# dates are a function of that green commit, so a rerun mints the same SHA and
# "aligned" is a fact to check: this prints what it would write and whether
# the remote holds it. Commits stacked on a stamp, such as a revdep report,
# leave it aligned and are dropped only when a newer alpha moves the strand.
#
# A series with `<S>-rc-dev` gets `<S>-rc-alpha` too: the same stamp on the rc
# commit unflavored from that green commit, which is what a revdep run checks.
#
# Usage: series-alpha.sh <S> [--remote <name>] [--alpha <sha10>/<version>] [--push]
#   <S> is the series, `v2.0-cyanoptera-fwd` for `v2.0-cyanoptera-fwd-alpha`.
#   --alpha names the build instead of reading upstream's pointer.
#   --push writes the strands, leased on what the remote held when this run read it.

set -euo pipefail
# A failure inside `$(...)` stops the run too, rather than minting an empty SHA.
shopt -s inherit_errexit
# shellcheck source=series-lib.sh
. "$(dirname "$0")/series-lib.sh"

usage='usage: series-alpha.sh <S> [--remote <name>] [--alpha <sha10>/<version>] [--push]'
argerr() { echo "$usage" >&2; exit 2; }

remote=${SERIES_REMOTE:-origin}
alpha=
push=
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --alpha) [ $# -ge 2 ] || argerr; alpha=$2; shift 2 ;;
    --push) push=1; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
S=${args[0]}
# A forward series tracks the same upstream branch as its base.
branch=${S%-fwd}

staging=https://duckdb-staging.duckdb.org
extensions=https://extensions.duckdb.org
# The platforms R packages are built for, and two extensions the test suite installs.
platforms='linux_amd64 linux_arm64 osx_amd64 osx_arm64 windows_amd64_mingw'
probes='icu httpfs'

git fetch -q "$remote" "+refs/heads/$S-*:refs/remotes/$remote/$S-*"
green="refs/remotes/$remote/$S-green"
git rev-parse -q --verify "$green" >/dev/null ||
  { echo "Error: $S-green does not exist on $remote" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# <url> -> the HTTP status, with the body in $work/body
http() { curl -sS -L -m 60 -o "$work/body" -w '%{http_code}' "$1"; }

if [ -z "$alpha" ]; then
  status=$(http "$staging/release/$branch/latest_alpha_version.txt")
  case "$status" in
    200) alpha=$(tr -d '[:space:]' <"$work/body") ;;
    403 | 404)
      echo "$S: upstream publishes no alpha of $branch; nothing to stamp"
      exit 0 ;;
    *) echo "Error: reading the alpha of $branch from $staging answered HTTP $status" >&2; exit 1 ;;
  esac
fi
sha10=${alpha%%/*}
version=${alpha#*/}
[[ $sha10 =~ ^[0-9a-f]{10}$ && $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+-alpha[0-9]+$ ]] ||
  { echo "Error: '$alpha' is not <sha10>/vX.Y.Z-alphaN" >&2; exit 1; }
release=${version%-*}  # v2.0.0
suffix=${version##*-}  # alpha46057

# The pointer is written only once the extensions are deployed, so a gap here is
# upstream's, and the strand stays where it is until it is understood.
for p in $platforms; do
  for e in $probes; do
    status=$(curl -sS -I -m 60 -o /dev/null -w '%{http_code}' "$extensions/$version/$p/$e.duckdb_extension.gz")
    [ "$status" = 200 ] ||
      { echo "Error: $version has no $e for $p (HTTP $status); not stamping it" >&2; exit 1; }
  done
done

# The vendor commit of that engine on green, and the newest commit above it that
# still carries it: green is linear by invariant, so that is the one under the
# next vendor commit.
vendored=$(git log --first-parent -1 --format=%H --grep="^vendor: .*$series_upstream_repo@$sha10" "$green")
if [ -z "$vendored" ]; then
  echo "$S: $version is $series_upstream_repo@$sha10, which $S-green has not vendored; nothing to stamp yet"
  exit 0
fi
later=$(git rev-list --first-parent --reverse --grep='^vendor: ' "$vendored..$green")
if [ -n "$later" ]; then
  base=$(git rev-parse "${later%%$'\n'*}^")
else
  base=$(git rev-parse "$green")
fi

pragma=$series_engine_file
loader=$series_vendor_dir/generated_extension_loader_package_build.cpp
define() { git show "$1:$pragma" | sed -n "s/^#define $2 \"\\(.*\\)\"\$/\\1/p"; }

source_id=$(define "$base" DUCKDB_SOURCE_ID)
[ "$source_id" = "$sha10" ] ||
  { echo "Error: $(git rev-parse --short "$base") carries engine $source_id, not $sha10" >&2; exit 1; }

export GIT_INDEX_FILE="$work/index"

# <commit> <path> <sed script> -> stage the edited file, failing when nothing changed
edit() {
  local before after
  before=$(git rev-parse "$1:$2")
  after=$(git show "$1:$2" | sed -e "$3" | git hash-object -w --stdin)
  [ "$before" != "$after" ] ||
    { echo "Error: the stamp changed nothing in $2 of $(git rev-parse --short "$1")" >&2; return 1; }
  git update-index --cacheinfo "100644,$after,$2"
}

# <commit> -> the tree of its stamp
stamp_tree() {
  local c=$1 dev devn patch
  dev=$(define "$c" DUCKDB_VERSION)  # v2.0.0-dev87149
  case "$dev" in
    "$release-dev"[0-9]*) ;;
    *) echo "Error: $(git rev-parse --short "$c") stamps $dev, which is no $release-dev version" >&2; return 1 ;;
  esac
  devn=${dev##*-}           # dev87149
  patch=${release##*.}      # 0
  git read-tree "$c"
  edit "$c" "$pragma" "s/^#define DUCKDB_VERSION \"$dev\"\$/#define DUCKDB_VERSION \"$version\"/;
    s/^#define DUCKDB_PATCH_VERSION \"$patch-$devn\"\$/#define DUCKDB_PATCH_VERSION \"$patch-$suffix\"/"
  edit "$c" "$series_stamp_file" "s/^duckdb_version <- \"${dev#v}\"\$/duckdb_version <- \"${version#v}\"/"
  # A C++ extension records the version it was built for, which is the commit
  # under a `-dev` stamp and the version under a release one.
  if git cat-file -e "$c:$loader" 2>/dev/null; then
    edit "$c" "$loader" "s/api_version = \"$sha10\";/api_version = \"$version\";/"
  fi
  local t
  t=$(git write-tree)
  if git grep -q -F -e "$devn" "$t" -- "$series_vendor_dir" "$series_stamp_file"; then
    echo "Error: the stamp left $devn behind:" >&2
    git grep -n -F -e "$devn" "$t" -- "$series_vendor_dir" "$series_stamp_file" >&2
    return 1
  fi
  echo "$t"
}

# <commit> -> its stamp, with its author, committer and dates
mint() {
  local c=$1 t
  t=$(stamp_tree "$c")
  printf '%s\n' \
    "chore: Stamp the engine as $version" \
    "" \
    "Upstream built $series_upstream_repo@$sha10 as $version and published its extensions" \
    "under that version; a -dev stamp looks them up under the commit instead." \
    "Only the version stamp differs from the parent (scripts/series-alpha.sh)." \
    "" \
    "Stamped-from: $(git rev-parse "$c")" |
    GIT_AUTHOR_NAME=$(git log -1 --format=%an "$c") GIT_AUTHOR_EMAIL=$(git log -1 --format=%ae "$c") \
    GIT_AUTHOR_DATE=$(git log -1 --format=%ad --date=raw "$c") \
    GIT_COMMITTER_NAME=$(git log -1 --format=%cn "$c") GIT_COMMITTER_EMAIL=$(git log -1 --format=%ce "$c") \
    GIT_COMMITTER_DATE=$(git log -1 --format=%cd --date=raw "$c") \
    git commit-tree "$t" -p "$c"
}

stale=
# <strand> <stamp> -> report it, and write it under --push
align() {
  local name=$1 new=$2 old above ref="refs/heads/$1"
  old=$(git rev-parse -q --verify "refs/remotes/$remote/$name" || true)
  if [ -n "$old" ] && git merge-base --is-ancestor "$new" "$old"; then
    above=$(git rev-list --count "$new..$old")
    echo "$name: aligned at $(git rev-parse --short "$new"), $version, $above commit(s) on top"
    return 0
  fi
  echo "$name: ${old:+$(git rev-parse --short "$old") -> }$(git rev-parse --short "$new")," \
    "$version on $(git rev-parse --short "$new^")"
  if [ -z "$push" ]; then
    stale=1
    return 0
  fi
  env -u GIT_INDEX_FILE git push -q "$remote" "--force-with-lease=$ref:$old" "+$new:$ref"
}

# Minted first: a failure inside an argument's `$(...)` would not stop the run.
new=$(mint "$base")
align "$S-alpha" "$new"

rc_dev="refs/remotes/$remote/$S-rc-dev"
if git rev-parse -q --verify "$rc_dev" >/dev/null; then
  rc_base=$(git log -1 --format=%H --grep="^Unflavored-from: $base\$" "$rc_dev")
  if [ -n "$rc_base" ]; then
    new=$(mint "$rc_base")
    align "$S-rc-alpha" "$new"
  else
    echo "$S-rc-alpha: $S-rc-dev has no twin of $(git rev-parse --short "$base"); realign it first (series-rc.sh)"
    stale=1
  fi
fi

if [ -n "$stale" ]; then
  [ -n "$push" ] || echo "Not aligned; --push writes it."
  exit 1
fi
