#!/bin/bash
# Read-only: which generations of a line may go, and the commands that retire
# them, for a human to run.
#
# A generation is never rewritten, and a cutover deletes nothing
# (scripts/series-cutover.sh), so generations accumulate: the line's first
# refs, `-fwd` or `-v000`, `-v001`, and so on. The loop serves a generation while
# it is one of its line's two newest or the one r-universe publishes, and
# everything else is frozen (scripts/series-lib.sh, series_served). A frozen
# generation costs refs in two repositories and an entry in the fork's universe,
# and buys nothing once a newer generation has been published: its history is in
# that generation by construction, replayed commit for commit
# (.claude/skills/series-forward/SKILL.md).
#
# So a generation may be pruned when it is frozen and older than the published
# one. A frozen generation newer than the published one is superseded too, but
# it may be the one about to be published, so it is listed and not offered.
# Nothing here deletes anything: the commands are printed, and a human runs
# them, after the two checks the script cannot make -- that no landing is being
# built from the generation (scripts/series-land.sh keeps that state in a clone),
# and that the fork's universe no longer names its green.
#
# What goes, per generation: its four refs, the rc and alpha strands derived
# from it, its retry ledger, in the fork; its green's copy in the canonical
# repository; and first, where an archive remote is named, a copy of every one
# of them there, so the commits stay reachable (handbook/branches/model/README.md).
#
# Usage: series-prune.sh <line> [--remote <name>] [--canonical <name>] [--archive <name>]
#   series-prune.sh v2.0-cyanoptera
#   --remote    the remote carrying the series refs; default `origin`.
#   --canonical the canonical repository, where `main` declares what is published
#               and where the green's copy lives; default `upstream`.
#   --archive   a remote of the archive, krlmlr/duckdb-r-old, that the refs are
#               pushed to before they are deleted; default `archive`, or
#               $SERIES_ARCHIVE. Without one the archive push is printed as a
#               step to arrange rather than a command to run.
#
# The options are spelled the same in every scripts/series-*.sh; see the shared
# contract in handbook/operations/vendoring/series-loop/README.md.
#
# Exit status: 0, whatever it finds; 2 on a usage or lookup error.

set -euo pipefail
# shellcheck source=series-lib.sh
. "$(dirname "$0")/series-lib.sh"

usage='usage: series-prune.sh <line> [--remote <name>] [--canonical <name>] [--archive <name>]'
argerr() { echo "$usage" >&2; exit 2; }
remote=${SERIES_REMOTE:-origin}
canonical=${SERIES_CANONICAL-upstream}
archive=${SERIES_ARCHIVE-archive}
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --canonical) [ $# -ge 2 ] || argerr; canonical=$2; shift 2 ;;
    --archive) [ $# -ge 2 ] || argerr; archive=$2; shift 2 ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
line=${args[0]}
[ -z "$(series_gen "$line")" ] || { echo "Error: $line is a generation; name its line, $(series_line "$line")" >&2; exit 2; }

git fetch -q "$remote"
main_ref=''
if [ -n "$canonical" ] && git remote get-url "$canonical" >/dev/null 2>&1; then
  git fetch -q "$canonical" main 2>/dev/null || true
  git rev-parse -q --verify "refs/remotes/$canonical/main" >/dev/null && main_ref="refs/remotes/$canonical/main"
fi
[ -n "$main_ref" ] || main_ref="refs/remotes/$remote/main"

mapfile -t gens < <(series_generations "$line" "$remote")
[ ${#gens[@]} -gt 0 ] || { echo "Error: no generation of $line on $remote" >&2; exit 2; }
published=$(series_published "$main_ref" "$line")
pub_gen=$(series_gen "${published:-$line}")
[ -n "$pub_gen" ] || pub_gen=-1

echo "=== generations of $line on $remote, newest first"
prunable=()
for g in "${gens[@]}"; do
  n=$(series_gen "$g"); [ -n "$n" ] || n=-1
  state=served
  if [ "$g" = "$published" ]; then
    state="served, published by $(series_yaml_field "$main_ref" "$line" flavor)"
  elif ! series_served "$g" "$remote" "$published"; then
    if [ "$n" -lt "$pub_gen" ]; then
      state="frozen, older than the published generation: may be pruned"
      prunable+=("$g")
    else
      state="frozen, newer than the published generation: superseded, kept until something newer is published"
    fi
  fi
  printf '  %-28s %s  %s\n' "$g" "$(git rev-parse --short "refs/remotes/$remote/$g-green" 2>/dev/null || echo '       ')" "$state"
done
[ -n "$published" ] || echo "  (scripts/series.yaml on main publishes $line from no generation; nothing is prunable until it does)"
echo

if [ ${#prunable[@]} -eq 0 ]; then
  echo "Nothing to prune."
  exit 0
fi

echo "Before running anything below, check by hand what this cannot:"
echo "  * no landing is being built from a listed generation (scripts/series-land.sh keeps that in a clone);"
echo "  * the fork's universe, krlmlr.r-universe.dev, no longer names a listed green in packages.json."
echo

for g in "${prunable[@]}"; do
  refs=()
  for r in build dev green build-base rc-dev alpha rc-alpha; do
    git rev-parse -q --verify "refs/remotes/$remote/$g-$r" >/dev/null && refs+=("$g-$r")
  done
  git rev-parse -q --verify "refs/remotes/$remote/retry-$g-dev" >/dev/null && refs+=("retry-$g-dev")
  echo "# $g: ${#refs[@]} ref(s) on $remote"
  if [ -n "$archive" ] && git remote get-url "$archive" >/dev/null 2>&1; then
    printf 'git push %s' "$archive"
    for r in "${refs[@]}"; do printf ' %s:refs/heads/%s' "refs/remotes/$remote/$r" "$r"; done
    echo
  else
    echo "# first, push these refs to the archive (krlmlr/duckdb-r-old), which has no remote here:"
    printf '#   %s\n' "${refs[@]}"
  fi
  printf 'git push --delete %s' "$remote"
  printf ' %s' "${refs[@]}"
  echo
  if [ -n "$canonical" ] && git remote get-url "$canonical" >/dev/null 2>&1 &&
    [ -n "$(git ls-remote "$canonical" "refs/heads/$g-green" | cut -f1)" ]; then
    echo "git push --delete $canonical $g-green"
  fi
  echo
done
echo "Nothing above was run."
