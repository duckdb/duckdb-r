#!/bin/bash
# Collect rcc results and failure logs, indexed by commit SHA.
#
# Iterates first-parent commits since $SINCE on every refs/remotes/*/*-dev
# branch (deduped by SHA) and, for each commit:
#   1. Reads the `rcc` commit status from
#      repos/{owner}/{repo}/commits/<sha>/statuses
#      (skipping commits with no rcc status; they are retried next time).
#   2. Parses the workflow run id from the status `target_url`.
#   3. Fetches the run object for the latest run_attempt and skips it if the
#      run is not yet `completed` (also retried next time).
#   4. Appends a merged {commit, status, run} record to runs2.ndjson.
#   5. For failed runs, ensures logs2/<sha>.log exists by either moving an
#      existing logs/<run_id>.log into place (expected to shrink logs/), or
#      downloading the run logs zip and keeping the trailing $LOG_TAIL lines.
#
# OUT_DIR/runs.json and OUT_DIR/runs.ndjson are intentionally not touched
# (scheduled for removal); the new state lives in OUT_DIR/runs2.ndjson and
# OUT_DIR/logs2/<sha>.log.
#
# Designed to be run inside a worktree that holds both the source branches
# (where *-dev refs live) and the accumulated data (OUT_DIR).
#
# Environment variables:
#   GH_TOKEN  - GitHub token with actions:read, statuses:read (required)
#   OUT_DIR   - destination directory (default: runs)
#   LOG_TAIL  - number of trailing log lines to keep per failed run
#               (default: 10000)
#   SINCE     - earliest commit date to consider, ISO 8601
#               (default: 2026-04-11)
#   MAX_NEW   - cap on commits inspected via the GitHub API per invocation;
#               commits already recorded in runs2.ndjson don't count against
#               this cap (default: 400)
#
# Requires: gh, jq, unzip, git. Portable to bash on Linux and macOS.

set -euo pipefail

OUT_DIR="${OUT_DIR:-runs}"
LOG_TAIL="${LOG_TAIL:-10000}"
SINCE="${SINCE:-2026-04-11}"
MAX_NEW="${MAX_NEW:-400}"

mkdir -p "${OUT_DIR}/logs2"

# Portable temp file/dir helpers: BSD mktemp (macOS) does not accept
# --suffix or --tmpdir, but plain `mktemp` and `mktemp -d` are universal.
tmproot="$(mktemp -d)"
trap 'rm -rf "${tmproot}"' EXIT

mktmp() {
  mktemp "${tmproot}/tmp.XXXXXX"
}

is_failure_conclusion() {
  case "$1" in
    failure|timed_out|startup_failure|action_required) return 0 ;;
    *) return 1 ;;
  esac
}

# SHAs already recorded in runs2.ndjson are skipped so re-running the script
# only does work for new commits.
seen_shas="$(mktmp)"
: > "${seen_shas}"
if [ -s "${OUT_DIR}/runs2.ndjson" ]; then
  jq -r '.commit' "${OUT_DIR}/runs2.ndjson" | sort -u > "${seen_shas}"
fi

# Collect first-parent commits from every refs/remotes/*/*-dev ref since
# SINCE, deduped by SHA, newest first (git's natural order).
# `for-each-ref`'s shell glob does not cross `/`, so list everything under
# refs/remotes/ and filter on the suffix.
shas_file="$(mktmp)"
{
  while IFS= read -r ref; do
    git log --first-parent --pretty=format:'%H' --after="${SINCE}" "${ref}" --
    echo
  done < <(git for-each-ref --format='%(refname)' 'refs/remotes/' \
             | awk '/-dev$/')
} | awk 'NF && !seen[$0]++' > "${shas_file}"

total="$(wc -l < "${shas_file}" | tr -d ' ')"
echo "Unique commits to inspect: ${total}"

processed=0
skipped_no_status=0
skipped_pending=0
skipped_known=0
inspected=0
moved=0
fetched=0
expired=0

while IFS= read -r sha; do
  if [ -s "${seen_shas}" ] && grep -qx -- "${sha}" "${seen_shas}"; then
    skipped_known=$((skipped_known + 1))
    continue
  fi

  if [ "${inspected}" -ge "${MAX_NEW}" ]; then
    break
  fi
  inspected=$((inspected + 1))

  status_json="$(gh api "repos/{owner}/{repo}/commits/${sha}/statuses" 2>/dev/null \
    | jq -c '[.[] | select(.context == "rcc")] | .[0] // empty')"
  if [ -z "${status_json}" ]; then
    echo "Commit ${sha}: no rcc status, skipping"
    skipped_no_status=$((skipped_no_status + 1))
    continue
  fi

  target_url="$(jq -r '.target_url // ""' <<<"${status_json}")"
  run_id="$(printf '%s' "${target_url}" \
              | sed -n 's#.*/actions/runs/\([0-9][0-9]*\).*#\1#p')"
  if [ -z "${run_id}" ]; then
    echo "Commit ${sha}: rcc status has no parseable run id (target_url=${target_url}), skipping"
    skipped_no_status=$((skipped_no_status + 1))
    continue
  fi

  run_json="$(gh api "repos/{owner}/{repo}/actions/runs/${run_id}" 2>/dev/null \
    | jq -c '{
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
  if [ -z "${run_json}" ]; then
    echo "Commit ${sha}: failed to fetch run ${run_id}, skipping"
    skipped_no_status=$((skipped_no_status + 1))
    continue
  fi

  run_status="$(jq -r '.status // ""' <<<"${run_json}")"
  if [ "${run_status}" != "completed" ]; then
    echo "Commit ${sha}: run ${run_id} status is ${run_status}, skipping for now"
    skipped_pending=$((skipped_pending + 1))
    continue
  fi

  jq -c -n \
    --arg commit "${sha}" \
    --argjson status "${status_json}" \
    --argjson run "${run_json}" \
    '{commit: $commit, status: $status, run: $run}' \
    >> "${OUT_DIR}/runs2.ndjson"
  printf '%s\n' "${sha}" >> "${seen_shas}"
  processed=$((processed + 1))

  conclusion="$(jq -r '.conclusion // ""' <<<"${run_json}")"
  if ! is_failure_conclusion "${conclusion}"; then
    continue
  fi

  logfile="${OUT_DIR}/logs2/${sha}.log"
  old_logfile="${OUT_DIR}/logs/${run_id}.log"
  if [ -f "${old_logfile}" ]; then
    mv -f "${old_logfile}" "${logfile}"
    echo "Moved existing log file for run ${run_id} into place for commit ${sha}"
    moved=$((moved + 1))
    continue
  fi

  echo "Fetching logs for commit ${sha} run ${run_id} (conclusion: ${conclusion})"
  tmp_zip="$(mktmp)"
  ok=1
  gh api \
    -H 'Accept: application/vnd.github+json' \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    "repos/{owner}/{repo}/actions/runs/${run_id}/logs" \
    > "${tmp_zip}" 2>/dev/null || ok=0

  if [ "${ok}" = "1" ] && [ -s "${tmp_zip}" ]; then
    tmp_dir="$(mktemp -d "${tmproot}/log.XXXXXX")"
    if unzip -q "${tmp_zip}" -d "${tmp_dir}" 2>/dev/null; then
      # Concatenate every per-step log file in path order (job/step
      # order) and keep only the final $LOG_TAIL lines. Avoid sort -z
      # / xargs -0 because BSD versions on older macOS lack them.
      {
        while IFS= read -r f; do
          cat -- "$f"
        done < <(find "${tmp_dir}" -type f -name '*.txt' | LC_ALL=C sort)
      } 2>/dev/null \
        | tail -n "${LOG_TAIL}" \
        > "${logfile}" || true
      if [ ! -s "${logfile}" ]; then
        printf 'logs archive contained no text\n' > "${logfile}"
      fi
      fetched=$((fetched + 1))
    else
      printf 'logs archive could not be unzipped\n' > "${logfile}"
      expired=$((expired + 1))
    fi
    rm -rf "${tmp_dir}"
  else
    printf 'logs unavailable (likely expired or access denied)\n' > "${logfile}"
    expired=$((expired + 1))
  fi
done < "${shas_file}"

echo "Inspected: ${inspected}/${MAX_NEW}, recorded: ${processed}, already known: ${skipped_known}, no rcc status: ${skipped_no_status}, pending: ${skipped_pending}"
echo "Logs moved: ${moved}, fetched: ${fetched}, unavailable: ${expired}"
echo "Done."
