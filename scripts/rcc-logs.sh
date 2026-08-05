#!/bin/bash
# Collect rcc results and failure logs for commits the verdict store has no
# record for, and stage them for publication to the orphan `rcc2` branch.
#
# The scheduled backstop, and only that: the `each-rcc` legs publish their own
# verdicts within seconds of deciding them (scripts/each-shard.sh), and the run's
# fan-in recovers what a dead leg could not (scripts/each-harvest.sh). This is
# what covers the case where neither ran at all, because the whole workflow was
# cancelled -- it can reconstruct a record from the commit status and the run
# object, and a *run*-level log in place of the per-commit one.
#
# Iterates first-parent commits since $SINCE on every refs/remotes/*/*-dev
# branch (deduped by SHA) and, for each commit with no record:
#   1. Reads the `rcc` commit status from
#      repos/{owner}/{repo}/commits/<sha>/statuses
#      (skipping commits with no rcc status; they are retried next time).
#   2. Parses the workflow run id from the status `target_url`.
#   3. Fetches the run object for the latest run_attempt and skips it if the
#      run is not yet `completed` (also retried next time).
#   4. Writes a merged {commit, status, run} record to
#      OUT_DIR/runs2.d/<xx>/<sha>.ndjson.
#   5. For failed runs, downloads the run logs zip and keeps the trailing
#      $LOG_TAIL lines as OUT_DIR/logs2.d/<xx>/<sha>.log.
#
# OUT_DIR is a *staging* directory, not a checkout: this script writes the files
# a publication would add, and scripts/rcc-publish.sh puts them on the branch.
# Nothing here checks the branch out -- which commits are already decided is one
# tree-only fetch (scripts/rcc-decided.sh), and the store's bulk is harvested
# logs this script has no use for.
#
# $SINCE defaults to the store's retention window rather than a fixed date, and
# that is load-bearing: consolidation drops records past the window, so a
# backstop looking further back would re-derive every tick exactly what the next
# consolidation deletes.
#
# Designed to be run from a checkout that holds the source branches, i.e. where
# the *-dev refs live.
#
# Environment variables:
#   GH_TOKEN  - GitHub token with actions:read, statuses:read (required)
#   OUT_DIR   - staging directory to write into (default: runs)
#   LOG_TAIL  - number of trailing log lines to keep per failed run
#               (default: 10000)
#   SINCE     - earliest commit date to consider, ISO 8601
#               (default: RCC_RETENTION_DAYS ago)
#   MAX_NEW   - cap on commits inspected via the GitHub API per invocation;
#               commits already recorded don't count against this cap
#               (default: 400)
#
# Requires: gh, jq, unzip, git. Portable to bash on Linux and macOS.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
. "${here}/rcc-lib.sh"

OUT_DIR="${OUT_DIR:-runs}"
LOG_TAIL="${LOG_TAIL:-10000}"
SINCE="${SINCE:-$(rcc_cutoff "${RCC_RETENTION_DAYS}")}"
MAX_NEW="${MAX_NEW:-400}"

mkdir -p "${OUT_DIR}"

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

stage() { # <path-on-branch> -> the staging path, parents created
  local path="${OUT_DIR}/$1"
  mkdir -p "$(dirname "${path}")"
  printf '%s' "${path}"
}

# What the store already holds, in one tree-only fetch. Fatal when it cannot be
# read: answering "nothing is decided" would re-derive several hundred records
# that are already on the branch, at one API call each.
seen_shas="$(mktmp)"
if ! "${here}/rcc-decided.sh" > "${seen_shas}"; then
  echo "Could not read the verdict store; refusing to re-derive it." >&2
  exit 1
fi
LC_ALL=C sort -u "${seen_shas}" -o "${seen_shas}"

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
echo "Commits on or after ${SINCE} to inspect: ${total}"
echo "Already decided: $(wc -l < "${seen_shas}" | tr -d ' ')"

processed=0
skipped_no_status=0
skipped_pending=0
skipped_known=0
inspected=0
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

  # Shared projection, so a record written here is shaped exactly like one written
  # by an `each-rcc` leg or its fan-in; see scripts/rcc-run-fields.jq.
  run_json="$(gh api "repos/{owner}/{repo}/actions/runs/${run_id}" 2>/dev/null \
    | jq -c -f "${here}/rcc-run-fields.jq")"
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
    > "$(stage "$(rcc_part_path "${sha}")")"
  printf '%s\n' "${sha}" >> "${seen_shas}"
  processed=$((processed + 1))

  conclusion="$(jq -r '.conclusion // ""' <<<"${run_json}")"
  if ! is_failure_conclusion "${conclusion}"; then
    echo "Commit ${sha}: run ${run_id} conclusion is ${conclusion}, skipping logs"
    continue
  fi

  echo "Fetching logs for commit ${sha} run ${run_id} (conclusion: ${conclusion})"
  logfile="$(stage "$(rcc_log_path "${sha}")")"
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
echo "Logs fetched: ${fetched}, unavailable: ${expired}"
echo "Done."
