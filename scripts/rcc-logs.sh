#!/bin/bash
# Collect results and failure logs for completed GitHub Actions runs of the
# "rcc" workflow.
#
# Designed to be run inside a worktree (or any directory) that holds the
# accumulated data:
#
#   OUT_DIR/runs.json       - array of all known runs, newest first
#   OUT_DIR/runs.ndjson     - one {id, commit, state} record per line
#   OUT_DIR/logs/<id>.log   - last $LOG_TAIL lines of the combined run log,
#                              only for runs with a failure conclusion;
#                              if GitHub has expired the logs (~90 days)
#                              the file contains a short marker instead.
#
# In-flight runs (queued / in_progress) are skipped: only confirmed results
# are recorded. Each invocation processes at most $MAX_NEW runs that are
# new since the last invocation (i.e. whose id is not already present in
# OUT_DIR/runs.ndjson). Older "still new" runs are picked up on subsequent
# invocations.
#
# Environment variables:
#   GH_TOKEN  - GitHub token with actions:read (required)
#   OUT_DIR   - destination directory (default: runs)
#   WORKFLOW  - workflow file name or id (default: R-CMD-check.yaml,
#               whose `name:` is "rcc")
#   LOG_TAIL  - number of trailing log lines to keep per failed run
#               (default: 10000)
#   PER_PAGE  - API page size (default: 100)
#   MAX_NEW   - cap on new runs processed per invocation (default: 400)
#
# Requires: gh, jq, unzip. Portable to bash on Linux and macOS.

set -euo pipefail

OUT_DIR="${OUT_DIR:-runs}"
WORKFLOW="${WORKFLOW:-R-CMD-check.yaml}"
LOG_TAIL="${LOG_TAIL:-10000}"
PER_PAGE="${PER_PAGE:-100}"
MAX_NEW="${MAX_NEW:-400}"

mkdir -p "${OUT_DIR}/logs"

# Portable temp file/dir helpers: BSD mktemp (macOS) does not accept
# --suffix or --tmpdir, but plain `mktemp` and `mktemp -d` are universal.
tmproot="$(mktemp -d)"
trap 'rm -rf "${tmproot}"' EXIT

mktmp() {
  mktemp "${tmproot}/tmp.XXXXXX"
}

existing_ndjson="$(mktmp)"
known_ids="$(mktmp)"

if [ -f "${OUT_DIR}/runs.json" ]; then
  jq -c '.[]' "${OUT_DIR}/runs.json" > "${existing_ndjson}"
fi
if [ -s "${existing_ndjson}" ]; then
  jq -r '.id' "${existing_ndjson}" | sort -u > "${known_ids}"
fi

is_failure_conclusion() {
  case "$1" in
    failure|timed_out|startup_failure|action_required) return 0 ;;
    *) return 1 ;;
  esac
}

new_ndjson="$(mktmp)"
new_count=0
seen_total=0

echo "Fetching workflow runs for ${WORKFLOW} (cap: ${MAX_NEW} new)..."

# Process substitution keeps $new_count visible in the parent shell, and
# closing FD 3 stops the upstream `gh api --paginate` once we have enough.
exec 3< <(
  gh api --paginate \
    "repos/{owner}/{repo}/actions/workflows/${WORKFLOW}/runs?per_page=${PER_PAGE}" \
    --jq '.workflow_runs[] | {
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
          }' \
    | jq -c 'select(.status == "completed")'
)

while IFS= read -r run <&3; do
  seen_total=$((seen_total + 1))
  id="$(jq -r '.id' <<<"${run}")"
  if [ -s "${known_ids}" ] && grep -qx -- "${id}" "${known_ids}"; then
    continue
  fi
  printf '%s\n' "${run}" >> "${new_ndjson}"
  new_count=$((new_count + 1))
  if [ "${new_count}" -ge "${MAX_NEW}" ]; then
    break
  fi
done

exec 3<&-

echo "Inspected ${seen_total} completed runs; ${new_count} new."

# Merge existing + new, sorted newest first.
merged_ndjson="$(mktmp)"
cat "${existing_ndjson}" "${new_ndjson}" \
  | jq -c -s 'sort_by(.created_at) | reverse | .[]' \
  > "${merged_ndjson}"

jq -s '.' "${merged_ndjson}" > "${OUT_DIR}/runs.json"
jq -c '{id, commit: .head_sha, state: (.conclusion // "unknown")}' \
  "${merged_ndjson}" > "${OUT_DIR}/runs.ndjson"

# Fetch logs for new failures.
fetched=0
expired=0
while IFS= read -r run; do
  id="$(jq -r '.id' <<<"${run}")"
  conclusion="$(jq -r '.conclusion // ""' <<<"${run}")"
  if ! is_failure_conclusion "${conclusion}"; then
    echo "Run ${id} conclusion is ${conclusion}, skipping logs"
    continue
  fi

  logfile="${OUT_DIR}/logs/${id}.log"
  if [ -f "${logfile}" ]; then
    echo "Log for run ${id} already exists, skipping fetch"
    continue
  fi

  echo "Fetching logs for run ${id} (conclusion: ${conclusion})"
  tmp_zip="$(mktmp)"
  ok=1
  gh api \
    -H 'Accept: application/vnd.github+json' \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    "repos/{owner}/{repo}/actions/runs/${id}/logs" \
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
done < "${new_ndjson}"

echo "Logs fetched: ${fetched}, unavailable: ${expired}"
echo "Done."
