#!/bin/bash
# Trigger rcc workflow runs for commits on a branch that don't yet have a build status.
#
# Walks the first-parent history from HEAD (up to MAX_COMMITS commits) and collects
# commits with no rcc status, stopping at the first commit that has any status
# (success, failure, or running/pending).  Builds are then triggered in chronological
# order (oldest first), up to MAX_RUNS.
#
# To re-trigger builds for specific commits: rebase those commits above the boundary
# commit and force-push.  The script will then pick them up on the next run.
#
# Usage:
#   GH_TOKEN=<token> scripts/each-rcc.sh <ref>
#   GH_TOKEN=<token> scripts/each-rcc.sh   # defaults to current HEAD branch
#
# Local testing example:
#   GH_TOKEN=$(gh auth token) scripts/each-rcc.sh refs/heads/my-feature-dev
#
# Environment variables:
#   GH_TOKEN   - GitHub token with statuses:read and actions:write (required)
#   MAX_COMMITS - maximum number of commits to inspect (default: 100)
#   MAX_RUNS    - maximum number of workflow runs to schedule (default: 100)
#   DRY_RUN     - if non-empty, print what would be triggered without actually running

set -euo pipefail

REF="${1:-${GITHUB_REF:-$(git symbolic-ref HEAD)}}"
MAX_COMMITS="${MAX_COMMITS:-100}"
MAX_RUNS="${MAX_RUNS:-100}"

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "ERROR: GH_TOKEN is not set" >&2
  exit 1
fi

echo "Branch ref: ${REF}"
echo "Scanning up to ${MAX_COMMITS} commits, scheduling up to ${MAX_RUNS} runs"

commits_to_run=()
count=0

while IFS= read -r commit; do
  count=$(( count + 1 ))
  if (( count > MAX_COMMITS )); then
    echo "Reached MAX_COMMITS limit (${MAX_COMMITS}), stopping"
    break
  fi

  # Look for any rcc status on this commit (success, failure, pending/running)
  status=$(gh api "repos/{owner}/{repo}/commits/${commit}/statuses" \
    | jq -r '.[] | select(.context == "rcc") | .state' \
    | head -n 1)

  if [[ -n "$status" ]]; then
    echo "Boundary: ${commit} (status: ${status}), stopping"
    break
  fi

  commits_to_run+=("$commit")
done < <(git log --first-parent --pretty=format:"%H" --)

total="${#commits_to_run[@]}"
echo "Commits without rcc status: ${total}"

if (( total == 0 )); then
  echo "Nothing to do"
  exit 0
fi

# Trigger in chronological order (oldest first), capped at MAX_RUNS
scheduled=0
for (( i=total-1; i>=0; i-- )); do
  if (( scheduled >= MAX_RUNS )); then
    echo "Reached MAX_RUNS limit (${MAX_RUNS}), stopping"
    break
  fi

  commit="${commits_to_run[$i]}"
  if [[ -n "${DRY_RUN:-}" ]]; then
    echo "[dry-run] Would trigger rcc for commit ${commit}"
  else
    echo "Triggering rcc for commit ${commit}"
    gh workflow run rcc -f ref="$commit" -r "$REF"
  fi
  scheduled=$(( scheduled + 1 ))
done

echo "Scheduled ${scheduled} run(s)"
