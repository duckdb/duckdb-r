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
#   undecided -> no green and no red (all pending / no status yet). The caller
#                succeeds and does nothing; the next daily run re-checks once CI
#                has decided.
#
# "Youngest green" is the most recent commit in the window with rcc=success;
# resetting there discards at most 5 unverified (pending/red) commits, which the
# subsequent `vendor-one.sh` re-creates from upstream — a bounded re-roll.
#
# Commit statuses are read via `gh api` (context "rcc"), exactly as
# scripts/each-rcc.sh does. Writes `decision` and `green_sha` to $GITHUB_OUTPUT
# when set; always echoes the decision to stdout. Per-commit states go to stderr.
#
# Environment:
#   GH_TOKEN  - GitHub token with statuses:read (required in CI)
#   WINDOW    - commits to inspect, tip + (WINDOW-1) before (default: 6)

set -euo pipefail

WINDOW="${WINDOW:-6}"

# Newest rcc commit-status state for a SHA: success | failure | error | pending | none
rcc_state() {
  gh api "repos/{owner}/{repo}/commits/$1/statuses" \
    --jq '[.[] | select(.context == "rcc")][0].state // "none"' 2>/dev/null || echo "none"
}

mapfile -t COMMITS < <(git log -n "$WINDOW" --first-parent --format="%H" HEAD)

green=""
saw_red=0
for sha in "${COMMITS[@]}"; do
  state="$(rcc_state "$sha")"
  echo "  ${sha} rcc=${state}" >&2
  case "$state" in
    success)
      green="$sha"
      break
      ;;
    failure | error)
      saw_red=1
      ;;
  esac
done

if [ -n "$green" ]; then
  decision=green
elif [ "$saw_red" -eq 1 ]; then
  decision=red
else
  decision=undecided
fi

echo "decision=${decision} green_sha=${green}"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "decision=${decision}"
    echo "green_sha=${green}"
  } >>"$GITHUB_OUTPUT"
fi
