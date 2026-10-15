#!/bin/bash
# Prepare a cutover: the pull requests that point r-universe at a newer
# generation's green, and the review of what that generation changed.
#
# A line is served by generations, `<L>`, `<L>-v000`, `<L>-v001` and so on, each
# the same series rebuilt on a newer `main` beside the one before it
# (.claude/skills/series-forward/SKILL.md, scripts/series-lib.sh). r-universe
# builds the package from one generation's green, the one `publishes_from` names
# in scripts/series.yaml and in the universe's `packages.json`. A cutover is
# changing that name: nothing is swapped, nothing is deleted, and no ref moves.
# The generation that was published stays where it is, and is pruned later by a
# human (scripts/series-prune.sh).
#
# This script moves no ref either. It gathers what the decision rests on and
# writes what the two pull requests change:
#
#   * the coverage gate: the new green vendors at least the upstream commit the
#     published green vendors, so verification never goes backwards. An ancestry
#     check in the upstream clone; without one it degrades to a warning;
#   * the convergence read against the generation this one was built from
#     (scripts/series-converge.sh), whose findings a cutover inherits rather
#     than resolves;
#   * the package on both sides: `Package:` and `Version:` of the two greens,
#     and a warning where the version would not move forward, since r-universe
#     installs by version and has no upgrade to offer until the new chain's
#     counter climbs past the old one's;
#   * whether the canonical repository carries the new green yet, which the
#     loop's firings mirror (scripts/series-advance.sh) and the universe needs;
#   * the review: everything the generation changed against current `main`
#     outside the engine -- the R side, `src/` outside `src/duckdb/`, the tests
#     and the patch stack -- as a stat here and as a full diff in --out, which is
#     what a reviewer reads before pointing consumers at it;
#   * the changes themselves: the `packages.json` entry for the universe that
#     publishes the flavor, and the `publishes_from` line of scripts/series.yaml,
#     which --apply writes into this checkout for the pull request against `main`.
#
# Usage: series-cutover.sh <generation> [--remote <name>] [--canonical <name>]
#                          [--upstream <path>] [--out <dir>] [--apply]
#   series-cutover.sh v2.0-cyanoptera-v001 --upstream ../../../duckdb
#
#   --remote <name>   a remote of *this* repository carrying the series refs;
#                     default `origin`, or $SERIES_REMOTE.
#   --canonical <name> the remote of the canonical repository, where `main` and
#                     scripts/series.yaml are read from and where r-universe
#                     reads the green; default `upstream`, or $SERIES_CANONICAL.
#   --upstream <path> a `duckdb/duckdb` checkout on disk, for the coverage gate.
#                     Never a remote name, whatever it is called.
#   --out <dir>       where the review diff and the two changes are written;
#                     default a fresh temporary directory, named at the end.
#   --apply           rewrite `publishes_from` in scripts/series.yaml here and
#                     regenerate the flavor tables (scripts/series-table.R), for
#                     the pull request against `main`. Writes files, never refs.
#
# The options are spelled the same in every scripts/series-*.sh; see the shared
# contract in handbook/operations/vendoring/series-loop/README.md.
#
# Exit status: 0 when the cutover may be proposed, 1 when the gate refuses it,
# 2 on a usage or lookup error.

set -euo pipefail
# shellcheck source=series-lib.sh
. "$(dirname "$0")/series-lib.sh"

usage='usage: series-cutover.sh <generation> [--remote <name>] [--canonical <name>] [--upstream <path>] [--out <dir>] [--apply]'
argerr() { echo "$usage" >&2; exit 2; }
remote=${SERIES_REMOTE:-origin}
canonical=${SERIES_CANONICAL-upstream}
upstream=${UPSTREAM_CLONE:-}
out='' apply=''
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --canonical) [ $# -ge 2 ] || argerr; canonical=$2; shift 2 ;;
    --upstream) [ $# -ge 2 ] || argerr; upstream=$2; shift 2 ;;
    --out) [ $# -ge 2 ] || argerr; out=$2; shift 2 ;;
    --apply) apply=1; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
S=${args[0]}
here=$(cd "$(dirname "$0")" && pwd)
cd "$(git rev-parse --show-toplevel)"

[ -n "$(series_gen "$S")" ] || {
  echo "Error: $S is a line's first refs, not a generation; name the generation to publish" >&2
  exit 2
}
line=$(series_line "$S")

git fetch -q "$remote"
# `main` and the declaration are the canonical repository's; the fork's mirror
# may lag by a cycle (handbook/branches/mirrors/README.md).
main_ref=''
if [ -n "$canonical" ] && git remote get-url "$canonical" >/dev/null 2>&1; then
  git fetch -q "$canonical" main 2>/dev/null || true
  git rev-parse -q --verify "refs/remotes/$canonical/main" >/dev/null && main_ref="refs/remotes/$canonical/main"
fi
if [ -z "$main_ref" ]; then
  echo "Warning: could not read main from '$canonical'; reading the fork's mirror" >&2
  main_ref="refs/remotes/$remote/main"
fi

for r in build dev green build-base; do
  git rev-parse -q --verify "refs/remotes/$remote/$S-$r" >/dev/null ||
    { echo "Error: $S-$r does not exist on $remote" >&2; exit 2; }
done

flavor=$(series_yaml_field "$main_ref" "$line" flavor)
[ -n "$flavor" ] || { echo "Error: scripts/series.yaml on main declares no flavor for the line $line" >&2; exit 2; }
published=$(series_published "$main_ref" "$line")
[ -n "$published" ] || { echo "Error: the flavor $flavor publishes from no generation of $line" >&2; exit 2; }
repo=$(series_yaml_field "$main_ref" "$line" repo)
if [ "$published" = "$S" ]; then
  echo "$flavor already publishes from $S-green; nothing to cut over."
  exit 0
fi

# See scripts/series-advance.sh: the pathspec narrows the walk, the subject
# decides, and an empty answer explains itself on stderr.
base_scan_depth="${BASE_SCAN_DEPTH:-20}"
vendored_sha() {
  local subjects sha n
  subjects=$(git log -n "$base_scan_depth" --format=%s "$1" -- src/duckdb || true)
  sha=$(sed -nr 's/^.*duckdb.duckdb@([0-9a-f]+)( .*)?$/\1/p' <<<"$subjects" | head -n 1)
  if [ -z "$sha" ]; then
    n=$(grep -c . <<<"$subjects" || true)
    if [ "$n" -ge "$base_scan_depth" ]; then
      echo "vendored_sha: $base_scan_depth src/duckdb commits on $1, none of them vendoring;" >&2
      echo "  if that is genuine, raise BASE_SCAN_DEPTH" >&2
    else
      echo "vendored_sha: no vendor commit among $n src/duckdb commits on $1" >&2
    fi
  fi
  echo "$sha"
}
desc_field() { git show "$1:DESCRIPTION" 2>/dev/null | sed -n "s/^$2: *//p" | head -n 1 || true; }

# GNU sort, wherever it is called: on Linux that is `sort`, on macOS it is
# `gsort` and the system `sort` is BSD's. Empty when neither is GNU, which is a
# comparison not made rather than a wrong one.
if command -v gsort >/dev/null 2>&1; then gnu_sort='gsort'; else gnu_sort='sort'; fi
case "$("$gnu_sort" --version 2>/dev/null || true)" in *"GNU coreutils"*) ;; *) gnu_sort= ;; esac
version_cmp() { # <a> <b> -> -1, 0, 1
  local sorted
  [ "$1" != "$2" ] || { printf '%s\n' 0; return; }
  sorted=$(printf '%s\n%s\n' "$1" "$2" | "$gnu_sort" -V)
  if [ "${sorted%%$'\n'*}" = "$1" ]; then printf '%s\n' -1; else printf '%s\n' 1; fi
}

old_green="refs/remotes/$remote/$published-green"
new_green="refs/remotes/$remote/$S-green"
git rev-parse -q --verify "$old_green" >/dev/null ||
  { echo "Error: $published-green, the published green, does not exist on $remote" >&2; exit 2; }

echo "=== cutover of $flavor: $published -> $S"
echo

rc=0
# --- coverage -----------------------------------------------------------------
old_up=$(vendored_sha "$old_green")
new_up=$(vendored_sha "$new_green")
echo "published green $published-green $(git rev-parse --short "$old_green") vendors ${old_up:-<nothing>}"
echo "next green      $S-green $(git rev-parse --short "$new_green") vendors ${new_up:-<nothing>}"
if [ -n "$old_up" ]; then
  if [ -z "$new_up" ]; then
    echo "REFUSED: the published green vendors $old_up and the next green vendors nothing"
    exit 1
  fi
  if [ -n "$upstream" ]; then
    git -C "$upstream" rev-parse --git-dir >/dev/null 2>&1 || {
      echo "Error: $upstream is not a git checkout; --upstream is a path to a duckdb/duckdb clone, not a remote" >&2
      exit 2
    }
    if git -C "$upstream" merge-base --is-ancestor "$old_up" "$new_up"; then
      echo "coverage: the next green covers the published one"
    else
      echo "REFUSED: $S-green does not cover $published-green; coverage would regress"
      exit 1
    fi
  else
    echo "Warning: no upstream clone given, coverage not verified; pass --upstream <path>"
  fi
fi
echo

# --- convergence ---------------------------------------------------------------
# What the two generations carry, against the one this was built from: a
# difference is inherited by the cutover, never resolved by it.
"$here/series-converge.sh" "$S" --remote "$remote" --no-fetch || rc=$?
if [ "$rc" -eq 1 ]; then
  echo "  ^ a cutover inherits these onto the lineage r-universe builds from."
  rc=0
elif [ "$rc" -ne 0 ]; then
  exit "$rc"
fi
echo

# --- the package on both sides ----------------------------------------------
old_pkg=$(desc_field "$old_green" Package); new_pkg=$(desc_field "$new_green" Package)
oldv=$(desc_field "$old_green" Version); newv=$(desc_field "$new_green" Version)
echo "package: ${old_pkg:-<none>} ${oldv:--}  ->  ${new_pkg:-<none>} ${newv:--}"
[ "$old_pkg" = "$new_pkg" ] || echo "  ^ the name changes, and r-universe would publish a different package"
if [ -n "$gnu_sort" ] && [ -n "$oldv" ] && [ -n "$newv" ]; then
  case "$(version_cmp "$oldv" "$newv")" in
    0) echo "Warning: the version does not move; whoever has $oldv never sees the replacement" ;;
    1) echo "Warning: the version goes back, from $oldv to $newv; r-universe has no upgrade to offer"
       echo "  until the new chain's counter passes $oldv. Normal on a preview line, whose prefix is pinned." ;;
  esac
fi
echo

# --- the canonical copy ------------------------------------------------------
# r-universe builds from the canonical repository, where the loop mirrors every
# generation's green (scripts/series-advance.sh); the pull request names a
# branch that has to be there.
if [ -n "$canonical" ] && git remote get-url "$canonical" >/dev/null 2>&1; then
  canon=$(git ls-remote "$canonical" "refs/heads/$S-green" | cut -f1)
  if [ -z "$canon" ]; then
    echo "canonical: $S-green is not in $canonical yet; the next firing mirrors it, or push it plainly:"
    echo "  git push $canonical $(git rev-parse "$new_green"):refs/heads/$S-green"
  elif [ "$canon" = "$(git rev-parse "$new_green")" ]; then
    echo "canonical: $S-green is at $(git rev-parse --short "$new_green") in $canonical, level with the fork"
  else
    echo "canonical: $S-green is at ${canon:0:10} in $canonical, behind the fork's $(git rev-parse --short "$new_green"); the next firing fast-forwards it"
  fi
  echo
fi

# --- the review ---------------------------------------------------------------
# Everything the generation changed against today's `main`, engine aside: the
# glue, the R side, the tests and the patch stack. The generation's seed is a
# recent `main`, so this is the series' own work, which a reviewer reads before
# consumers are pointed at it. The stat here, the diff in --out.
[ -n "$out" ] || out=$(mktemp -d "${TMPDIR:-/tmp}/series-cutover-$S-XXXXXX")
mkdir -p "$out"
excludes=(':(exclude)src/duckdb' ':(exclude)R/version.R' ':(exclude)src/include/sources.mk'
  ':(exclude)src/Makevars' ':(exclude)src/Makevars.win' ':(exclude)man/figures' ':(exclude)DESCRIPTION'
  ':(exclude)NEWS.md' ':(exclude)README.Rmd' ':(exclude)README.md' ':(exclude).github/README.md')
echo "review: what $S-green changes against main $(git rev-parse --short "$main_ref"), outside the engine"
git diff --stat=100 "$main_ref" "$new_green" -- . "${excludes[@]}" | sed 's/^/  /'
git diff "$main_ref" "$new_green" -- . "${excludes[@]}" > "$out/review.diff"
git diff --stat=100 "$main_ref" "$new_green" -- . "${excludes[@]}" > "$out/review.stat"
echo "  full diff: $out/review.diff"
echo

# --- the two changes --------------------------------------------------------
universe=${repo%%/*}
cat > "$out/packages.json.change" <<EOF
In https://github.com/$universe/$universe.r-universe.dev, packages.json, the entry for $flavor:

  {"package": "$flavor", "url": "https://github.com/$repo", "branch": "$S-green"}

was:

  {"package": "$flavor", "url": "https://github.com/$repo", "branch": "$published-green"}
EOF
cat > "$out/series.yaml.change" <<EOF
In scripts/series.yaml on main, the entry for $flavor:

    publishes_from: $S-green

was:

    publishes_from: $published-green

then scripts/series-table.R and a README render regenerate the tables.
EOF
echo "the pull requests:"
echo "  1. $universe/$universe.r-universe.dev: $out/packages.json.change"
echo "  2. $repo, against main: $out/series.yaml.change"
if [ -n "$apply" ]; then
  python3 - "$line" "$S-green" <<'PY'
import re, sys
line, new = sys.argv[1], sys.argv[2]
p = 'scripts/series.yaml'
s = open(p).read()
entries = re.split(r'(?m)^(?=  - )', s)
for i, e in enumerate(entries):
    if re.search(r'(?m)^    series: ' + re.escape(line) + r'$', e):
        entries[i] = re.sub(r'(?m)^    publishes_from: .*$', '    publishes_from: ' + new, e)
open(p, 'w').write(''.join(entries))
PY
  "$here/series-table.R" >/dev/null 2>&1 || echo "  (scripts/series-table.R could not run here; regenerate the tables before the pull request)"
  echo "  applied: scripts/series.yaml now publishes $flavor from $S-green; render README.Rmd and open the pull request"
fi
echo
echo "No ref was moved. The published generation stays until the pull requests merge,"
echo "and is pruned later (scripts/series-prune.sh $line)."
