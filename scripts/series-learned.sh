#!/bin/bash
# What a series' `-dev` learned beyond its buffer: for every vendor commit, the
# fix the loop folded into it that its `-build` twin does not carry.
#
# `-build` is what pure vendoring produces, plus the glue each engine needed to
# compile, that being what the glue gate checks. `-dev` is the same commits with
# what CI demanded afterwards folded in: snapshots, tests, R code, and glue a
# test rather than the compiler asked for (.claude/skills/series-loop/SKILL.md,
# stage 2). A forward replays `-dev` (scripts/series-forward-build.sh), so it
# inherits every one of those fixes, the ones that were right and the ones that
# were expedient. This prints them, one commit at a time, so that they are read
# and judged before they travel: a fix found wanting is answered after the
# replay, as a commit on the forward commit that carries it, folded in with
# scripts/series-fold.sh. Nothing here is a decision; it is the material.
#
# The difference is the one stage 5's carry takes (scripts/series-advance.sh):
# the paths the `-dev` commit changed, less the buffer's own strand
# (`src/duckdb/`, `patch/`), what vendoring regenerates (`R/version.R`,
# `src/include/sources.mk`, the Makevars, the logos), the tooling stage 4 ports,
# and `DESCRIPTION`; and of those, only the paths whose blob differs from the
# twin's, so glue the buffer already carries is not reported as learned.
# What is printed for each is the commit's own change to those paths,
# `git diff <commit>^ <commit> -- <paths>`, as a stat, or in full with --diff.
#
# `--vendor` asks the question one strand down: `-build` against `-vendor`, the
# pure vendoring the buffer is derived from (handbook/branches/model/README.md).
# On a series that is the glue the gate demanded, commit by commit; on a forward
# it is everything `-fwd-build` carries beyond vendoring on the new base, after
# `main`'s delta and the replay's adaptations have met every fix, which is the
# report a correction to the forward's buffer is judged from
# (.claude/skills/series-forward/SKILL.md).
#
# **Read-only.** It writes no ref, makes no commit, and touches no worktree.
#
# Usage: series-learned.sh <series> [--remote <name>] [--since <ref>] [--diff] [--vendor]
#   <series>  the series, `v2.0-cyanoptera`; its `-dev` and `-build` are read,
#             or with --vendor its `-build` and `-vendor`, `v2.0-cyanoptera-fwd`
#   --since   the commit the walk starts above; the series' seed by default,
#             `chore: Add fifth version component`, and where a cut series has
#             none, its merge base with `main`
#   --diff    print each commit's learned change in full, not as a stat
#   --vendor  read `<S>-build` against `<S>-vendor`
#
# --remote is spelled the same in every scripts/series-*.sh; see the shared
# contract in handbook/operations/vendoring/series-loop/README.md.
#
# Exit status: 0, whatever it finds; 2 on a usage or lookup error.

set -euo pipefail
# shellcheck source=series-lib.sh
. "$(dirname "$0")/series-lib.sh"

usage='usage: series-learned.sh <series> [--remote <name>] [--since <ref>] [--diff] [--vendor]'
argerr() { echo "$usage" >&2; exit 2; }
remote=${SERIES_REMOTE:-origin}
since=''
full=''
upper=dev lower=build
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --since) [ $# -ge 2 ] || argerr; since=$2; shift 2 ;;
    --diff) full=1; shift ;;
    --vendor) upper=build lower=vendor; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
S=${args[0]}
# The strand that learned, and the one it learned beyond: `-dev` over `-build`,
# or on a forward with --vendor, `-build` over `-vendor`.
dev="$remote/$S-$upper"
build="$remote/$S-$lower"

for r in "$dev" "$build"; do
  git rev-parse -q --verify "$r^{commit}" >/dev/null || {
    echo "Error: ${r#"$remote"/} does not exist on $remote" >&2
    exit 2
  }
done

if [ -z "$since" ]; then
  since=$(series_seed_of "$dev")
  [ -n "$since" ] || since=$(git merge-base "$dev" "$remote/main" 2>/dev/null || true)
  [ -n "$since" ] || { echo "Error: $S-$upper has no seed and no merge base with $remote/main; pass --since" >&2; exit 2; }
fi
git rev-parse -q --verify "$since^{commit}" >/dev/null || { echo "Error: --since $since is not a commit" >&2; exit 2; }

# The buffer's commit for each upstream SHA, oldest first where a repair left
# two, as scripts/series-advance.sh indexes twins.
declare -A TWIN=()
while IFS=$'\t' read -r c subj; do
  series_is_vendor "$subj" || continue
  sha=$(series_sha_of "$subj")
  [ -n "$sha" ] && [ -z "${TWIN[$sha]:-}" ] && TWIN[$sha]=$c
done < <(git log --reverse --format='%H%x09%s' "$build")

# The paths a `-dev` commit learned: the carry's filter, from the twin's side.
learned_paths() { # <dev commit> <build twin>
  local d=$1 c=$2 f
  git show --format= --name-only --no-renames "$d" | sort -u | series_carry_filter |
    while IFS= read -r f; do
      [ "$(git rev-parse --quiet --verify "$c:$f" 2>/dev/null)" \
        != "$(git rev-parse --quiet --verify "$d:$f" 2>/dev/null)" ] || continue
      printf '%s\n' "$f"
    done
}

echo "=== what $S-$upper learned beyond $S-$lower, above $(git rev-parse --short "$since")"
echo
total=0 learned=0 untwinned=0
declare -A FILES=()
while IFS=$'\t' read -r d subj; do
  series_is_vendor "$subj" || continue
  total=$((total + 1))
  sha=$(series_sha_of "$subj")
  c=${TWIN[$sha]:-}
  if [ -z "$c" ]; then
    untwinned=$((untwinned + 1))
    echo "--- $(git rev-parse --short "$d")  $series_upstream_repo@${sha:0:10}: no twin on $S-$lower"
    echo
    continue
  fi
  mapfile -t paths < <(learned_paths "$d" "$c")
  [ ${#paths[@]} -gt 0 ] || continue
  learned=$((learned + 1))
  for f in "${paths[@]}"; do FILES[$f]=$((${FILES[$f]:-0} + 1)); done
  echo "--- $(git rev-parse --short "$d")  $series_upstream_repo@${sha:0:10}  (twin $(git rev-parse --short "$c"))"
  # The prose the repair left, where the message has an `R-side fix` section:
  # its first paragraph, which names what was adapted and why.
  git log -1 --format=%B "$d" |
    awk 'tolower($0) ~ /^r-side fix/ { on = 1; next } on && /^-+$/ { next } on && /^$/ { if (seen) exit; next } on { print "    " $0; seen = 1 }' |
    head -n 6
  if [ -n "$full" ]; then
    git diff "$d^" "$d" -- "${paths[@]}" | sed 's/^/    /'
  else
    git diff --stat=80 "$d^" "$d" -- "${paths[@]}" | sed 's/^/    /'
  fi
  echo
done < <(git log --reverse --first-parent --format='%H%x09%s' "$since..$dev")

echo "$learned of $total vendor commit(s) learned something beyond the buffer" \
  "${untwinned:+; $untwinned with no twin on $S-$lower}" | sed 's/ ;/;/'
if [ ${#FILES[@]} -gt 0 ]; then
  echo
  echo "files, by how often a commit learned something in them:"
  for f in "${!FILES[@]}"; do printf '  %4d  %s\n' "${FILES[$f]}" "$f"; done | sort -rn -k1,1 -k2
fi
