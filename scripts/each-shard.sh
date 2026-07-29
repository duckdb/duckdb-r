#!/bin/bash
# Build one shard of an `each-rcc` plan: many commits, one job, one workspace.
#
# Walks its slice of `plan.json` oldest-first, and for every commit resets the
# workspace to it, runs `scripts/rcc-one.sh`, and writes the `rcc` commit-status
# -- the same marker `scripts/each-rcc.sh` produces indirectly by dispatching an
# `rcc` run per commit. Downstream consumers (`scripts/vendor-gate.sh`,
# `scripts/rcc-logs.sh`, the repair skills) see no difference.
#
# Why the reuse works even though every commit starts from a clean tree:
# `R CMD build` copies the package and `R CMD check` compiles from the copy, so
# object timestamps never survive a commit anyway. The mechanism that does
# survive is **ccache**, which is content-addressed and lives on the runner's
# local disk for the whole job. A typical adjacent vendor commit recompiles only
# the handful of unity objects it invalidates -- ~98% hits, measured in
# scripts/VENDORING-LOOP.md, Appendix A.2. That is the whole point of putting
# consecutive commits in one job.
#
# Stopping is graceful, not fatal. The leg stops at its own deadline and reports
# what it did not reach, rather than being killed at GitHub's 6-hour job limit
# mid-commit. Progress is durable per commit (the status), so the next run simply
# replans whatever is left; nothing is checkpointed.
#
# Usage:
#   SHARD=1 PLAN=plan.json LOG_DIR=/tmp/each-logs GH_TOKEN=<token> \
#     scripts/each-shard.sh
#
# Environment variables:
#   GH_TOKEN          - token with statuses:write (required unless DRY_RUN)
#   SHARD             - shard number from plan.json; 1 is the oldest slice of
#                       the plan and N the branch tip (required)
#   PLAN              - plan file (default: plan.json)
#   LOG_DIR           - where per-commit logs and the index are written; must be
#                       outside the workspace, which is wiped per commit
#                       (default: $RUNNER_TEMP/each-logs)
#   DEADLINE_MINUTES  - stop starting new commits past this (default: 300)
#   LOG_TAIL          - trailing lines kept per commit (default: 10000)
#   SUMMARY_TAIL      - trailing lines of every failed stage quoted into the job
#                       summary (default: 50; 0 keeps the excerpts out)
#   SUMMARY_MAX_BYTES - stop adding excerpts past this much summary text
#                       (default: 900000; GitHub truncates a step summary at
#                       1 MiB, and a truncated summary loses the table too)
#   DRY_RUN           - if non-empty, list the commits and exit

set -uo pipefail

SHARD="${SHARD:?SHARD is required}"
PLAN="${PLAN:-plan.json}"
LOG_DIR="${LOG_DIR:-${RUNNER_TEMP:-/tmp}/each-logs}"
DEADLINE_MINUTES="${DEADLINE_MINUTES:-300}"
LOG_TAIL="${LOG_TAIL:-10000}"
SUMMARY_TAIL="${SUMMARY_TAIL:-50}"
SUMMARY_MAX_BYTES="${SUMMARY_MAX_BYTES:-900000}"

here="$(cd "$(dirname "$0")" && pwd)"
started="$(date -u +%s)"
deadline=$(( started + DEADLINE_MINUTES * 60 ))

mkdir -p "${LOG_DIR}"
index="${LOG_DIR}/index.ndjson"
: > "${index}"

# Scratch, deliberately *not* under LOG_DIR: that directory is uploaded as the
# leg's artifact, and the per-stage logs are the commit log sliced up, so
# shipping both would double every artifact for nothing.
workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT
stage_dir="${workdir}/stages"
excerpts="${workdir}/excerpts.md"
excerpts_omitted=0
: > "${excerpts}"

mapfile -t commits < <(jq -r --argjson s "${SHARD}" '.shards[] | select(.index == $s) | .commits[].sha' "${PLAN}")

if [ "${#commits[@]}" -eq 0 ]; then
  echo "Shard ${SHARD}: no commits in ${PLAN}"
  exit 0
fi

echo "Shard ${SHARD}: ${#commits[@]} commit(s), deadline in ${DEADLINE_MINUTES} min"
for sha in "${commits[@]}"; do
  echo "  ${sha}  $(git log -1 --format=%s "${sha}" 2>/dev/null | cut -c1-72)"
done

if [ -n "${DRY_RUN:-}" ]; then
  echo "[dry-run] not building"
  exit 0
fi

# ------------------------------------------------------------- status sink --
# Point the status at *this leg's* job rather than the whole run, so clicking
# through from a commit lands on the log that decided it. The URL still contains
# /actions/runs/<id>/, which is what scripts/rcc-logs.sh parses out.
job_url="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-0}"
if [ -n "${GITHUB_RUN_ID:-}" ] && [ -n "${RUNNER_NAME:-}" ]; then
  # A runner executes one job at a time, so its name identifies this leg
  # unambiguously -- more robust than matching the rendered job name.
  resolved="$(gh api \
    "repos/{owner}/{repo}/actions/runs/${GITHUB_RUN_ID}/attempts/${GITHUB_RUN_ATTEMPT:-1}/jobs" \
    --paginate --jq '.jobs[] | select(.runner_name == env.RUNNER_NAME) | .html_url' 2>/dev/null \
    | tail -n 1)"
  [ -n "${resolved}" ] && job_url="${resolved}"
fi
description="${GITHUB_WORKFLOW:-each-rcc} / shard ${SHARD}"
echo "Status target: ${job_url}"

set_status() {
  local sha="$1" state="$2"
  gh api --method POST \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "repos/{owner}/{repo}/statuses/${sha}" \
    -f "state=${state}" \
    -f "target_url=${job_url}" \
    -f "description=${description}" \
    -f "context=rcc" > /dev/null
}

# --------------------------------------------------------------- excerpts ----
# What a red commit owes the reader of the run summary: which stage broke, and
# enough of its tail to tell a compile error from a failing test -- without
# opening a 40-minute job log and scrolling to the end of it. The full log is
# still harvested onto the `rcc` branch; this is an excerpt, not the record.
#
# Fenced with four backticks, because R, roxygen and pkgdown output can contain
# a triple fence of its own, and stripped of SGR escapes, which Markdown renders
# as line noise.
emit_excerpt() {
  local sha="$1" stage="$2" log="$3"
  [ -f "${log}" ] || return 0
  if [ "$(wc -c < "${excerpts}")" -ge "${SUMMARY_MAX_BYTES}" ]; then
    excerpts_omitted=$(( excerpts_omitted + 1 ))
    return 0
  fi
  {
    printf '<details><summary><code>%s</code> &mdash; <b>%s</b> (last %s lines)</summary>\n\n' \
      "${sha:0:9}" "${stage}" "${SUMMARY_TAIL}"
    printf '````text\n'
    tail -n "${SUMMARY_TAIL}" "${log}" | sed -e 's/\r$//' -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g'
    printf '````\n\n</details>\n\n'
  } >> "${excerpts}"
}

# One excerpt per failed stage, in the order the stages ran. `outcomes.tsv` is
# written by scripts/rcc-one.sh; a stage with a log but no verdict in it is the
# one the `timeout` killed, and it is the one worth showing.
write_excerpts() {
  local sha="$1" dir="$2" fallback="$3"
  local outcomes="${dir}/outcomes.tsv"
  local -a stages=()
  local stage log

  [ "${SUMMARY_TAIL}" -gt 0 ] || return 0

  if [ -s "${outcomes}" ]; then
    mapfile -t stages < <(awk -F'\t' '$2 == "failure" { print $1 }' "${outcomes}")
  fi
  for log in "${dir}"/*.log; do
    [ -f "${log}" ] || continue
    stage="$(basename "${log}" .log)"
    awk -F'\t' -v n="${stage}" '$1 == n { seen = 1 } END { exit !seen }' \
      "${outcomes}" 2>/dev/null || stages+=("${stage}")
  done

  if [ "${#stages[@]}" -eq 0 ]; then
    # No stage detail at all: rcc-one.sh died before the first stage, or the
    # checkout is old enough not to write any. The commit's own tail beats
    # nothing.
    emit_excerpt "${sha}" "whole commit" "${fallback}"
    return 0
  fi

  for stage in "${stages[@]}"; do
    emit_excerpt "${sha}" "${stage}" "${dir}/${stage}.log"
  done
}

# ------------------------------------------------------------------- loop ----
built=0
failed=0
skipped=0
last_duration=0

for sha in "${commits[@]}"; do
  now="$(date -u +%s)"
  remaining=$(( deadline - now ))

  # Stop before starting a commit that the trailing pace says will not finish.
  # Always attempt the first one, or a leg whose budget was mis-estimated would
  # make no progress at all and the next run would repeat the mistake.
  if [ "${built}" -gt 0 ] && [ "${remaining}" -le "${last_duration}" ]; then
    echo "Deadline reached with ${remaining}s left (last commit took ${last_duration}s); stopping."
    skipped=$(( skipped + 1 ))
    continue
  fi
  if [ "${remaining}" -le 0 ]; then
    skipped=$(( skipped + 1 ))
    continue
  fi

  echo "::group::${sha}  $(git log -1 --format=%s "${sha}" | cut -c1-72)"
  commit_started="$(date -u +%s)"

  # A full reset per commit. `R CMD build` runs ./cleanup, which tars up
  # src/duckdb and deletes it; leaving that behind would poison the next
  # commit's configure step. Cleaning is cheap and makes every commit's verdict
  # identical to one from a fresh checkout -- ccache, which lives outside the
  # workspace, carries the reuse.
  if ! git checkout --force --detach "${sha}"; then
    echo "::endgroup::"
    echo "${sha}: cannot check out (rewritten history?); leaving it undecided."
    skipped=$(( skipped + 1 ))
    continue
  fi
  # `-e .ccache` is belt and braces: the workflow pins CCACHE_DIR outside the
  # workspace, but hendrikmuhs/ccache-action has historically defaulted it to
  # `.ccache` here, and wiping the cache every commit would defeat the shard.
  git clean -qfdx -e .ccache

  set_status "${sha}" "pending"

  log="${LOG_DIR}/${sha}.log"
  full_log="${LOG_DIR}/${sha}.full"
  rm -rf "${stage_dir}"
  mkdir -p "${stage_dir}"
  EACH_STAGE_DIR="${stage_dir}" \
    timeout "${remaining}s" "${here}/rcc-one.sh" > "${full_log}" 2>&1
  rc=$?
  tail -n "${LOG_TAIL}" "${full_log}" > "${log}"
  rm -f "${full_log}"
  cat "${log}"

  commit_ended="$(date -u +%s)"
  last_duration=$(( commit_ended - commit_started ))

  failed_stages='[]'
  if [ -s "${stage_dir}/outcomes.tsv" ]; then
    failed_stages="$(awk -F'\t' '$2 == "failure" { print $1 }' "${stage_dir}/outcomes.tsv" \
      | jq -Rsc 'split("\n") | map(select(length > 0))')"
  fi

  if [ "${rc}" -eq 0 ]; then
    state="success"
    built=$(( built + 1 ))
  else
    state="failure"
    failed=$(( failed + 1 ))
    built=$(( built + 1 ))
    write_excerpts "${sha}" "${stage_dir}" "${log}"
  fi
  set_status "${sha}" "${state}"

  jq -c -n \
    --arg commit "${sha}" \
    --arg state "${state}" \
    --arg target_url "${job_url}" \
    --arg description "${description}" \
    --argjson shard "${SHARD}" \
    --argjson duration "${last_duration}" \
    --argjson rc "${rc}" \
    --argjson failed_stages "${failed_stages}" \
    '{commit: $commit, state: $state, target_url: $target_url,
      description: $description, shard: $shard,
      duration_seconds: $duration, exit_code: $rc,
      failed_stages: $failed_stages}' >> "${index}"

  echo "::endgroup::"
  echo "${sha}: ${state} (${last_duration}s, exit ${rc})"

  if command -v ccache > /dev/null 2>&1; then
    ccache --show-stats --verbose 2>/dev/null | head -n 12 || true
  fi
done

# ---------------------------------------------------------------- summary ----
elapsed=$(( $(date -u +%s) - started ))
echo
echo "Shard ${SHARD}: ${built} built (${failed} failed), ${skipped} deferred, ${elapsed}s elapsed"

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Shard ${SHARD}"
    echo
    echo "| Commit | Result | Duration |"
    echo "| --- | --- | --- |"
    jq -r '"| `\(.commit[0:9])` | \(.state)"
           + ((.failed_stages // []) | if length > 0 then " (" + join(", ") + ")" else "" end)
           + " | \(.duration_seconds)s |"' "${index}"
    if [ "${skipped}" -gt 0 ]; then
      echo
      echo "${skipped} commit(s) deferred to the next run (leg deadline)."
    fi
    if [ -s "${excerpts}" ]; then
      echo
      echo "#### Failing stages"
      echo
      cat "${excerpts}"
      if [ "${excerpts_omitted}" -gt 0 ]; then
        echo "${excerpts_omitted} further excerpt(s) omitted to keep this summary under" \
             "${SUMMARY_MAX_BYTES} bytes; the full logs are on the \`rcc\` branch."
        echo
      fi
    fi
  } >> "${GITHUB_STEP_SUMMARY}"
fi

# Deliberately succeed even when commits failed: a red commit is a *result*, not
# a broken leg, and failing the job here would only obscure which one it was.
# The `rcc` statuses carry the verdicts.
exit 0
