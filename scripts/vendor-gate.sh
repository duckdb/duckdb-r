#!/bin/bash
# Decide whether the daily vendoring run should advance, fail, or wait, based on
# the `rcc` commit-status of the dev branch tip and the 5 commits before it
# (first-parent window of WINDOW=6 commits).
#
# Decision (scanning the window newest -> oldest):
#   green     -> some commit in the window has rcc=success. Prints
#                "green_sha=<youngest-green-sha>". The caller resets the dev
#                branch to that commit and vendors at most 25 commits on top.
#   red       -> no green in the window, but at least one rcc=failure/error.
#                The caller fails loudly (a real breakage is near the tip and no
#                green base is within reach; repair is needed first).
#   stale     -> no green and no red, but a commit still has no rcc result after
#                more than MAX_AGE_HOURS. The caller fails loudly: CI never
#                decided in time (e.g. the commit was never scheduled, or a run
#                is wedged), so silently waiting another day would hide the stall.
#   undecided -> no green and no red, and every result-less commit is younger
#                than MAX_AGE_HOURS. The caller succeeds and does nothing; the
#                next daily run re-checks once CI has had time to decide.
#
# The stale/undecided split adapts a simple rule: a commit without a CI result
# that is younger than MAX_AGE_HOURS is still legitimately "in flight" (skip
# silently), but once it ages past MAX_AGE_HOURS with no result something is
# wrong and we surface it loudly rather than stalling forever.
#
# "Youngest green" is the most recent commit in the window with rcc=success;
# resetting there discards at most 5 unverified (pending/red) commits, which the
# subsequent `vendor-one.sh` re-creates from upstream — a bounded re-roll.
#
# Commit statuses are read via `gh api` (context "rcc"), exactly as
# scripts/each-rcc.sh does. Writes `decision`, `green_sha`, and `stale_sha` to
# $GITHUB_OUTPUT when set; always echoes the decision to stdout. Per-commit
# states go to stderr.
#
# Environment:
#   GH_TOKEN       - GitHub token with statuses:read (required in CI)
#   WINDOW         - commits to inspect, tip + (WINDOW-1) before (default: 6)
#   MAX_AGE_HOURS  - a result-less commit older than this turns "undecided" into
#                    a loud "stale" failure (default: 6)

set -euo pipefail

WINDOW="${WINDOW:-6}"
MAX_AGE_HOURS="${MAX_AGE_HOURS:-6}"
max_age_secs=$(( MAX_AGE_HOURS * 3600 ))
now="$(date +%s)"

# Newest rcc commit-status state for a SHA: success | failure | error | pending | none
rcc_state() {
  gh api "repos/{owner}/{repo}/commits/$1/statuses" \
    --jq '[.[] | select(.context == "rcc")][0].state // "none"' 2>/dev/null || echo "none"
}

# "<sha> <committer-date-unix>" per line, newest first.
mapfile -t COMMITS < <(git log -n "$WINDOW" --first-parent --format="%H %ct" HEAD)

green=""
saw_red=0
stale_sha=""
for line in "${COMMITS[@]}"; do
  sha="${line%% *}"
  cdate="${line##* }"
  state="$(rcc_state "$sha")"
  age=$(( now - cdate ))
  age_h=$(( age / 3600 ))
  echo "  ${sha} rcc=${state} age=${age_h}h" >&2
  case "$state" in
    success)
      green="$sha"
      break
      ;;
    failure | error)
      saw_red=1
      ;;
    *)
      # pending / none: a commit still without an rcc result. Remember the
      # first (youngest) one that has been waiting longer than MAX_AGE_HOURS.
      if [ "$age" -gt "$max_age_secs" ] && [ -z "$stale_sha" ]; then
        stale_sha="$sha"
      fi
      ;;
  esac
done

if [ -n "$green" ]; then
  decision=green
elif [ "$saw_red" -eq 1 ]; then
  decision=red
elif [ -n "$stale_sha" ]; then
  decision=stale
else
  decision=undecided
fi

echo "decision=${decision} green_sha=${green} stale_sha=${stale_sha}"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "decision=${decision}"
    echo "green_sha=${green}"
    echo "stale_sha=${stale_sha}"
  } >>"$GITHUB_OUTPUT"
fi
