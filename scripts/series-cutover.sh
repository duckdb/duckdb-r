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
# that takes its place. GitHub keeps a pull request's head as `refs/pull/<n>/head`
# for as long as the pull request exists, closed or not, so the commits stay
# reachable and the pull request is where to find them; nothing is merged, and
# the deletion of the `-fwd` refs afterwards loses nothing, because their tips
# are the series' refs now. `--no-archive` skips this, for a remote that is
# not on GitHub; without it the script refuses to swap when it cannot archive.
#
# It is also the one move the series loop never makes: the loop reports a ready
# cutover and stops (.claude/skills/series-loop/SKILL.md), because retiring the
# lineage r-universe builds from is a decision, not a stage. This script is the
# mechanical half of that rule -- it runs from a terminal, on a typed
# confirmation, and nowhere else. `--prepare` is the part that needs neither:
# the gates, the convergence read and the review, written for a human to read
# before deciding, with nothing moved and nothing opened.
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
#                          [--upstream <path>] [--out <dir>] [--prepare] [--no-archive]
#   series-cutover.sh main --upstream ../../../duckdb
#   series-cutover.sh main --upstream ../../../duckdb --prepare --out /tmp/main-cutover
#
# `--canonical <name>` names the repository r-universe publishes the base
# flavors from -- default `upstream`, as in series-advance.sh -- which carries a
# copy of every `<S>-green`, the forward's included (scripts/series-advance.sh).
# A cutover is the one move that takes green off its lineage, so it is the one
# place that copy is forced -- under a lease, and after the swap, so the
# canonical repository is never ahead of the fork -- and the forward's copy
# there is deleted with the fork's `-fwd` refs.
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
#   --no-archive      swap without the archive pull requests.
# Both are spelled the same in every scripts/series-*.sh; see the shared
# contract in handbook/operations/vendoring/series-loop/README.md.
#
# The archive pull requests are opened with `gh api` (REST, no GraphQL) against
# the repository a remote's URL names; `git config remote.<name>.github
# <owner>/<repo>` names it where the URL does not, as in a test fixture.
# $SERIES_GH names another `gh`.
#
# The upstream clone is needed for the coverage gate (an ancestry check
# between vendored upstream SHAs); without it the gate degrades to a warning.

set -euo pipefail

usage='usage: series-cutover.sh <series> [--remote <name>] [--canonical <name>] [--upstream <path>] [--out <dir>] [--prepare] [--no-archive]'
argerr() { echo "$usage" >&2; exit 2; }
remote=${SERIES_REMOTE:-origin}
canonical=${SERIES_CANONICAL-upstream}
upstream=${UPSTREAM_CLONE:-}
gh=${SERIES_GH:-gh}
out='' prepare='' archive=1
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --canonical) [ $# -ge 2 ] || argerr; canonical=$2; shift 2 ;;
    --upstream) [ $# -ge 2 ] || argerr; upstream=$2; shift 2 ;;
    --out) [ $# -ge 2 ] || argerr; out=$2; shift 2 ;;
    --prepare) prepare=1; shift ;;
    --no-archive) archive=''; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
S=${args[0]}
here=$(cd "$(dirname "$0")" && pwd)
# Pathspecs below are the repository's, wherever this was started from.
cd "$(git rev-parse --show-toplevel)"

# Fail before the fetch, not after it: an unattended firing has no terminal, so
# there is nothing for it to confirm with and no reason to do any work first.
# `--prepare` moves nothing and may run anywhere.
if [ -z "$prepare" ] && { [ ! -t 0 ] || [ ! -t 1 ]; }; then
  echo "Error: cutover is a manual operation; run this script from a terminal." >&2
  echo "  The series loop reports a ready cutover and stops; a human runs it." >&2
  echo "  See .claude/skills/series-forward/SKILL.md and series-loop." >&2
  echo "  --prepare runs the gates and the review alone, from anywhere." >&2
  exit 1
fi

git fetch -q "$remote"
# `main` for the review is the canonical repository's; the fork's mirror may lag
# by a cycle (handbook/branches/mirrors/README.md). The two greens there are
# what the archive and the cleanup read.
main_ref="refs/remotes/$remote/main"
if [ -n "$canonical" ] && git remote get-url "$canonical" >/dev/null 2>&1; then
  git fetch -q "$canonical" main 2>/dev/null || true
  git fetch -q "$canonical" "$S-green" "$S-fwd-green" 2>/dev/null ||
    git fetch -q "$canonical" "$S-green" 2>/dev/null ||
    git fetch -q "$canonical" "$S-fwd-green" 2>/dev/null || true
  git rev-parse -q --verify "refs/remotes/$canonical/main" >/dev/null && main_ref="refs/remotes/$canonical/main"
fi

# See scripts/series-advance.sh: the pathspec narrows the walk, the subject
# decides, and an empty answer explains itself on stderr.
vendored_sha() {
  local subjects sha n
  subjects=$(git log -n 20 --format=%s "$1" -- src/duckdb || true)
  sha=$(sed -nr 's/^.*duckdb.duckdb@([0-9a-f]+)( .*)?$/\1/p' <<<"$subjects" | head -n 1)
  if [ -z "$sha" ]; then
    n=$(grep -c . <<<"$subjects" || true)
    if [ "$n" -ge 20 ]; then
      echo "vendored_sha: 20 src/duckdb commits on $1, none of them vendoring;" >&2
      echo "  if that is genuine, raise the bound in this helper" >&2
    else
      echo "vendored_sha: no vendor commit among $n src/duckdb commits on $1" >&2
    fi
  fi
  echo "$sha"
}

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

# The GitHub repository a remote names, `owner/repo`, for `gh api`. The config
# key comes first so a fixture whose URL is a path can still name one.
github_slug() { # <remote> -> owner/repo | ""
  local slug url
  slug=$(git config "remote.$1.github" 2>/dev/null || true)
  if [ -z "$slug" ]; then
    url=$(git remote get-url "$1" 2>/dev/null || true)
    slug=$(sed -nr 's#^(https://|git@|ssh://git@)github\.com[:/]([^/]+/[^/]+?)(\.git)?/?$#\2#p' <<<"$url")
  fi
  echo "$slug"
}

# Open a draft pull request from <head> against <base> in the repository
# <remote> names, and close it at once. Printed, then done; a failure stops the
# run before anything is swapped, since the archive is what keeps the swap
# readable afterwards.
archive_pr() { # <remote> <head> <base> -> prints the pull request
  local r=$1 head=$2 base=$3 slug n body
  slug=$(github_slug "$r")
  [ -n "$slug" ] || {
    echo "Error: $r is not a GitHub remote, so $head cannot be archived there." >&2
    echo "  Set 'git config remote.$r.github <owner>/<repo>' or pass --no-archive." >&2
    exit 1
  }
  body="Archive of \`$head\` as it stood before the cutover of \`$S\` on $(date -u +%Y-%m-%d): \`$(git rev-parse "refs/remotes/$r/$head")\`.

The cutover moves \`$head\` onto the lineage of \`$base\`, which this history is no ancestor of. A pull request keeps its head reachable as \`refs/pull/<n>/head\` for as long as it exists, so this one is opened and closed on the spot and never merged (scripts/series-cutover.sh)."
  n=$("$gh" api -X POST "repos/$slug/pulls" -f title="chore(series): Archive $head before its cutover" \
    -f head="$head" -f base="$base" -F draft=true -f body="$body" --jq .number) || {
    echo "Error: could not open the archive pull request for $head in $slug" >&2
    exit 1
  }
  "$gh" api -X PATCH "repos/$slug/pulls/$n" -f state=closed --jq .number >/dev/null || {
    echo "Error: could not close the archive pull request $slug#$n" >&2
    exit 1
  }
  echo "  archived $head as $slug#$n (closed; its head is refs/pull/$n/head there)"
}

for r in build dev green build-base; do
  git rev-parse -q --verify "refs/remotes/$remote/$S-fwd-$r" >/dev/null ||
    { echo "Error: $S-fwd-$r does not exist on $remote"; exit 1; }
done

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

if git rev-parse -q --verify "refs/remotes/$remote/$S-green" >/dev/null; then
  old_up=$(vendored_sha "refs/remotes/$remote/$S-green")
else
  old_up=
fi
new_up=$(vendored_sha "refs/remotes/$remote/$S-fwd-green")
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
      echo "  The third argument is a path to a duckdb/duckdb clone, not a remote."
      exit 1
    }
    git -C "$upstream" merge-base --is-ancestor "$old_up" "$new_up" || {
      echo "Error: forward green does not cover old green; coverage would regress"
      exit 1
    }
  else
    echo "Warning: no upstream clone given, coverage gate not verified"
  fi
fi

# Convergence: the coverage gate above asks whether the forward has vendored far
# enough, which is a statement about how much upstream it reaches and none at all
# about what it carries. This asks the other half -- whether the two branches
# still hold the same package -- and prints it here so the operator confirms with
# it on screen. It reports rather than refuses: the invariant's second half is
# *explicable*, and whether a difference is explicable is a judgement no script
# can make -- which is why this prints and the human decides.
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
fi

leases=()
refspecs=()
echo "refs to swap:"
for r in build dev green build-base; do
  new=$(git rev-parse "refs/remotes/$remote/$S-fwd-$r")
  # An empty expected value leases the ref as "must not exist yet", which is
  # what a base ref from `missing` needs. The refspecs carry no leading `+`:
  # a forced refspec defeats --force-with-lease outright, and the lease alone
  # already authorizes the non-fast-forward swap.
  cur=$(git rev-parse -q --verify "refs/remotes/$remote/$S-$r") || cur=
  leases+=("--force-with-lease=refs/heads/$S-$r:$cur")
  refspecs+=("$new:refs/heads/$S-$r")
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
# so this names it and leaves the decision with the confirmation.
#
# On a preview line the fourth component never covers it: the prefix is pinned
# to the line being previewed rather than taken from `main`
# (scripts/preview-prefix.sh), so the forward keeps it and only the restarted
# counter differs. A version going back is normal there, and the warning says so.
#
# Without a GNU sort the versions are still printed and simply not compared:
# the swap is not worth blocking over a missing coreutils, and a comparison
# made with the wrong tool would read as a clean bill.
if [ -z "$gnu_sort" ]; then
  echo "Note: no GNU sort here, so the versions above were not compared."
  echo "  Read them: a $S-green version that does not move forward is an upgrade"
  echo "  r-universe cannot offer. Install GNU coreutils as 'gsort' -- on"
  echo "  macOS, 'brew install coreutils'."
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
# The stat here, the diff in --out, for a human to read before consumers are
# pointed at it. The exclusions are the files vendoring and the version
# bookkeeping regenerate, which a convergence read excludes for the same reason.
echo
[ -n "$out" ] || out=$(mktemp -d "${TMPDIR:-/tmp}/series-cutover-$S-XXXXXX")
mkdir -p "$out"
excludes=(':(exclude)src/duckdb' ':(exclude)R/version.R' ':(exclude)src/include/sources.mk'
  ':(exclude)src/Makevars' ':(exclude)src/Makevars.win' ':(exclude)man/figures' ':(exclude)DESCRIPTION'
  ':(exclude)NEWS.md' ':(exclude)README.Rmd' ':(exclude)README.md' ':(exclude).github/README.md')
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
    grep -qxF "$r" <<<"$(printf '%s\n' "${present[@]}")" || continue
    covered=
    for o in "${kept[@]}"; do
      if git merge-base --is-ancestor "refs/remotes/$remote/$S-$r" "refs/remotes/$remote/$S-$o"; then
        covered=$o
        break
      fi
    done
    [ -n "$covered" ] || { kept+=("$r"); archives+=("$remote $S-$r $S-fwd-$r"); }
  done
  if [ -n "$canonical" ] && git remote get-url "$canonical" >/dev/null 2>&1 &&
    git rev-parse -q --verify "refs/remotes/$canonical/$S-green" >/dev/null; then
    if git rev-parse -q --verify "refs/remotes/$canonical/$S-fwd-green" >/dev/null; then
      archives+=("$canonical $S-green $S-fwd-green")
    else
      archives+=("$canonical $S-green main")
    fi
  fi
fi
if [ ${#archives[@]} -gt 0 ]; then
  echo "archive pull requests, opened and closed before the swap:"
  for a in "${archives[@]}"; do
    read -r r head base <<<"$a"
    slug=$(github_slug "$r")
    echo "  $head -> $base in ${slug:-$r (not a GitHub remote: set remote.$r.github or pass --no-archive)}"
  done
  command -v "$gh" >/dev/null 2>&1 || echo "  ($gh is not installed; the swap will refuse without --no-archive)"
elif [ -n "$archive" ]; then
  echo "archive pull requests: none needed; nothing on $remote is replaced"
else
  echo "archive pull requests: skipped (--no-archive); the replaced history is reachable from nothing after the swap"
fi
echo

# The cleanup the swap leaves: the forward's refs, whose tips are the series'
# now, its derived strands and retry ledger, and the forward green's copy in the
# canonical repository. scripts/series-prune.sh lists whatever this could not
# delete.
leftovers=()
for r in build dev green build-base rc-dev alpha rc-alpha; do
  git rev-parse -q --verify "refs/remotes/$remote/$S-fwd-$r" >/dev/null && leftovers+=("$S-fwd-$r")
done
git rev-parse -q --verify "refs/remotes/$remote/retry-$S-fwd-dev" >/dev/null && leftovers+=("retry-$S-fwd-dev")
echo "deleted after the swap: ${leftovers[*]} on $remote"
canon_fwd=
if [ -n "$canonical" ] && git rev-parse -q --verify "refs/remotes/$canonical/$S-fwd-green" >/dev/null; then
  canon_fwd=1
  echo "                        $S-fwd-green on $canonical"
fi

if [ -n "$prepare" ]; then
  echo
  echo "Prepared; nothing was opened, pushed or deleted. Run without --prepare, from a terminal, to cut over."
  exit 0
fi

# The gate above says the swap is allowed; this asks whether it is wanted. It
# comes last so the operator confirms with the coverage lines, the package
# versions and the four ref moves on screen, and it takes the series name
# rather than a keystroke because the mistake worth catching is cutting over
# the wrong series.
echo
printf 'Replace series %s with %s-fwd-*? Type the series name to confirm: ' "$S" "$S"
read -r confirm
[ "$confirm" = "$S" ] || { echo "Aborted; nothing was pushed."; exit 1; }

# Archive first: a pull request moves no ref, and a failure here leaves the
# series exactly as it was.
if [ ${#archives[@]} -gt 0 ]; then
  command -v "$gh" >/dev/null 2>&1 || {
    echo "Error: $gh is not installed, so nothing can be archived; pass --no-archive to swap anyway." >&2
    exit 1
  }
  echo "archiving:"
  for a in "${archives[@]}"; do
    read -r r head base <<<"$a"
    archive_pr "$r" "$head" "$base"
  done
fi

git push --atomic "${leases[@]}" "$remote" "${refspecs[@]}"
if [ ${#missing[@]} -eq 4 ]; then
  echo "Series $S created from its forward counterpart."
else
  echo "Series $S replaced by its forward counterpart."
fi

# The canonical repository carries a copy of green for r-universe to publish
# from, and the swap just moved green onto a lineage the old one is no more an
# ancestor of. This is the only place that copy is forced: the loop's own mirror
# is fast-forward only and would stop the next firing on exactly this
# divergence. After the swap, never before, so the canonical copy is never ahead
# of the fork -- and under a lease, so a green nobody here wrote is not
# overwritten silently. The forward's copy there goes with the fork's `-fwd`
# refs: its tip is `<S>-green` now.
if [ -n "$canonical" ]; then
  new_green=$(git rev-parse "refs/remotes/$remote/$S-fwd-green")
  git fetch -q "$canonical" "$S-green" 2>/dev/null || true
  cur=$(git rev-parse -q --verify FETCH_HEAD) || cur=
  if [ "$cur" = "$new_green" ]; then
    echo "canonical $S-green already at $(git rev-parse --short "$new_green")"
  elif git push --force-with-lease="refs/heads/$S-green:$cur" \
      "$canonical" "$new_green:refs/heads/$S-green"; then
    echo "canonical $S-green -> $(git rev-parse --short "$new_green")"
  else
    echo "Warning: could not move $S-green in $canonical; r-universe still" >&2
    echo "  publishes the pre-cutover lineage until it is moved by hand." >&2
  fi
  if [ -n "$canon_fwd" ] && ! git push "$canonical" ":refs/heads/$S-fwd-green"; then
    echo "Warning: could not delete $S-fwd-green in $canonical; scripts/series-prune.sh $S lists it" >&2
  fi
fi

# Best-effort: some git proxies refuse deletions. Until these refs are gone,
# the loop ignores a forward series whose refs equal its base series, and
# scripts/series-prune.sh prints the deletion for a human.
dels=()
for r in "${leftovers[@]}"; do dels+=(":refs/heads/$r"); done
if [ ${#dels[@]} -gt 0 ] && ! git push "$remote" "${dels[@]}"; then
  echo "Warning: could not delete ${leftovers[*]} on $remote; remove them via the forge UI," >&2
  echo "  or from the commands scripts/series-prune.sh $S prints" >&2
fi
echo "Re-cut the derived strands from the swapped-in series where it had them:"
echo "  scripts/series-rc.sh $S --push, scripts/series-alpha.sh $S --push (.claude/skills/series-rc, series-alpha)."
