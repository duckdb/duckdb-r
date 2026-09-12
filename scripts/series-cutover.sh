#!/bin/bash
# Atomically replace a series with its forward counterpart.
#
# A forward series <S>-fwd-* is the same series rebuilt on a newer `main`
# (.claude/skills/series-forward.md). Once its green ref covers at least the
# upstream commits the old green covered, this script swaps all four series
# refs in one atomic push, so consumers of <S>-green never observe a
# half-replaced series. The swap is the one sanctioned non-fast-forward move
# of a green ref.
#
# It is also the one move the series loop never makes: the loop reports a ready
# cutover and stops (.claude/skills/series-loop.md), because retiring the
# lineage r-universe builds from is a decision, not a stage. This script is the
# mechanical half of that rule — it runs from a terminal, on a typed
# confirmation, and nowhere else.
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
# Usage: series-cutover.sh <series> [remote] [upstream-clone]
#   series-cutover.sh main origin ../duckdb
#
# The upstream clone is needed for the coverage gate (an ancestry check
# between vendored upstream SHAs); without it the gate degrades to a warning.

set -euo pipefail

S=${1:?usage: series-cutover.sh <series> [remote] [upstream-clone]}
remote=${2:-origin}
upstream=${3:-}

# Fail before the fetch, not after it: an unattended firing has no terminal, so
# there is nothing for it to confirm with and no reason to do any work first.
if [ ! -t 0 ] || [ ! -t 1 ]; then
  echo "Error: cutover is a manual operation; run this script from a terminal." >&2
  echo "  The series loop reports a ready cutover and stops; a human runs it." >&2
  echo "  See .claude/skills/series-forward.md and series-loop.md." >&2
  exit 1
fi

git fetch -q "$remote"

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
  gnu_sort=gsort
else
  gnu_sort=sort
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

for r in build dev green build-base; do
  git rev-parse -q --verify "refs/remotes/$remote/$S-fwd-$r" >/dev/null ||
    { echo "Error: $S-fwd-$r does not exist on $remote"; exit 1; }
done

# A base series ref may legitimately be missing: a series started as -fwd has
# no counterpart to replace, and the cutover creates the ref rather than
# swapping it. Only the forward refs are required.
missing=()
for r in build dev green build-base; do
  git rev-parse -q --verify "refs/remotes/$remote/$S-$r" >/dev/null ||
    missing+=("$S-$r")
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
"$(dirname "$0")/series-converge.sh" "$S" "$remote" --no-fetch || rc=$?
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
# one cost that nothing else on screen shows. `<S>-dev` is what r-universe
# builds, so its version is the one consumers are offered, and the replay's
# renumbering starts the fifth component well below what the base series
# accumulated. Usually the fourth component covers it, because the forward is
# seeded on a newer `main` whose version has moved on since; where it does not,
# r-universe has nothing to offer as an upgrade until the new chain's counter
# climbs past the old one's. That is a cost rather than a corruption, and
# whether it is worth paying is a judgement, so this names it and leaves the
# decision with the confirmation.
#
# Without a GNU sort the versions are still printed and simply not compared:
# the swap is not worth blocking over a missing coreutils, and a comparison
# made with the wrong tool would read as a clean bill.
if [ -z "$gnu_sort" ]; then
  echo "Note: no GNU sort here, so the versions above were not compared."
  echo "  Read them: a $S-dev version that does not move forward is an upgrade"
  echo "  r-universe cannot offer. Install GNU coreutils as 'gsort' -- on"
  echo "  macOS, 'brew install coreutils'."
else
  for r in dev green; do
    oldv=$(desc_field "refs/remotes/$remote/$S-$r" Version)
    newv=$(desc_field "refs/remotes/$remote/$S-fwd-$r" Version)
    [ -n "$oldv" ] && [ -n "$newv" ] || continue
    case "$(version_cmp "$oldv" "$newv")" in
      -1) continue ;;
      # Equal is the same problem wearing the other face: two different trees
      # published under one version, so whoever already has it never sees the
      # replacement at all.
      0) echo "Warning: $S-$r keeps version $oldv across the swap." ;;
      1) echo "Warning: $S-$r would go from $oldv back to $newv." ;;
    esac
    if [ "$r" = dev ]; then
      echo "  r-universe publishes from this ref and has no upgrade to offer"
      echo "  until the forward chain's counter passes $oldv."
    fi
  done
fi

# The gate above says the swap is allowed; this asks whether it is wanted. It
# comes last so the operator confirms with the coverage lines, the package
# versions and the four ref moves on screen, and it takes the series name
# rather than a keystroke because the mistake worth catching is cutting over
# the wrong series.
printf 'Replace series %s with %s-fwd-*? Type the series name to confirm: ' "$S" "$S"
read -r confirm
[ "$confirm" = "$S" ] || { echo "Aborted; nothing was pushed."; exit 1; }

git push --atomic "${leases[@]}" "$remote" "${refspecs[@]}"
if [ ${#missing[@]} -eq 4 ]; then
  echo "Series $S created from its forward counterpart."
else
  echo "Series $S replaced by its forward counterpart."
fi

# Best-effort: some git proxies refuse deletions. Until these refs are gone,
# the loop ignores a forward series whose refs equal its base series.
if ! git push "$remote" ":refs/heads/$S-fwd-build" ":refs/heads/$S-fwd-dev" \
    ":refs/heads/$S-fwd-green" ":refs/heads/$S-fwd-build-base"; then
  echo "Warning: could not delete $S-fwd-* refs; remove them via the forge UI"
fi
