#!/bin/bash
# Vendors DuckDB sources commit-by-commit from the upstream repository.
# Used by the series loop (.claude/skills/series-loop.md).
# See scripts/VENDORING.md for complete documentation
#
# https://unix.stackexchange.com/a/654932/19205
# Using bash for -o pipefail

set -e
set -x
set -o pipefail

# The checkout to vendor into, so the series loop can run `main`'s copy of this
# script against another worktree. Only *this* script comes from `main` that
# way: everything it invokes by relative path -- `scripts/rconfigure.py`,
# `patch/*.patch`, `./configure` -- stays the target tree's.
cd "${VENDOR_REPO:-$(dirname "$0")/..}"
toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: $PWD is not a git worktree" >&2
  exit 1
}
[ "$toplevel" -ef . ] || {
  echo "Error: $PWD is not the root of its worktree ($toplevel)" >&2
  exit 1
}

project=duckdb
vendor_base_dir=src/duckdb
vendor_dir=${vendor_base_dir}
repo_org=${project}
repo_name=${project}


upstream_basedir=""
num_commits=1
check_glue=true

# Matches the bound in vendored_sha() (scripts/series-advance.sh).
base_scan_depth="${BASE_SCAN_DEPTH:-20}"

while [ $# -gt 0 ]; do
  case "$1" in
    --commits|-c)
      num_commits="$2"
      shift 2
      ;;
    --no-check-glue)
      check_glue=false
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      upstream_basedir="$1"
      shift
      ;;
  esac
done

if [ -z "$upstream_basedir" ]; then
  upstream_basedir=../../../${project}
fi

upstream_dir=${project}

if [ ! -d "$upstream_dir" ]; then
  git clone "$upstream_basedir" "$upstream_dir"
elif [ "$upstream_basedir" != "$upstream_dir" ]; then
  git -C "$upstream_dir" fetch origin
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working directory not clean"
  exit 1
fi

if [ -n "$(git -C "$upstream_dir" status --porcelain)" ]; then
  echo "Warning: working directory $upstream_dir not clean"
fi

start=$(git -C "$upstream_dir" rev-parse --verify HEAD)

glue_compile_flags() {
  # src/Makevars includes Makevars.rstrtmgr, which only ./configure writes and
  # .gitignore keeps out of the tree; without it `make -n` stops before it ever
  # prints a compile line.
  [ -f src/Makevars.rstrtmgr ] || ./configure >/dev/null 2>&1
  (cd src && R CMD SHLIB -n cpp11.cpp 2>/dev/null) |
    grep -m 1 -E -- '-c cpp11\.cpp' |
    sed -E 's/^ *(ccache )?g\+\+ //; s/ -c cpp11\.cpp -o cpp11\.o *$//'
}

glue_compiles() {
  local flags
  flags=$(glue_compile_flags)
  if [ -z "$flags" ]; then
    echo "Error: could not derive glue compile flags (R CMD SHLIB -n)"
    return 2
  fi
  # `eval` because R quotes its include path (-I"/usr/share/R/include"); plain
  # expansion word-splits without removing the quotes, so g++ never finds R.h
  # and every glue file looks broken.
  (cd src && ls *.cpp | FLAGS="$flags" xargs -P 4 -I{} \
    sh -c 'eval "g++ $FLAGS -fsyntax-only \"\$1\"" 2>/dev/null || echo "$1"' sh {}) | sort |
    tee /tmp/vendor-one-glue-failures.txt |
    { ! grep -q .; }
}

# The upstream SHA the branch has vendored, and the base of the next walk.
# Answering empty is not an option: an empty base makes the range below read
# `..${start}`, whose missing left side git resolves to the upstream clone's
# HEAD -- a range nobody chose, and one that silently vendors the wrong span.
# The same rule, and the same bound, as vendored_sha() in
# scripts/series-advance.sh; scripts/vendor.sh has its own copy.
vendored_sha() {
  local subjects sha n
  subjects=$(git log -n "${base_scan_depth}" --format="%s" -- ${vendor_dir} | tee /dev/stderr)
  sha=$(sed -nr '/^.*'${repo_org}.${repo_name}'@([0-9a-f]+)( .*)?$/{s//\1/;p;}' <<<"$subjects" | head -n 1)
  if [ -z "$sha" ]; then
    n=$(grep -c . <<<"$subjects" || true)
    echo "Error: no ${repo_org}/${repo_name}@ subject among the newest $n" \
      "${vendor_dir} commit(s) of $(git rev-parse --abbrev-ref HEAD)" >&2
    if [ "$n" -ge "${base_scan_depth}" ]; then
      echo "  the scan is bounded at ${base_scan_depth}; if that is genuinely too" \
        "shallow, raise BASE_SCAN_DEPTH" >&2
    fi
    return 1
  fi
  echo "$sha"
}

commits_vendored=0

while [ $commits_vendored -lt $num_commits ]; do
  echo "=== Vendoring commit $((commits_vendored + 1)) of $num_commits ==="

  # Where the last run left off; re-read every iteration, because each vendored
  # commit moves it.
  if ! base=$(vendored_sha); then
    rm -rf "$upstream_dir"
    exit 1
  fi

  original=$(git -C "$upstream_dir" log --first-parent --reverse --format="%H" "${base}".."${start}" --)

  if [ -z "$original" ]; then
    echo "No more commits to vendor. Done."
    rm -rf "$upstream_dir"
    exit 0
  fi

  message=
  is_tag=

  for commit in $original; do
    echo "Importing commit $commit"

    git -C "$upstream_dir" checkout "$commit" || {
      echo "Error: Failed to checkout commit $commit"
      rm -rf "$upstream_dir"
      exit 1
    }

    rm -rf ${vendor_dir}

    echo "R: configure"
    DUCKDB_PATH="$upstream_dir" python3 scripts/rconfigure.py || {
      echo "Error: Failed to configure"
      rm -rf "$upstream_dir"
      exit 1
    }

    # `--reverse` needs `--forward` beside it: on its own it prompts
    # ("Unreversed patch detected!  Ignore -R? [n]") and hangs a run whose
    # stdin is a terminal.
    # scripts/vendor.sh has the same three-way split and the same exit 4.
    for f in patch/*.patch; do
      if patch -i "$f" -p1 --forward --dry-run; then
        patch -i "$f" -p1 --forward --no-backup-if-mismatch
      elif patch -i "$f" -p1 --reverse --forward --dry-run; then
        echo "Removing patch $f (its change is already in the regenerated tree)"
        rm "$f"
      else
        echo ""
        echo "=== PATCH BROKEN: $f (upstream ${commit}) ==="
        echo "It neither applies forward nor reverses cleanly, so its change is"
        echo "not in the regenerated tree and cannot be re-applied: the code it"
        echo "patches moved."
        echo "The regenerated sources for ${commit} are in the working tree,"
        echo "uncommitted, and the upstream clone is kept."
        echo "Rebase $f against them, keeping the rebased patch outside the tree,"
        echo "then 'git checkout -- .', put it back, and rerun this script."
        echo "Delete it only after confirming its change is genuinely upstream."
        exit 4
      fi
    done

    # Always vendor tags
    if [ "$(git -C "$upstream_dir" describe --tags "$commit" | grep -c -- -)" -eq 0 ]; then
      message="vendor: Update vendored sources (tag $(git -C "$upstream_dir" describe --tags "$commit")) to ${repo_org}/${repo_name}@$commit"
      is_tag=true
      break
    fi

    # pragma_version.cpp always differs, so "more than one" is the test for a
    # real change.
    if [ "$(git status --porcelain -- ${vendor_base_dir} | wc -l)" -gt 1 ]; then
      message="vendor: Update vendored sources to ${repo_org}/${repo_name}@$commit"
      break
    fi
  done

  if [ "$message" = "" ]; then
    echo "No changes found. Done."
    # Nothing was vendored, so leave the tree exactly as the run found it.
    # rconfigure.py rewrites R/version.R, src/Makevars, src/Makevars.win and
    # src/include/sources.mk for every candidate it tries, not just ${vendor_dir},
    # and any leftover of those would make the next run refuse on a dirty tree.
    # Restoring everything is safe because the run refused to start on one:
    # anything untracked here was created by this run. The clone is ignored,
    # so `git clean` leaves it for `rm -rf` below to remove deliberately.
    git checkout -- .
    git clean -fd
    rm -rf "$upstream_dir"
    exit 0
  fi

  our_tag=$(git describe --tags --abbrev=0 | sed -r 's/-[0-9]$//')
  upstream_tag=$(git -C "$upstream_dir" describe --tags --abbrev=0)

  if [ "$our_tag" = "v1.3.3" ]; then
    # Inofficial release v1.3.3
    our_tag="v1.3.2"
  fi

  echo "Our tag: $our_tag"
  echo "Upstream tag: $upstream_tag"

  version=$(sed -r -n '/^Version: (.*)$/ s//\1/p' DESCRIPTION)
  version_array=(${version//./ })
  for i in {0..4}; do
    if [ -z "${version_array[i]}" ]; then
      version_array[i]=0
    fi
  done
  version_array[4]=$((version_array[4] + 1))
  new_version=$(IFS=.; echo "${version_array[*]}")

  echo "Updating version from $version to $new_version"
  sed -i.bak -r 's/^(Version: ).*$/\1'"$new_version"'/' DESCRIPTION
  rm DESCRIPTION.bak

  git add .

  (
    echo "$message"
    echo
    git -C "$upstream_dir" log -1 --format="Date: %ai" "${commit}"
    echo
    git -C "$upstream_dir" log --first-parent --format="%s" "${base}".."${commit}" |
      tee /dev/stderr |
      sed -r 's%#([0-9]+)%https://redirect.github.com/'${repo_org}/${repo_name}'/pull/\1%g'
  ) | git commit --file /dev/stdin || {
    echo "Error: Failed to commit changes"
    rm -rf "$upstream_dir"
    exit 1
  }

  commits_vendored=$((commits_vendored + 1))

  echo "Successfully vendored commit $commits_vendored"

  if [ "$check_glue" = true ] && ! glue_compiles; then
    echo ""
    echo "=== GLUE BROKEN by $(git rev-parse --short HEAD) (upstream ${commit}) ==="
    echo "Files: $(tr '\n' ' ' < /tmp/vendor-one-glue-failures.txt)"
    echo "The breaking vendor commit is at HEAD and the upstream clone is kept."
    echo "Fix the glue, run clang-format, amend into HEAD appending an"
    echo "'R-side fix' section to the message, then rerun this script."
    exit 3
  fi

  if [ -n "${is_tag}" ]; then
    echo "Vendored a tag. Stopping."
    rm -rf "$upstream_dir"
    exit 0
  fi
done

echo "Successfully vendored $commits_vendored commit(s)"
rm -rf "$upstream_dir"
