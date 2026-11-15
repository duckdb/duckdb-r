#!/bin/bash
# Read-only: what a cutover left behind, and the commands that remove it, for a
# human to run.
#
# A cutover swaps the four `<S>-fwd-*` refs into the series' place and then
# deletes them, together with the forward's vendor strand, its derived strands,
# its retry ledger and the forward green's copy in the canonical repository
# (scripts/series-cutover.sh). The deletions are best effort: a git proxy may
# refuse them, a run may be interrupted after the swap, and an older cutover
# predates the derived strands. What stays is cutover litter -- refs whose tips
# the series' own refs reach, or strands derived from a `-dev` that no longer
# exists -- which the loop ignores and nobody reads.
#
# The test is ancestry, the forward's green against the series' green or, where that green tells nothing,
# its `-dev` against the series' `-dev`, as scripts/series-check.sh reads it too (`series_fwd_swapped`, scripts/series-lib.sh).
# A forward the series' refs do not reach is live, and nothing of it is offered.
# Where no `<S>-fwd-dev` exists at all,
# every remaining `<S>-fwd-*` ref and the ledger are litter by definition.
#
# Nothing here is lost by deletion:
# the replaced lineages and the vendor strand are under the heads of the stacks' first pull requests,
# which pin them (scripts/series-cutover-stack.sh),
# the forward's tips are the series' refs,
# and the derived strands are recomputed from `<S>-dev` (scripts/series-rc.sh, scripts/series-alpha.sh).
# Nothing here deletes anything either: the commands are printed, and a person or a session runs them, in two forms,
# each leased on or checked against the tip read here, so a ref that moved since is refused:
# one `git push` per repository, and, for a remote on GitHub,
# one line per ref, for where git may not delete at all, as in a cloud session, whose git proxy refuses it:
# a dispatch of .github/workflows/delete-branch.yaml, for a session, where the workflow can prove the deletion safe:
# for a `-fwd-` ref whose twin, the same name without the `fwd-`, is at its tip, as litter is right after a swap,
# or where a closed pull request's head is the ref's tip;
# and otherwise, as for litter whose series ref has moved on since, a `gh api -X DELETE` that checks the tip first,
# for a maintainer's shell (`series_delete_line`, scripts/series-lib.sh).
# The second is the form scripts/series-cutover.sh prints for what its own deletion left.
#
# Usage: series-prune.sh <series> [--remote <name>] [--canonical <name>]
#   series-prune.sh v2.0-cyanoptera
#   --remote    the remote carrying the series refs; default `origin`.
#   --canonical the canonical repository, which carries a copy of every green;
#               default `upstream`.
#
# The options are spelled the same in every scripts/series-*.sh; see the shared
# contract in handbook/operations/vendoring/series-loop/README.md.
#
# Exit status: 0, whatever it finds; 2 on a usage or lookup error.

set -euo pipefail
# shellcheck source=series-lib.sh
. "$(dirname "$0")/series-lib.sh"

usage='usage: series-prune.sh <series> [--remote <name>] [--canonical <name>]'
argerr() { echo "$usage" >&2; exit 2; }
remote=${SERIES_REMOTE:-origin}
canonical=${SERIES_CANONICAL-upstream}
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --canonical) [ $# -ge 2 ] || argerr; canonical=$2; shift 2 ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
S=${args[0]}
case "$S" in
  *-fwd) echo "Error: $S is a forward; name the series it forwards, ${S%-fwd}" >&2; exit 2 ;;
esac

git fetch -q "$remote"
have() { git rev-parse -q --verify "refs/remotes/$1/$2^{commit}" >/dev/null 2>&1; }
have "$remote" "$S-green" || { echo "Error: $S-green does not exist on $remote" >&2; exit 2; }

canon_has_fwd='' canon_tip=''
if [ -n "$canonical" ] && git remote get-url "$canonical" >/dev/null 2>&1; then
  if git fetch -q "$canonical" "$S-fwd-green" 2>/dev/null; then canon_has_fwd=1 canon_tip=$(git rev-parse FETCH_HEAD); fi
fi

echo "=== $S on $remote: green $(git rev-parse --short "refs/remotes/$remote/$S-green")"
fwd_refs=()
for r in build dev green build-base vendor rc-dev alpha rc-alpha; do
  have "$remote" "$S-fwd-$r" && fwd_refs+=("$S-fwd-$r")
done
have "$remote" "retry-$S-fwd-dev" && fwd_refs+=("retry-$S-fwd-dev")

if [ ${#fwd_refs[@]} -eq 0 ] && [ -z "$canon_has_fwd" ]; then
  echo "  no $S-fwd-* ref on $remote${canonical:+ or $canonical}; nothing to prune"
  exit 0
fi

litter='' fwd_green='' fwd_dev=''
if have "$remote" "$S-fwd-green"; then fwd_green=refs/remotes/$remote/$S-fwd-green; fi
if have "$remote" "$S-fwd-dev"; then fwd_dev=refs/remotes/$remote/$S-fwd-dev; fi
if by=$(series_fwd_swapped "$fwd_green" "$fwd_dev" "refs/remotes/$remote/$S-green" "refs/remotes/$remote/$S-dev"); then
  litter=1
fi
case "$by" in
  green)
    if [ -n "$litter" ]; then
      echo "  $S-fwd-green $(git rev-parse --short "$fwd_green") is an ancestor of $S-green: the forward was swapped in"
    else
      echo "  $S-fwd-green $(git rev-parse --short "$fwd_green") is not an ancestor of $S-green: the forward is live"
    fi
    ;;
  dev)
    green_said=", and no $S-fwd-green exists" live_said=", though it has no green"
    if [ -n "$fwd_green" ]; then
      echo "  $S-fwd-green $(git rev-parse --short "$fwd_green") sits below the seed of $S-fwd-dev, as at the forward's birth, which tells nothing"
      green_said='' live_said=''
    fi
    if [ -n "$litter" ]; then
      echo "  $S-fwd-dev is an ancestor of $S-dev$green_said: the forward was swapped in"
    else
      echo "  $S-fwd-dev is not an ancestor of $S-dev: the forward is live$live_said"
    fi
    ;;
  *) echo "  no $S-fwd-dev exists: whatever is named $S-fwd-* is derived from nothing" ;;
esac

if [ -z "$litter" ]; then
  echo "  live forward: ${fwd_refs[*]}"
  echo "Nothing to prune."
  exit 0
fi

echo
echo "cutover litter:"
printf '  %s\n' "${fwd_refs[@]}"
[ -z "$canon_has_fwd" ] || echo "  $S-fwd-green on $canonical"
echo
echo "The replaced lineages are under the heads of the stacks' first pull requests,"
echo "and the derived strands are recomputed by scripts/series-rc.sh and series-alpha.sh,"
echo "so the deletion loses nothing. To run by hand:"
# Each deletion is leased on the tip read here, so a ref that moved since is refused rather than deleted.
tip_of() { git rev-parse "refs/remotes/$remote/$1"; }
if [ ${#fwd_refs[@]} -gt 0 ]; then
  printf 'git push'
  for r in "${fwd_refs[@]}"; do printf ' --force-with-lease=refs/heads/%s:%s' "$r" "$(tip_of "$r")"; done
  printf ' %s' "$remote"
  printf ' :refs/heads/%s' "${fwd_refs[@]}"
  echo
fi
[ -z "$canon_has_fwd" ] ||
  echo "git push --force-with-lease=refs/heads/$S-fwd-green:$canon_tip $canonical :refs/heads/$S-fwd-green"
gh_lines=()
if [ -n "$(series_github_slug "$remote")" ]; then
  series_delete_listing "$remote"
  for r in "${fwd_refs[@]}"; do gh_lines+=("$(series_delete_line "$remote" "$r" "$(tip_of "$r")")"); done
fi
if [ -n "$canon_has_fwd" ] && [ -n "$(series_github_slug "$canonical")" ]; then
  series_delete_listing "$canonical"
  gh_lines+=("$(series_delete_line "$canonical" "$S-fwd-green" "$canon_tip")")
fi
if [ ${#gh_lines[@]} -gt 0 ]; then
  echo "or, where git may not delete, one line per ref: a dispatch of the deletion workflow, for a session, where the"
  echo "ref's twin without its fwd- or a pull request's head is at its tip, else a deletion that checks the tip first,"
  echo "for a maintainer's shell:"
  printf '%s\n' "${gh_lines[@]}"
fi
echo "Nothing above was run."
