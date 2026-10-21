#!/bin/bash
# Fast-forward `<S>-green` over the commits of `<S>-dev` the per-commit check
# passed. The last job of every `each-rcc` run on a `-dev` branch runs it
# (.github/workflows/each.yaml, job `green`), retry runs and dispatches
# included, so green moves when a verdict lands rather than when a routine
# next fires; a human runs it by hand where that job could not push.
#
# **Two rules, one per kind of ref, as the routines applied them.**
#
#   * A series, a `<S>-dev` with a `<S>-build` beside it, takes the passed
#     prefix: green moves to the newest commit such that every commit in
#     `<S>-green..it` has a `success` record, and the walk stops at the first
#     commit without one, red or undecided. The prefix below a red still
#     counts, because green is what r-universe installs and a repair replays
#     only the tail above the red. It is the series loop's rule
#     (.claude/skills/series-loop/SKILL.md, stage 3).
#   * A landing, `<L>-land-dev` or an iteration's `<L>-land-v<n>-dev`, moves
#     all or nothing: green goes to the tip once every commit above it has
#     passed, and stays at its base until then. Nothing publishes a landing's
#     green, so a prefix buys nothing, and a green held at the base is never
#     stranded off the lineage by a fix folded into a commit CI had passed
#     (.claude/skills/series-land/SKILL.md). It is the rule a landing's
#     coordinator applied by hand.
#
# Anything else is left alone and says so: an rc strand has no green, a
# `-dev` with neither a buffer nor a landing's name is not the loop's, and a
# forward whose green is an ancestor of its base's is cutover litter, which
# the loop does not serve either (scripts/series-check.sh).
#
# **Never backwards, never forced.** The walk starts at green, so the move is
# a fast-forward by construction, and it is checked again before the push.
# The push carries a lease on the green this run read: a ref another writer
# moved in between is read again and walked from where it stands, never
# overwritten, and a third refusal ends the run.
#
# **Why no lock is needed.** Two `each-rcc` runs on one branch never overlap,
# because the workflow's concurrency group is per branch; a retry run on
# `retry-<S>-dev` is in a group of its own and may finish beside one on
# `<S>-dev`, which is what the lease is for. The series loop does not move
# green. It rewrites `<S>-dev` when it folds a repair, and keeps green an
# ancestor of what it pushes by reading green again just before the push
# (series-loop stage 2), the same condition every `each-rcc` plan refuses to
# start without.
#
# **A move across a workflow file may be refused.** GitHub refuses a GitHub
# App's token, which a workflow's own token is, a push that changes a file
# under `.github/workflows/` without the `workflows` permission, and a port from
# `main` often changes one. When the push is refused for that, a series' green
# moves as far as the newest commit that leaves `.github/workflows/` as green
# has it, and the run exits 1 naming the commit it could not cross: a token
# with that permission (the job's `SERIES_GREEN_TOKEN`), or this script run by
# hand, takes it over. A landing moves all or nothing, so it does not move.
#
# Verdicts come from the `rcc2` store, one record per commit, whose newest
# line wins: `<remote>/rcc2` in this clone, or, with RCC_READ_DIR set, a
# records-only clone of the store kept there (scripts/rcc-lib.sh), which is how
# the job reads it without fetching every harvested log.
#
# Usage: series-green.sh <S> [--remote <name>] [--push]
#   <S> is what precedes `-dev` in the branch name: `main`,
#   `v2.0-cyanoptera-fwd`, `v2.0-cyanoptera-land-v9`. Without --push the run
#   says where green would move and writes nothing.
#
# Environment variables:
#   SERIES_REMOTE  - the default for --remote (default: origin)
#   RCC_BRANCH     - the store's branch (default: rcc2)
#   RCC_READ_DIR   - read the store from a records-only clone kept here, rather
#                    than from <remote>/rcc2 in this clone; the clone helpers in
#                    scripts/rcc-lib.sh read GH_TOKEN, GITHUB_REPOSITORY and
#                    RCC_REMOTE for where it comes from
#
# Exit status: 0 when green moved or had nothing to move, 1 when it could not
# move as far as the rule says, 2 on a usage error.
#
# --remote is spelled the same in every scripts/series-*.sh; see the shared
# contract in handbook/operations/vendoring/series-loop/README.md.

set -euo pipefail
# A failure inside `$(...)` stops the run too, rather than reading as empty.
shopt -s inherit_errexit

usage='usage: series-green.sh <S> [--remote <name>] [--push]'
argerr() { echo "$usage" >&2; exit 2; }
remote=${SERIES_REMOTE:-origin}
push=''
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) [ $# -ge 2 ] || argerr; remote=$2; shift 2 ;;
    --push) push=1; shift ;;
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
S=${args[0]}
rcc=${RCC_BRANCH:-rcc2}
here=$(cd "$(dirname "$0")" && pwd)

# Said on stdout, and in the job summary when there is one.
report() {
  echo "$*"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    printf '%s\n\n' "$*" >> "$GITHUB_STEP_SUMMARY"
  fi
}
short() { git rev-parse --short "$1"; }

case "$S" in
  *-land | *-land-v[0-9]*) kind=landing ;;
  *) kind=series ;;
esac
base=''
case "$S" in *-fwd) base=${S%-fwd} ;; esac

# --- the store ----------------------------------------------------------------

if [ -n "${RCC_READ_DIR:-}" ]; then
  # shellcheck source=rcc-lib.sh
  . "$here/rcc-lib.sh"
  # In a subshell, because the clone helper exports GIT_NO_LAZY_FETCH for the
  # store's sake, and this clone may be a partial one that has to fetch lazily.
  (rcc_clone_init "$RCC_READ_DIR")
  store_ref=$(rcc_fetch_tip "$RCC_READ_DIR" "$rcc" --filter=blob:limit=16k) ||
    { echo "Error: cannot read the $rcc store" >&2; exit 1; }
  store_git=(git -C "$RCC_READ_DIR")
else
  git fetch -q "$remote" "+refs/heads/$rcc:refs/remotes/$remote/$rcc" ||
    { echo "Error: cannot fetch $rcc from $remote" >&2; exit 1; }
  store_ref="refs/remotes/$remote/$rcc"
  store_git=(git)
fi

# The newest verdict's state, `missing` without a record.
state_of() { # <sha>
  local st
  st=$("${store_git[@]}" show "$store_ref:runs2.d/${1:0:2}/$1.ndjson" 2>/dev/null |
    sed -nr 's/.*"status":[^}]*"state": *"([a-z]+)".*/\1/p' | tail -n 1 || true)
  echo "${st:-missing}"
}

# --- one round: read, walk, push ---------------------------------------------

# Reads the refs into `green` and `dev`, and says whether there is anything of
# the loop's to align: 0 yes, 1 no.
read_refs() {
  local heads r
  heads=$(git ls-remote "$remote" "refs/heads/$S-green" "refs/heads/$S-dev" \
    "refs/heads/$S-build" ${base:+"refs/heads/$base-green"})
  has() { awk -v r="refs/heads/$1" '$2 == r { f = 1 } END { exit !f }' <<<"$heads"; }
  for r in green dev; do
    has "$S-$r" || { report "$S: no $S-$r on $remote, nothing to align"; return 1; }
  done
  if [ "$kind" = series ] && ! has "$S-build"; then
    report "$S: neither a series (no $S-build) nor a landing, nothing to align"
    return 1
  fi
  git fetch -q "$remote" "+refs/heads/$S-green:refs/remotes/$remote/$S-green" \
    "+refs/heads/$S-dev:refs/remotes/$remote/$S-dev"
  green=$(git rev-parse "refs/remotes/$remote/$S-green")
  dev=$(git rev-parse "refs/remotes/$remote/$S-dev")
  if [ -n "$base" ] && has "$base-green"; then
    git fetch -q "$remote" "+refs/heads/$base-green:refs/remotes/$remote/$base-green"
    if git merge-base --is-ancestor "$green" "refs/remotes/$remote/$base-green"; then
      report "$S: green is an ancestor of $base-green, cutover litter, nothing to align"
      return 1
    fi
  fi
  return 0
}

# Walks `green..dev` by the rule of the ref's kind into `new`, and names the
# first commit that has not passed in `stop` and `stop_state`.
walk() {
  local sha st
  new=$green stop='' stop_state=''
  if [ "$kind" = landing ]; then
    while IFS= read -r sha; do
      st=$(state_of "$sha")
      [ "$st" = success ] || { stop=$sha stop_state=$st; break; }
    done < <(git rev-list --reverse --first-parent "$green..$dev")
    [ -n "$stop" ] || new=$dev
  else
    while IFS= read -r sha; do
      st=$(state_of "$sha")
      case "$st" in
        success) new=$sha ;;
        *) stop=$sha stop_state=$st; break ;;
      esac
    done < <(git rev-list --reverse "$green..$dev")
  fi
}

# The newest commit in `green..<to>` up to which `.github/workflows/` stays as
# green has it, and the first commit that changes it, on one line.
workflow_free() { # <to>
  local c wf at_green last=$green
  at_green=$(git rev-parse -q --verify "$green:.github/workflows" || echo none)
  while IFS= read -r c; do
    wf=$(git rev-parse -q --verify "$c:.github/workflows" || echo none)
    [ "$wf" = "$at_green" ] || { echo "$last $c"; return; }
    last=$c
  done < <(git rev-list --reverse "$green..$1")
  echo "$last"
}

push_green() { # <commit> -> 0 pushed; the refusal in `refusal`
  local out
  if out=$(git push --force-with-lease="refs/heads/$S-green:$green" "$remote" \
    "$1:refs/heads/$S-green" 2>&1); then
    return 0
  fi
  refusal=$out
  return 1
}

for round in 1 2 3; do
  read_refs || exit 0
  if ! git merge-base --is-ancestor "$green" "$dev"; then
    report "Error: $S-green ($(short "$green")) is not an ancestor of $S-dev ($(short "$dev"))." \
      "Something rewrote verified history, or a ref move is half-finished; green does not move."
    exit 1
  fi
  walk
  passed=$(git rev-list --count "$green..$new")
  total=$(git rev-list --count "$green..$dev")
  if [ -n "$stop" ]; then
    first="first not passed: $(short "$stop") ($stop_state)"
  else
    first="every commit has passed"
  fi
  if [ "$new" = "$green" ]; then
    report "$S-green stays at $(short "$green") ($kind rule): $first, $total in flight."
    exit 0
  fi
  # By construction, and checked anyway: a fast-forward, and on dev's lineage.
  if ! git merge-base --is-ancestor "$green" "$new" || ! git merge-base --is-ancestor "$new" "$dev"; then
    report "Error: $S-green would not fast-forward to $(short "$new")."
    exit 1
  fi
  if [ -z "$push" ]; then
    report "$S-green would move $(short "$green") -> $(short "$new") ($kind rule):" \
      "$passed of $total passed, $first; --push moves it."
    exit 0
  fi
  if push_green "$new"; then
    report "$S-green -> $(short "$new") ($kind rule): $passed of $total passed, $first."
    exit 0
  fi

  # Refused. Another writer first: read again and walk from where it put green.
  now=$(git ls-remote "$remote" "refs/heads/$S-green" | cut -f1)
  if [ "$now" != "$green" ]; then
    echo "$S-green moved from $(short "$green") to ${now:0:7} under this run; reading again"
    continue
  fi
  # Then the one refusal a partial move answers.
  case "$refusal" in
    *workflow*) ;;
    *)
      report "Error: the push of $S-green was refused:" "$refusal"
      exit 1
      ;;
  esac
  if [ "$kind" = landing ]; then
    report "Error: the push of $S-green was refused over a workflow file, and a landing's green" \
      "moves all or nothing. Push $(short "$new") with a token that may change workflows:" \
      "$refusal"
    exit 1
  fi
  crossing=''
  read -r w crossing <<<"$(workflow_free "$new")"
  if [ -z "$crossing" ]; then
    report "Error: the push of $S-green was refused, though no commit up to $(short "$new")" \
      "changes .github/workflows/:" "$refusal"
    exit 1
  fi
  if [ "$w" != "$green" ] && ! push_green "$w"; then
    report "Error: the push of $S-green was refused, below any workflow change too:" "$refusal"
    exit 1
  fi
  if [ "$w" != "$green" ]; then
    moved="$S-green -> $(short "$w"), as far as this token may move it."
  else
    moved="$S-green stays at $(short "$green")."
  fi
  report "$moved Its push to $(short "$new") was refused," \
    "because $(short "$crossing") changes .github/workflows/:" \
    "a token with the workflows permission, or this script run by hand, takes it from there."
  exit 1
done
report "Error: $S-green kept moving under this run; giving up after $round rounds."
exit 1
