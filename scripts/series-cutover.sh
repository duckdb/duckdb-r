#!/bin/bash
# Replace a series with its forward counterpart, keeping the replaced history
# reachable: archive pull requests first, then one atomic swap.
#
# A forward series <S>-fwd-* is the same series rebuilt on a newer `main`
# (.claude/skills/series-forward/SKILL.md). Once its green ref covers at least
# the upstream commits the old green covered, this script swaps all four series
# refs in one atomic push, so consumers of <S>-green never observe a
# half-replaced series. The swap is the one sanctioned non-fast-forward move of
# a green ref, and the names stay what they were: r-universe keeps building
# `<S>-green`, and nothing outside the two repositories has to learn a new one.
#
# What the swap would orphan is kept first. Each lineage it moves a ref off --
# `<S>-dev` (green is on it) and `<S>-build` (build-base is on it) in the fork,
# and the copy of `<S>-green` in the canonical repository -- is the head of a
# draft pull request opened and closed on the spot, against the forward ref
# that takes its place; so is `<S>-vendor`, the strand the buffer is derived
# from (handbook/branches/model/README.md), which the forward's `-fwd-vendor`
# replaces like the four. GitHub keeps a pull request's head as `refs/pull/<n>/head`
# for as long as the pull request exists, closed or not, so the commits stay
# reachable and the pull request is where to find them; nothing is merged, and
# the deletion of the `-fwd` refs afterwards loses nothing, because their tips
# are the series' refs now. Each deletion is leased on the tip this run read,
# so a `-fwd` ref that moved since, whose new commits nothing archived, stays
# and is reported. `--no-archive` skips the archive, for a remote that is not on
# GitHub, on a terminal only; without it the script refuses to swap when it
# cannot archive.
#
# It is also the one move the series loop never makes: the loop reports a ready
# cutover and stops (.claude/skills/series-loop/SKILL.md), because retiring the
# lineage r-universe builds from is a decision, not a stage. This script swaps
# only on a confirmation that names the series, typed on a terminal, or given
# as `--confirm <series>@<sha>`, where <sha> is the tip of `<S>-fwd-green` that
# `--prepare` printed for the maintainer to decide on. The script cannot tell
# who passes it: what keeps a firing from cutting over is the loop's rule and
# the decision rule of .claude/skills/series-cutover/SKILL.md, and what the SHA
# does is tie the run to the state that decision was taken on.
# `--prepare` is the part that needs no confirmation: the gates, the
# convergence read and the review, written for a human to read before
# deciding, with nothing moved and nothing opened.
#
# A base series ref that does not exist yet is created rather than swapped:
# a series that started as -fwd has no counterpart to replace.
#
# The report names the package on both sides -- `Package:` once, and `Version:`
# for each of the four refs, before and after -- because the swap moves both:
# the forward regenerates its own flavor commits, and the replay renumbers the
# fifth component as a counter of its own chain. A version that goes backwards
# is the one cost of the swap that nothing else on screen shows.
#
# The review is everything the forward changed against current `main` outside
# the engine -- the R side, `src/` outside `src/duckdb/`, the tests and the patch
# stack -- as a stat on screen and as a full diff in --out. The forward's seed is
# a recent `main`, so that diff is the series' own work, which a human reads
# before consumers are pointed at it. The convergence read beside it
# (scripts/series-converge.sh) is the other half: what the forward carries
# against what the series it replaces carries.
#
# Usage: series-cutover.sh <series> [--remote <name>] [--canonical <name>]
#                          [--upstream <path>] [--out <dir>]
#                          [--prepare | --confirm <series>@<sha>] [--no-archive]
#   series-cutover.sh main --upstream ../../../duckdb
#   series-cutover.sh main --upstream ../../../duckdb --prepare --out /tmp/main-cutover
#   series-cutover.sh main --upstream ../../../duckdb --confirm main@0123456789ab
#
# `--canonical <name>` names the repository r-universe publishes the base
# flavors from -- default `upstream`, as in series-advance.sh -- which carries a
# copy of every `<S>-green`, the forward's included (scripts/series-advance.sh).
# A cutover is the one move that takes green off its lineage, so it is the one
# place that copy is forced -- under a lease, and after the swap, so the
# canonical repository is never ahead of the fork -- and the forward's copy
# there is deleted with the fork's `-fwd` refs. An empty name says there is no
# canonical repository. The run reads it once, with `git ls-remote`, and fetches
# what that listed; a name no remote here answers to, or a remote that cannot be
# read, leaves that copy neither archived nor moved, which a terminal run
# reports as left behind.
#
# The two are different kinds of thing, and a `gh` clone carries names that made
# them easy to swap while both were positional:
#   --remote <name>   a remote of *this* repository -- the one carrying the
#                     series refs. A clone made with `gh` has both `origin`
#                     and `upstream`; pass whichever holds `<series>-green`.
#   --upstream <path> a filesystem path to a `duckdb/duckdb` checkout, read
#                     with `git -C`. Never a remote name, whatever it is
#                     called.
#   --out <dir>       where the review diff is written; default a fresh
#                     temporary directory, named on screen.
#   --prepare         the gates, the reads and the review only: no terminal
#                     needed, no pull request opened, no ref moved.
#   --confirm <series>@<sha>
#                     the confirmation the prompt asks for, given on the
#                     command line, so that no terminal is needed and the
#                     command itself records it: the series being cut over, and
#                     the tip of `<S>-fwd-green` that --prepare printed, as 12
#                     to 40 lowercase hex digits. Another name, another shape
#                     of SHA, or --prepare or --no-archive beside it is a
#                     usage error, before anything is read. Once fetched, a
#                     `<S>-fwd-green` that is not at that SHA is a refusal.
#   --no-archive      swap without the archive pull requests; on a terminal
#                     only.
# Both are spelled the same in every scripts/series-*.sh; see the shared
# contract in handbook/operations/vendoring/series-loop/README.md.
#
# The archive pull requests are opened with `gh api` (REST, no GraphQL) against
# the repository a remote's URL names; `git config remote.<name>.github
# <owner>/<repo>` names it where the URL does not, as in a test fixture.
# $SERIES_GH names another `gh`. A plan that archives in a remote naming no
# repository, or finds no `gh`, refuses before the confirmation, on a terminal
# too, and before any pull request is opened.
#
# The upstream clone is needed for the coverage gate (an ancestry check
# between vendored upstream SHAs); without it the gate degrades to a warning.
#
# Under --confirm nobody reads the screen before the swap, so what a terminal
# run prints for the operator to weigh refuses instead, before anything is
# opened or moved: a coverage gate it cannot verify, for want of an upstream
# clone or of a vendored SHA it can read on the old green; a convergence read
# that diverged or did not finish; a package name the swap changes; a `-dev` or
# `-green` version that does not move forward, or versions not compared for
# want of GNU sort; and a --canonical remote that does not exist or cannot be
# read. --prepare lists the ones it found, as what --confirm would refuse on.
#
# After the swap the script prints the archive pull requests, number and URL,
# and the undo: one leased push per repository that puts the old tips back from
# the archive pull requests' heads and the forward's refs beside them.
#
# Exit status:
#   0  swapped and cleaned up, or prepared.
#   1  refused or failed before or at the swap, so nothing was swapped: a gate,
#      a typed confirmation that does not match, no terminal and no --confirm,
#      under --confirm a forward green not at the SHA it names or a warning
#      (above), an archive that could not be opened, or a lease the swap lost.
#      Archive pull requests already opened stay, and a rerun finds them.
#   2  a usage error, a --confirm that does not name the series and a SHA among
#      them; nothing was read or moved.
#   9  swapped, with something left behind: a forward ref the remote refused
#      to delete, which is cutover litter; a forward ref that moved since the
#      run read it, whose deletion the lease refused; the canonical copy of
#      green the remote refused to move; or that copy out of reach, as no
#      remote here names it or the remote could not be read. Each is printed
#      above a last line `SWAPPED, LEFT BEHIND`: litter and a refused move with
#      the command that finishes them, a moved ref with the command that shows
#      what moved, and a copy out of reach with the archive and the leased
#      move it is still owed, which wait on reading the tip it holds. The swap
#      stands, and a rerun is not what finishes any of them.
#   Any other status is a command that failed, such as git's 128 under
#   `set -e`, and it comes before the swap, so nothing was swapped, as for 1.
#   After the swap every command that can fail is checked and reported, save
#   the writing of this output: a reader that stops reading ends the run there,
#   by SIGPIPE (141) or as a failed write, and then the refs say what happened.

set -euo pipefail
# shellcheck source=series-lib.sh
. "$(dirname "$0")/series-lib.sh"

usage='usage: series-cutover.sh <series> [--remote <name>] [--canonical <name>] [--upstream <path>] [--out <dir>] [--prepare | --confirm <series>@<sha>] [--no-archive]'
argerr() { echo "$usage" >&2; exit 2; }
remote=${SERIES_REMOTE:-origin}
canonical=${SERIES_CANONICAL-upstream}
upstream=${UPSTREAM_CLONE:-}
gh=${SERIES_GH:-gh}
out='' prepare='' archive=1 confirm='' confirmed='' confirm_sha=''
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --canonical) [ $# -ge 2 ] || argerr; canonical=$2; shift 2 ;;
    --upstream) [ $# -ge 2 ] || argerr; upstream=$2; shift 2 ;;
    --out) [ $# -ge 2 ] || argerr; out=$2; shift 2 ;;
    --prepare) prepare=1; shift ;;
    --confirm) [ $# -ge 2 ] || argerr; confirm=$2; confirmed=1; shift 2 ;;
    --no-archive) archive=''; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
S=${args[0]}
# The command --prepare prints for a terminal: this run's options, --prepare
# aside, with the remotes spelled out, since the variables that set them may
# not be set where it is typed.
again="scripts/series-cutover.sh $(printf '%q' "$S") --remote $(printf '%q' "$remote") --canonical $(printf '%q' "$canonical")"
[ -z "$upstream" ] || again+=" --upstream $(printf '%q' "$upstream")"
[ -z "$out" ] || again+=" --out $(printf '%q' "$out")"
[ -n "$archive" ] || again+=" --no-archive"
# The confirmation on the command line is checked before anything is read: it
# is the operator's statement of which series to replace, and on which state,
# so a name that is not this one is a command that contradicts itself, and so is
# one that both swaps and moves nothing. A swap nobody watches keeps what it
# replaces, so it never comes without the archive.
if [ -n "$confirmed" ]; then
  if [ -n "$prepare" ]; then
    echo "Error: --prepare moves nothing and --confirm swaps; pass one of them." >&2
    argerr
  fi
  if [ -z "$archive" ]; then
    echo "Error: --confirm swaps with nobody watching, and --no-archive would keep the replaced history nowhere;" >&2
    echo "  a cutover without the archive runs on a terminal. Nothing was moved." >&2
    argerr
  fi
  case "$confirm" in
    *@*) confirm_sha=${confirm##*@} confirm=${confirm%@*} ;;
  esac
  if [ "$confirm" != "$S" ]; then
    echo "Error: --confirm names '$confirm', but the series to cut over is '$S'; nothing was moved." >&2
    argerr
  fi
  if ! [[ $confirm_sha =~ ^[0-9a-f]{12,40}$ ]]; then
    echo "Error: --confirm takes $S@<sha>, the tip of $S-fwd-green that --prepare printed," >&2
    echo "  as 12 to 40 lowercase hex digits; nothing was moved." >&2
    argerr
  fi
fi
here=$(cd "$(dirname "$0")" && pwd)
# Pathspecs below are the repository's, wherever this was started from.
cd "$(git rev-parse --show-toplevel)"

# Fail before the fetch, not after it: without a terminal and without
# --confirm there is nothing to confirm with, and no reason to do any work
# first. An unattended firing of the loop is that case, and never passes
# --confirm. `--prepare` moves nothing and may run anywhere.
if [ -z "$prepare" ] && [ -z "$confirmed" ] && { [ ! -t 0 ] || [ ! -t 1 ]; }; then
  echo "Error: a cutover swaps only on a confirmation that names the series:" >&2
  echo "  type it on a terminal, or pass --confirm <series>@<sha> once a maintainer has decided" >&2
  echo "  the cutover on the state --prepare showed (.claude/skills/series-cutover/SKILL.md)." >&2
  echo "  The series loop reports a ready cutover and stops; it never confirms one." >&2
  echo "  --prepare runs the gates and the review alone, from anywhere." >&2
  exit 1
fi

# What a terminal run prints for the operator to weigh before typing the name.
# Under --confirm nobody weighs it, so each is collected here and the run
# refuses on them before anything is opened or moved; --prepare lists them.
held=()
hold() { held+=("$1"); }

# A canonical remote that is named and missing leaves r-universe's copy of
# green on the old lineage, neither archived nor moved. An empty name is how to
# say there is none (SERIES_CANONICAL='' or --canonical ''), so a name nothing
# here answers to is a clone set up otherwise: a terminal run ends in exit 9
# with that copy left behind, and --confirm refuses before the fetch.
canon_why= # why the canonical copy of green is out of this run's reach
if [ -n "$canonical" ] && ! git remote get-url "$canonical" >/dev/null 2>&1; then
  canon_why="no remote here is called $canonical"
  if [ -n "$confirmed" ]; then
    echo "Error: there is no remote '$canonical', so the canonical copy of $S-green would be neither archived" >&2
    echo "  nor moved, and --confirm swaps with nobody to move it. Name the remote with --canonical <name>," >&2
    echo "  or pass --canonical '' where there is no canonical repository. Nothing was moved." >&2
    exit 1
  fi
  echo "Warning: there is no remote '$canonical', so the canonical copy of $S-green will be neither archived"
  echo "  nor moved, and the run ends in exit 9 with it left behind. Name the remote with --canonical <name>,"
  echo "  or pass --canonical '' where there is no canonical repository."
  hold "canonical: no remote '$canonical'"
fi

# A fork that cannot be fetched ends the run here, before anything is opened or
# moved; --prune drops what was deleted there, so nothing below plans on it.
git fetch -q --prune "$remote"
# `main` for the review is the canonical repository's; the fork's mirror may lag
# by a cycle (handbook/branches/mirrors/README.md). The two greens there are
# what the archive, the move and the cleanup read. The repository is read once,
# and only what that read listed is fetched: a tracking ref an earlier fetch
# left is dropped where the read did not list it, and a remote that cannot be
# read (an auth failure, a proxy refusing it) puts that copy out of reach, as a
# missing remote does, rather than leaving the plan to a ref nobody read.
main_ref="refs/remotes/$remote/main"
canon_read= # set once the canonical repository has been read and fetched
if [ -n "$canonical" ] && [ -z "$canon_why" ]; then
  if listed=$(git ls-remote "$canonical" refs/heads/main "refs/heads/$S-green" "refs/heads/$S-fwd-green"); then
    specs=()
    for b in main "$S-green" "$S-fwd-green"; do
      if awk -v ref="refs/heads/$b" '$2 == ref { f = 1 } END { exit !f }' <<<"$listed"; then
        specs+=("+refs/heads/$b:refs/remotes/$canonical/$b")
      else
        git update-ref -d "refs/remotes/$canonical/$b"
      fi
    done
    if [ ${#specs[@]} -eq 0 ] || git fetch -q "$canonical" "${specs[@]}"; then canon_read=1; fi
  fi
  if [ -z "$canon_read" ]; then
    canon_why="$canonical could not be read"
    echo "Warning: could not read $canonical (above), so the canonical copy of $S-green would be neither"
    echo "  archived nor moved, and a swap on a terminal ends in exit 9 with it left behind. Check the remote's"
    echo "  URL and access, or pass --canonical '' where there is no canonical repository."
    hold "canonical: could not read $canonical"
  elif git rev-parse -q --verify "refs/remotes/$canonical/main" >/dev/null; then
    main_ref="refs/remotes/$canonical/main"
  fi
fi

# One field of a branch's DESCRIPTION, empty when the ref or the field is not
# there. Both fields this script reads are per-branch: the flavor rename writes
# `Package:`, and the replay renumbers the fifth component of `Version:`.
#
# A missing ref is ordinary here -- a series opened as `-fwd` has no base refs
# at all -- so `git show`'s failure is swallowed rather than left to `pipefail`,
# which would otherwise make an empty answer end the run.
desc_field() {
  git show "$1:DESCRIPTION" 2>/dev/null | sed -n "s/^$2: *//p" | head -n 1 || true
}

# GNU sort, wherever it is called: on Linux that is `sort`, on macOS it is
# `gsort` and the system `sort` is BSD's. Prefer `gsort`, then verify -- the
# same choice, and the same reason, scripts/flavor.sh makes for `sed`. Empty
# when neither is GNU, which is a comparison not made rather than a wrong one.
if command -v gsort >/dev/null 2>&1; then
  gnu_sort='gsort'
else
  gnu_sort='sort'
fi
case "$("$gnu_sort" --version 2>/dev/null || true)" in
  *"GNU coreutils"*) ;;
  *) gnu_sort= ;;
esac

# Where two dotted versions sort against each other, as -1, 0 or 1. `sort -V`
# compares them component by component and numerically, so 1.5.5.9013.36 sorts
# below 1.5.5.9020.12 rather than by string order, and a missing component
# ranks below a present one: 1.5.5.9020 below 1.5.5.9020.1.
version_cmp() {
  local sorted
  [ "$1" != "$2" ] || { printf '%s\n' 0; return; }
  sorted=$(printf '%s\n%s\n' "$1" "$2" | "$gnu_sort" -V)
  if [ "${sorted%%$'\n'*}" = "$1" ]; then printf '%s\n' -1; else printf '%s\n' 1; fi
}

# Open a draft pull request from <head> against <base> in the repository
# <remote> names, and close it at once. Printed, with its URL, and recorded in
# `archived` for the summary and the undo after the swap; a failure stops the
# run before anything is swapped, since the archive is what keeps the swap
# readable afterwards. A rerun after a swap that failed finds the pull request
# it opened the first time, by its title and the tip its body names, and opens
# no second one.
archived=() # "<remote> <head> <owner/repo> <number>"
archive_pr() { # <remote> <head> <base> -> prints the pull request
  local r=$1 head=$2 base=$3 slug n body tip title existing
  slug=$(series_github_slug "$r") # never empty: the plan refused a remote without one
  tip=$(git rev-parse "refs/remotes/$r/$head")
  title="chore(series): Archive $head before its cutover"
  existing=$("$gh" api -X GET "repos/$slug/pulls" -f state=closed -f head="${slug%%/*}:$head" -f per_page=20 \
    --jq "[.[] | select(.title == \"$title\" and (.body | contains(\"$tip\")))][0].number // empty" 2>/dev/null || true)
  if [ -n "$existing" ]; then
    echo "  already archived $head as $slug#$existing (its head is refs/pull/$existing/head there): https://github.com/$slug/pull/$existing"
    archived+=("$r $head $slug $existing")
    return
  fi
  body="Archive of \`$head\` as it stood before the cutover of \`$S\` on $(date -u +%Y-%m-%d): \`$tip\`.

The cutover moves \`$head\` onto the lineage of \`$base\`, which this history is no ancestor of. A pull request keeps its head reachable as \`refs/pull/<n>/head\` for as long as it exists, so this one is opened and closed on the spot and never merged (scripts/series-cutover.sh)."
  n=$("$gh" api -X POST "repos/$slug/pulls" -f title="$title" \
    -f head="$head" -f base="$base" -F draft=true -f body="$body" --jq .number) || {
    echo "Error: could not open the archive pull request for $head in $slug" >&2
    exit 1
  }
  "$gh" api -X PATCH "repos/$slug/pulls/$n" -f state=closed --jq .number >/dev/null || {
    echo "Error: could not close the archive pull request $slug#$n" >&2
    exit 1
  }
  echo "  archived $head as $slug#$n (closed; its head is refs/pull/$n/head there): https://github.com/$slug/pull/$n"
  archived+=("$r $head $slug $n")
}

for r in build dev green build-base; do
  git rev-parse -q --verify "refs/remotes/$remote/$S-fwd-$r" >/dev/null ||
    { echo "Error: $S-fwd-$r does not exist on $remote"; exit 1; }
done

# The state the decision was taken on: the green the swap installs, as
# --prepare printed it. Under --confirm the run swaps that green or nothing.
fwd_green=$(git rev-parse "refs/remotes/$remote/$S-fwd-green")
if [ -n "$confirmed" ]; then
  case "$fwd_green" in
    "$confirm_sha"*) ;;
    *)
      echo "Error: $S-fwd-green is at $fwd_green on $remote, not at the $confirm_sha that --confirm names." >&2
      echo "  The forward moved after the state the decision was taken on; prepare again, and take" >&2
      echo "  the new tip back to the maintainer. Nothing was moved." >&2
      exit 1
      ;;
  esac
fi

# A base series ref may legitimately be missing: a series started as -fwd has
# no counterpart to replace, and the cutover creates the ref rather than
# swapping it. Only the forward refs are required.
missing=()
present=()
for r in build dev green build-base; do
  if git rev-parse -q --verify "refs/remotes/$remote/$S-$r" >/dev/null; then
    present+=("$r")
  else
    missing+=("$S-$r")
  fi
done
[ ${#missing[@]} -eq 0 ] ||
  echo "Note: ${missing[*]} missing on $remote, will be created from $S-fwd-*"

old_green=
old_up=
if git rev-parse -q --verify "refs/remotes/$remote/$S-green" >/dev/null; then
  old_green=1
  old_up=$(series_vendored_sha "refs/remotes/$remote/$S-green")
fi
new_up=$(series_vendored_sha "refs/remotes/$remote/$S-fwd-green")
echo "old green vendors: ${old_up:-<nothing>}"
echo "new green vendors: ${new_up:-<nothing>}"

# Coverage gate: the forward green must vendor at least what the old green
# vendored, so verification never moves backwards at cutover.
if [ -n "$old_up" ]; then
  if [ -z "$new_up" ]; then
    echo "Error: old green vendors $old_up but forward green vendors nothing"
    exit 1
  fi
  if [ -n "$upstream" ]; then
    # Separate "git could not run there" from "the ancestry says no": both
    # reach the `||` below, and reporting a regression for a path that is not
    # a checkout sends the reader after the wrong thing. A remote name passed
    # as the path is exactly that case.
    git -C "$upstream" rev-parse --git-dir >/dev/null 2>&1 || {
      echo "Error: $upstream is not a git checkout"
      echo "  The third argument is a path to a $series_upstream_repo clone, not a remote."
      exit 1
    }
    git -C "$upstream" merge-base --is-ancestor "$old_up" "$new_up" || {
      echo "Error: forward green does not cover old green; coverage would regress"
      exit 1
    }
  elif [ -n "$confirmed" ]; then
    # On a terminal the operator reads the warning below before typing the
    # name; under --confirm nobody does, so the gate holds rather than degrades.
    echo "Error: no upstream clone given, so the coverage gate cannot be verified, and --confirm" >&2
    echo "  swaps with nobody to read a warning; pass --upstream <path>. Nothing was moved." >&2
    exit 1
  else
    echo "Warning: no upstream clone given, coverage gate not verified"
    hold "coverage: no upstream clone given"
  fi
elif [ -n "$old_green" ]; then
  # A green that exists and names no vendored SHA leaves the gate nothing to
  # hold the forward against, which is the gate not verified, not passed;
  # series_vendored_sha has said why on stderr.
  if [ -n "$confirmed" ]; then
    echo "Error: no vendored SHA could be read on $S-green, so the coverage gate cannot be verified," >&2
    echo "  and --confirm swaps with nobody to read a warning. Nothing was moved." >&2
    exit 1
  fi
  echo "Warning: no vendored SHA could be read on $S-green, coverage gate not verified"
  hold "coverage: no vendored SHA read on $S-green"
fi

# Convergence: the coverage gate above asks whether the forward has vendored far
# enough, which is a statement about how much upstream it reaches and none at all
# about what it carries. This asks the other half -- whether the two branches
# still hold the same package -- and prints it here so the operator confirms with
# it on screen. It reports rather than refuses: the invariant's second half is
# *explicable*, and whether a difference is explicable is a judgement no script
# can make -- which is why this prints and the human decides, and why under
# --confirm, with no human reading, a finding is held.
echo
rc=0
"$here/series-converge.sh" "$S" --remote "$remote" --no-fetch || rc=$?
# 1 is a divergence to read; 2 is the comparison not being available at all --
# a series that started as `-fwd` has no `<S>-dev` to compare against, and the
# script has already said so on its own.
if [ "$rc" -eq 1 ]; then
  echo
  echo "  ^ read these before confirming. A swap does not resolve them: it makes"
  echo "    them the serving branch's, on the lineage r-universe builds from."
  hold "convergence: paths the forwarding does not explain"
elif [ "$rc" -ne 0 ] && git rev-parse -q --verify "refs/remotes/$remote/$S-dev" >/dev/null; then
  echo
  echo "  ^ the convergence read stopped with status $rc although $S-dev exists;"
  echo "    read why above before confirming."
  hold "convergence: the read stopped with status $rc"
fi
echo

# The package the swap publishes, named on both sides. `Package:` and
# `Version:` are what a consumer installs, and the swap moves both: the name
# because the forward regenerates its own flavor commits, the version because
# the replay renumbers the fifth component as a counter of its own chain. So
# each ref is shown with the version it carries before and after, and a name
# that changes is called out rather than left to be read off four lines.
old_pkg=$(desc_field "refs/remotes/$remote/$S-dev" Package)
new_pkg=$(desc_field "refs/remotes/$remote/$S-fwd-dev" Package)
if [ -z "$old_pkg" ] || [ "$old_pkg" = "$new_pkg" ]; then
  echo "package: ${new_pkg:-<none>}"
else
  echo "package: $old_pkg -> $new_pkg"
  echo "  ^ the swap renames the package. A series and its forward are flavored"
  echo "    the same; a name that moved means the forward was seeded with"
  echo "    another flavor, and the swap would publish a different package."
  hold "package: renamed from $old_pkg to ${new_pkg:-<none>}"
fi

# The vendor strand swaps with the four where the forward has one; a forward
# written before the strand existed has none, and the series derives one from
# its new buffer afterwards (scripts/series-vendor.sh --init).
swap=(build dev green build-base)
if git rev-parse -q --verify "refs/remotes/$remote/$S-fwd-vendor" >/dev/null; then
  swap+=(vendor)
else
  echo "Note: $S-fwd-vendor does not exist on $remote; after the swap, derive the strand:"
  echo "  scripts/series-vendor.sh $S --init --remote $remote --push"
fi

leases=()
refspecs=()
# The undo is the swap read backwards: each base ref leased on the forward's
# tip and put back on its old one, or deleted where the swap created it, and
# each forward ref written again at the tip it gave. Those carry no lease and no
# `+`, so a forward ref the deletion left at that tip is no change.
undo_leases=()
undo_refspecs=()
echo "refs to swap:"
for r in "${swap[@]}"; do
  new=$(git rev-parse "refs/remotes/$remote/$S-fwd-$r")
  # An empty expected value leases the ref as "must not exist yet", which is
  # what a base ref from `missing` needs. The refspecs carry no leading `+`:
  # a forced refspec defeats --force-with-lease outright, and the lease alone
  # already authorizes the non-fast-forward swap.
  cur=$(git rev-parse -q --verify "refs/remotes/$remote/$S-$r") || cur=
  leases+=("--force-with-lease=refs/heads/$S-$r:$cur")
  refspecs+=("$new:refs/heads/$S-$r")
  undo_leases+=("--force-with-lease=refs/heads/$S-$r:$new")
  undo_refspecs+=("$cur:refs/heads/$S-$r" "$new:refs/heads/$S-fwd-$r")
  short=${cur:0:7}
  oldv=$(desc_field "refs/remotes/$remote/$S-$r" Version)
  newv=$(desc_field "refs/remotes/$remote/$S-fwd-$r" Version)
  printf '  %-26s %-7s %-16s ->  %-7s %s\n' \
    "$S-$r" "${short:-<new>}" "${oldv:--}" "${new:0:7}" "${newv:--}"
done

# A version that does not move forward -- back, or not at all -- is the swap's
# one cost that nothing else on screen shows. `<S>-green` is what r-universe
# publishes (handbook/branches/mirrors/README.md), so its version is the one
# consumers are offered, and the replay's renumbering starts the fifth component
# well below what the base series accumulated. Usually the fourth component
# covers it, because the forward is seeded on a newer `main` whose version has
# moved on since; where it does not, r-universe has nothing to offer as an
# upgrade until the new chain's counter climbs past the old one's. That is a
# cost rather than a corruption, and whether it is worth paying is a judgement,
# so this names it and leaves the decision with the confirmation: typed on a
# terminal, or held under --confirm, which nobody types.
#
# On a preview line the fourth component never covers it: the prefix is pinned
# to the line being previewed rather than taken from `main`
# (scripts/preview-prefix.sh), so the forward keeps it and only the restarted
# counter differs. A version going back is normal there, and the warning says so.
#
# Without a GNU sort the versions are still printed and simply not compared:
# a terminal swap is not worth blocking over a missing coreutils, and a
# comparison made with the wrong tool would read as a clean bill. Under
# --confirm nobody reads the versions instead, so the missing comparison is held.
if [ -z "$gnu_sort" ]; then
  echo "Note: no GNU sort here, so the versions above were not compared."
  echo "  Read them: a $S-green version that does not move forward is an upgrade"
  echo "  r-universe cannot offer. Install GNU coreutils as 'gsort' -- on"
  echo "  macOS, 'brew install coreutils'."
  hold "version: not compared, for want of GNU sort"
else
  for r in dev green; do
    oldv=$(desc_field "refs/remotes/$remote/$S-$r" Version)
    newv=$(desc_field "refs/remotes/$remote/$S-fwd-$r" Version)
    if [ -z "$oldv" ] || [ -z "$newv" ]; then continue; fi
    case "$(version_cmp "$oldv" "$newv")" in
      -1) continue ;;
      # Equal is the same problem wearing the other face: two different trees
      # published under one version, so whoever already has it never sees the
      # replacement at all.
      0)
        echo "Warning: $S-$r keeps version $oldv across the swap."
        hold "version: $S-$r keeps $oldv"
        ;;
      1)
        echo "Warning: $S-$r would go from $oldv back to $newv."
        hold "version: $S-$r goes from $oldv back to $newv"
        ;;
    esac
    if [ "$r" = green ]; then
      echo "  r-universe publishes from this ref and has no upgrade to offer"
      echo "  until the forward chain's counter passes $oldv. On a preview line"
      echo "  that is normal: its prefix is pinned to the line it previews, so"
      echo "  only the counter moves, and the replay restarts it."
    fi
  done
fi

# The review: what the forward changed against today's `main`, engine aside.
# The stat here, the diff in --out, for a human to read before consumers are
# pointed at it. The exclusions are the files vendoring and the version
# bookkeeping regenerate, which a convergence read excludes for the same reason.
echo
[ -n "$out" ] || out=$(mktemp -d "${TMPDIR:-/tmp}/series-cutover-$S-XXXXXX")
mkdir -p "$out"
excludes=(':(exclude)DESCRIPTION' ':(exclude)NEWS.md' ':(exclude)README.Rmd' ':(exclude)README.md'
  ':(exclude).github/README.md')
for x in "$series_vendor_dir" "${series_regenerated[@]}" "${series_regenerated_dirs[@]}"; do
  excludes+=(":(exclude)$x")
done
new_green_ref="refs/remotes/$remote/$S-fwd-green"
echo "review: what $S-fwd-green changes against main $(git rev-parse --short "$main_ref"), outside the engine"
git diff --stat=100 "$main_ref" "$new_green_ref" -- . "${excludes[@]}" | sed 's/^/  /'
git diff "$main_ref" "$new_green_ref" -- . "${excludes[@]}" > "$out/review.diff"
git diff --stat=100 "$main_ref" "$new_green_ref" -- . "${excludes[@]}" > "$out/review.stat"
echo "  full diff: $out/review.diff"
echo

# What the swap would orphan, and where it is kept: one archive pull request per
# lineage. A ref whose tip is an ancestor of a ref already kept is on that
# lineage -- green on -dev, build-base on -build, and the two may be equal --
# and needs none of its own, which is why the strands come before the markers.
# The canonical repository's copy of green is a lineage of its own there,
# against the forward's copy where the loop has mirrored it and against `main`
# where it has not; the base only decides what the pull request shows.
archives=() # "<remote> <head> <base>"
if [ -n "$archive" ]; then
  kept=()
  for r in dev build green build-base; do
    # Empty arrays in the `+` form, which keeps `set -u` quiet on any bash.
    grep -qxF "$r" <<<"$(printf '%s\n' ${present[@]+"${present[@]}"})" || continue
    covered=
    for o in ${kept[@]+"${kept[@]}"}; do
      if git merge-base --is-ancestor "refs/remotes/$remote/$S-$r" "refs/remotes/$remote/$S-$o"; then
        covered=$o
        break
      fi
    done
    [ -n "$covered" ] || { kept+=("$r"); archives+=("$remote $S-$r $S-fwd-$r"); }
  done
  # The vendor strand is a lineage of its own, replaced by the forward's.
  if git rev-parse -q --verify "refs/remotes/$remote/$S-vendor" >/dev/null &&
    git rev-parse -q --verify "refs/remotes/$remote/$S-fwd-vendor" >/dev/null; then
    archives+=("$remote $S-vendor $S-fwd-vendor")
  fi
  if [ -n "$canon_read" ] && git rev-parse -q --verify "refs/remotes/$canonical/$S-green" >/dev/null; then
    if git rev-parse -q --verify "refs/remotes/$canonical/$S-fwd-green" >/dev/null; then
      archives+=("$canonical $S-green $S-fwd-green")
    else
      archives+=("$canonical $S-green main")
    fi
  fi
fi
# Each remote archived in has to name its repository, and `gh` has to be there,
# or the swap refuses; both are read here, so that it refuses before the first
# pull request is opened rather than after the archive in another remote.
unarchivable=()
if [ ${#archives[@]} -gt 0 ]; then
  echo "archive pull requests, opened and closed before the swap:"
  for a in "${archives[@]}"; do
    read -r r head base <<<"$a"
    slug=$(series_github_slug "$r")
    if [ -n "$slug" ]; then
      echo "  $head -> $base in $slug"
    else
      echo "  $head -> $base in $r, which is not a GitHub remote"
      unarchivable+=("$r is not a GitHub remote, so $head cannot be archived there; set 'git config remote.$r.github <owner>/<repo>'")
    fi
  done
  command -v "$gh" >/dev/null 2>&1 || unarchivable+=("$gh is not installed, so nothing can be archived")
elif [ -n "$archive" ]; then
  echo "archive pull requests: none needed; nothing on $remote is replaced"
else
  echo "archive pull requests: skipped (--no-archive); the replaced history is reachable from nothing after the swap"
fi
echo

# The cleanup the swap leaves: the forward's refs, whose tips are the series'
# now, its vendor strand, its derived strands and retry ledger, and the forward
# green's copy in the canonical repository, each deleted under a lease on the
# tip read here. scripts/series-prune.sh lists whatever this could not delete.
leftovers=()
leftover_tips=()
for r in "$S-fwd-"{build,dev,green,build-base,vendor,rc-dev,alpha,rc-alpha} "retry-$S-fwd-dev"; do
  tip=$(git rev-parse -q --verify "refs/remotes/$remote/$r") || continue
  leftovers+=("$r")
  leftover_tips+=("$tip")
done
echo "deleted after the swap: ${leftovers[*]} on $remote"
canon_fwd= # the tip of the forward's copy of green in the canonical repository
if [ -n "$canon_read" ] && canon_fwd=$(git rev-parse -q --verify "refs/remotes/$canonical/$S-fwd-green"); then
  echo "                        $S-fwd-green on $canonical"
fi

if [ -n "$prepare" ]; then
  echo
  if [ ${#unarchivable[@]} -gt 0 ]; then
    echo "the swap would refuse, on a terminal too, as the archive cannot be opened; --no-archive is the terminal's override:"
    printf '  %s\n' "${unarchivable[@]}"
    echo
  fi
  if [ ${#held[@]} -gt 0 ]; then
    echo "--confirm would refuse on what this run warned about, which a terminal run leaves to the operator:"
    printf '  %s\n' "${held[@]}"
    echo
  fi
  # The SHA, not a command to paste: a cutover without a terminal names the
  # state a maintainer decided on (.claude/skills/series-cutover/SKILL.md).
  echo "Prepared; nothing was opened, pushed or deleted. The state to decide on:"
  echo "  $S-fwd-green at $fwd_green"
  echo "To cut over on a terminal, which asks for the series name:"
  echo "  $again"
  exit 0
fi

# The gate above says the swap is allowed; this asks whether it is wanted. It
# comes last so the operator confirms with the coverage lines, the package
# versions and the four ref moves on screen, and it takes the series name
# rather than a keystroke because the mistake worth catching is cutting over
# the wrong series. `--confirm` gave that name on the command line, checked
# before anything was read, where it stays on record with the command, and the
# SHA of the state decided on, checked after the fetch; what this run held for
# the operator to weigh refuses it here instead, before anything is opened.
echo
if [ ${#unarchivable[@]} -gt 0 ]; then
  echo "Error: the swap archives what it replaces first, and this run cannot:" >&2
  printf '  %s\n' "${unarchivable[@]}" >&2
  echo "  Nothing was opened or moved. On a terminal, --no-archive swaps without the archive." >&2
  exit 1
fi
if [ -n "$confirmed" ] && [ ${#held[@]} -gt 0 ]; then
  echo "Error: --confirm swaps with nobody to weigh a warning, and this run printed these:" >&2
  printf '  %s\n' "${held[@]}" >&2
  echo "  Nothing was opened or moved. They go back to the maintainer, and a cutover that" >&2
  echo "  accepts them runs on a terminal (.claude/skills/series-cutover/SKILL.md)." >&2
  exit 1
fi
if [ -n "$confirmed" ]; then
  echo "Replacing series $S with $S-fwd-*, confirmed by --confirm $S@$confirm_sha, the tip of $S-fwd-green."
else
  printf 'Replace series %s with %s-fwd-*? Type the series name to confirm: ' "$S" "$S"
  read -r confirm
  [ "$confirm" = "$S" ] || { echo "Aborted; nothing was pushed."; exit 1; }
fi

# Archive first: a pull request moves no ref, and a failure here leaves the
# series exactly as it was.
if [ ${#archives[@]} -gt 0 ]; then
  echo "archiving:"
  for a in "${archives[@]}"; do
    read -r r head base <<<"$a"
    archive_pr "$r" "$head" "$base"
  done
fi

git push --atomic "${leases[@]}" "$remote" "${refspecs[@]}" || {
  echo "Error: the swap was refused, and an atomic push moves nothing when it is; nothing was swapped." >&2
  exit 1
}
if [ ${#missing[@]} -eq 4 ]; then
  echo "Series $S created from its forward counterpart."
else
  echo "Series $S replaced by its forward counterpart."
fi

# What does not happen from here on is left behind rather than fatal: the swap
# stands, so a rerun is not what finishes it. Each is printed at the end with
# what does, and the run exits 9.
left=()          # "<remote> <ref>": a deletion refused, of a ref at the tip read
moved=()         # "<remote> <ref> <tip read> <tip now>": a deletion the lease refused
green_left=''    # the push that moves the canonical copy of green, not made
green_why=()     # what green_left is printed under
canon_undo=''    # the canonical half of the undo
new_green=$fwd_green

# Delete <ref>s in <repo>, each under a lease on the tip this run read: a ref
# that moved since holds commits the swap did not take, such as an overlapping
# firing's, and deleting it would leave them on no ref. Some git proxies refuse
# deletions outright, a cloud session's among them, and a push that was refused
# may still have deleted some, so what is left is read back rather than
# assumed: a ref still at the tip read is litter, and one anywhere else, or not
# read back at all, has moved. Until litter is gone, the loop ignores a forward
# whose green is an ancestor of its base's, and scripts/series-prune.sh lists it.
delete_leased() { # <repo> <ref> <tip> [<ref> <tip>]...
  local repo=$1 still r t now i readback=1
  shift
  dl_pairs=("$@") dl_leases=() dl_refs=()
  for ((i = 0; i < ${#dl_pairs[@]}; i += 2)); do
    dl_leases+=("--force-with-lease=refs/heads/${dl_pairs[i]}:${dl_pairs[i + 1]}")
    dl_refs+=(":refs/heads/${dl_pairs[i]}")
  done
  git push "${dl_leases[@]}" "$repo" "${dl_refs[@]}" && return 0
  still=$(git ls-remote --heads "$repo") || readback=
  for ((i = 0; i < ${#dl_pairs[@]}; i += 2)); do
    r=${dl_pairs[i]} t=${dl_pairs[i + 1]} now=
    # awk reads the whole listing: `grep -q` would stop at the first match, and
    # `cut` before it die of SIGPIPE, which `pipefail` reports as no match.
    if [ -n "$readback" ]; then
      now=$(awk -v ref="refs/heads/$r" '$2 == ref { print $1 }' <<<"$still")
      [ -n "$now" ] || continue
    fi
    if [ "$now" = "$t" ]; then
      left+=("$repo $r")
    else
      moved+=("$repo $r $t $now")
    fi
  done
}

# The canonical repository carries a copy of green for r-universe to publish
# from, and the swap just moved green onto a lineage the old one is no more an
# ancestor of. This is the only place that copy is forced: the loop's own mirror
# is fast-forward only and would stop the next firing on exactly this
# divergence. After the swap, never before, so the canonical copy is never ahead
# of the fork; and under a lease on the copy this run read and archived, so a
# green nobody here wrote, or archived, is not overwritten silently. The
# forward's copy there goes with the fork's `-fwd` refs: its tip is `<S>-green`
# now.
#
# A copy out of this run's reach has no tip to lease on, so what it is owed is
# printed as steps rather than as a command to run as it stands: the archive
# first, as above, then the move under a lease on the tip it holds.
if [ -n "$canon_why" ]; then
  green_why=("$S-green in the canonical repository was neither archived nor moved, as $canon_why; r-universe publishes it."
    "Once a remote here reads it, archive the copy it holds as the pull requests above were, then move it under a lease"
    "on that tip:")
  green_left="git push --force-with-lease=refs/heads/$S-green:<the tip it holds> $canonical $new_green:refs/heads/$S-green"
elif [ -n "$canon_read" ]; then
  cur=$(git rev-parse -q --verify "refs/remotes/$canonical/$S-green") || cur=
  if [ "$cur" = "$new_green" ]; then
    echo "canonical $S-green already at $(git rev-parse --short "$new_green")"
  elif git push --force-with-lease="refs/heads/$S-green:$cur" \
      "$canonical" "$new_green:refs/heads/$S-green"; then
    echo "canonical $S-green -> $(git rev-parse --short "$new_green")"
    canon_undo="git push --atomic --force-with-lease=refs/heads/$S-green:$new_green $canonical $cur:refs/heads/$S-green"
    [ -z "$canon_fwd" ] || canon_undo="$canon_undo $canon_fwd:refs/heads/$S-fwd-green"
  else
    # The line that finishes it leases on what the canonical repository holds
    # now, read again, so that a green that moved after this run read it does
    # not get the line refused too; what moved is named, to be read first.
    now=$(git ls-remote "$canonical" "refs/heads/$S-green" | cut -f1) || now=$cur
    if [ "$now" = "$new_green" ]; then
      echo "canonical $S-green already at $(git rev-parse --short "$new_green"), moved there by another push"
    else
      green_why=("$S-green in $canonical is still on the pre-cutover lineage, which r-universe publishes; move it:")
      [ "$now" = "$cur" ] || green_why+=("It is at ${now:-<nothing>} now, not at the ${cur:-<nothing>} this run read and archived;"
        "read what moved there before running this.")
      green_left="git push --force-with-lease=refs/heads/$S-green:$now $canonical $new_green:refs/heads/$S-green"
    fi
  fi
  [ -z "$canon_fwd" ] || delete_leased "$canonical" "$S-fwd-green" "$canon_fwd"
fi

pairs=()
for i in "${!leftovers[@]}"; do pairs+=("${leftovers[i]}" "${leftover_tips[i]}"); done
delete_leased "$remote" "${pairs[@]}"

# What a session quotes: the archive pull requests, and the undo, filled in.
# The undo fetches the archive pull requests' heads first, so it runs in any
# clone, not only this one; green and -build-base are on those lineages.
if [ ${#archived[@]} -gt 0 ]; then
  echo
  echo "archive pull requests, closed and never merged; each head keeps the lineage it names:"
  for a in "${archived[@]}"; do
    read -r r head slug n <<<"$a"
    echo "  $head: $slug#$n https://github.com/$slug/pull/$n"
  done
fi
echo
echo "undo, while nothing has moved since: one leased push per repository puts the old tips back,"
echo "  and the forward's refs at the tips they gave; re-cut the derived strands of both afterwards:"
# A canonical green this run did not move needs no undo there.
for repo in "$remote" "$canonical"; do
  [ -n "$repo" ] || continue
  [ "$repo" = "$remote" ] || [ -n "$canon_undo" ] || continue
  pulls=()
  # Empty after --no-archive; the `+` form keeps `set -u` quiet on any bash.
  for a in ${archived[@]+"${archived[@]}"}; do
    read -r r head slug n <<<"$a"
    [ "$r" != "$repo" ] || pulls+=("refs/pull/$n/head")
  done
  [ ${#pulls[@]} -eq 0 ] || echo "  git fetch $repo ${pulls[*]}"
  if [ "$repo" = "$remote" ]; then
    echo "  git push --atomic ${undo_leases[*]} $remote ${undo_refspecs[*]}"
  else
    echo "  $canon_undo"
  fi
done

echo
echo "Re-cut the derived strands from the swapped-in series where it had them:"
echo "  scripts/series-rc.sh $S --push, scripts/series-alpha.sh $S --push (.claude/skills/series-rc, series-alpha)."
echo "The fork's universe still names $S-fwd-green for the forward's flavor; nothing installs it, and the"
echo "  next forward writes the ref again (handbook/branches/flavors/README.md)."

if [ ${#left[@]} -gt 0 ] || [ ${#moved[@]} -gt 0 ] || [ -n "$green_left" ]; then
  echo
  echo "left behind: the swap stands, and what follows it did not happen."
  if [ -n "$green_left" ]; then
    printf '  %s\n' "${green_why[@]}"
    echo "    $green_left"
  fi
  for repo in "$remote" "$canonical"; do
    refs=()
    for l in ${left[@]+"${left[@]}"}; do
      read -r r ref <<<"$l"
      [ "$r" != "$repo" ] || refs+=("$ref")
    done
    [ ${#refs[@]} -gt 0 ] || continue
    echo "  cutover litter in $repo, which loses nothing when deleted: ${refs[*]}"
    for ref in "${refs[@]}"; do echo "    $(series_delete_line "$repo" "$ref")"; done
  done
  # A moved ref is not litter: what moved onto it may be on no other ref, so it
  # is shown rather than deleted, and what the series needs of it is a repair
  # on <S>-dev before anyone deletes the ref by hand.
  for repo in "$remote" "$canonical"; do
    first=1
    for l in ${moved[@]+"${moved[@]}"}; do
      read -r r ref tip now <<<"$l"
      [ "$r" = "$repo" ] || continue
      if [ -n "$first" ]; then
        echo "  moved in $repo since this run read them, so kept: each may hold commits no other ref has. Read them:"
        first=
      fi
      where="at ${now:0:12} now"
      [ -n "$now" ] || where="not read back"
      echo "    $ref, read at ${tip:0:12}, $where:"
      echo "      git fetch $repo refs/heads/$ref && git log --oneline $tip..FETCH_HEAD"
    done
    [ -n "$first" ] || echo "    What $S needs of them goes onto $S-dev as a repair; then delete each by hand, never by a rerun."
  done
  echo "SWAPPED, LEFT BEHIND: $S is cut over; run the lines above, or hand them to a maintainer."
  exit 9
fi
