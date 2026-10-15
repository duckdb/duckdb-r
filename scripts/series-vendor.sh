#!/bin/bash
# The vendor strand of a series, `<S>-vendor`: pure vendoring, one commit per
# upstream commit, vendored once and carried forward by a rebase
# (handbook/branches/model/README.md). What vendor-one.sh --strand writes is
# the strand's; what this script does is derive the rest from it.
#
# Usage: series-vendor.sh <S> [--remote <name>] [--count <n>] [--no-check-glue] [--push]
#        series-vendor.sh <S> --init [--remote <name>] [--push]
#        series-vendor.sh <S> --forward <seed> [--remote <name>] [--push]
#
#   The default extends `<S>-build` from `<S>-vendor`, in the worktree it is run
#   from, which must stand at `<S>-build`: every strand commit above the
#   buffer's newest twin is cherry-picked onto HEAD, what the buffer alone
#   carries is regenerated (nothing here: the Makevars travel with the strand),
#   a vendor commit's counter is stamped, and the glue gate runs. Broken glue
#   stops with the pick at HEAD for the fix to be amended in; a rerun continues
#   from there. --count bounds the picks; --push pushes HEAD to `<S>-build`.
#
#   --init derives `<S>-vendor` from an existing `<S>-build`, once: for every
#   buffer commit above the seed that touches the vendor paths, a strand commit
#   carrying those paths and nothing else, with the buffer commit's message and
#   author. Nothing is re-vendored, and the ref must not exist yet.
#
#   --forward writes `<S>-fwd-vendor`, the strand carried onto <seed>, the
#   commit the forward's buffer stands on. Where the seed vendors an engine the
#   strand has, the commits above it are rebased onto the seed, which is a
#   `git apply` of each pure vendoring diff. Where it does not (a rewind, or a
#   seed off the strand's line), the strand's first commit is written once as
#   the seed plus the foot's vendor paths taken whole, which is what vendoring
#   that engine onto the seed would produce, and the rest is cherry-picked above
#   it. A conflict is patch drift and stops with the worktree kept.
#
#   Nothing is pushed without --push. --remote is spelled the same in every
#   scripts/series-*.sh (handbook/operations/vendoring/series-loop/README.md).
#
# Exit status: 2 usage; 1 refused, or a pick that conflicts; 3 broken glue,
# with the pick at HEAD; 6 the glue check could not run.

set -euo pipefail

usage='usage: series-vendor.sh <S> [--remote <name>] [--count <n>] [--no-check-glue] [--push]
       series-vendor.sh <S> --init [--remote <name>] [--push]
       series-vendor.sh <S> --forward <seed> [--remote <name>] [--push]'
argerr() { echo "$usage" >&2; exit 2; }

remote=${SERIES_REMOTE:-origin}
mode=pick seed_arg='' count='' push='' check_glue=true
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --count) [ $# -ge 2 ] || argerr; count=$2; shift 2 ;;
    --forward) [ $# -ge 2 ] || argerr; mode=forward; seed_arg=$2; shift 2 ;;
    --init) mode=init; shift ;;
    --no-check-glue) check_glue=false; shift ;;
    --push) push=1; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
S=${args[0]}
case "$count" in '' | *[!0-9]*) [ -z "$count" ] || argerr ;; esac

# What a strand commit carries: the vendored tree, the patch stack applied to
# it, and the files vendoring regenerates from it and from `src/Makevars.in`.
# Everything else a buffer commit holds, the counter and the glue the gate
# demanded, is the buffer's own.
VENDOR_PATHS=(src/duckdb patch R/version.R src/include/sources.mk src/Makevars src/Makevars.win man/figures)

# What the buffer regenerates after a pick, beyond the counter: nothing here,
# because every generated file is the strand's. A repository whose generator
# reads the R side as well regenerates it here.
regenerate() { :; }

cd "$(git rev-parse --show-toplevel)"
git fetch -q "$remote"
vendor_ref="refs/remotes/$remote/$S-vendor"
build_ref="refs/remotes/$remote/$S-build"

# The seed a ref stands on, which the strand starts above.
seed_of() { git log --first-parent --format=%H --grep='^chore: Add fifth version component$' -1 "$1"; }

# Does a subject say its commit vendored? The subject decides, never the path.
is_vendor() { # <subject>
  case "$1" in vendor:* | *duckdb/duckdb@[0-9a-f]*) return 0 ;; *) return 1 ;; esac
}

# An ERE over the vendor paths, each matched as itself or as a directory.
vendor_re=''
for p in "${VENDOR_PATHS[@]}"; do
  vendor_re="${vendor_re:+$vendor_re|}$(printf '%s' "$p" | sed 's/[.]/\\./g')"
done
vendor_re="^($vendor_re)(/|\$)"

# <tree-ish>'s entries under the vendor paths, as `ls-tree -r` prints them.
vendor_entries() { git ls-tree -r --full-tree "$1" | awk -F'\t' -v re="$vendor_re" '$2 ~ re'; }

# What two commits are twins by: the same vendor paths, blob for blob.
vendor_key() { vendor_entries "$1" | git hash-object --stdin; }

# The tree of <base> with the vendor paths taken whole from <from>.
splice() { # <base> <from> -> tree
  local idx
  idx=$(mktemp)
  GIT_INDEX_FILE=$idx git read-tree "$1"
  GIT_INDEX_FILE=$idx git ls-files -z | awk -v RS='\0' -v ORS='\0' -v re="$vendor_re" '$0 ~ re' |
    GIT_INDEX_FILE=$idx git update-index --force-remove -z --stdin
  vendor_entries "$2" | GIT_INDEX_FILE=$idx git update-index --index-info
  GIT_INDEX_FILE=$idx git write-tree
  rm -f "$idx"
}

# A commit with <from>'s message and author on <parent>, holding <tree>.
commit_like() { # <from> <parent> <tree> -> commit
  git log -1 --format=%B "$1" |
    GIT_AUTHOR_NAME="$(git log -1 --format=%an "$1")" \
    GIT_AUTHOR_EMAIL="$(git log -1 --format=%ae "$1")" \
    GIT_AUTHOR_DATE="$(git log -1 --format=%aD "$1")" \
    git commit-tree "$3" -p "$2"
}

# The next counter value: the fifth component of DESCRIPTION's version plus
# one, as vendor-one.sh stamps it on a buffer commit.
stamp() {
  local version new
  version=$(sed -r -n '/^Version: (.*)$/ s//\1/p' DESCRIPTION)
  new=$(awk -F. -v OFS=. '{ for (i = NF + 1; i <= 5; i++) $i = 0; $5 = $5 + 1; print }' <<<"$version")
  sed -i.bak -r 's/^(Version: ).*$/\1'"$new"'/' DESCRIPTION
  rm -f DESCRIPTION.bak
}

# The glue gate, as vendor-one.sh runs it after a vendor commit.
glue_failures=$(mktemp)
glue_compile_flags() {
  [ -f src/Makevars.rstrtmgr ] || ./configure >/dev/null 2>&1 || true
  (cd src && R CMD SHLIB -n cpp11.cpp 2>/dev/null) |
    grep -m 1 -E -- '-c cpp11\.cpp' |
    sed -E 's/^ *(ccache )?g\+\+ //; s/ -c cpp11\.cpp -o cpp11\.o *$//'
}
glue_compiles() { # 0 compiles, 1 some file does not, 2 the check could not run
  local flags
  flags=$(glue_compile_flags)
  [ -n "$flags" ] || return 2
  # shellcheck disable=SC2016,SC2251  # the sh child expands $FLAGS and $1; the negation is the verdict
  (cd src && printf '%s\n' *.cpp | FLAGS="$flags" xargs -P "$(nproc 2>/dev/null || echo 4)" -I{} \
    sh -c 'eval "g++ $FLAGS -fsyntax-only \"\$1\"" 2>/dev/null || echo "$1"' sh {}) | sort |
    tee "$glue_failures" |
    { ! grep -q .; }
}

# --- --init: the strand derived from the buffer ------------------------------

if [ "$mode" = init ]; then
  git rev-parse -q --verify "$build_ref" >/dev/null || { echo "Error: no $S-build on $remote" >&2; exit 1; }
  if git rev-parse -q --verify "$vendor_ref" >/dev/null; then
    echo "Error: $S-vendor exists on $remote; --init derives a strand once, from a buffer that has none" >&2
    exit 1
  fi
  seed=$(seed_of "$build_ref")
  [ -n "$seed" ] || { echo "Error: $S-build has no seed to start the strand above" >&2; exit 1; }
  prev=$seed
  n=0
  while IFS= read -r c; do
    [ -n "$(git diff-tree --no-commit-id --name-only -r "$c" | grep -m 1 -E "$vendor_re" || true)" ] || continue
    tree=$(splice "$prev" "$c")
    [ "$tree" != "$(git rev-parse "$prev^{tree}")" ] || continue
    prev=$(commit_like "$c" "$prev" "$tree")
    n=$((n + 1))
  done < <(git rev-list --reverse --first-parent "$seed..$build_ref")
  git update-ref "refs/heads/$S-vendor" "$prev"
  echo "$S-vendor: $n commit(s) above $(git rev-parse --short "$seed"), derived from $S-build $(git rev-parse --short "$build_ref")"
  if [ -n "$push" ]; then
    git push --force-with-lease="refs/heads/$S-vendor:" "$remote" "$prev:refs/heads/$S-vendor"
  else
    echo "Not pushed; rerun with --push, or: git push $remote $S-vendor"
  fi
  exit 0
fi

# --- --forward: the strand carried onto a new seed ---------------------------

if [ "$mode" = forward ]; then
  git rev-parse -q --verify "$vendor_ref" >/dev/null || { echo "Error: no $S-vendor on $remote" >&2; exit 1; }
  seed=$(git rev-parse -q --verify "$seed_arg^{commit}") ||
    { echo "Error: --forward $seed_arg is not a commit" >&2; exit 1; }
  vseed=$(seed_of "$vendor_ref")
  [ -n "$vseed" ] || { echo "Error: $S-vendor has no seed" >&2; exit 1; }
  engine=$(git show "$seed:src/duckdb/src/function/table/version/pragma_version.cpp" 2>/dev/null |
    sed -rn 's/^#define DUCKDB_SOURCE_ID "([0-9a-f]+)"$/\1/p')
  anchor=''
  if [ -n "$engine" ]; then
    anchor=$(git log --format='%H %s' "$vseed..$vendor_ref" | grep -m 1 -F "@$engine" | cut -d' ' -f1 || true)
  fi
  wt=$(mktemp -d "${TMPDIR:-/tmp}/series-vendor-$S-XXXXXX")
  git worktree add --detach -q "$wt" "$seed"
  stop() {
    echo >&2
    echo "The strand does not apply on $(git rev-parse --short "$seed"): patch drift." >&2
    echo "Resolve it in $wt, finish the rebase or the cherry-pick there, and write the ref by hand:" >&2
    echo "  git branch -f $S-fwd-vendor <tip>" >&2
    exit 1
  }
  if [ -n "$anchor" ]; then
    echo "$S-fwd-vendor: $(git rev-parse --short "$seed") vendors $engine, which $S-vendor has as $(git rev-parse --short "$anchor");"
    echo "  rebasing $(git rev-list --count "$anchor..$vendor_ref") commit(s) above it onto the seed"
    git -C "$wt" rebase -q --onto "$seed" "$anchor" "$vendor_ref" || stop
  else
    foot=$(git rev-list --reverse --first-parent "$vseed..$vendor_ref" | head -n 1 || true)
    if [ -z "$foot" ]; then
      echo "$S-vendor has nothing above its seed; $S-fwd-vendor is the seed"
    else
      echo "$S-fwd-vendor: $(git rev-parse --short "$seed") vendors ${engine:-nothing}, which $S-vendor does not have: a rewind;"
      echo "  the foot $(git rev-parse --short "$foot") is written on the seed whole, and $(git rev-list --count "$foot..$vendor_ref") commit(s) cherry-picked above it"
      first=$(commit_like "$foot" "$seed" "$(splice "$seed" "$foot")")
      git -C "$wt" checkout -q --detach "$first"
      if [ "$(git rev-list --count "$foot..$vendor_ref")" -gt 0 ]; then
        git -C "$wt" cherry-pick "$foot..$vendor_ref" >/dev/null || stop
      fi
    fi
  fi
  tip=$(git -C "$wt" rev-parse HEAD)
  git worktree remove --force "$wt"
  git update-ref "refs/heads/$S-fwd-vendor" "$tip"
  echo "$S-fwd-vendor: $(git rev-list --count "$seed..$tip") commit(s) on $(git rev-parse --short "$seed"), tip $(git rev-parse --short "$tip")"
  if [ -n "$push" ]; then
    cur=$(git rev-parse -q --verify "refs/remotes/$remote/$S-fwd-vendor" 2>/dev/null || true)
    git push --force-with-lease="refs/heads/$S-fwd-vendor:$cur" "$remote" "$tip:refs/heads/$S-fwd-vendor"
  else
    echo "Not pushed; rerun with --push, or: git push --force-with-lease $remote $S-fwd-vendor"
  fi
  exit 0
fi

# --- the default: the buffer extended from the strand ------------------------

git rev-parse -q --verify "$vendor_ref" >/dev/null ||
  { echo "Error: no $S-vendor on $remote; derive it once: scripts/series-vendor.sh $S --init --push" >&2; exit 1; }
git rev-parse -q --verify "$build_ref" >/dev/null || { echo "Error: no $S-build on $remote" >&2; exit 1; }
git merge-base --is-ancestor "$build_ref" HEAD ||
  { echo "Error: HEAD is not at or above $S-build $(git rev-parse --short "$build_ref"); check it out first" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "Error: working directory not clean" >&2; exit 1; }
[ -z "$(git rev-parse -q --verify CHERRY_PICK_HEAD 2>/dev/null)" ] ||
  { echo "Error: a cherry-pick is in progress; finish or abort it first" >&2; exit 1; }

# The buffer's newest twin on the strand, by the vendor paths blob for blob:
# the newest buffer commits' keys, and the newest strand commit carrying one.
# Bounded as the base scan is, and raised the same way.
depth="${BASE_SCAN_DEPTH:-20}"
keys=$(for c in $(git rev-list -n "$depth" HEAD); do vendor_key "$c"; done)
anchor=''
while IFS= read -r c; do
  if grep -qxF "$(vendor_key "$c")" <<<"$keys"; then anchor=$c; break; fi
done < <(git rev-list "$vendor_ref")
[ -n "$anchor" ] || {
  echo "Error: none of the newest $depth commits of HEAD shares its vendor paths with a commit of $S-vendor;" >&2
  echo "  if the buffer is genuinely that far ahead, raise BASE_SCAN_DEPTH" >&2
  exit 1
}
todo=$(git rev-list --reverse "$anchor..$vendor_ref")
if [ -z "$todo" ]; then
  echo "$S-build is level with $S-vendor at $(git rev-parse --short "$anchor"); nothing to pick"
  exit 0
fi

picked=0
for c in $todo; do
  [ -z "$count" ] || [ "$picked" -lt "$count" ] || break
  subj=$(git log -1 --format=%s "$c")
  echo "Picking $(git rev-parse --short "$c") $subj"
  git cherry-pick "$c" >/dev/null || {
    echo >&2
    echo "The pick conflicts: patch drift between $S-vendor and $S-build." >&2
    echo "Resolve it, 'git cherry-pick --continue', and rerun." >&2
    exit 1
  }
  regenerate
  if is_vendor "$subj"; then stamp; fi
  git add -A
  git commit -q --amend --no-edit
  picked=$((picked + 1))
  if [ "$check_glue" = true ]; then
    glue_status=0
    glue_compiles || glue_status=$?
    if [ "$glue_status" = 2 ]; then
      echo
      echo "=== GLUE CHECK COULD NOT RUN at $(git rev-parse --short HEAD) ==="
      echo "Deriving the compile flags needs src/Makevars.rstrtmgr, which only ./configure"
      echo "writes; run ./configure and read its output, then rerun, or pass --no-check-glue."
      echo "Nothing was compiled, so this says nothing about the commit at HEAD."
      exit 6
    elif [ "$glue_status" != 0 ]; then
      echo
      echo "=== GLUE BROKEN by $(git rev-parse --short HEAD) ==="
      echo "Files: $(tr '\n' ' ' < "$glue_failures")"
      echo "The breaking pick is at HEAD. Fix the glue, 'git commit --amend --no-edit', and rerun;"
      echo "the fix is the buffer's, so the strand commit stays as it is."
      exit 3
    fi
  fi
done
rm -f "$glue_failures"
echo "$S-build: $picked commit(s) picked from $S-vendor, HEAD $(git rev-parse --short HEAD)"
if [ -n "$push" ]; then
  git push "$remote" "HEAD:refs/heads/$S-build"
else
  echo "Not pushed; rerun with --push, or: git push $remote HEAD:$S-build"
fi
