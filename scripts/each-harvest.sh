#!/bin/bash
# Fan-in for `each-rcc`: make sure every commit the legs decided has a record on
# the orphan `rcc` branch.
#
# This used to be the *only* writer: the legs uploaded artifacts, said nothing,
# and this job folded them into `runs2.ndjson` once, at the end. That made the
# join a barrier -- the tip's verdict waited for the slowest leg, which can be
# five hours behind -- and it made the artifact the only copy of a per-commit log
# until then, so a cancelled run lost them and the scheduled backstop could only
# put a run-level log in their place.
#
# The legs now publish each record the moment it exists
# (scripts/rcc-part-push.sh), one file per commit, so this job's role is
# reconciliation:
#
#   1. fill in records for commits whose leg died, or could not reach the branch,
#      between deciding a commit and publishing it -- the artifact holds the same
#      record file, so this is a copy, not a reconstruction;
#   2. bring `runs2.ndjson` up to date, which is where the ~10 MB aggregate is
#      touched exactly once per run instead of once per commit
#      (scripts/rcc-merge.sh, via scripts/rcc-push.sh).
#
# A record is normally written once and then left alone, which is what makes both
# steps idempotent: re-running this after a lost push re-reads the same artifacts
# and finds nothing to do.
#
# The exception is a **retry** (.claude/skills/series-loop.md): a commit rebuilt
# on its own SHA to overturn a verdict that was never about its tree. Then the
# state under a known key legitimately changes, and the newer verdict wins --
# record, log and all. Readers take the first record for a SHA, so a second one
# would be invisible; replacing is the only thing that works.
#
# "Newer" has to be checked, not assumed, and that is a consequence of legs
# publishing as they go. A leg's verdict is on the branch within seconds, but this
# job runs when the *whole run* is done -- possibly hours later. So a retry can
# land, and be correct, while an earlier run is still building: replaying that
# earlier run's artifact here would put its stale verdict back, and nothing would
# repair it. The commit-status is already the retry's, so the planner never
# rebuilds; scripts/rcc-logs.sh skips commits that have a record. The verdict
# would simply be wrong until someone noticed.
#
# Run ids order this reliably -- they increase per repository, and a re-run keeps
# the id of the run it re-runs -- so a record from a *higher* run id than ours is
# newer than anything we can offer, and we leave it alone.
#
# `scripts/rcc-logs.sh` remains the scheduled backstop for the case where this job
# never runs at all, because the whole workflow was cancelled.
#
# Usage:
#   ARTIFACTS=<dir-of-downloaded-leg-artifacts> OUT_DIR=runs \
#     GH_TOKEN=<token> scripts/each-harvest.sh
#
# Environment variables:
#   GH_TOKEN   - token with actions:read (required)
#   ARTIFACTS  - directory the leg artifacts were downloaded into (required)
#   OUT_DIR    - the rcc worktree (default: runs)
#   RUN_ID     - workflow run to attribute reconstructed records to
#                (default: $GITHUB_RUN_ID)

set -euo pipefail

ARTIFACTS="${ARTIFACTS:?ARTIFACTS is required}"
OUT_DIR="${OUT_DIR:-runs}"
RUN_ID="${RUN_ID:-${GITHUB_RUN_ID:-}}"

here="$(cd "$(dirname "$0")" && pwd)"

if [ -z "${RUN_ID}" ]; then
  echo "RUN_ID or GITHUB_RUN_ID is required" >&2
  exit 1
fi

part_path() { printf '%s/runs2.d/%s/%s.ndjson' "${OUT_DIR}" "${1:0:2}" "$1"; }

mkdir -p "${OUT_DIR}/logs2"

# What the branch already says about a commit, from whichever layout holds it: its
# own record first, then the aggregate for the records that predate `runs2.d/` and
# are deliberately left there (scripts/rcc-merge.sh). Emits
# "<state> <run-id>"; empty when the commit is new.
#
# Both branches tolerate a malformed record rather than aborting: this loop is the
# only path by which a whole run's results reach the branch, and one unreadable
# line must not take the other twenty-six commits down with it.
recorded_record() { # <sha>
  local sha="$1" part
  part="$(part_path "${sha}")"
  if [ -f "${part}" ]; then
    jq -r '"\(.status.state // "") \(.run.id // 0)"' "${part}" 2>/dev/null || true
    return 0
  fi
  if [ -s "${OUT_DIR}/runs2.ndjson" ]; then
    grep -m 1 "\"commit\"[[:space:]]*:[[:space:]]*\"${sha}\"" "${OUT_DIR}/runs2.ndjson" \
      | jq -r '"\(.status.state // "") \(.run.id // 0)"' 2>/dev/null || true
  fi
  return 0
}

# The run object, for the one case where a leg wrote an index line but no record
# file: an old leg, or one interrupted between the two. Fetched lazily, because
# the common case needs it not at all.
run_json=""
load_run_json() {
  [ -n "${run_json}" ] && return 0
  run_json="$(gh api "repos/{owner}/{repo}/actions/runs/${RUN_ID}" \
    | jq -c -f "${here}/rcc-run-fields.jq")"
}

published=0
recorded=0
replaced=0
superseded=0
logs=0
known=0

while IFS= read -r index_file; do
  shard_dir="$(dirname "${index_file}")"
  while IFS= read -r line; do
    sha="$(jq -r '.commit' <<<"${line}")"
    state="$(jq -r '.state' <<<"${line}")"
    part="$(part_path "${sha}")"
    known_record="$(recorded_record "${sha}")"
    previous="${known_record%% *}"
    previous_run="${known_record##* }"
    [ "${known_record}" = "${previous}" ] && previous_run=0
    case "${previous_run}" in ''|*[!0-9]*) previous_run=0 ;; esac

    # Same verdict as the branch already carries: nothing to add. This is the
    # common case on a retry of the push itself, and it is what makes this
    # script safe to run again with the same artifacts.
    if [ -n "${previous}" ] && [ "${previous}" = "${state}" ]; then
      if [ -f "${part}" ]; then
        published=$(( published + 1 ))
      else
        known=$(( known + 1 ))
      fi
      # A published record whose log never made it is still worth completing --
      # and a log left over from a verdict this one overturned is worth removing,
      # which is the case the leg's own publish cannot see (it compares blob ids,
      # and a success simply has no log to compare).
      if [ "${state}" = "failure" ]; then
        if [ -f "${shard_dir}/${sha}.log" ] && [ ! -f "${OUT_DIR}/logs2/${sha}.log" ]; then
          cp -f "${shard_dir}/${sha}.log" "${OUT_DIR}/logs2/${sha}.log"
          logs=$(( logs + 1 ))
        fi
      elif [ -f "${OUT_DIR}/logs2/${sha}.log" ]; then
        echo "Commit ${sha}: ${state}, dropping the log left by an earlier verdict"
        rm -f "${OUT_DIR}/logs2/${sha}.log"
      fi
      continue
    fi

    if [ -n "${previous}" ]; then
      # A record from a later run than ours has seen something we have not -- a
      # retry, most likely. Ours is the stale one; leave the branch alone.
      if [ "${previous_run}" -gt "${RUN_ID}" ]; then
        echo "Commit ${sha}: recorded as ${previous} by run ${previous_run}," \
          "newer than this run -- keeping it, not replacing with ${state}"
        superseded=$(( superseded + 1 ))
        continue
      fi
      echo "Commit ${sha}: recorded as ${previous}, now ${state} -- replacing the record"
      # The stale log goes with the stale verdict; the new one is written below
      # if this verdict is a failure too.
      rm -f "${OUT_DIR}/logs2/${sha}.log"
      replaced=$(( replaced + 1 ))
    else
      recorded=$(( recorded + 1 ))
    fi

    mkdir -p "$(dirname "${part}")"
    if [ -f "${shard_dir}/parts/${sha}.ndjson" ]; then
      cp -f "${shard_dir}/parts/${sha}.ndjson" "${part}"
    else
      # No record in the artifact: rebuild it from the index line, which carries
      # everything except the run object and the status timestamps.
      load_run_json
      jq -c -n \
        --arg commit "${sha}" \
        --arg state "${state}" \
        --arg target_url "$(jq -r '.target_url // ""' <<<"${line}")" \
        --arg description "$(jq -r '.description // ""' <<<"${line}")" \
        --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --argjson run "${run_json}" \
        --argjson timing "$(jq -c '{shard, duration_seconds, exit_code,
                                    failed_stages: (.failed_stages // [])}' <<<"${line}")" \
        '{commit: $commit,
          status: {context: "rcc", state: $state, target_url: $target_url,
                   description: $description, created_at: $now, updated_at: $now},
          run: $run,
          timing: $timing}' > "${part}"
    fi

    # Logs are kept for failures only, matching scripts/rcc-logs.sh. The
    # difference is that this log is the *commit's* output, not the whole run's,
    # because the leg captured it per commit.
    if [ "${state}" = "failure" ] && [ -f "${shard_dir}/${sha}.log" ]; then
      cp -f "${shard_dir}/${sha}.log" "${OUT_DIR}/logs2/${sha}.log"
      logs=$(( logs + 1 ))
    fi
  done < "${index_file}"
done < <(find "${ARTIFACTS}" -name 'index.ndjson' | LC_ALL=C sort)

echo "Published by the legs: ${published}, reconciled here: ${recorded}," \
  "replaced: ${replaced}, superseded by a newer run: ${superseded}," \
  "already known: ${known}, logs kept: ${logs}"
