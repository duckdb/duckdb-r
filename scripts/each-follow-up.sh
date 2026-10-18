#!/bin/bash
# Dispatch one more `each-rcc` run when this one left planned commits undecided.
#
# A leg stops at its own deadline and defers the commits it did not reach
# (scripts/each-shard.sh), the planner defers the oldest commits past
# MAX_SHARDS legs, and a leg that dies leaves its in-flight commit undecided.
# Nothing else plans them before the next push, and a series' green ref waits
# behind them until then. So the run's last job asks for one more pass on the
# branch, which plans whatever the verdict store still lacks when it starts.
#
# It dispatches only when every one of these holds, checked in this order:
#
#   * The branch still points at the commit the plan was made from. A push
#     since has a run of its own, and a force-push that retired this run must
#     not be undone by it. A cancelled run never gets here: the job's `if:` is
#     `!cancelled()`.
#   * Commits remain: a planned commit the store has no record for, or one the
#     planner deferred past MAX_SHARDS.
#   * The run made progress: fewer planned commits lack a record than when the
#     plan was made. Every follow-up then decides at least one commit or ends
#     the chain, and the range is finite, so no chain is endless, not even one
#     behind a leg that dies the same way every time or a store the legs cannot
#     write. A commit that alone outlasts a leg's budget does not start one
#     either: the first commit a leg builds is never deferred, because it had
#     the whole budget and a kill at the deadline is its verdict.
#   * No other run of the workflow is waiting on the branch. GitHub keeps only
#     the newest pending run of a concurrency group, so a dispatch would cancel
#     a push's or an operator's run, which plans the same commits anyway.
#
# "Undecided" is the store's answer, read the way the planner reads it
# (scripts/rcc-decided.sh); commit statuses decide nothing here either.
#
# The follow-up gets this run's inputs without `force`, plus `follow-up-of`,
# which keeps the planner from replanning a `retry-<S>-dev` tip this run has
# already planned again. See handbook/operations/ci/per-commit/legs/README.md.
#
# Usage:
#   GH_TOKEN=<token> PLAN=plan.json RUN_ID=<id> scripts/each-follow-up.sh
#
# Environment variables:
#   GH_TOKEN          - token with contents:read and actions:write (required)
#   PLAN              - this run's plan file, which names the branch and the
#                       commit it was planned from (default: plan.json)
#   RUN_ID            - this run's id (default: $GITHUB_RUN_ID)
#   INPUTS            - this run's inputs as a JSON object, passed on to the
#                       follow-up (default: none)
#   WORKFLOW          - the workflow file to dispatch (default: each.yaml)
#   DRY_RUN           - if non-empty, print the dispatch instead of sending it
#   EACH_DECIDED_FILE - offline hook: read decided commits from this file, one
#                       SHA per line, instead of the store

set -euo pipefail

PLAN="${PLAN:-plan.json}"
RUN_ID="${RUN_ID:-${GITHUB_RUN_ID:?RUN_ID or GITHUB_RUN_ID is required}}"
export RUN_ID
INPUTS="${INPUTS:-}"
WORKFLOW="${WORKFLOW:-each.yaml}"

here="$(cd "$(dirname "$0")" && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

report() {
  echo "$*"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    printf '## each-rcc follow-up\n\n%s\n' "$*" >> "${GITHUB_STEP_SUMMARY}"
  fi
}

branch="$(jq -r '.branch' "${PLAN}")"
head="$(jq -r '.head // ""' "${PLAN}")"
tip="$(git ls-remote origin "refs/heads/${branch}" | cut -f1)"
if [ -z "${head}" ] || [ "${tip}" != "${head}" ]; then
  report "Not dispatched: ${branch} has moved from ${head:-?} to ${tip:-nothing}."
  exit 0
fi

if [ -n "${EACH_DECIDED_FILE:-}" ]; then
  cp "${EACH_DECIDED_FILE}" "${workdir}/decided"
else
  "${here}/rcc-decided.sh" > "${workdir}/decided"
fi

before="$(jq '.planned_without_verdict // 0' "${PLAN}")"
capped="$(jq '.commits_deferred // 0' "${PLAN}")"
left="$(jq -r '.shards[].commits[].sha' "${PLAN}" \
  | grep -cvxF -f "${workdir}/decided" || true)"
echo "Planned without a verdict: ${before}; still without one: ${left};" \
  "deferred past the shard cap: ${capped}"

if [ $(( left + capped )) -eq 0 ]; then
  report "Not dispatched: every commit the run planned has a verdict."
  exit 0
fi
if [ "${left}" -ge "${before}" ]; then
  report "Not dispatched: the run decided none of the ${before} commit(s) it planned without a verdict."
  exit 0
fi

waiting="$(gh api -X GET "repos/{owner}/{repo}/actions/workflows/${WORKFLOW}/runs" \
  -f branch="${branch}" -f per_page=100 \
  --jq '[.workflow_runs[]
         | select(.status != "completed" and (.id | tostring) != env.RUN_ID)]
         | length')"
if [ "${waiting}" -gt 0 ]; then
  report "Not dispatched: another ${WORKFLOW} run on ${branch} is waiting to plan the same commits."
  exit 0
fi

body="$(jq -n -c \
  --arg ref "${branch}" \
  --arg run "${RUN_ID}" \
  --argjson inputs "${INPUTS:-null}" \
  '{ref: $ref,
    inputs: (($inputs // {}) | del(.force, .branch, ."follow-up-of")
             | with_entries(select(.value != null and .value != "")
                            | .value |= tostring)
             | . + {"follow-up-of": $run})}')"

verb="Dispatched"
if [ -n "${DRY_RUN:-}" ]; then
  verb="Would dispatch"
  echo "[dry-run] POST repos/{owner}/{repo}/actions/workflows/${WORKFLOW}/dispatches ${body}"
else
  gh api --method POST "repos/{owner}/{repo}/actions/workflows/${WORKFLOW}/dispatches" \
    --input - <<<"${body}"
fi
report "${verb} a follow-up run on ${branch}: this run decided $(( before - left )) commit(s), and $(( left + capped )) remain."
