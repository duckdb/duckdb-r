#!/bin/bash
# Read-only: what a cutover left behind, and the commands that remove it, for a
# human to run.
#
# A cutover swaps the four `<S>-fwd-*` refs into the series' place and then
# deletes them, together with the forward's derived strands, its retry ledger
# and the forward green's copy in the canonical repository
# (scripts/series-cutover.sh). The deletions are best effort: a git proxy may
# refuse them, a run may be interrupted after the swap, and an older cutover
# predates the derived strands. What stays is cutover litter -- refs whose tips
# the series' own refs reach, or strands derived from a `-dev` that no longer
# exists -- which the loop ignores and nobody reads.
#
# The test is ancestry: a forward whose green is an ancestor of the series'
# green has been swapped in (the series moves on afterwards, so equality cannot
# be the test, as scripts/series-check.sh says). A forward whose green is not
# is live, and nothing of it is offered. Where no `<S>-fwd-dev` exists at all,
# every remaining `<S>-fwd-*` ref and the ledger are litter by definition.
#
# Nothing here is lost by deletion: the replaced lineages are the heads of the
# closed archive pull requests the cutover opened, the forward's tips are the
# series' refs, and the derived strands are recomputed from `<S>-dev`
# (scripts/series-rc.sh, scripts/series-alpha.sh). Nothing here deletes
# anything either: the commands are printed, and a human runs them.
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

canon_has_fwd=
if [ -n "$canonical" ] && git remote get-url "$canonical" >/dev/null 2>&1; then
  if git fetch -q "$canonical" "$S-fwd-green" 2>/dev/null; then canon_has_fwd=1; fi
fi

echo "=== $S on $remote: green $(git rev-parse --short "refs/remotes/$remote/$S-green")"
fwd_refs=()
for r in build dev green build-base rc-dev alpha rc-alpha; do
  have "$remote" "$S-fwd-$r" && fwd_refs+=("$S-fwd-$r")
done
have "$remote" "retry-$S-fwd-dev" && fwd_refs+=("retry-$S-fwd-dev")

if [ ${#fwd_refs[@]} -eq 0 ] && [ -z "$canon_has_fwd" ]; then
  echo "  no $S-fwd-* ref on $remote${canonical:+ or $canonical}; nothing to prune"
  exit 0
fi

litter=
if have "$remote" "$S-fwd-green"; then
  if git merge-base --is-ancestor "refs/remotes/$remote/$S-fwd-green" "refs/remotes/$remote/$S-green"; then
    echo "  $S-fwd-green $(git rev-parse --short "refs/remotes/$remote/$S-fwd-green") is an ancestor of $S-green: the forward was swapped in"
    litter=1
  else
    echo "  $S-fwd-green $(git rev-parse --short "refs/remotes/$remote/$S-fwd-green") is not an ancestor of $S-green: the forward is live"
  fi
elif have "$remote" "$S-fwd-dev"; then
  if git merge-base --is-ancestor "refs/remotes/$remote/$S-fwd-dev" "refs/remotes/$remote/$S-dev"; then
    echo "  $S-fwd-dev is an ancestor of $S-dev, and no $S-fwd-green exists: the forward was swapped in"
    litter=1
  else
    echo "  $S-fwd-dev is not an ancestor of $S-dev: the forward is live, though it has no green"
  fi
else
  echo "  no $S-fwd-dev exists: whatever is named $S-fwd-* is derived from nothing"
  litter=1
fi

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
echo "The replaced lineages are the heads of the archive pull requests the cutover opened,"
echo "and the derived strands are recomputed by scripts/series-rc.sh and series-alpha.sh,"
echo "so the deletion loses nothing. To run by hand:"
if [ ${#fwd_refs[@]} -gt 0 ]; then
  printf 'git push --delete %s' "$remote"
  printf ' %s' "${fwd_refs[@]}"
  echo
fi
[ -z "$canon_has_fwd" ] || echo "git push --delete $canonical $S-fwd-green"
echo "Nothing above was run."
