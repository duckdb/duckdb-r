#!/bin/bash
# Replace a series with its forward counterpart in one atomic swap,
# once every tip the swap moves a ref off is pinned by a pull request's head in the fork.
#
# A forward series <S>-fwd-* is the same series rebuilt on a newer `main`
# (.claude/skills/series-forward/SKILL.md).
# Once its green covers at least the upstream commits the old green covered,
# this script swaps the series refs in one atomic push,
# so consumers of <S>-green never observe a half-replaced series.
# The swap is the one sanctioned non-fast-forward move of a green ref, and the names stay what they were:
# r-universe keeps building `<S>-green`, and nothing outside the two repositories learns a new one.
# It is also the one move the series loop never makes:
# the loop reports a ready cutover and stops (.claude/skills/series-loop/SKILL.md),
# because retiring the lineage r-universe builds from is a decision, not a stage.
#
# .claude/skills/series-cutover/SKILL.md drives a cutover, and this script serves two of its steps.
# Neither reads from a terminal or calls `gh`, and a run names exactly one of them:
#   --prepare               reports, and decides and moves nothing:
#                           the refs to swap with their versions, the coverage gate,
#                           the convergence read (scripts/series-converge.sh), the package on both sides,
#                           the review, as a stat on screen and a full diff in --out,
#                           the pin of each tip the swap replaces, or that it has none yet,
#                           what --confirm would refuse on, and the tip of `<S>-fwd-green` to decide on.
#   --confirm <series>@<sha>
#                           swaps, on the state a maintainer decided:
#                           the series, and that tip as 12 to 40 lowercase hex digits.
# The script cannot tell who passes --confirm:
# what keeps a firing from cutting over is the loop's rule and the skill's decision rule,
# and what the SHA does is tie the run to the state that decision was taken on.
#
# What --confirm enforces, each before anything is pushed, and nothing else:
#   the SHA       `<S>-fwd-green` is still at the decided commit.
#   coverage      the forward's green vendors an upstream commit that descends from the one the old green vendored,
#                 read in the --upstream clone; a run without one refuses,
#                 and so does an old green on which no vendored SHA can be read.
#   the canonical repository
#                 a --canonical that names no remote here, or one that cannot be read, refuses,
#                 since the run could then neither check nor move the copy of green it holds.
#   the pins      every tip the swap moves a ref off is reachable from a pull request's head (below).
#   the mechanics one atomic push leased on every tip it replaces,
#                 then the forward's refs deleted, each leased on the tip read.
# Convergence, the package name and the versions are reported, never enforced:
# whether a difference is explicable is the review's judgement, and the decision is taken on the report that shows them.
# A version that does not move forward is the one cost of the swap nothing else on screen shows:
# the forward regenerates its own flavor commits, and the replay renumbers the fifth component as a counter of its chain.
#
# The pins keep the replaced history reachable, and this script opens no pull request.
# The skill builds a stack for each strand X with scripts/series-cutover-stack.sh <S> <X>,
# whose first branch `cutover/<S>/<X>/1-main` descends from the old tip `<S>-<X>`,
# and opens that branch as a pull request in the fork;
# GitHub keeps a pull request's head as `refs/pull/<n>/head` for as long as the pull request exists, closed or not.
# The run lists the fork's pull request heads once, with `git ls-remote`, fetches the stack branches once,
# and takes a stack branch as a pin where its tip is some pull request's head.
# Every tip the swap moves a ref off must be an ancestor of a pin:
# `-dev`, `-build`, `-green`, `-build-base` and `-vendor` in the fork, and `<S>-green` in the canonical repository,
# which no stack starts from: it is pinned as an ancestor of a pin in the fork, as it is where it is the fork's green.
# A tip that is not refuses the run with exit 1, naming the ref and the stack to build.
#
# A base series ref that does not exist yet is created rather than swapped:
# a series that started as -fwd has no counterpart to replace, and nothing to pin.
#
# The review is everything the forward changed against current `main` outside the engine:
# the R side, `src/` outside `src/duckdb/`, the tests and the patch stack.
# The forward's seed is a recent `main`, so that diff is the series' own work.
#
# Usage: series-cutover.sh <series> [--remote <name>] [--canonical <name>]
#                          [--upstream <path>] [--out <dir>]
#                          (--prepare | --confirm <series>@<sha>)
#   series-cutover.sh main --upstream ../../../duckdb --prepare --out /tmp/main-cutover
#   series-cutover.sh main --upstream ../../../duckdb --confirm main@0123456789ab
#
#   --remote <name>   a remote of *this* repository, the fork, carrying the series refs and the stacks.
#                     A clone made with `gh` has both `origin` and `upstream`; pass whichever holds `<series>-green`.
#   --canonical <name>
#                     the repository r-universe publishes the base flavors from, default `upstream`,
#                     as in series-advance.sh, which carries a copy of every `<S>-green`, the forward's included.
#                     The swap forces that copy, under a lease and after the fork's swap,
#                     so the canonical repository is never ahead of the fork,
#                     and deletes the forward's copy there with the fork's `-fwd` refs.
#                     The run reads it once, with `git ls-remote`, and fetches what that listed.
#                     An empty name says there is no canonical repository.
#   --upstream <path> a filesystem path to a `duckdb/duckdb` checkout, read with `git -C` for the coverage gate.
#                     Never a remote name, whatever it is called.
#   --out <dir>       where the review diff is written; default a fresh temporary directory, named on screen.
#   --prepare, --confirm <series>@<sha>
#                     as above. Both, neither, another series name or another shape of SHA is a usage error,
#                     before anything is read.
# The options are spelled the same in every scripts/series-*.sh;
# see the shared contract in handbook/operations/vendoring/series-loop/README.md.
#
# After the swap the script prints the undo:
# a fetch of the pinning pull requests' heads, then one leased push per repository
# that puts the old tips back and the forward's refs beside them,
# save a forward ref that moved since the run read it, which was never deleted.
# Where a remote refused a deletion it prints the line that finishes it (`series_delete_line`, scripts/series-lib.sh):
# on GitHub, a dispatch of .github/workflows/delete-branch.yaml for a session,
# with no pull request for a `-fwd-` ref whose twin without the `fwd-` is at its tip, as the swap leaves each,
# or naming a pull request whose head is the ref's tip;
# where neither holds, a `gh api -X DELETE` that checks the tip first, for a maintainer's shell.
#
# Exit status:
#   0  swapped and cleaned up, or prepared.
#   1  refused or failed before or at the swap, so nothing was swapped:
#      a forward ref missing, a coverage gate that fails, and under --confirm a forward green not at the SHA it names,
#      a coverage gate it cannot verify, a canonical remote missing or unreadable, a tip no pin reaches,
#      or a lease the swap lost.
#      Under --prepare only a missing forward ref or a failing coverage gate is 1; the rest is reported.
#   2  a usage error, neither --prepare nor --confirm among them, or a --confirm that does not name the series
#      and a SHA; nothing was read or moved.
#   9  swapped, with something left behind: a forward ref the remote refused to delete, which is cutover litter;
#      a forward ref that moved since the run read it, whose deletion the lease refused;
#      a forward ref whose deletion was refused and that could not be read back, in a state the run does not know;
#      or the canonical copy of green the remote refused to move.
#      Each is printed above a last line `SWAPPED, LEFT BEHIND`:
#      litter and a refused move with the command that finishes them,
#      a moved ref with the command that shows what moved,
#      and a ref not read back with the command that reads it.
#      The swap stands, and a rerun is not what finishes any of them.
#   Any other status is a command that failed, such as git's 128 under `set -e`,
#   and it comes before the swap, so nothing was swapped, as for 1.
#   After the swap every command that can fail is checked and reported, save the writing of this output:
#   a reader that stops reading ends the run there, by SIGPIPE (141) or as a failed write,
#   and then the refs say what happened.

set -euo pipefail
# shellcheck source=series-lib.sh
. "$(dirname "$0")/series-lib.sh"

usage='usage: series-cutover.sh <series> [--remote <name>] [--canonical <name>] [--upstream <path>] [--out <dir>] (--prepare | --confirm <series>@<sha>)'
argerr() { echo "$usage" >&2; exit 2; }
remote=${SERIES_REMOTE:-origin}
canonical=${SERIES_CANONICAL-upstream}
upstream=${UPSTREAM_CLONE:-}
out='' prepare='' confirm='' confirmed='' confirm_sha=''
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --canonical) [ $# -ge 2 ] || argerr; canonical=$2; shift 2 ;;
    --upstream) [ $# -ge 2 ] || argerr; upstream=$2; shift 2 ;;
    --out) [ $# -ge 2 ] || argerr; out=$2; shift 2 ;;
    --prepare) prepare=1; shift ;;
    --confirm) [ $# -ge 2 ] || argerr; confirm=$2; confirmed=1; shift 2 ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
S=${args[0]}
# The mode is checked before anything is read.
# The confirmation is the statement of which series to replace, and on which state,
# so a name that is not this one is a command that contradicts itself, and so is one that both swaps and moves nothing;
# a run that names neither mode has nothing to do.
if [ -n "$confirmed" ]; then
  if [ -n "$prepare" ]; then
    echo "Error: --prepare moves nothing and --confirm swaps; pass one of them." >&2
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
elif [ -z "$prepare" ]; then
  echo "Error: pass --prepare to report what a cutover of $S would do, or --confirm $S@<sha> to swap it" >&2
  echo "  on the tip of $S-fwd-green a maintainer decided on (.claude/skills/series-cutover/SKILL.md)." >&2
  echo "  The series loop reports a ready cutover and stops; it never confirms one. Nothing was read." >&2
  argerr
fi
here=$(cd "$(dirname "$0")" && pwd)
# Pathspecs below are the repository's, wherever this was started from.
cd "$(git rev-parse --show-toplevel)"

# What --confirm refuses on, collected for --prepare to list at the end.
# Under --confirm each refuses where it is found, before anything is pushed.
held=()
hold() { held+=("$1"); }

# A canonical remote that is named and missing leaves r-universe's copy of green out of reach:
# the run could neither check that it is pinned nor move it.
# An empty name is how to say there is none (SERIES_CANONICAL='' or --canonical ''),
# so a name nothing here answers to is a clone set up otherwise, and --confirm refuses before the fetch.
canon_out= # set where the canonical repository is out of this run's reach
if [ -n "$canonical" ] && ! git remote get-url "$canonical" >/dev/null 2>&1; then
  if [ -n "$confirmed" ]; then
    echo "Error: there is no remote '$canonical', so the canonical copy of $S-green could be neither checked nor moved." >&2
    echo "  Name the remote with --canonical <name>, or pass --canonical '' where there is no canonical repository." >&2
    echo "  Nothing was moved." >&2
    exit 1
  fi
  echo "Warning: there is no remote '$canonical', so the canonical copy of $S-green can be neither checked nor moved."
  echo "  Name the remote with --canonical <name>, or pass --canonical '' where there is no canonical repository."
  hold "canonical: no remote '$canonical'"
  canon_out=1
fi

# A fork that cannot be fetched ends the run here, before anything is moved;
# --prune drops what was deleted there, so nothing below plans on it.
# The stack branches are fetched by name too, so that a narrower refspec does not leave them out,
# and --prune drops a stack branch deleted since, which would otherwise read as a pin.
# The pull request heads are listed once; a fork whose listing fails has no pins this run can read.
git fetch -q --prune "$remote"
git fetch -q --prune "$remote" "+refs/heads/cutover/$S/*:refs/remotes/$remote/cutover/$S/*"
pulls_why=
pull_heads=$(git ls-remote "$remote" 'refs/pull/*/head') || {
  pull_heads=
  pulls_why="the pull request heads of $remote could not be listed (above), so no stack reads as a pin"
}

# `main` for the review is the canonical repository's; the fork's mirror may lag by a cycle
# (handbook/branches/mirrors/README.md). The two greens there are what the pins, the move and the cleanup read.
# The repository is read once, and only what that read listed is fetched:
# a tracking ref an earlier fetch left is dropped where the read did not list it,
# and a remote that cannot be read (an auth failure, a proxy refusing it) puts that copy out of reach,
# as a missing remote does, rather than leaving the plan to a ref nobody read.
main_ref="refs/remotes/$remote/main"
canon_read= # set once the canonical repository has been read and fetched
if [ -n "$canonical" ] && [ -z "$canon_out" ]; then
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
    if [ -n "$confirmed" ]; then
      echo "Error: could not read $canonical (above), so the canonical copy of $S-green could be neither checked nor moved." >&2
      echo "  Check the remote's URL and access, or pass --canonical '' where there is no canonical repository." >&2
      echo "  Nothing was moved." >&2
      exit 1
    fi
    echo "Warning: could not read $canonical (above), so the canonical copy of $S-green can be neither checked nor moved."
    echo "  Check the remote's URL and access, or pass --canonical '' where there is no canonical repository."
    hold "canonical: could not read $canonical"
    canon_out=1
  elif git rev-parse -q --verify "refs/remotes/$canonical/main" >/dev/null; then
    main_ref="refs/remotes/$canonical/main"
  fi
fi

# One field of a branch's DESCRIPTION, empty when the ref or the field is not there.
# Both fields this script reads are per-branch:
# the flavor rename writes `Package:`, and the replay renumbers the fifth component of `Version:`.
#
# A missing ref is ordinary here, since a series opened as `-fwd` has no base refs at all,
# so `git show`'s failure is swallowed rather than left to `pipefail`,
# which would otherwise make an empty answer end the run.
desc_field() {
  git show "$1:DESCRIPTION" 2>/dev/null | sed -n "s/^$2: *//p" | head -n 1 || true
}

# GNU sort, wherever it is called: on Linux that is `sort`, on macOS it is `gsort` and the system `sort` is BSD's.
# Prefer `gsort`, then verify: the same choice, and the same reason, scripts/flavor.sh makes for `sed`.
# Empty when neither is GNU, which is a comparison not made rather than a wrong one.
if command -v gsort >/dev/null 2>&1; then
  gnu_sort='gsort'
else
  gnu_sort='sort'
fi
case "$("$gnu_sort" --version 2>/dev/null || true)" in
  *"GNU coreutils"*) ;;
  *) gnu_sort= ;;
esac

# Where two dotted versions sort against each other, as -1, 0 or 1.
# `sort -V` compares them component by component and numerically,
# so 1.5.5.9013.36 sorts below 1.5.5.9020.12 rather than by string order,
# and a missing component ranks below a present one: 1.5.5.9020 below 1.5.5.9020.1.
version_cmp() {
  local sorted
  [ "$1" != "$2" ] || { printf '%s\n' 0; return; }
  sorted=$(printf '%s\n%s\n' "$1" "$2" | "$gnu_sort" -V)
  if [ "${sorted%%$'\n'*}" = "$1" ]; then printf '%s\n' -1; else printf '%s\n' 1; fi
}

for r in build dev green build-base; do
  git rev-parse -q --verify "refs/remotes/$remote/$S-fwd-$r" >/dev/null ||
    { echo "Error: $S-fwd-$r does not exist on $remote"; exit 1; }
done

# The state the decision was taken on: the green the swap installs, as --prepare printed it.
# Under --confirm the run swaps that green or nothing.
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

# A base series ref may legitimately be missing: a series started as -fwd has no counterpart to replace,
# and the cutover creates the ref rather than swapping it. Only the forward refs are required.
missing=()
for r in build dev green build-base; do
  git rev-parse -q --verify "refs/remotes/$remote/$S-$r" >/dev/null || missing+=("$S-$r")
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

# Coverage gate: the forward green must vendor at least what the old green vendored,
# so verification never moves backwards at cutover.
if [ -n "$old_up" ]; then
  if [ -z "$new_up" ]; then
    echo "Error: old green vendors $old_up but forward green vendors nothing"
    exit 1
  fi
  if [ -n "$upstream" ]; then
    # Separate "git could not run there" from "the ancestry says no": both reach the `||` below,
    # and reporting a regression for a path that is not a checkout sends the reader after the wrong thing.
    # A remote name passed as the path is exactly that case.
    git -C "$upstream" rev-parse --git-dir >/dev/null 2>&1 || {
      echo "Error: $upstream is not a git checkout"
      echo "  --upstream takes a path to a $series_upstream_repo clone, not a remote."
      exit 1
    }
    git -C "$upstream" merge-base --is-ancestor "$old_up" "$new_up" || {
      echo "Error: forward green does not cover old green; coverage would regress"
      exit 1
    }
    echo "coverage: the forward green's $new_up covers the old green's $old_up"
  elif [ -n "$confirmed" ]; then
    echo "Error: no upstream clone given, so the coverage gate cannot be verified, and --confirm" >&2
    echo "  swaps only where it is; pass --upstream <path>. Nothing was moved." >&2
    exit 1
  else
    echo "Warning: no upstream clone given, coverage gate not verified"
    hold "coverage: no upstream clone given"
  fi
elif [ -n "$old_green" ]; then
  # A green that exists and names no vendored SHA leaves the gate nothing to hold the forward against,
  # which is the gate not verified, not passed; series_vendored_sha has said why on stderr.
  if [ -n "$confirmed" ]; then
    echo "Error: no vendored SHA could be read on $S-green, so the coverage gate cannot be verified," >&2
    echo "  and --confirm swaps only where it is. Nothing was moved." >&2
    exit 1
  fi
  echo "Warning: no vendored SHA could be read on $S-green, coverage gate not verified"
  hold "coverage: no vendored SHA read on $S-green"
fi

# Convergence: the coverage gate above asks whether the forward has vendored far enough,
# which says how much upstream it reaches and nothing about what it carries.
# This asks the other half, whether the two branches still hold the same package.
# It reports and never refuses: the invariant's second half is *explicable*,
# and whether a difference is explicable is the review's judgement, which no script can make.
echo
rc=0
"$here/series-converge.sh" "$S" --remote "$remote" --no-fetch || rc=$?
# 1 is a divergence to read; 2 is the comparison not being available at all:
# a series that started as `-fwd` has no `<S>-dev` to compare against, and the script has already said so.
if [ "$rc" -eq 1 ]; then
  echo
  echo "  ^ reported, not enforced: the review explains each, or the forward is repaired where it differs."
  echo "    A swap does not resolve them: it makes them the serving branch's, on the lineage r-universe builds from."
elif [ "$rc" -ne 0 ] && git rev-parse -q --verify "refs/remotes/$remote/$S-dev" >/dev/null; then
  echo
  echo "  ^ the convergence read stopped with status $rc although $S-dev exists;"
  echo "    reported, not enforced: read why above."
fi
echo

# The package the swap publishes, named on both sides.
# `Package:` and `Version:` are what a consumer installs, and the swap moves both:
# the name because the forward regenerates its own flavor commits,
# the version because the replay renumbers the fifth component as a counter of its own chain.
# So each ref is shown with the version it carries before and after,
# and a name that changes is called out rather than left to be read off four lines.
old_pkg=$(desc_field "refs/remotes/$remote/$S-dev" Package)
new_pkg=$(desc_field "refs/remotes/$remote/$S-fwd-dev" Package)
if [ -z "$old_pkg" ] || [ "$old_pkg" = "$new_pkg" ]; then
  echo "package: ${new_pkg:-<none>}"
else
  echo "package: $old_pkg -> $new_pkg"
  echo "  ^ the swap renames the package. A series and its forward are flavored the same;"
  echo "    a name that moved means the forward was seeded with another flavor,"
  echo "    and the swap would publish a different package. Reported, not enforced."
fi

# The vendor strand swaps with the four where the forward has one;
# a forward written before the strand existed has none,
# and the series derives one from its new buffer afterwards (scripts/series-vendor.sh --init).
swap=(build dev green build-base)
if git rev-parse -q --verify "refs/remotes/$remote/$S-fwd-vendor" >/dev/null; then
  swap+=(vendor)
else
  echo "Note: $S-fwd-vendor does not exist on $remote; after the swap, derive the strand:"
  echo "  scripts/series-vendor.sh $S --init --remote $remote --push"
fi

leases=()
refspecs=()
# The undo is the swap read backwards: each base ref leased on the forward's tip and put back on its old one,
# or deleted where the swap created it, and each forward ref written again at the tip it gave.
# Those carry no lease and no `+`, so a forward ref the deletion left at that tip is no change;
# one that moved since the run read it was never deleted, and the undo leaves it out.
undo_leases=()
undo_refspecs=()
undo_fwd=() # "<ref> <tip>": a forward ref the undo writes back, unless it moved
# Each tip the swap moves a ref off, for the pins: its label, its tip, and the strand whose stack is its own.
need_label=()
need_tip=()
need_x=()
echo "refs to swap:"
for r in "${swap[@]}"; do
  new=$(git rev-parse "refs/remotes/$remote/$S-fwd-$r")
  # An empty expected value leases the ref as "must not exist yet", which is what a missing base ref needs.
  # The refspecs carry no leading `+`: a forced refspec defeats --force-with-lease outright,
  # and the lease alone already authorizes the non-fast-forward swap.
  cur=$(git rev-parse -q --verify "refs/remotes/$remote/$S-$r") || cur=
  leases+=("--force-with-lease=refs/heads/$S-$r:$cur")
  refspecs+=("$new:refs/heads/$S-$r")
  undo_leases+=("--force-with-lease=refs/heads/$S-$r:$new")
  undo_refspecs+=("$cur:refs/heads/$S-$r")
  undo_fwd+=("$S-fwd-$r $new")
  if [ -n "$cur" ] && [ "$cur" != "$new" ]; then
    need_label+=("$S-$r")
    need_tip+=("$cur")
    # -build-base is a marker on -build, and has no stack of its own.
    if [ "$r" = build-base ]; then need_x+=(build); else need_x+=("$r"); fi
  fi
  short=${cur:0:7}
  oldv=$(desc_field "refs/remotes/$remote/$S-$r" Version)
  newv=$(desc_field "refs/remotes/$remote/$S-fwd-$r" Version)
  printf '  %-26s %-7s %-16s ->  %-7s %s\n' \
    "$S-$r" "${short:-<new>}" "${oldv:--}" "${new:0:7}" "${newv:--}"
done
# The canonical copy of green is replaced too, by the move after the swap.
canon_cur= # the tip of green in the canonical repository, as read
if [ -n "$canon_read" ] && canon_cur=$(git rev-parse -q --verify "refs/remotes/$canonical/$S-green") &&
  [ "$canon_cur" != "$fwd_green" ]; then
  need_label+=("$S-green in $canonical")
  need_tip+=("$canon_cur")
  need_x+=(green)
fi

# A version that does not move forward, back or not at all, is the swap's one cost that nothing else on screen shows.
# `<S>-green` is what r-universe publishes (handbook/branches/mirrors/README.md),
# so its version is the one consumers are offered,
# and the replay's renumbering starts the fifth component well below what the base series accumulated.
# Usually the fourth component covers it, because the forward is seeded on a newer `main` whose version has moved on;
# where it does not, r-universe has nothing to offer as an upgrade until the new chain's counter climbs past the old one's.
# That is a cost rather than a corruption, and whether it is worth paying is a judgement,
# so this names it, and the decision taken on the --prepare report weighs it.
#
# On a preview line the fourth component never covers it:
# the prefix is pinned to the line being previewed rather than taken from `main` (scripts/preview-prefix.sh),
# so the forward keeps it and only the restarted counter differs.
# A version going back is normal there, and the warning says so.
#
# Without a GNU sort the versions are still printed and simply not compared:
# a comparison made with the wrong tool would read as a clean bill.
if [ -z "$gnu_sort" ]; then
  echo "Note: no GNU sort here, so the versions above were not compared."
  echo "  Read them: a $S-green version that does not move forward is an upgrade"
  echo "  r-universe cannot offer. Install GNU coreutils as 'gsort'; on"
  echo "  macOS, 'brew install coreutils'."
else
  for r in dev green; do
    oldv=$(desc_field "refs/remotes/$remote/$S-$r" Version)
    newv=$(desc_field "refs/remotes/$remote/$S-fwd-$r" Version)
    if [ -z "$oldv" ] || [ -z "$newv" ]; then continue; fi
    case "$(version_cmp "$oldv" "$newv")" in
      -1) continue ;;
      # Equal is the same problem wearing the other face: two different trees published under one version,
      # so whoever already has it never sees the replacement at all.
      0) echo "Warning: $S-$r keeps version $oldv across the swap." ;;
      1) echo "Warning: $S-$r would go from $oldv back to $newv." ;;
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
# The stat here, the diff in --out, for the review that the decision is taken on.
# The exclusions are the files vendoring and the version bookkeeping regenerate,
# which a convergence read excludes for the same reason.
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

# The pins: the stack branches `cutover/<S>/<X>/1-main` whose tip is some pull request's head in the fork.
# A stack branch without one is no pin, however it was built: deleting the branch would lose what it keeps.
stack_x=()    # the strand of each stack branch fetched
stack_head=() # its tip
stack_pull=() # the pull request whose head it is, empty for none
prefix="refs/remotes/$remote/cutover/$S/"
while read -r sha ref; do
  x=${ref#"$prefix"}
  [ "${x%/1-main}/1-main" = "$x" ] || continue
  x=${x%/1-main}
  case "$x" in '' | */*) continue ;; esac
  stack_x+=("$x")
  stack_head+=("$sha")
  # awk reads the whole listing and prints the first match: a reader that stopped at it would end awk by SIGPIPE.
  stack_pull+=("$(awk -v sha="$sha" '$1 == sha && !n++ { sub(/^refs\/pull\//, "", $2); sub(/\/head$/, "", $2); print $2 }' \
    <<<"$pull_heads")")
done < <(git for-each-ref --format='%(objectname) %(refname)' "$prefix")

# The pin that reaches <tip>, as an index into the stack arrays: the strand's own stack first, then any other,
# so that green is pinned by its own stack where it has one, and by -dev's where it has not.
pin_of() { # <tip> <strand> -> index; fails when no pin reaches it
  local i
  for i in ${stack_x[@]+"${!stack_x[@]}"}; do
    [ "${stack_x[i]}" = "$2" ] && [ -n "${stack_pull[i]}" ] &&
      git merge-base --is-ancestor "$1" "${stack_head[i]}" && { echo "$i"; return 0; }
  done
  for i in ${stack_x[@]+"${!stack_x[@]}"}; do
    [ -n "${stack_pull[i]}" ] && git merge-base --is-ancestor "$1" "${stack_head[i]}" && { echo "$i"; return 0; }
  done
  return 1
}
# What pins <tip>, which no pin reaches yet, read off its strand's own stack.
pin_advice() { # <tip> <strand> -> one line
  local i own='' stack="cutover/$S/$2/1-main" build="scripts/series-cutover-stack.sh $S $2"
  for i in ${stack_x[@]+"${!stack_x[@]}"}; do [ "${stack_x[i]}" != "$2" ] || own=$i; done
  if [ -z "$own" ]; then
    echo "build the stack, $build, and open $stack as a pull request in $remote"
  elif ! git merge-base --is-ancestor "$1" "${stack_head[own]}"; then
    echo "$stack does not reach it: rebuild the stack, $build"
  else
    echo "$stack reaches it but is no pull request's head in $remote: open it as one"
  fi
}
in_list() { # <item> <list...>: whether the item is among the list
  local x n=$1
  shift
  for x in "$@"; do [ "$x" != "$n" ] || return 0; done
  return 1
}

echo "pins: what keeps each tip the swap replaces reachable, a stack branch that is a pull request's head in $remote:"
[ -z "$pulls_why" ] || echo "  $pulls_why"
unpinned=()
undo_pulls=() # the pull request heads the undo fetches, each once
for i in ${need_label[@]+"${!need_label[@]}"}; do
  tip=${need_tip[i]}
  if j=$(pin_of "$tip" "${need_x[i]}"); then
    status="pinned by cutover/$S/${stack_x[j]}/1-main, refs/pull/${stack_pull[j]}/head"
    p="refs/pull/${stack_pull[j]}/head"
    in_list "$p" ${undo_pulls[@]+"${undo_pulls[@]}"} || undo_pulls+=("$p")
  else
    status="not yet: $(pin_advice "$tip" "${need_x[i]}")"
    unpinned+=("${need_label[i]} at ${tip:0:12}: ${status#not yet: }")
    hold "pins: ${need_label[i]} is reachable from no pull request's head in $remote"
  fi
  printf '  %-30s %-7s %s\n' "${need_label[i]}" "${tip:0:7}" "$status"
done
[ ${#need_label[@]} -gt 0 ] || echo "  none needed: the swap moves no ref off a tip"
echo

# The cleanup the swap leaves: the forward's refs, whose tips are the series' now, its vendor strand,
# its derived strands and retry ledger, and the forward green's copy in the canonical repository,
# each deleted under a lease on the tip read here.
# scripts/series-prune.sh lists whatever this could not delete.
# The stack branches stay: the skill closes their pull requests and deletes them after the swap.
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
  if [ ${#held[@]} -gt 0 ]; then
    echo "--confirm would refuse on these, as they stand:"
    printf '  %s\n' "${held[@]}"
    echo
  fi
  # The SHA, not a command to paste: the decision names the state it was taken on
  # (.claude/skills/series-cutover/SKILL.md).
  echo "Prepared; nothing was pushed or deleted. The state to decide on:"
  echo "  $S-fwd-green at $fwd_green"
  exit 0
fi

echo
if [ ${#unpinned[@]} -gt 0 ]; then
  echo "Error: the swap would move refs off tips that no pull request's head in $remote keeps:" >&2
  printf '  %s\n' "${unpinned[@]}" >&2
  echo "  Nothing was pushed or deleted." >&2
  exit 1
fi
echo "Replacing series $S with $S-fwd-*, confirmed by --confirm $S@$confirm_sha, the tip of $S-fwd-green."

git push --atomic "${leases[@]}" "$remote" "${refspecs[@]}" || {
  echo "Error: the swap was refused, and an atomic push moves nothing when it is; nothing was swapped." >&2
  exit 1
}
if [ ${#missing[@]} -eq 4 ]; then
  echo "Series $S created from its forward counterpart."
else
  echo "Series $S replaced by its forward counterpart."
fi

# What does not happen from here on is left behind rather than fatal:
# the swap stands, so a rerun is not what finishes it.
# Each is printed at the end with what does, and the run exits 9.
left=()       # "<remote> <ref>": a deletion refused, of a ref at the tip read
moved=()      # "<remote> <ref> <tip read> <tip now>": a deletion the lease refused
unread=()     # "<remote> <ref> <tip read>": a deletion refused, and not read back
canon_left=() # what the canonical repository is still owed: why, and the command, indented
canon_undo='' # the canonical half of the undo, its forward green aside
new_green=$fwd_green

# Delete <ref>s in <repo>, each under a lease on the tip this run read:
# a ref that moved since holds commits the swap did not take, such as an overlapping firing's,
# and deleting it would leave them on no ref.
# Some git proxies refuse deletions outright, a cloud session's among them,
# and a push that was refused may still have deleted some, so what is left is read back rather than assumed:
# a ref still at the tip read is litter, and one anywhere else has moved.
# A listing that cannot be read says neither, so each ref is reported as not read back, in a state this run does not know.
# Until litter is gone, the loop ignores a forward whose tips its base's refs reach (`series_fwd_swapped`, scripts/series-lib.sh),
# and scripts/series-prune.sh lists it.
delete_leased() { # <repo> <ref> <tip> [<ref> <tip>]...
  local repo=$1 still r t now i
  shift
  dl_pairs=("$@") dl_leases=() dl_refs=()
  for ((i = 0; i < ${#dl_pairs[@]}; i += 2)); do
    dl_leases+=("--force-with-lease=refs/heads/${dl_pairs[i]}:${dl_pairs[i + 1]}")
    dl_refs+=(":refs/heads/${dl_pairs[i]}")
  done
  git push "${dl_leases[@]}" "$repo" "${dl_refs[@]}" && return 0
  if ! still=$(git ls-remote --heads "$repo"); then
    for ((i = 0; i < ${#dl_pairs[@]}; i += 2)); do unread+=("$repo ${dl_pairs[i]} ${dl_pairs[i + 1]}"); done
    return 0
  fi
  for ((i = 0; i < ${#dl_pairs[@]}; i += 2)); do
    r=${dl_pairs[i]} t=${dl_pairs[i + 1]}
    # awk reads the whole listing: `grep -q` would stop at the first match,
    # and `cut` before it die of SIGPIPE, which `pipefail` reports as no match.
    now=$(awk -v ref="refs/heads/$r" '$2 == ref { print $1 }' <<<"$still")
    [ -n "$now" ] || continue
    if [ "$now" = "$t" ]; then
      left+=("$repo $r $t")
    else
      moved+=("$repo $r $t $now")
    fi
  done
}

# The canonical repository carries a copy of green for r-universe to publish from,
# and the swap just moved green onto a lineage the old one is no more an ancestor of.
# This is the only place that copy is forced:
# the loop's own mirror is fast-forward only and would stop the next firing on exactly this divergence.
# After the swap, never before, so the canonical copy is never ahead of the fork;
# and under a lease on the copy this run read and checked for a pin, so a green nobody here read is not overwritten.
# The forward's copy there goes with the fork's `-fwd` refs: its tip is `<S>-green` now.
if [ -n "$canon_read" ]; then
  if [ "$canon_cur" = "$new_green" ]; then
    echo "canonical $S-green already at $(git rev-parse --short "$new_green")"
  elif git push --force-with-lease="refs/heads/$S-green:$canon_cur" \
    "$canonical" "$new_green:refs/heads/$S-green"; then
    echo "canonical $S-green -> $(git rev-parse --short "$new_green")"
    canon_undo="git push --atomic --force-with-lease=refs/heads/$S-green:$new_green $canonical $canon_cur:refs/heads/$S-green"
  else
    # The line that finishes it leases on what the canonical repository holds now, read again,
    # so that a green that moved after this run read it does not get the line refused too;
    # what moved is named, to be read first.
    now=$(git ls-remote "$canonical" "refs/heads/$S-green" | cut -f1) || now=$canon_cur
    if [ "$now" = "$new_green" ]; then
      echo "canonical $S-green already at $(git rev-parse --short "$new_green"), moved there by another push"
    else
      canon_left=("$S-green in $canonical is still on the pre-cutover lineage, which r-universe publishes; move it:")
      [ "$now" = "$canon_cur" ] || canon_left+=("It is at ${now:-<nothing>} now, not at the ${canon_cur:-<nothing>} this run read;"
        "read what moved there before running this.")
      canon_left+=("  git push --force-with-lease=refs/heads/$S-green:$now $canonical $new_green:refs/heads/$S-green")
    fi
  fi
  [ -z "$canon_fwd" ] || delete_leased "$canonical" "$S-fwd-green" "$canon_fwd"
fi

pairs=()
for i in "${!leftovers[@]}"; do pairs+=("${leftovers[i]}" "${leftover_tips[i]}"); done
delete_leased "$remote" "${pairs[@]}"

# A forward ref that moved since this run read it was never deleted,
# and the tip read would be a non-fast-forward against the one it holds now, refusing the whole atomic push;
# so the undo leaves it out, and says so.
kept_moved() { # <repo> <ref>: whether the deletion's lease refused it
  local l r ref
  for l in ${moved[@]+"${moved[@]}"}; do
    read -r r ref _ <<<"$l"
    [ "$r $ref" != "$1 $2" ] || return 0
  done
  return 1
}
for u in "${undo_fwd[@]}"; do
  read -r ref tip <<<"$u"
  kept_moved "$remote" "$ref" || undo_refspecs+=("$tip:refs/heads/$ref")
done
if [ -n "$canon_undo" ] && [ -n "$canon_fwd" ] && ! kept_moved "$canonical" "$S-fwd-green"; then
  canon_undo="$canon_undo $canon_fwd:refs/heads/$S-fwd-green"
fi
# What a session quotes: the undo, filled in.
# It fetches the pinning pull requests' heads first, so it runs in any clone, not only this one,
# and after the stack branches are deleted; every old tip, the canonical green's included, is on one of them.
echo
echo "undo, while nothing has moved since: a fetch of the pins, then one leased push per repository puts the old tips back,"
echo "  and the forward's refs at the tips they gave; re-cut the derived strands of both afterwards:"
[ ${#undo_pulls[@]} -eq 0 ] || echo "  git fetch $remote ${undo_pulls[*]}"
echo "  git push --atomic ${undo_leases[*]} $remote ${undo_refspecs[*]}"
# A canonical green this run did not move needs no undo there.
[ -z "$canon_undo" ] || echo "  $canon_undo"
[ ${#moved[@]} -eq 0 ] || {
  echo "  It leaves out the forward's refs that moved since this run read them, listed below:"
  echo "  they were never deleted, so they need no undo."
}

echo
echo "Re-cut the derived strands from the swapped-in series where it had them:"
echo "  scripts/series-rc.sh $S --push, scripts/series-alpha.sh $S --push (.claude/skills/series-rc, series-alpha)."
echo "The fork's universe still names $S-fwd-green for the forward's flavor; nothing installs it, and the"
echo "  next forward writes the ref again (handbook/branches/flavors/README.md)."

if [ ${#left[@]} -gt 0 ] || [ ${#moved[@]} -gt 0 ] || [ ${#unread[@]} -gt 0 ] || [ ${#canon_left[@]} -gt 0 ]; then
  echo
  echo "left behind: the swap stands, and what follows it did not happen."
  [ ${#canon_left[@]} -eq 0 ] || printf '  %s\n' "${canon_left[@]}"
  for repo in "$remote" "$canonical"; do
    refs=()
    tips=()
    for l in ${left[@]+"${left[@]}"}; do
      read -r r ref t <<<"$l"
      [ "$r" != "$repo" ] || { refs+=("$ref"); tips+=("$t"); }
    done
    [ ${#refs[@]} -gt 0 ] || continue
    echo "  cutover litter in $repo, which loses nothing when deleted: ${refs[*]}"
    echo "  one line per ref: a dispatch of the deletion workflow, for a session, where the ref's twin without its fwd-"
    echo "  or a pull request's head is at its tip, else a deletion that checks the tip first, for a maintainer's shell:"
    series_delete_listing "$repo"
    # Each line is for the tip this run read back as litter, so it refuses a ref that has moved since.
    for i in "${!refs[@]}"; do echo "    $(series_delete_line "$repo" "${refs[i]}" "${tips[i]}")"; done
  done
  # A moved ref is not litter: what moved onto it may be on no other ref, so it is shown rather than deleted,
  # and what the series needs of it is a repair on <S>-dev before anyone deletes the ref by hand.
  for repo in "$remote" "$canonical"; do
    first=1
    for l in ${moved[@]+"${moved[@]}"}; do
      read -r r ref tip now <<<"$l"
      [ "$r" = "$repo" ] || continue
      if [ -n "$first" ]; then
        echo "  moved in $repo since this run read them, so kept: each may hold commits no other ref has. Read them:"
        first=
      fi
      echo "    $ref, read at ${tip:0:12}, at ${now:0:12} now:"
      echo "      git fetch $repo refs/heads/$ref && git log --oneline $tip..FETCH_HEAD"
    done
    [ -n "$first" ] || echo "    What $S needs of them goes onto $S-dev as a repair; then delete each by hand, never by a rerun."
  done
  # A ref not read back may be gone, still at the tip read, or moved: a refused push may have deleted some of what it named.
  # Each is shown with the line that reads it, and what each answer means.
  for repo in "$remote" "$canonical"; do
    first=1
    for l in ${unread[@]+"${unread[@]}"}; do
      read -r r ref tip <<<"$l"
      [ "$r" = "$repo" ] || continue
      if [ -n "$first" ]; then
        echo "  not read back from $repo after a deletion was refused there, so in a state this run does not know:"
        first=
      fi
      echo "    $ref, read at ${tip:0:12}:"
      echo "      git ls-remote $repo refs/heads/$ref"
    done
    [ -n "$first" ] || {
      echo "    One gone needs nothing; one still at the tip read is cutover litter, which loses nothing when deleted;"
      echo "    one anywhere else moved and may hold commits no other ref has: read <tip read>..<its tip> before deleting it."
    }
  done
  echo "SWAPPED, LEFT BEHIND: $S is cut over; dispatch the workflow lines above, and hand the rest to a maintainer."
  exit 9
fi
