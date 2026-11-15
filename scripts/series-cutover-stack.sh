#!/bin/bash
# Build the review stack of one strand of a cutover and push it to the fork:
# the old tip with `main`'s changes replayed onto it, the forward's engine, the forward's tree, and the old tree again,
# each layer a branch on the one before.
#
# A cutover swaps `<S>-fwd-*` in for `<S>-*` (scripts/series-cutover.sh),
# and what the two differ by is reviewed first, as one stack of draft pull requests per strand
# that the session running the cutover opens with its own GitHub tools (.claude/skills/series-cutover/SKILL.md).
# This script builds and pushes the branches, prints the pull requests to open, and opens nothing: it never calls `gh`.
# For a strand <X> of `vendor`, `build`, `dev` or `green`, the layers are, in the fork:
#
#   cutover/<S>/<X>/1-main    `<S>-<X>` with `main`'s changes replayed onto it, its engine kept
#   cutover/<S>/<X>/2-engine  the forward's engine copied in, only where it differs from the one below
#   cutover/<S>/<X>/3-fwd     the tree of `<S>-fwd-<X>`
#   cutover/<S>/<X>/4-old     the tree of `<S>-<X>` again
#
# `main` stands for the branch the series releases from, on which the base under its seed lies:
# `main` itself for most series, and another branch, such as `v2.0-cyanoptera`, for a series that releases from it.
# The layer is called `1-main` all the same.
#
# The first layer stands on the old tip,
# so a pull request with it as head keeps the old lineage reachable as `refs/pull/<n>/head`,
# which is what the swap checks before it moves a ref.
# Once the swap has run, `<S>-<X>` is the forward's tip, and `-fwd` refs a remote refused to delete may stay beside it:
# a stack built then would move `1-main` onto the forward's lineage, and the head of an open pull request with it.
# So the script refuses where `<S>-dev` and `<S>-fwd-dev` are one lineage:
# where `<S>-dev` carries the seed of `<S>-fwd-dev`, which a forward's `-dev` never sits below,
# and which the series' `-dev` carries only once the swap has put the forward's lineage in its place,
# whatever was folded above the seed since; a forward's `-dev` without a seed is read by ancestry, either way.
# The strand itself cannot tell: a forward's green sits below its seed at birth, on a commit the series' green may have too.
#
# The replay spans `main` from the old series' base to the forward's base,
# each the commit under the seed (`series_seed_subject`, scripts/series-config.sh)
# and the flavor commits scripts/flavor.sh writes below it, read on `<S>-dev` and on `<S>-fwd-dev`;
# a `-dev` with no seed takes its merge base with the fork's `main`.
# Where the old base is an ancestor of the forward's base,
# `main`'s first-parent commits in the span are cherry-picked onto the old tip one by one, with `-x`,
# a merge against its first parent.
# Every pick leaves out the engine paths, the vendor paths (`series_vendor_paths`) but `patch/`,
# so that this layer keeps the old tip's engine and the next one brings the forward's,
# while a change to the patch stack is replayed like any other change.
# A vendor commit leaves out its DESCRIPTION too, where vendoring stamps the counter,
# which a carry leaves out for the same reason (`series_carry_filter`, scripts/series-lib.sh).
# A commit that carries nothing else is recorded as vendoring only, or as an engine change only.
# A commit whose change the old strand already has, as the same patch or as a pick that changes nothing,
# is recorded as present.
# Where the old base is not an ancestor of the forward's, the layer is one commit, labeled as such:
# the three-way merge `git merge-tree --write-tree --merge-base=<old base> <old tip> <forward base>`,
# with the forward base's engine paths read from the old base, for the same reason.
#
# `2-engine` copies the forward's engine paths onto `1-main` wherever the two differ:
# where the tips vendor different upstream commits,
# and where they vendor the same one but the engine changed beside vendoring, as a commit of the patch stack changes it.
# `patch/` stays that of `1-main`, so that what the forward changed in the patch stack shows in `3-fwd`.
#
# A conflict stops the build with the worktree kept, as stage 5 stops on a carry:
# resolve it there, `git add` the paths, and rerun with --continue, or throw the build away with --abort,
# from the worktree or from the checkout that started the build.
# Nothing is pushed before every layer is built.
# rerere records each resolution (scripts/setup-git.sh, which this script runs),
# so a rebuild that meets the same conflict resolves it the same way without stopping;
# the commit names the paths either way.
#
# Commits are deterministic: a pick keeps its author and its dates, every commit has the same committer,
# and every other commit is dated by the newer of the two tips,
# so the same inputs give the same SHAs on any machine.
# The layers go up in one atomic push, each leased on the tip this run read, or on its absence,
# so a rebuild moves existing branches only from where it found them.
# A `2-engine` an earlier build pushed, which this one has no use for, is left where it is:
# GitHub closes a pull request whose base branch is deleted, as the `3-fwd` one's is,
# so the script prints the steps that retire it, for the session to take in their order.
# Where the remote refuses a deletion, the `gh api` line it prints instead checks the tip first,
# since the API takes no lease.
#
# Then the script prints a summary per layer, written to be the body of the layer's pull request:
# what was replayed, what was recorded as present, as vendoring only or as an engine change only,
# which conflicts were resolved, which commits of `main` `2-engine` carries the engine paths of, and the diff stat.
# Last come the pull requests to open, with repository, base, head and title,
# in the order the session links them into one GitHub stack.
# The calls that link them are the skill's, since only the pull requests' numbers fill them in.
# --summary writes the same to a file before the push, so a file that cannot be written refuses before anything moves,
# and removes it again where the push is refused, so that no summary of a build that was never pushed is left behind.
# Only a regular file is removed: a link or a device is left as it is, and the run says what it left.
# The script reads no terminal: stdin is /dev/null, and a conflict stops the run for the next one to resume.
#
# Usage: series-cutover-stack.sh <series> <strand> [--remote <name>] [--upstream <path>] [--summary <file>] [--continue | --abort]
#   series-cutover-stack.sh v2.0-cyanoptera dev --upstream ../../../duckdb --summary /tmp/dev.md
#   <strand>          one of vendor, build, dev, green.
#   --remote <name>   the remote of this repository carrying the series refs, the fork, where the stack is pushed.
#                     Default `origin`, or $SERIES_REMOTE.
#   --upstream <path> a duckdb/duckdb checkout, read with `git -C` to count the upstream commits a `2-engine` spans;
#                     default $UPSTREAM_CLONE. Without one the range is named and not counted.
#                     It changes no commit.
#   --summary <file>  also write the summary and the pull requests to <file>.
#   --continue        finish a build that stopped on a conflict, with the options it was started with;
#                     --summary and --upstream given here replace theirs.
#   --abort           discard a stopped build and its worktree.
# The options are spelled as in every scripts/series-*.sh;
# see the shared contract in handbook/operations/vendoring/series-loop/README.md.
#
# Exit status:
#   0  built and pushed.
#   1  refused or failed, and nothing pushed: a ref missing, a series on its forward's lineage,
#      an engine that cannot be read, a stopped build in the way, a summary file that cannot be written,
#      a push refused, a lease it lost among them, which removes a regular --summary file again.
#      A rerun reads the refs anew.
#   2  a usage error; nothing was read.
#   3  stopped on a conflict, the worktree and the build kept for --continue; nothing was pushed.
#   9  built and pushed, and a `2-engine` of an earlier build left for the session to retire,
#      printed with the steps that do so.
#   Any other status is a command that failed, before the push.

set -euo pipefail
shopt -s inherit_errexit
# shellcheck source=series-lib.sh
. "$(dirname "$0")/series-lib.sh"

usage='usage: series-cutover-stack.sh <series> <strand> [--remote <name>] [--upstream <path>] [--summary <file>] [--continue | --abort]'
argerr() { echo "$usage" >&2; exit 2; }

remote=${SERIES_REMOTE:-origin}
upstream=${UPSTREAM_CLONE:-}
summary='' action=build remote_given='' upstream_given='' summary_given=''
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; remote_given=1; shift 2 ;;
    --upstream) [ $# -ge 2 ] || argerr; upstream=$2; upstream_given=1; shift 2 ;;
    --summary) [ $# -ge 2 ] || argerr; summary=$2; summary_given=1; shift 2 ;;
    --continue) [ "$action" = build ] || argerr; action=resume; shift ;;
    --abort) [ "$action" = build ] || argerr; action=abort; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 2 ] || argerr
[ -n "${args[0]}" ] || argerr
S=${args[0]} X=${args[1]}
case "$X" in
  vendor | build | dev | green) ;;
  *) echo "Error: a strand is vendor, build, dev or green, not '$X'" >&2; argerr ;;
esac

# Nothing below reads a terminal, and nothing git runs may ask one.
exec </dev/null
export GIT_TERMINAL_PROMPT=0

cut="cutover/$S/$X"
self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
common=$(git rev-parse --path-format=absolute --git-common-dir)
# A stopped build lives here, in the repository rather than in one worktree,
# so --continue and --abort work from the kept worktree as well as from the checkout that started it.
STATE="$common/series-cutover-stack/${S//\//-}-$X"

# Every commit this script writes has this committer, and the commits that are not picks this author;
# see the header for the dates.
id_name=series-cutover-stack
id_email=series-cutover-stack@invalid
short() { git rev-parse --short=10 "$1"; }

if [ "$action" = abort ]; then
  if [ -f "$STATE/vars" ]; then
    # shellcheck source=/dev/null
    . "$STATE/vars"
    # Out of the worktree first, where the stop sent whoever runs this: git cannot run in a directory it deleted.
    cd "$common"
    [ ! -d "$wt" ] || git worktree remove --force "$wt"
    git worktree prune
    rm -rf "$STATE"
    echo "$S $X: the stopped build is discarded, and nothing was pushed"
  else
    rm -rf "$STATE"
    echo "$S $X: no stopped build to abort"
  fi
  exit 0
fi

tmp=$(mktemp -d)
wt='' keep=''
# A build that fails before its first stop leaves nothing behind;
# one that has stopped once keeps its worktree whatever happens, since it may hold a resolution somebody made.
cleanup() {
  rm -rf "$tmp"
  if [ -z "$keep" ] && [ -n "$wt" ]; then
    git worktree remove --force "$wt" 2>/dev/null || true
    rm -rf "$STATE"
  fi
}
trap cleanup EXIT

# --- the paths a layer keeps or takes ---------------------------------------

paths_re() { # <path or glob>... -> an ERE matching each as itself or as a directory
  local re='' p
  for p in "$@"; do re="${re:+$re|}$(series_re_of "$p")"; done
  printf '^(%s)(/|$)' "$re"
}
# The engine paths, the vendor paths but `patch/`: what every pick leaves out of `1-main`, and what `2-engine` takes from the forward.
# A vendor commit leaves out DESCRIPTION too, where vendoring stamps the counter.
# A change to the patch stack is replayed like any other, so that what the forward changed there shows in `3-fwd`.
engine_paths=()
for p in "${series_vendor_paths[@]}"; do [ "$p" = patch ] || engine_paths+=("$p"); done
engine_re=$(paths_re "${engine_paths[@]}")
vendor_commit_re=$(paths_re "${engine_paths[@]}" DESCRIPTION)
zero=$(git hash-object -t blob --stdin < /dev/null | tr '0-9a-f' '0')

tree_with() { # <tree-ish> <tree-ish to take paths from> <ERE> -> a tree
  local idx=$tmp/index
  rm -f "$idx"
  GIT_INDEX_FILE=$idx git read-tree "$1"
  {
    GIT_INDEX_FILE=$idx git -c core.quotePath=false ls-files |
      RE=$3 awk 'BEGIN { re = ENVIRON["RE"] } $0 ~ re' | sed "s/^/0 $zero\t/"
    git -c core.quotePath=false ls-tree -r --full-tree "$2" |
      RE=$3 awk -F'\t' 'BEGIN { re = ENVIRON["RE"] } $2 ~ re'
  } | GIT_INDEX_FILE=$idx git update-index --index-info
  GIT_INDEX_FILE=$idx git write-tree
}

# A commit of <tree> on <parent>, for a pick to apply: its change is the one between the two, and nothing of it is kept but that.
synthetic() { # <tree> <parent> -> commit
  GIT_AUTHOR_NAME=$id_name GIT_AUTHOR_EMAIL=$id_email GIT_AUTHOR_DATE=$stamp \
    GIT_COMMITTER_NAME=$id_name GIT_COMMITTER_EMAIL=$id_email GIT_COMMITTER_DATE=$stamp \
    git commit-tree --no-gpg-sign "$1" -p "$2" -m 'series-cutover-stack: the change to replay'
}

layer_commit() { # <tree> <parent> <message file> -> commit
  GIT_AUTHOR_NAME=$id_name GIT_AUTHOR_EMAIL=$id_email GIT_AUTHOR_DATE=$stamp \
    GIT_COMMITTER_NAME=$id_name GIT_COMMITTER_EMAIL=$id_email GIT_COMMITTER_DATE=$stamp \
    git commit-tree --no-gpg-sign "$1" -p "$2" -F "$3"
}

record() { # <kind> <commit> [<detail>]
  printf '%s\t%s\t%s\n' "$1" "$2" "${3:-}" >> "$STATE/log"
}

save_vars() {
  declare -p S X remote upstream summary wt old fwd old_base fwd_base mode stamp \
    old_engine fwd_engine stopped stopped_left stopped_kind stopped_paths LEASE > "$STATE/vars"
}

clear_merge_state() {
  local f
  for f in MERGE_MSG AUTO_MERGE; do rm -f "$(git -C "$wt" rev-parse --git-path "$f")"; done
}

# --- the build, or the stopped one resumed ------------------------------------

stopped='' stopped_left='' stopped_kind='' stopped_paths=''
if [ "$action" = resume ]; then
  [ -f "$STATE/vars" ] || { echo "Error: no stopped build of $S $X to continue" >&2; exit 1; }
  given_summary=$summary given_upstream=$upstream given_remote=$remote
  # shellcheck source=/dev/null
  . "$STATE/vars"
  keep=1
  [ -z "$summary_given" ] || summary=$given_summary
  [ -z "$upstream_given" ] || upstream=$given_upstream
  [ -z "$remote_given" ] || [ "$given_remote" = "$remote" ] ||
    { echo "Error: this build was started against '$remote', not '$given_remote'" >&2; exit 1; }
  [ -d "$wt" ] || { echo "Error: the kept worktree $wt is gone; rerun with --abort" >&2; exit 1; }
  mapfile -t todo < "$STATE/todo"
else
  [ ! -f "$STATE/vars" ] || {
    # shellcheck source=/dev/null
    (. "$STATE/vars"; echo "Error: a build of $S $X stopped at $(short "$stopped" 2>/dev/null || echo "$stopped"), in $wt" >&2)
    echo "  Resolve it and rerun with --continue, or discard it with --abort." >&2
    exit 1
  }
  # The DESCRIPTION merge driver and rerere, as for every replay here.
  if [ -x "$(dirname "$0")/setup-git.sh" ]; then
    VENDOR_REPO="$(git rev-parse --show-toplevel)" "$(dirname "$0")/setup-git.sh" >/dev/null
  fi
  git config --get merge.ours-version.driver >/dev/null ||
    { echo "Error: merge driver not registered, run scripts/setup-git.sh" >&2; exit 1; }

  # One read of the fork: the four tips, and the stack an earlier build left, whose tips are what this build's push is leased on.
  listing=$(git ls-remote --heads "$remote" "refs/heads/$S-$X" "refs/heads/$S-fwd-$X" \
    "refs/heads/$S-dev" "refs/heads/$S-fwd-dev" "refs/heads/$cut/*") ||
    { echo "Error: cannot read '$remote'" >&2; exit 1; }
  declare -A HEAD_OF=()
  while read -r sha ref; do
    [ -n "$ref" ] || continue
    HEAD_OF[${ref#refs/heads/}]=$sha
  done <<<"$listing"
  declare -A WANT=()
  for r in "$S-$X" "$S-fwd-$X" "$S-dev" "$S-fwd-dev"; do
    [ -n "${HEAD_OF[$r]:-}" ] || { echo "Error: '$remote' has no $r, so there is no stack to build" >&2; exit 1; }
    WANT[$r]=1
  done
  specs=()
  for r in "${!WANT[@]}"; do specs+=("+refs/heads/$r:refs/remotes/$remote/$r"); done
  git fetch -q "$remote" "${specs[@]}"
  declare -A LEASE=()
  for L in 1-main 2-engine 3-fwd 4-old; do LEASE[$L]=${HEAD_OF[$cut/$L]:-}; done
  old=${HEAD_OF[$S-$X]} fwd=${HEAD_OF[$S-fwd-$X]}

  # One lineage, as after the swap with the forward's refs left behind: a stack built on it would move the pin.
  # Read on `-dev`, by the forward's seed (see the header).
  one_lineage() { # <series -dev> <forward -dev>
    local seed
    seed=$(series_seed_of "$2")
    if [ -n "$seed" ]; then
      git merge-base --is-ancestor "$seed" "$1"
    else
      git merge-base --is-ancestor "$2" "$1" || git merge-base --is-ancestor "$1" "$2"
    fi
  }
  if one_lineage "${HEAD_OF[$S-dev]}" "${HEAD_OF[$S-fwd-dev]}"; then
    echo "Error: $S-dev at $(short "${HEAD_OF[$S-dev]}") and $S-fwd-dev at $(short "${HEAD_OF[$S-fwd-dev]}") are one lineage, as after the swap" >&2
    echo "  with the forward's refs left behind: a stack built on it would move $cut/1-main off the old tip it pins." >&2
    echo "  Nothing was pushed. Delete the forward's refs, as scripts/series-prune.sh $S lists them." >&2
    exit 1
  fi

  # The base a series stands on: the commit under its seed and the flavor commits below that, as scripts/flavor.sh names them.
  flavor_re='^chore: Update (flavor patch|version) to '
  base_of() { # <-dev tip> -> commit, empty when none
    local seed c
    seed=$(series_seed_of "$1")
    if [ -z "$seed" ]; then
      git fetch -q "$remote" "+refs/heads/main:refs/remotes/$remote/main" || return 0
      git merge-base "$1" "refs/remotes/$remote/main" || true
      return 0
    fi
    c=$(git rev-parse -q --verify "$seed^") || return 0
    while [[ $(git log -1 --format=%s "$c") =~ $flavor_re ]]; do
      c=$(git rev-parse -q --verify "$c^") || return 0
    done
    echo "$c"
  }
  old_base=$(base_of "${HEAD_OF[$S-dev]}")
  fwd_base=$(base_of "${HEAD_OF[$S-fwd-dev]}")
  [ -n "$old_base" ] || { echo "Error: no base found under the seed of $S-dev" >&2; exit 1; }
  [ -n "$fwd_base" ] || { echo "Error: no base found under the seed of $S-fwd-dev" >&2; exit 1; }
  if git merge-base --is-ancestor "$old_base" "$fwd_base"; then mode=pick; else mode=merge; fi

  # The engine each tip vendors, as its tree records it, or else as its newest vendor subject names it.
  engine_of() { # <commit> -> abbreviated upstream SHA, empty when unreadable
    local e
    e=$(series_engine_of "$1")
    [ -n "$e" ] || e=$(series_vendored_sha "$1" 2>/dev/null)
    echo "$e"
  }
  old_engine=$(engine_of "$old")
  fwd_engine=$(engine_of "$fwd")
  [ -n "$old_engine" ] || { echo "Error: cannot read the engine $S-$X vendors" >&2; exit 1; }
  [ -n "$fwd_engine" ] || { echo "Error: cannot read the engine $S-fwd-$X vendors" >&2; exit 1; }

  ct_old=$(git log -1 --format=%ct "$old")
  ct_fwd=$(git log -1 --format=%ct "$fwd")
  stamp="$((ct_old > ct_fwd ? ct_old : ct_fwd)) +0000"

  rm -rf "$STATE"
  mkdir -p "$STATE"
  : > "$STATE/log"
  wt=$(mktemp -d)
  git worktree add --detach -q "$wt" "$old"

  # What to replay, oldest first, each with the commit of the old strand that already carries it as the same patch, or `-`.
  # Vendor commits are never matched by patch: what they carry beyond vendoring is read when they come up.
  todo=()
  if [ "$mode" = merge ]; then
    todo=("merge -")
  else
    declare -A OLD_PID=()
    mine=$(git log --no-merges --format='%H %s' "$old_base..$old" |
      while read -r c s; do series_is_vendor "$s" || echo "$c"; done)
    if [ -n "$mine" ]; then
      while read -r pid c; do OLD_PID[$pid]=$c; done < <(
        git log --no-walk=unsorted --stdin -p --format='commit %H' <<<"$mine" | git patch-id --stable)
    fi
    span=$(git log --reverse --first-parent --format='%H %s' "$old_base..$fwd_base" |
      while read -r c s; do series_is_vendor "$s" || echo "$c"; done)
    declare -A AS=()
    if [ -n "$span" ] && [ ${#OLD_PID[@]} -gt 0 ]; then
      while read -r pid c; do
        [ -z "${OLD_PID[$pid]:-}" ] || AS[$c]=${OLD_PID[$pid]}
      done < <(git log --no-walk=unsorted --stdin -p --diff-merges=first-parent --format='commit %H' <<<"$span" |
        git patch-id --stable)
    fi
    while read -r c; do
      [ -n "$c" ] || continue
      todo+=("$c ${AS[$c]:--}")
    done < <(git rev-list --reverse --first-parent "$old_base..$fwd_base")
  fi
  save_vars
fi

stop() { # <commit or `merge`> <left out> <pick|merge> <conflicted paths>
  stopped=$1 stopped_left=$2 stopped_kind=$3 stopped_paths=$4
  : > "$STATE/todo"
  [ "${#todo[@]}" -le $((i + 1)) ] || printf '%s\n' "${todo[@]:i+1}" > "$STATE/todo"
  save_vars
  keep=1
  echo >&2
  if [ "$1" = merge ]; then
    echo "Error: $S $X: the three-way merge of main's changes onto $S-$X conflicted" >&2
  else
    echo "Error: $S $X: replaying $(short "$1") onto $S-$X conflicted:" >&2
    echo "  $(git log -1 --format=%s "$1")" >&2
  fi
  echo >&2
  git -C "$wt" diff --name-only --diff-filter=U | sed 's/^/  /' >&2
  echo >&2
  echo "  cd $wt" >&2
  echo "  # resolve, then: git add <paths>" >&2
  echo "  $self $S $X --continue      # or --abort to discard" >&2
  echo >&2
  echo "No ref was written." >&2
  exit 3
}

# shellcheck disable=SC2016  # Markdown backticks in the messages, not commands
# A pick whose result is staged in the worktree: committed, or, where it changes nothing, recorded as present.
# <left out> is `v` for a vendor commit without its engine paths and DESCRIPTION, `e` for another without its engine paths,
# and empty for a whole one; <paths> are the conflicts it stopped on, resolved by hand or by rerere.
commit_pick() { # <commit> <left out> <paths>
  local c=$1 head tree body msg=$tmp/msg new an ae ad cd
  head=$(git -C "$wt" rev-parse HEAD)
  [ -z "$3" ] || git -C "$wt" rerere >/dev/null 2>&1 || true
  tree=$(git -C "$wt" write-tree)
  if [ "$tree" = "$(git rev-parse "$head^{tree}")" ]; then
    git -C "$wt" reset -q --hard "$head"
    clear_merge_state
    if [ -n "$3" ]; then record present "$c" "resolved to no change"; else record present "$c" "applies as no change"; fi
    return 0
  fi
  body=$(git log -1 --format=%B "$c")
  {
    printf '%s\n\n' "$body"
    case "$2" in
      v) printf 'Its engine paths and DESCRIPTION are left out: this layer keeps the engine of `%s`.\n\n' "$S-$X" ;;
      e) printf 'Its engine paths are left out: this layer keeps the engine of `%s`.\n\n' "$S-$X" ;;
    esac
    [ -z "$3" ] || printf 'Conflicts resolved replaying it onto `%s`: %s.\n\n' "$S-$X" "$3"
    printf '(cherry picked from commit %s)\n' "$c"
  } > "$msg"
  {
    IFS= read -r an
    IFS= read -r ae
    IFS= read -r ad
    IFS= read -r cd
  } < <(git log -1 --format='%an%n%ae%n%ad%n%cd' --date=raw "$c")
  new=$(GIT_AUTHOR_NAME=$an GIT_AUTHOR_EMAIL=$ae GIT_AUTHOR_DATE=$ad \
    GIT_COMMITTER_NAME=$id_name GIT_COMMITTER_EMAIL=$id_email GIT_COMMITTER_DATE=$cd \
    git -C "$wt" commit-tree --no-gpg-sign "$tree" -p "$head" -F "$msg")
  git -C "$wt" update-ref HEAD "$new"
  clear_merge_state
  record "pick${2:+-$2}" "$c"
}

commit_merge() { # <paths>
  local head tree new msg=$tmp/msg
  head=$(git -C "$wt" rev-parse HEAD)
  [ -z "$1" ] || git -C "$wt" rerere >/dev/null 2>&1 || true
  tree=$(git -C "$wt" write-tree)
  {
    printf 'chore(cutover): Replay main'"'"'s changes onto %s as one three-way merge\n\n' "$S-$X"
    printf 'The base of %s, %s, is not an ancestor of the base of %s, %s,\n' "$S-dev" "$(short "$old_base")" "$S-fwd-dev" "$(short "$fwd_base")"
    printf 'so main'"'"'s changes between the two are applied as one three-way merge,\n'
    printf 'not commit by commit:\n\n'
    printf '    git merge-tree --write-tree --merge-base=%s %s %s\n\n' "$old_base" "$old" "$fwd_base"
    printf 'with the engine paths of the forward'"'"'s base read from the old base,\n'
    printf 'so that this layer keeps the engine of %s.\n' "$S-$X"
    [ -z "$1" ] || printf '\nConflicts resolved: %s.\n' "$1"
  } > "$msg"
  new=$(layer_commit "$tree" "$head" "$msg")
  git -C "$wt" update-ref HEAD "$new"
  git -C "$wt" reset -q --hard "$new"
  clear_merge_state
  record merge "$new"
}

finish() { # <commit or `merge`> <left out> <pick|merge> <paths>
  if [ "$3" = merge ]; then commit_merge "$4"; else commit_pick "$1" "$2" "$4"; fi
}

# A step that did not apply: resolved by rerere where it holds a resolution for every conflicted path, stopped otherwise.
conflicted() { # <commit or `merge`> <left out> <pick|merge> <git's output>
  local -a paths
  mapfile -t paths < <(git -C "$wt" diff --name-only --diff-filter=U)
  if [ ${#paths[@]} -eq 0 ]; then
    cat "$4" >&2
    echo "Error: $S $X: replaying $1 failed without a conflict" >&2
    stop "$1" "$2" "$3" ''
  fi
  if [ "$(git config --bool rerere.enabled || true)" = true ] && [ -z "$(git -C "$wt" rerere remaining)" ]; then
    git -C "$wt" add -- "${paths[@]}"
    record resolved "$1" "${paths[*]} (by rerere)"
    finish "$1" "$2" "$3" "${paths[*]}"
    return 0
  fi
  stop "$1" "$2" "$3" "${paths[*]}"
}

# A commit of `main`, picked without its engine paths, and without its DESCRIPTION where it is a vendor commit;
# one that carries nothing else is recorded as vendoring only, or as an engine change only, and left out.
pick() { # <commit>
  local c=$1 src=$1 left=e re=$engine_re t p1 out=$tmp/out
  local -a m=()
  p1=$(git rev-parse "$c^1")
  ! series_is_vendor "$(git log -1 --format=%s "$c")" || left=v re=$vendor_commit_re
  t=$(tree_with "$c^{tree}" "$p1^{tree}" "$re")
  if [ "$t" = "$(git rev-parse "$c^{tree}")" ]; then
    left=''
    ! git rev-parse -q --verify "$c^2" >/dev/null || m=(-m 1)
  elif [ "$t" = "$(git rev-parse "$p1^{tree}")" ]; then
    if [ "$left" = v ]; then record vendor "$c"; else record engine "$c"; fi
    return 0
  else
    src=$(synthetic "$t" "$p1")
  fi
  if git -C "$wt" -c advice.mergeConflict=false cherry-pick --no-commit "${m[@]}" "$src" > "$out" 2>&1; then
    commit_pick "$c" "$left" ''
  else
    conflicted "$c" "$left" pick "$out"
  fi
}

merge_step() {
  local theirs syn out st t
  theirs=$(tree_with "$fwd_base^{tree}" "$old_base^{tree}" "$engine_re")
  syn=$(synthetic "$theirs" "$old_base")
  set +e
  out=$(git -C "$wt" merge-tree --write-tree --merge-base="$old_base" "$old" "$syn" 2>&1)
  st=$?
  set -e
  case "$st" in
    0)
      t=${out%%$'\n'*}
      git -C "$wt" read-tree -u --reset "$t"
      commit_merge ''
      ;;
    1)
      # The same merge, made in the worktree so that the conflict can be resolved there: a pick of the change from the old base.
      if git -C "$wt" -c advice.mergeConflict=false cherry-pick --no-commit "$syn" > "$tmp/out" 2>&1; then
        commit_merge ''
      else
        conflicted merge '' merge "$tmp/out"
      fi
      ;;
    *) echo "$out" >&2; echo "Error: git merge-tree failed" >&2; exit 1 ;;
  esac
}

if [ -n "$stopped" ]; then
  unmerged=$(git -C "$wt" diff --name-only --diff-filter=U)
  if [ -n "$unmerged" ]; then
    i=-1
    stop "$stopped" "$stopped_left" "$stopped_kind" "$stopped_paths"
  fi
  if [ "$stopped" = merge ]; then
    echo "$S $X: resuming after the merge"
  else
    echo "$S $X: resuming after $(short "$stopped")"
  fi
  record resolved "$stopped" "$stopped_paths"
  s=$stopped
  stopped=''
  finish "$s" "$stopped_left" "$stopped_kind" "$stopped_paths"
fi

i=0
while [ "$i" -lt "${#todo[@]}" ]; do
  read -r c as <<<"${todo[i]}"
  if [ -z "$c" ]; then
    :
  elif [ "$c" = merge ]; then
    merge_step
  elif [ "$as" != - ]; then
    record present "$c" "the same change as \`$(short "$as")\` on \`$S-$X\`"
  else
    pick "$c"
  fi
  i=$((i + 1))
done

# --- the layers above the replay ----------------------------------------------

declare -A SHA=()
layers=(1-main)
l1=$(git -C "$wt" rev-parse HEAD)
if [ "$l1" = "$old" ]; then
  {
    printf 'chore(cutover): Replay nothing of main'"'"'s onto %s\n\n' "$S-$X"
    if [ "$old_base" = "$fwd_base" ]; then
      printf 'The two series stand on the same base, %s.\n' "$(short "$old_base")"
    else
      printf 'Main'"'"'s first-parent commits from %s to %s change nothing here;\n' "$(short "$old_base")" "$(short "$fwd_base")"
      printf 'the summary of this layer records each.\n'
    fi
  } > "$tmp/msg"
  l1=$(layer_commit "$(git rev-parse "$old^{tree}")" "$old" "$tmp/msg")
fi
SHA[1-main]=$l1
top=$l1

same_engine() { # <sha> <sha>: one an abbreviation of the other
  case "$1" in "$2"*) return 0 ;; esac
  case "$2" in "$1"*) return 0 ;; esac
  return 1
}
# The forward's engine paths on `1-main`, whose own are the old tip's: a layer wherever the two differ,
# by the upstream commit they vendor or by what changed in the engine beside vendoring.
engine_tree=$(tree_with "$top^{tree}" "$fwd^{tree}" "$engine_re")
if [ "$engine_tree" != "$(git rev-parse "$top^{tree}")" ]; then
  {
    printf 'chore(cutover): Take the engine of %s\n\n' "$S-fwd-$X"
    printf 'The engine paths of %s at %s, its vendor paths but patch/: %s.\n' "$S-fwd-$X" "$(short "$fwd")" "${engine_paths[*]}"
    if same_engine "$old_engine" "$fwd_engine"; then
      printf 'Both tips vendor %s@%s, so the two differ by what changed in the engine beside vendoring,\n' \
        "$series_upstream_repo" "$fwd_engine"
      printf 'in a commit of main whose engine paths the layer below leaves out, or on the forward.\n'
    else
      printf 'They span the upstream range %s@%s..%s,\n' "$series_upstream_repo" "$old_engine" "$fwd_engine"
      printf 'from the engine of %s to the engine of %s.\n' "$S-$X" "$S-fwd-$X"
    fi
    printf 'The patch stack stays that of the layer below, so its changes show in the next.\n'
  } > "$tmp/msg"
  SHA[2-engine]=$(layer_commit "$engine_tree" "$top" "$tmp/msg")
  top=${SHA[2-engine]}
  layers+=(2-engine)
fi
printf 'chore(cutover): Take the tree of %s\n\nThe tree of %s at %s.\n' "$S-fwd-$X" "$S-fwd-$X" "$(short "$fwd")" > "$tmp/msg"
SHA[3-fwd]=$(layer_commit "$(git rev-parse "$fwd^{tree}")" "$top" "$tmp/msg")
printf 'chore(cutover): Take the tree of %s back\n\nThe tree of %s at %s, which this stack started from.\n' "$S-$X" "$S-$X" "$(short "$old")" > "$tmp/msg"
SHA[4-old]=$(layer_commit "$(git rev-parse "$old^{tree}")" "${SHA[3-fwd]}" "$tmp/msg")
layers+=(3-fwd 4-old)
declare -A BELOW=([1-main]="$S-$X")
prev=1-main
for L in "${layers[@]:1}"; do BELOW[$L]=$cut/$prev; prev=$L; done

# --- the summary ------------------------------------------------------------

list_cap=200
# shellcheck disable=SC2016  # Markdown backticks, not commands
listed() { # <kinds> <heading>: a list of the log's records of those kinds, `a|b` naming two
  local -a recs
  local n r c d
  mapfile -t recs < <(awk -F'\t' -v k="$1" '$1 ~ ("^(" k ")$")' "$STATE/log")
  [ ${#recs[@]} -gt 0 ] || return 0
  printf '\n%s\n\n' "$2"
  for r in "${recs[@]:0:list_cap}"; do
    IFS=$'\t' read -r _ c d <<<"$r"
    if [ "$c" = merge ] || ! git rev-parse -q --verify "$c^{commit}" >/dev/null; then
      printf -- '- the merge: %s\n' "$d"
    elif [ -n "$d" ]; then
      printf -- '- `%s` %s: %s\n' "$(short "$c")" "$(git log -1 --format=%s "$c")" "$d"
    else
      printf -- '- `%s` %s\n' "$(short "$c")" "$(git log -1 --format=%s "$c")"
    fi
  done
  n=$((${#recs[@]} - list_cap))
  [ "$n" -le 0 ] || printf -- '- and %d more, among `git log --first-parent --oneline %s..%s`\n' "$n" "$(short "$old_base")" "$(short "$fwd_base")"
}
count() { awk -F'\t' -v k="$1" '$1 == k' "$STATE/log" | wc -l | tr -d ' '; }
stat_of() { # <from> <to>
  if [ "$(git rev-parse "$1^{tree}")" = "$(git rev-parse "$2^{tree}")" ]; then
    echo "No change against the layer below."
  else
    echo '```text'
    git diff --stat=100 --stat-count=40 "$1" "$2"
    echo '```'
  fi
}
# shellcheck disable=SC2016  # Markdown backticks, not commands
upstream_count() {
  local a b
  if [ -z "$upstream" ]; then
    echo 'Pass `--upstream` to count the upstream commits it spans.'
  elif a=$(git -C "$upstream" rev-parse -q --verify "$old_engine^{commit}" 2>/dev/null) &&
    b=$(git -C "$upstream" rev-parse -q --verify "$fwd_engine^{commit}" 2>/dev/null); then
    printf 'Upstream, `%s` is %s commits ahead of `%s` and %s behind it.\n' "$fwd_engine" \
      "$(git -C "$upstream" rev-list --count "$a..$b")" "$old_engine" "$(git -C "$upstream" rev-list --count "$b..$a")"
  else
    printf 'The clone `%s` does not have both upstream commits.\n' "$upstream"
  fi
}

# shellcheck disable=SC2016  # Markdown backticks, not commands
section() { # <layer>
  local L=$1 B=$cut/$1
  printf '## %s\n\n' "$B"
  case "$L" in
    1-main)
      if [ "$mode" = merge ]; then
        printf '`main`'"'"'s changes from `%s`, the base of `%s`, to `%s`, the base of `%s`,\n' \
          "$(short "$old_base")" "$S-dev" "$(short "$fwd_base")" "$S-fwd-dev"
        printf 'applied onto `%s` at `%s` as one three-way merge, because the old base is not an ancestor of the forward'"'"'s.\n' \
          "$S-$X" "$(short "$old")"
        printf 'The engine paths stay those of `%s`.\n' "$S-$X"
      else
        printf '`main`'"'"'s first-parent commits from `%s`, the base of `%s`, to `%s`, the base of `%s`,\n' \
          "$(short "$old_base")" "$S-dev" "$(short "$fwd_base")" "$S-fwd-dev"
        printf 'replayed onto `%s` at `%s` one by one, with `-x`.\n\n' "$S-$X" "$(short "$old")"
        printf -- '- replayed whole: %s\n' "$(count pick)"
        printf -- '- replayed without their engine paths: %s\n' "$(count pick-e)"
        printf -- '- vendor commits replayed without their engine paths and `DESCRIPTION`: %s\n' "$(count pick-v)"
        printf -- '- recorded as present: %s\n' "$(count present)"
        printf -- '- vendoring only, left out: %s\n' "$(count vendor)"
        printf -- '- engine changes only, left out: %s\n' "$(count engine)"
        printf -- '- conflicts resolved: %s\n' "$(count resolved)"
        listed present 'Recorded as present:'
        listed vendor "Vendoring only, left out because this layer keeps the engine of \`$S-$X\`:"
        listed engine "Engine changes only, left out because this layer keeps the engine of \`$S-$X\`:"
        listed pick-v 'Vendor commits replayed without their engine paths and `DESCRIPTION`:'
        listed pick-e 'Replayed without their engine paths, which `2-engine` shows as the forward has them:'
      fi
      listed resolved 'Conflicts resolved:'
      ;;
    2-engine)
      if same_engine "$old_engine" "$fwd_engine"; then
        printf 'The engine of `%s` at `%s`, where both tips vendor `%s@%s`:\n' \
          "$S-fwd-$X" "$(short "$fwd")" "$series_upstream_repo" "$fwd_engine"
        printf 'its engine paths copied in, `patch/` aside, which differ by what changed in the engine beside vendoring,\n'
        printf 'in a commit of `main` whose engine paths the layer below leaves out, or on the forward.\n'
      else
        printf 'The engine of `%s` at `%s`, `%s@%s`, where `%s` vendors `%s@%s`:\n' \
          "$S-fwd-$X" "$(short "$fwd")" "$series_upstream_repo" "$fwd_engine" "$S-$X" "$series_upstream_repo" "$old_engine"
        printf 'its engine paths copied in, `patch/` aside, so that a change to the patch stack shows in the next layer.\n'
        upstream_count
      fi
      if [ "$mode" = merge ]; then
        printf '\nBeside vendoring, it carries the engine side of `main`'"'"'s changes, as the forward has it,\n'
        printf 'which the three-way merge of `1-main` leaves out.\n'
      else
        listed 'pick-e|engine' 'Beside vendoring, it carries the engine paths of these commits of `main`, as the forward has them, which `1-main` replays without them or leaves out:'
      fi
      ;;
    3-fwd) printf 'The tree of `%s` at `%s`.\n' "$S-fwd-$X" "$(short "$fwd")" ;;
    4-old) printf 'The tree of `%s` at `%s`, which the stack started from.\n' "$S-$X" "$(short "$old")" ;;
  esac
  printf '\nDiff against `%s`:\n\n' "${BELOW[$L]}"
  stat_of "$(if [ "$L" = 1-main ]; then echo "$old"; else echo "${SHA[${BELOW[$L]##*/}]}"; fi)" "${SHA[$L]}"
  echo
}

title_of() { # <layer>
  case "$1" in
    1-main) echo "Cutover $S, $X 1-main: main's changes replayed onto $S-$X" ;;
    2-engine) echo "Cutover $S, $X 2-engine: the engine of $S-fwd-$X" ;;
    3-fwd) echo "Cutover $S, $X 3-fwd: the tree of $S-fwd-$X" ;;
    4-old) echo "Cutover $S, $X 4-old: the tree of $S-$X back" ;;
  esac
}

slug=$(series_github_slug "$remote")
stale=''
[ -n "${SHA[2-engine]:-}" ] || [ -z "${LEASE[2-engine]}" ] || stale=$cut/2-engine
report=$tmp/report
{
  for L in "${layers[@]}"; do section "$L"; done
  echo "## Pull requests to open"
  echo
  echo "As drafts, each layer into the one below it, its section above as the body;"
  echo "a pull request already open for a head takes this base, title and body instead."
  echo "Then link them into one GitHub stack, in this order (.claude/skills/series-cutover/SKILL.md)."
  n=0
  for L in "${layers[@]}"; do
    n=$((n + 1))
    echo
    echo "$n. repository: ${slug:-(none: the remote $remote names no GitHub repository)}"
    echo "   base: ${BELOW[$L]}"
    echo "   head: $cut/$L"
    echo "   title: $(title_of "$L")"
    echo "   body: the section \"$cut/$L\" above"
  done
  if [ -n "$stale" ]; then
    echo
    echo "No longer in the stack: $stale, as the engine of $cut/1-main is now the forward's."
    echo "It is the base of the pull request of $cut/3-fwd, which GitHub would close if the branch went first,"
    echo "so the branch is left where it is. Retire it in this order,"
    echo "with the GitHub stack of these pull requests taken apart first and linked again after (.claude/skills/series-cutover/SKILL.md):"
    echo
    echo "1. Retarget the pull request of $cut/3-fwd onto $cut/1-main."
    echo "2. Close the pull request of $stale."
    echo "3. Delete the branch, leased on the tip this run read:"
    echo "   git push --force-with-lease=refs/heads/$stale:${LEASE[2-engine]} $remote :refs/heads/$stale"
    if [ -n "$slug" ]; then
      echo "   or, where the remote refuses a deletion, checked against that tip first, since the API takes no lease:"
      # shellcheck disable=SC2016  # a command for a person to run, printed as it stands
      printf '   if [ "$(gh api repos/%s/git/ref/heads/%s --jq .object.sha)" = %s ]; then %s; else echo '"'"'%s is not at %s: read what moved before deleting it'"'"'; fi\n' \
        "$slug" "$stale" "${LEASE[2-engine]}" "$(series_delete_line "$remote" "$stale")" "$stale" "${LEASE[2-engine]}"
    fi
  fi
} > "$report"

# Written before the push, so that a file that cannot be written leaves nothing moved.
if [ -n "$summary" ] && ! cp "$report" "$summary"; then
  echo "Error: $S $X: cannot write the summary to $summary, so nothing was pushed. Built, not pushed:" >&2
  for L in "${layers[@]}"; do echo "  ${SHA[$L]} $cut/$L" >&2; done
  keep=''
  exit 1
fi

# --- the push -----------------------------------------------------------------

push_args=(--atomic --porcelain)
refspecs=()
for L in "${layers[@]}"; do
  push_args+=("--force-with-lease=refs/heads/$cut/$L:${LEASE[$L]}")
  refspecs+=("${SHA[$L]}:refs/heads/$cut/$L")
done
if ! out=$(git push "${push_args[@]}" "$remote" "${refspecs[@]}" 2>&1); then
  echo "$out" >&2
  echo "Error: $S $X: the push was refused, and nothing moved:" >&2
  echo "  a branch of the stack moved since this run read it, or the remote refused the push. Built, not pushed:" >&2
  for L in "${layers[@]}"; do echo "  ${SHA[$L]} $cut/$L" >&2; done
  # The summary describes this build, which no branch holds.
  # `rm` would take a link and leave the file written through it, or take a device whole.
  if [ -n "$summary" ]; then
    if [ -L "$summary" ]; then
      echo "  The summary of this build, which was not pushed, was written through the link $summary" >&2
      echo "  to $(readlink -f -- "$summary" || readlink -- "$summary"), and both are left as they are: remove the summary there by hand." >&2
    elif [ ! -f "$summary" ]; then
      echo "  $summary is not a regular file, so it is left as it is, with whatever it took of the summary of this build, which was not pushed." >&2
    elif rm -f -- "$summary"; then
      echo "  The summary written to $summary for this build is removed, since the build was not pushed." >&2
    else
      echo "  The summary written to $summary is of this build, which was not pushed, and it could not be removed: remove it." >&2
    fi
  fi
  keep=''
  exit 1
fi

cat "$report"
echo
for L in "${layers[@]}"; do echo "pushed: ${SHA[$L]} $cut/$L"; done

git worktree remove --force "$wt"
rm -rf "$STATE"
wt='' keep=''
[ -z "$stale" ] || exit 9
