#!/bin/bash
# Trigger rcc workflow runs for commits on a branch that don't yet have a build status.
#
# Considers all commits on or after 2026-01-01 in the first-parent history from HEAD.
# Commits are scanned in chronological order (oldest first); for each one, checks for
# an existing rcc build status (success, failure, or running/pending).  Commits without
# any status are triggered immediately as they are found, so runs start queuing while
# the remaining commits are still being scanned.  All qualifying commits are always
# inspected and all pending ones are always triggered — there is no cap.
#
# To re-trigger builds for specific commits: rebase those commits above the boundary
# commit and force-push.  The script will then pick them up on the next run.
#
# Usage:
#   GH_TOKEN=<token> scripts/each-rcc.sh
#
# Local testing example (check out the branch first, then run):
#   git checkout my-feature-dev
#   GH_TOKEN=$(gh auth token) scripts/each-rcc.sh
#
# Environment variables:
#   GH_TOKEN  - GitHub token with statuses:read and actions:write (required)
#   SINCE     - earliest commit date to consider, ISO 8601 (default: 2026-01-01)
#   DRY_RUN   - if non-empty, print what would be triggered without actually running

set -euo pipefail

REF="$(git symbolic-ref HEAD)"
SINCE="${SINCE:-2026-01-01}"

gh auth status

echo "Branch ref: ${REF}"
echo "Scanning all commits on or after ${SINCE}"

# Scan and queue in a single pass, in chronological order (oldest first).
# Each commit without an rcc status is triggered as soon as it is found, so
# runs start queuing while the remaining commits are still being scanned.
# `awk 'NF'` re-emits every SHA newline-terminated — so the tip (the final line,
# left unterminated by `--pretty=format:` under `--reverse`) is not dropped by
# `read` — and emits nothing for empty input, avoiding a spurious empty commit.
scheduled=0
while IFS= read -r commit; do
  # Look for any rcc status on this commit (success, failure, pending/running)
  status=$(gh api "repos/{owner}/{repo}/commits/${commit}/statuses" \
    | jq -r '.[] | select(.context == "rcc") | .state' \
    | head -n 1)

  if [[ -n "$status" ]]; then
    echo "${commit}: already has status '${status}', skipping"
  elif [[ -n "${DRY_RUN:-}" ]]; then
    echo "${commit}: no status, [dry-run] would trigger rcc"
    scheduled=$(( scheduled + 1 ))
  else
    echo "${commit}: no status, triggering rcc"
    gh workflow run rcc -f ref="$commit" -r "$REF"
    scheduled=$(( scheduled + 1 ))
  fi
done < <(git log --first-parent --reverse --pretty=format:"%H" --after="${SINCE}" -- | awk 'NF')

echo "Scheduled ${scheduled} run(s)"
