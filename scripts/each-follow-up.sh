#!/bin/bash
# Dispatch one more `each-rcc` run when this one left planned commits undecided.
#
# A leg stops at its own deadline and defers the commits it did not reach
# (scripts/each-shard.sh), the planner defers the oldest commits past
# MAX_SHARDS legs, and a leg that dies leaves its in-flight commit undecided.
# So the run's last job asks for one more pass on the branch, which plans
# whatever the verdict store still lacks when it starts. When it dispatches, and
# why a chain of follow-ups ends, is stated once, in "The follow-up run" of
# handbook/operations/ci/per-commit/legs/README.md; this header holds the
# mechanism.
#
# What the run set out to decide is what its plan put in a shard: the commits
# that had no record when the plan was made (`planned_without_verdict`), and the
# ones planned despite a record (`replanned_despite_verdict`: a forced run's,
# and a `retry-<S>-dev` tip). One of the first kind is decided once the store
# holds a record for it, read the way the planner reads it
# (scripts/rcc-decided.sh); one of the second kind only once its record names
# this run, which takes the records themselves (scripts/rcc-lib.sh), fetched
# only when the plan has such a commit. Commit statuses decide nothing here.
#
# What remains is what a follow-up can still decide, which it never does by
# forcing: a planned commit without a record, a commit deferred past MAX_SHARDS
# without one (`deferred_shas`, asked of the store now rather than counted at
# plan time), and the retry tip (`retry_tip`) when this run did not judge it
# again. A forced commit a leg deferred keeps the record it had.
#
# The follow-up gets this run's inputs without `force`, plus `follow-up-of`,
# this run's id, and `follow-up-head`, the commit the plan was made from. The
# planner forces a retry tip again unless it equals that head
# (scripts/each-plan.sh), so the head is left out when the tip remains.
#
# The order is load-bearing. The store is read before the branch's tip is
# checked, and the waiting runs are listed right before the dispatch, so what is
# checked is as close as it gets to what is sent. A push between that list and
# the dispatch still loses its pending run to this one, which GitHub keeps as
# the newer; that run plans from the new tip, where the head suppresses nothing,
# so it does the push's work. A dispatch refused after the branch moved, such as
# a 422 because the new tip's workflow lacks an input, is that same move and
# ends the job quietly; any other refusal fails it.
#
# Usage:
#   GH_TOKEN=<token> PLAN=plan.json RUN_ID=<id> scripts/each-follow-up.sh
#
# Run it in a clone whose `origin` is the repository the run belongs to: the
# branch's tip is read from there, and `gh api` takes the repository from it.
#
# Environment variables:
#   GH_TOKEN          - token with contents:read and actions:write (required)
#   GITHUB_REPOSITORY - owner/repo whose `rcc2` branch is the store (set by
#                       Actions; required unless RCC_REMOTE is set)
#   RCC_REMOTE        - the store's remote URL, overriding GITHUB_REPOSITORY;
#                       how the test points this at a local repository
#   RCC_READ_DIR      - where scripts/rcc-decided.sh caches its clone of the
#                       store (default: $RUNNER_TEMP/rcc-read, else /tmp/rcc-read)
#   PLAN              - this run's plan file, which names the branch and the
#                       commit it was planned from (default: plan.json)
#   RUN_ID            - this run's id (default: $GITHUB_RUN_ID)
#   INPUTS            - this run's inputs as a JSON object, passed on to the
#                       follow-up (default: none)
#   WORKFLOW          - the workflow file to dispatch (default: each.yaml)
#   DRY_RUN           - if non-empty, print the dispatch instead of sending it
#   EACH_DECIDED_FILE - offline hook: read decided commits from this file, one
#                       SHA per line, instead of scripts/rcc-decided.sh; the
#                       records of replanned commits still come from the store

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

tip_of_branch() {
  local out
  out="$(git ls-remote origin "refs/heads/${branch}")" || {
    echo "each-follow-up: cannot reach origin to read ${branch}" >&2
    exit 1
  }
  cut -f1 <<<"${out}"
}

# --------------------------------------------------------------- the store --
if [ -n "${EACH_DECIDED_FILE:-}" ]; then
  cp "${EACH_DECIDED_FILE}" "${workdir}/decided"
else
  "${here}/rcc-decided.sh" > "${workdir}/decided"
fi

# ---------------------------------------------------------- the branch tip --
tip="$(tip_of_branch)"
if [ -z "${head}" ] || [ "${tip}" != "${head}" ]; then
  report "Not dispatched: ${branch} has moved from ${head:-?} to ${tip:-nothing}."
  exit 0
fi

# ---------------------------------------------------------- what remains --
# Every `grep -f` below reads its pattern file whole, and an empty one matches
# nothing, so `-v` keeps every line: an empty store leaves everything undecided.
jq -r '.shards[].commits[].sha' "${PLAN}" > "${workdir}/planned"
jq -r '(.replanned_despite_verdict // [])[]' "${PLAN}" \
  | grep -xF -f "${workdir}/planned" > "${workdir}/replanned" || true
jq -r '(.deferred_shas // [])[]' "${PLAN}" > "${workdir}/deferred"
retry_tip="$(jq -r '.retry_tip // ""' "${PLAN}")"

before_new="$(jq '.planned_without_verdict // 0' "${PLAN}")"
left_new="$(grep -cvxF -f "${workdir}/decided" "${workdir}/planned" || true)"
capped="$(grep -cvxF -f "${workdir}/decided" "${workdir}/deferred" || true)"
replanned="$(wc -l < "${workdir}/replanned" | tr -d ' ')"

# A replanned commit carries a record before and after; only the run named in
# its newest line says whether this run judged it again.
rejudged=0
retry_left=0
if [ "${replanned}" -gt 0 ]; then
  # shellcheck source=rcc-lib.sh
  . "${here}/rcc-lib.sh"
  records="${workdir}/records"
  (rcc_clone_init "${records}")
  store_tip="$(rcc_fetch_tip "${records}" rcc2 --filter=blob:limit=16k)" || {
    echo "each-follow-up: cannot fetch the records on rcc2" >&2
    exit 1
  }
  while IFS= read -r sha; do
    run="$(git -C "${records}" cat-file blob "${store_tip}:runs2.d/${sha:0:2}/${sha}.ndjson" 2>/dev/null \
      | tail -n 1 | jq -r '.run.id // empty' 2>/dev/null || true)"
    if [ "${run}" = "${RUN_ID}" ]; then
      rejudged=$((rejudged + 1))
    elif [ "${sha}" = "${retry_tip}" ]; then
      retry_left=1
    fi
  done < "${workdir}/replanned"
fi

before=$((before_new + replanned))
left=$((left_new + replanned - rejudged))
remain=$((left_new + capped + retry_left))
echo "Set out to decide: ${before}; still undecided: ${left}" \
  "(of them the retry tip: ${retry_left}); deferred past the shard cap and undecided: ${capped}"

if [ "${remain}" -eq 0 ]; then
  report "Not dispatched: nothing the run planned or deferred is left for a follow-up to decide."
  exit 0
fi
if [ "${left}" -ge "${before}" ]; then
  report "Not dispatched: the run decided none of the ${before} commit(s) it set out to decide."
  exit 0
fi

# ------------------------------------------------------------ the dispatch --
waiting="$(gh api -X GET "repos/{owner}/{repo}/actions/workflows/${WORKFLOW}/runs" \
  -f branch="${branch}" -f per_page=100 \
  --jq '[.workflow_runs[]
         | select(.status != "completed" and (.id | tostring) != env.RUN_ID)]
         | length')"
if [ "${waiting}" -gt 0 ]; then
  report "Not dispatched: another ${WORKFLOW} run on ${branch} is waiting to plan the same commits."
  exit 0
fi

follow_up_head="${head}"
[ "${retry_left}" -eq 0 ] || follow_up_head=""
body="$(jq -n -c \
  --arg ref "${branch}" \
  --arg run "${RUN_ID}" \
  --arg head "${follow_up_head}" \
  --argjson inputs "${INPUTS:-null}" \
  '{ref: $ref,
    inputs: (($inputs // {}) | del(.force, .branch, ."follow-up-of", ."follow-up-head")
             | with_entries(select(.value != null and .value != "")
                            | .value |= tostring)
             | . + {"follow-up-of": $run}
             | if $head != "" then . + {"follow-up-head": $head} else . end)}')"

verb="Dispatched"
if [ -n "${DRY_RUN:-}" ]; then
  verb="Would dispatch"
  echo "[dry-run] POST repos/{owner}/{repo}/actions/workflows/${WORKFLOW}/dispatches ${body}"
elif ! gh api --method POST "repos/{owner}/{repo}/actions/workflows/${WORKFLOW}/dispatches" \
    --input - <<<"${body}"; then
  tip="$(tip_of_branch)"
  if [ "${tip}" != "${head}" ]; then
    report "Not dispatched: ${branch} moved from ${head} to ${tip:-nothing} while dispatching."
    exit 0
  fi
  echo "each-follow-up: the dispatch on ${branch} was refused" >&2
  exit 1
fi
report "${verb} a follow-up run on ${branch}: this run decided $((before - left)) commit(s)," \
  "and ${remain} remain for it."
