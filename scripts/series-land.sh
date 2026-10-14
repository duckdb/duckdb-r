#!/bin/bash
# Land a series on `main`: build `<L>-land-dev`, every vendor commit of the
# series replayed without its flavor onto the `main` it will fast-forward
# (.claude/skills/series-land/SKILL.md).
#
# A line moves onto `main` when `main` starts releasing it. The series already
# holds the history `main` needs -- one commit per upstream commit, each judged
# by CI with the R-side fix it needed folded in -- but on a lineage of its own:
# its seed is an older `main`, everything `main` gained since arrived as ports,
# and the package carries a flavor. None of that may reach `main`, which only
# ever fast-forwards, so the landing is a forward onto `main` itself, with three
# differences from series-forward:
#
#   * the source is the series' rc strand, `<S>-rc-dev`, the package without its
#     flavor commit for commit (.claude/skills/series-rc/SKILL.md), so nothing
#     is renamed on the way and every commit replayed was already judged under
#     the name `main` ships;
#   * the source is `-dev`, not `-build`, because `main` needs the test-side
#     fixes the loop folded on `-dev`, which a buffer never carries;
#   * the base is `main` as it stands, never a seed: no flavor commits and no
#     version chore. Only `vendor:` commits are replayed, each stamped with the
#     prefix the series carries and a counter of its own
#     (series-forward-build.sh --prefix), so the commit `main` ends on carries
#     the version of the series commit it lands.
#
# The replay is scripts/series-forward-build.sh's: a rewind at the foot takes
# the vendored strand whole, a non-vendor commit `main` does not carry stops the
# run before anything is replayed, a conflict stops it with the tree kept, and
# the glue gate syntax-checks the glue where a pick could have broken it. The
# series' tooling syncs are placed here by subject, because `main` holds newer
# tooling than any of them.
#
# **The landing is checked against the series before it is pushed.** Its tip
# and the rc commit it was built up to must be the same package: the same tree,
# except where the landing takes `main`'s side by construction -- `NEWS.md`, the
# release paperwork no port carries, and the three READMEs, which no port
# carries either (scripts/series-converge.sh has the evidence for both classes),
# plus `DESCRIPTION`'s `Version:` line. A difference anywhere else is a commit
# `main` has that the series never ported, or a fix on one side only, and the
# commits CI would judge would not be the package the series proved. The push is
# refused until it is resolved.
#
# Committer dates are pinned to the base's, so a rebuild from the same inputs
# mints the same SHAs and CI does not judge a commit twice.
#
# **`<L>-land-green` bounds the per-commit build.** It is pushed at the base, so
# scripts/each-plan.sh scans `<L>-land-green..<L>-land-dev` as it scans any
# series, and `--status` advances it over the commits CI has passed, the way
# stage 3 advances a series' green (scripts/series-advance.sh). The landing is
# ready when the two refs are equal. There is no `-land-build`, so the loop's
# discovery never mistakes the pair for a series.
#
# **`--review` writes what a reviewer of `main` reads.** The landing's own diff
# is the engine's, hundreds of thousands of lines; what changes for `main`'s
# maintainers is everything else, the glue, R code and tests the series changed
# on the way. `<L>-land-review` is that alone: the landing's base, one commit
# that removes every workflow, and then, for each landing commit that changes
# anything outside the vendored strand, that change and nothing more, under the
# upstream commit that asked for it. Without its engine the R side compiles
# against nothing, so a check there could only fail, and without workflow files
# a pull request starts none. It goes to the canonical repository, where it is
# opened as a draft pull request against `main` and never merged: `main` takes
# the landing itself.
#
# Usage: series-land.sh <S> [--remote <name>] [--canonical <name>] [--push]
#                       [--placed <sha>]... [--no-check-glue]
#        series-land.sh <S> --status [--remote <name>] [--canonical <name>] [--push]
#        series-land.sh <S> --review [--remote <name>] [--canonical <name>] [--push]
#        series-land.sh <S> --abort
#   <S> is the series whose rc strand lands, `v2.0-cyanoptera-fwd` for
#   `v2.0-cyanoptera-fwd-rc-dev`; the refs are named for its line,
#   `v2.0-cyanoptera-land-*`, on --remote. `main` is read from --canonical.
#   Nothing is written to a remote without --push. A stopped build resumes when
#   rerun, from the worktree it kept; --abort discards that worktree.
#   --review reads the kept build, or `<L>-land-dev` on --remote when there is
#   none, and pushes `<L>-land-review` to --canonical.
#   --placed and --no-check-glue are passed to series-forward-build.sh.
#
# --remote and --canonical are spelled the same in every scripts/series-*.sh;
# see the shared contract in handbook/operations/vendoring/series-loop/README.md.

set -euo pipefail
# A failure inside `$(...)` stops the run too, rather than reading as empty.
shopt -s inherit_errexit

usage='usage: series-land.sh <S> [--remote <name>] [--canonical <name>] [--status | --review] [--push] [--placed <sha>]... [--no-check-glue] [--abort]'
argerr() { echo "$usage" >&2; exit 2; }

remote=${SERIES_REMOTE:-origin}
canonical=${SERIES_CANONICAL-upstream}
push='' status='' review='' abort=''
fwd_args=()
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --canonical) [ $# -ge 2 ] || argerr; canonical=$2; shift 2 ;;
    --placed) [ $# -ge 2 ] || argerr; fwd_args+=(--placed "$2"); shift 2 ;;
    --no-check-glue) fwd_args+=(--no-check-glue); shift ;;
    --push) push=1; shift ;;
    --status) status=1; shift ;;
    --review) review=1; shift ;;
    --abort) abort=1; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
S=${args[0]}
case "$S" in
  *-rc | *-land) echo "Error: $S is a derived strand; name the series it comes from" >&2; exit 2 ;;
esac
L=${S%-fwd}
here=$(cd "$(dirname "$0")" && pwd)

# A stopped or finished build lives here: the worktree it kept, the `main` it
# stands on, the rc commit it builds up to, that strand's seed, and the prefix.
STATE="$(git rev-parse --git-dir)/series-land-$L"

if [ -n "$abort" ]; then
  if [ -f "$STATE" ]; then
    read -r awt _ < "$STATE"
    [ -d "$awt" ] && git worktree remove --force "$awt"
    rm -f "$STATE"
    echo "$L: the kept landing build is discarded; refs on $remote are untouched"
  else
    echo "$L: nothing to abort"
  fi
  exit 0
fi

# The landing stands on the canonical `main` and on nothing else: a mirror that
# has not caught up is an older `main`, and a landing built on it cannot
# fast-forward the real one.
if [ -z "$canonical" ] || ! git remote get-url "$canonical" >/dev/null 2>&1; then
  echo "Error: no canonical remote \"$canonical\" to read main from." >&2
  echo "  Add duckdb/duckdb-r as 'upstream', or pass --canonical <name>." >&2
  exit 1
fi
git fetch -q "$canonical" main
main=$(git rev-parse "refs/remotes/$canonical/main" 2>/dev/null || git rev-parse FETCH_HEAD)

dev_ref="refs/remotes/$remote/$L-land-dev"
green_ref="refs/remotes/$remote/$L-land-green"
git fetch -q "$remote" "+refs/heads/$L-land-*:refs/remotes/$remote/$L-land-*"

# --- --status: what CI has decided, and green over the passed prefix ----------

rcc=${RCC_BRANCH:-rcc2}

# One record per commit; the same helper as scripts/series-advance.sh and
# scripts/series-check.sh, reading the same store.
state_of() {
  local rec
  rec=$(git show "$remote/$rcc:runs2.d/${1:0:2}/$1.ndjson" 2>/dev/null || true)
  [ -z "$rec" ] && { echo missing; return; }
  echo "$rec" | sed -nr 's/.*"status":[^}]*"state": *"([a-z]+)".*/\1/p' | head -n 1
}

if [ -n "$status" ]; then
  for r in "$dev_ref" "$green_ref"; do
    git rev-parse -q --verify "$r" >/dev/null ||
      { echo "Error: ${r#refs/remotes/"$remote"/} does not exist on $remote" >&2; exit 1; }
  done
  git fetch -q "$remote" "+refs/heads/$rcc:refs/remotes/$remote/$rcc" 2>/dev/null || true
  green=$(git rev-parse "$green_ref")
  dev=$(git rev-parse "$dev_ref")
  git merge-base --is-ancestor "$green" "$dev" ||
    { echo "Error: $L-land-green is not an ancestor of $L-land-dev" >&2; exit 1; }
  new_green=$green
  stop='' stop_state=''
  while IFS= read -r sha; do
    st=$(state_of "$sha")
    case "$st" in
      success) new_green=$sha ;;
      *) stop=$sha stop_state=$st; break ;;
    esac
  done < <(git rev-list --reverse --first-parent "$green..$dev")
  total=$(git rev-list --count "$green..$dev")
  passed=$(git rev-list --count "$green..$new_green")
  echo "$L-land-dev: $passed of $total commits above $L-land-green passed"
  if [ -n "$stop" ]; then
    echo "  first not passed: $(git rev-parse --short "$stop") ($stop_state)" \
      "$(git log -1 --format=%s "$stop")"
  fi
  if [ "$new_green" != "$green" ]; then
    if [ -n "$push" ]; then
      # Fast-forward only, as every green: a plain push refuses anything else.
      git push -q "$remote" "$new_green:refs/heads/$L-land-green"
      echo "  $L-land-green -> $(git rev-parse --short "$new_green")"
    else
      echo "  $L-land-green would move to $(git rev-parse --short "$new_green"); --push moves it"
    fi
  fi
  if [ "$new_green" = "$dev" ]; then
    if [ "$(git merge-base "$main" "$dev")" = "$main" ] &&
      [ -z "$(git log --format=%s "$main..$dev" | grep -v '^vendor:' || true)" ]; then
      echo "READY: every commit has passed, and main ($(git rev-parse --short "$main")) fast-forwards to it:"
      echo "  git push $canonical $(git rev-parse "$dev"):refs/heads/main"
    else
      echo "NOT READY: main ($(git rev-parse --short "$main")) is not the base of $L-land-dev;" \
        "it moved, so the landing has to be rebuilt on it"
      exit 1
    fi
  fi
  exit 0
fi

# --- --review: the landing without its engine, for a draft pull request ------

if [ -n "$review" ]; then
  if [ -f "$STATE" ]; then
    read -r wt base _ < "$STATE"
    tip=$(git -C "$wt" rev-parse HEAD)
  elif git rev-parse -q --verify "$dev_ref" >/dev/null; then
    tip=$(git rev-parse "$dev_ref")
    base=$main
  else
    echo "Error: no kept build and no $L-land-dev on $remote to review" >&2
    exit 1
  fi
  git merge-base --is-ancestor "$base" "$tip" ||
    { echo "Error: the landing does not stand on main $(git rev-parse --short "$base")" >&2; exit 1; }

  # The vendored strand, as series-forward-build.sh takes it whole, with the
  # Makevars generated from it, and `DESCRIPTION`, whose `Version:` every landing
  # commit moves; a change to any other line of it is still carried below.
  strand=(src/duckdb patch R/version.R src/include/sources.mk src/Makevars src/Makevars.win)
  excludes=(':(exclude).github/workflows' ':(exclude)DESCRIPTION')
  for p in "${strand[@]}"; do excludes+=(":(exclude)$p"); done
  unversioned() { git show "$1:DESCRIPTION" | grep -v '^Version:'; }
  main_version=$(git show "$base:DESCRIPTION" | sed -n 's/^Version: //p')

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  export GIT_INDEX_FILE="$work/index"
  export GIT_COMMITTER_DATE
  GIT_COMMITTER_DATE=$(git log -1 --format=%cd --date=raw "$base")

  git read-tree "$base"
  git ls-files -z -- .github/workflows | xargs -0 -r git update-index --force-remove --
  head=$(GIT_AUTHOR_DATE=$GIT_COMMITTER_DATE git commit-tree "$(git write-tree)" -p "$base" -m "ci: Remove every workflow from this review branch

The branch carries the R side of the $L landing without its engine,
so it compiles against nothing, and it is never merged.
Without workflow files a pull request from it starts no run.")

  picked=0
  for c in $(git rev-list --reverse --first-parent "$base..$tip"); do
    git diff --binary "$c~1" "$c" -- . "${excludes[@]}" > "$work/diff"
    desc=''
    [ "$(unversioned "$c")" = "$(unversioned "$c~1")" ] || desc=1
    [ -s "$work/diff" ] || [ -n "$desc" ] || continue
    [ -s "$work/diff" ] && git apply --cached --binary --whitespace=nowarn "$work/diff"
    if [ -n "$desc" ]; then
      blob=$(git show "$c:DESCRIPTION" | sed "s/^Version: .*/Version: $main_version/" |
        git hash-object -w --stdin)
      git update-index --cacheinfo "100644,$blob,DESCRIPTION"
    fi
    up=$(git log -1 --format=%s "$c" | sed -rn 's|^.*duckdb/duckdb@([0-9a-f]{10}).*$|\1|p')
    head=$(
      { echo "review: The R side of duckdb/duckdb ${up:-$(git rev-parse --short "$c")}"
        echo
        git log -1 --format=%B "$c"
        echo "Landing-commit: $c"; } |
        GIT_AUTHOR_NAME=$(git log -1 --format=%an "$c") GIT_AUTHOR_EMAIL=$(git log -1 --format=%ae "$c") \
        GIT_AUTHOR_DATE=$(git log -1 --format=%ad --date=raw "$c") \
        git commit-tree "$(git write-tree)" -p "$head"
    )
    picked=$((picked + 1))
  done
  unset GIT_INDEX_FILE

  echo "=== $L-land-review"
  echo "  $picked of $(git rev-list --count "$base..$tip") landing commits change the R side;" \
    "on main $(git rev-parse --short "$base") -> $(git rev-parse --short "$head")"
  echo "  $(git diff --shortstat "$base" "$head" -- . ':(exclude).github/workflows')"

  slug=$(git remote get-url "$canonical" | sed -E 's#^.*github\.com[:/]##; s#\.git$##')
  old=$(git ls-remote "$canonical" "refs/heads/$L-land-review" | cut -f1)
  if [ "$old" = "$head" ]; then
    echo "$L-land-review: already on $canonical"
  elif [ -z "$push" ]; then
    echo "Not pushed; --push writes $L-land-review to $canonical."
    exit 0
  else
    git push -q "$canonical" "--force-with-lease=refs/heads/$L-land-review:$old" \
      "+$head:refs/heads/$L-land-review"
    echo "$L-land-review -> $(git rev-parse --short "$head") on $canonical"
  fi
  echo "Open it as a draft, never to be merged:"
  echo "  gh pr create --repo $slug --draft --base main --head $L-land-review \\"
  echo "    --title \"Review: the R side of the $L landing\""
  exit 0
fi

# --- the build -----------------------------------------------------------------

if [ -f "$STATE" ]; then
  read -r wt base src seed prefix < "$STATE"
  [ -d "$wt" ] || { echo "Error: the kept worktree $wt is gone; rerun with --abort" >&2; exit 1; }
  if [ "$main" != "$base" ]; then
    echo "Error: main moved from $(git rev-parse --short "$base") to $(git rev-parse --short "$main")" >&2
    echo "  since this landing was started, so it can no longer fast-forward main." >&2
    echo "  Freeze main first (.claude/skills/series-land/SKILL.md), then --abort and rebuild." >&2
    exit 1
  fi
  echo "$L: resuming the build in $wt, on main $(git rev-parse --short "$base")," \
    "up to $(git rev-parse --short "$src")"
else
  rc="refs/remotes/$remote/$S-rc-dev"
  # An rc strand behind its source would land a package CI judged as an older
  # one; series-rc.sh recomputes it and says whether the remote holds that.
  "$here/series-rc.sh" "$S" --remote "$remote" >/dev/null || {
    echo "Error: $S-rc-dev is not aligned with $S-dev on $remote;" \
      "realign it first: scripts/series-rc.sh $S --push" >&2
    exit 1
  }
  src=$(git rev-parse "$rc")
  seed=$(git log --first-parent --format=%H --grep='^chore: Add fifth version component$' -1 "$src")
  [ -n "$seed" ] || { echo "Error: $S-rc-dev has no seed" >&2; exit 1; }
  prefix=$(git show "$seed:DESCRIPTION" |
    sed -rn 's/^Version: ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+$/\1/p')
  [ -n "$prefix" ] || { echo "Error: the seed of $S-rc-dev has no five-component version" >&2; exit 1; }
  base=$main
  wt=$(mktemp -d "${TMPDIR:-/tmp}/series-land-$L-XXXXXX")
  git worktree add --detach -q "$wt" "$base"
  echo "$wt $base $src $seed $prefix" > "$STATE"
  echo "$L: building on main $(git rev-parse --short "$base"), up to $S-rc-dev" \
    "$(git rev-parse --short "$src"), stamping $prefix.<n> in $wt"
fi

# The merge driver decides `DESCRIPTION` on every pick; its mapping lives in the
# shared .git/config, and the command it names is the worktree's own.
VENDOR_REPO="$wt" "$here/setup-git.sh" >/dev/null

# Two kinds of commit on the series vendor nothing and are `main`'s already, so
# they are placed here rather than left to the replay's content tests, which a
# port resolved by hand defeats:
#
#   * a port names the `main` commit it was picked from (series-port.sh picks
#     with -x), and one that the base descends from is in the base by ancestry,
#     the one test that cannot be wrong;
#   * a tooling sync changes only what `main` holds newer; series-port.sh
#     writes the subject.
#
# What a by-hand resolution changed beyond `main`'s commit is not lost to this:
# it is in the series' tree and not in the landing's, so the tree check below
# names it.
placed=()
while IFS= read -r c; do
  case "$(git log -1 --format=%s "$c")" in
    vendor:*) continue ;;
    "chore(series): Sync tooling with main" | "chore(series): Sync buffer tooling with main")
      placed+=(--placed "$c")
      continue
      ;;
  esac
  from=$(git log -1 --format=%B "$c" | sed -n 's/^(cherry picked from commit \([0-9a-f]\{40\}\))$/\1/p' | tail -n 1)
  if [ -n "$from" ] && git merge-base --is-ancestor "$from" "$base" 2>/dev/null; then
    placed+=(--placed "$c")
  fi
done < <(git rev-list --reverse "$seed..$src")

export GIT_COMMITTER_DATE
GIT_COMMITTER_DATE=$(git log -1 --format=%cd --date=raw "$base")
# A conflict resolved once is resolved for every rebuild: setup-git.sh turns
# rerere on, and staging what it replays lets a stop it fully resolved be
# continued here rather than handed back. Set for this run's git alone.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=rerere.autoUpdate GIT_CONFIG_VALUE_0=true
pick_state="$(git -C "$wt" rev-parse --absolute-git-dir)/series-forward-pick"
last_stop=''
while :; do
  st=0
  VENDOR_REPO="$wt" "$here/series-forward-build.sh" "$src" "$seed" --prefix "$prefix" \
    ${placed+"${placed[@]}"} ${fwd_args+"${fwd_args[@]}"} || st=$?
  if [ "$st" -ne 1 ] || [ ! -f "$pick_state" ] ||
    [ -n "$(git -C "$wt" diff --name-only --diff-filter=U)" ] ||
    [ "$(cat "$pick_state")" = "$last_stop" ]; then
    break
  fi
  last_stop=$(cat "$pick_state")
  echo "$L: rerere resolved that stop; continuing"
done
if [ "$st" -ne 0 ]; then
  echo
  echo "$L: the build stopped and is kept in $wt."
  echo "  Act there as the message above says, then rerun: scripts/series-land.sh $S"
  exit "$st"
fi

tip=$(git -C "$wt" rev-parse HEAD)
n=$(git rev-list --count "$base..$tip")
odd=$(git log --format='%h %s' "$base..$tip" | grep -v '^[0-9a-f]* vendor:' || true)
if [ -n "$odd" ]; then
  echo "Error: the landing carries commits that vendor nothing:" >&2
  echo "  ${odd//$'\n'/$'\n'  }" >&2
  exit 1
fi

# --- the same package as the series ------------------------------------------

version_lines() { git show "$1:DESCRIPTION" | grep -v '^Version:'; }
version_of() { git show "$1:DESCRIPTION" | sed -n 's/^Version: //p'; }
row() { printf '%s\t%s\t%s' "$@"; } # <path> <added/deleted> [<why>]
explained=() unexplained=()
while IFS=$'\t' read -r add del path; do
  case "$path" in
    NEWS.md | README.Rmd | README.md | .github/README.md)
      explained+=("$(row "$path" "$add/$del" "main's by construction; no port carries it")") ;;
    DESCRIPTION)
      if [ "$(version_lines "$tip")" = "$(version_lines "$src")" ]; then
        explained+=("$(row "$path" "$add/$del" \
          "the version: $(version_of "$tip") here, $(version_of "$src") on the series")")
      else
        unexplained+=("$(row "$path" "$add/$del")")
      fi
      ;;
    *) unexplained+=("$(row "$path" "$add/$del")") ;;
  esac
done < <(git diff --numstat "$tip" "$src")

echo "=== $L-land-dev"
echo "  $n vendor commits on main $(git rev-parse --short "$base") -> $(git rev-parse --short "$tip")"
echo "  built up to $S-rc-dev $(git rev-parse --short "$src")"
if [ ${#explained[@]} -gt 0 ]; then
  echo
  echo "  explained (${#explained[@]}):"
  printf '%s\n' "${explained[@]}" | awk -F'\t' '{ printf "    %-44s %-9s %s\n", $1, $2, $3 }'
fi
if [ ${#unexplained[@]} -gt 0 ]; then
  echo
  echo "  UNEXPLAINED (${#unexplained[@]}):"
  printf '%s\n' "${unexplained[@]}" | awk -F'\t' '{ printf "    %-44s %s\n", $1, $2 }'
  echo
  echo "DIVERGED: the landing is not the package $S-rc-dev holds."
  echo "  Port what main has to $S and realign its rc strand, or fold the fix the"
  echo "  landing lacks; then --abort and rebuild. Nothing was pushed."
  exit 1
fi

old_dev=$(git rev-parse -q --verify "$dev_ref" || true)
old_green=$(git rev-parse -q --verify "$green_ref" || true)
# Green keeps what CI has already passed when the chain under it is the same,
# and starts at the base otherwise.
new_green=$base
if [ -n "$old_green" ] && git merge-base --is-ancestor "$base" "$old_green" 2>/dev/null &&
  git merge-base --is-ancestor "$old_green" "$tip"; then
  new_green=$old_green
fi

if [ "$old_dev" = "$tip" ] && [ "$old_green" = "$new_green" ]; then
  echo
  echo "$L-land-dev: already on $remote"
  exit 0
fi
if [ -z "$push" ]; then
  echo
  echo "Not pushed; --push writes $L-land-dev at $(git rev-parse --short "$tip")" \
    "and $L-land-green at $(git rev-parse --short "$new_green")."
  exit 0
fi
# Both refs or neither: a `-dev` pushed without its green would be planned from
# the start of `main`'s history (scripts/each-plan.sh).
git push -q --atomic "$remote" \
  "--force-with-lease=refs/heads/$L-land-dev:$old_dev" \
  "--force-with-lease=refs/heads/$L-land-green:$old_green" \
  "+$new_green:refs/heads/$L-land-green" \
  "+$tip:refs/heads/$L-land-dev"
echo
echo "$L-land-dev -> $(git rev-parse --short "$tip"), $L-land-green -> $(git rev-parse --short "$new_green")"
echo "The build stays in $wt for repairs; --abort removes it."
