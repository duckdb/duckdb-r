#!/bin/bash
# Fan-in for `each-rcc`: fold the shards' per-commit results into the orphan
# `rcc` branch, from one writer, once.
#
# Every leg uploads an artifact holding `index.ndjson` (one record per commit it
# decided) and `<sha>.log` (the trailing output). This script merges them into
# the same files `scripts/rcc-logs.sh` maintains -- `runs2.ndjson` and
# `logs2/<sha>.log` -- with the same record shape, so every consumer of the `rcc`
# branch keeps working unchanged.
#
# Legs deliberately do not push. One orphan branch with N concurrent writers
# races and leaves partial state on cancel; a single fan-in writer does not.
#
# This is the *fast* path: results land seconds after the last leg instead of
# waiting for the next `rcc-logs.yaml` tick. It is not the only path.
# `rcc-logs.yaml` stays scheduled as the backstop, because it reconstructs the
# same records from durable ground truth (commit statuses plus run logs) and is
# idempotent -- so a fan-in that never ran, because the whole workflow was
# cancelled, self-heals on the next tick.
#
# Usage:
#   ARTIFACTS=<dir-of-downloaded-leg-artifacts> OUT_DIR=runs \
#     GH_TOKEN=<token> scripts/each-harvest.sh
#
# Environment variables:
#   GH_TOKEN   - token with actions:read (required)
#   ARTIFACTS  - directory the leg artifacts were downloaded into (required)
#   OUT_DIR    - the rcc worktree (default: runs)
#   RUN_ID     - workflow run to attribute the records to
#                (default: $GITHUB_RUN_ID)

set -euo pipefail

ARTIFACTS="${ARTIFACTS:?ARTIFACTS is required}"
OUT_DIR="${OUT_DIR:-runs}"
RUN_ID="${RUN_ID:-${GITHUB_RUN_ID:-}}"

mkdir -p "${OUT_DIR}/logs2"

if [ -z "${RUN_ID}" ]; then
  echo "RUN_ID or GITHUB_RUN_ID is required" >&2
  exit 1
fi

# One call for the whole fan-in: every commit in this run shares the run object,
# and the field set matches what scripts/rcc-logs.sh records.
run_json="$(gh api "repos/{owner}/{repo}/actions/runs/${RUN_ID}" | jq -c '{
    id,
    name,
    head_branch,
    head_sha,
    event,
    status,
    conclusion,
    run_attempt,
    run_number,
    run_started_at,
    created_at,
    updated_at,
    html_url,
    display_title,
    actor: (.actor.login // null),
    triggering_actor: (.triggering_actor.login // null)
  }')"

seen="$(mktemp)"
trap 'rm -f "${seen}"' EXIT
: > "${seen}"
if [ -s "${OUT_DIR}/runs2.ndjson" ]; then
  jq -r '.commit' "${OUT_DIR}/runs2.ndjson" | sort -u > "${seen}"
fi

recorded=0
logs=0
duplicates=0

while IFS= read -r index_file; do
  shard_dir="$(dirname "${index_file}")"
  while IFS= read -r record; do
    sha="$(jq -r '.commit' <<<"${record}")"
    state="$(jq -r '.state' <<<"${record}")"

    if grep -qx -- "${sha}" "${seen}"; then
      echo "Commit ${sha}: already recorded, skipping"
      duplicates=$(( duplicates + 1 ))
      continue
    fi

    # Shaped like the REST commit-status object scripts/rcc-logs.sh stores, so
    # readers that pick out .status.state / .status.target_url do not care which
    # path produced the record.
    status_json="$(jq -c -n \
      --arg state "${state}" \
      --arg target_url "$(jq -r '.target_url' <<<"${record}")" \
      --arg description "$(jq -r '.description' <<<"${record}")" \
      --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '{context: "rcc", state: $state, target_url: $target_url,
        description: $description, created_at: $created_at,
        updated_at: $created_at}')"

    jq -c -n \
      --arg commit "${sha}" \
      --argjson status "${status_json}" \
      --argjson run "${run_json}" \
      '{commit: $commit, status: $status, run: $run}' \
      >> "${OUT_DIR}/runs2.ndjson"
    printf '%s\n' "${sha}" >> "${seen}"
    recorded=$(( recorded + 1 ))

    # Logs are kept for failures only, matching scripts/rcc-logs.sh. The
    # difference is that this log is the *commit's* output, not the whole run's,
    # because the leg captured it per commit.
    if [ "${state}" = "failure" ] && [ -f "${shard_dir}/${sha}.log" ]; then
      cp -f "${shard_dir}/${sha}.log" "${OUT_DIR}/logs2/${sha}.log"
      logs=$(( logs + 1 ))
    fi
  done < "${index_file}"
done < <(find "${ARTIFACTS}" -name 'index.ndjson' | LC_ALL=C sort)

echo "Recorded: ${recorded}, already known: ${duplicates}, logs kept: ${logs}"
