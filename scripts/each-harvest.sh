#!/bin/bash
# Fan-in for `each-rcc`: make sure every commit the legs decided has a record on
# the orphan `rcc2` branch.
#
# The legs publish each record the moment it exists (scripts/each-shard.sh via
# scripts/rcc-publish.sh), one file per commit, so this job is a *reconciler*
# rather than the only writer: it fills in records for commits whose leg died, or
# could not reach the branch, between deciding a commit and publishing it. The
# artifact holds the same record file the leg would have pushed, so this is a
# copy, not a reconstruction -- and it is the only path to a **per-commit** log
# for such a leg, which is why the job stays even though it is usually a no-op.
# (The scheduled backstop, scripts/rcc-logs.sh, can only recover a *run*-level
# log, and scripts/series-check.sh classifies failures by what the log contains.)
#
# A record is normally written once and then left alone, which is what makes this
# idempotent: re-running it after a lost push re-reads the same artifacts and
# finds nothing to do.
#
# The exception is a **retry** (.claude/skills/series-loop.md): a commit rebuilt
# on its own SHA to overturn a verdict that was never about its tree. Then the
# state under a known key legitimately changes, and the newer verdict wins --
# record, log and all.
#
# "Newer" has to be checked, not assumed, and that is a consequence of legs
# publishing as they go. A leg's verdict is on the branch within seconds, but this
# job runs when the *whole run* is done -- possibly hours later. So a retry can
# land, and be correct, while an earlier run is still building: replaying that
# earlier run's artifact here would put its stale verdict back, and nothing would
# repair it. The commit status is already the retry's, so the planner never
# rebuilds; scripts/rcc-logs.sh skips commits that have a record. The verdict
# would simply be wrong until someone noticed.
#
# Run ids order this reliably -- they increase per repository, and a re-run keeps
# the id of the run it re-runs -- so a record from a *higher* run id than ours is
# newer than anything we can offer, and we leave it alone.
#
# What the branch currently says is read through a checkout-less clone fetched
# with `--filter=blob:limit=16k`: every record is far under that bound and every
# harvested log far over it, so one fetch brings the whole verdict history and
# none of its bulk. What this script produces goes into OUT_DIR, a *staging*
# directory in the shape of the branch, which scripts/rcc-publish.sh then
# publishes in one commit.
#
# Usage:
#   ARTIFACTS=<dir-of-downloaded-leg-artifacts> OUT_DIR=runs \
#     GH_TOKEN=<token> scripts/each-harvest.sh
#
# Environment variables:
#   GH_TOKEN     - token with actions:read and contents:read (required)
#   ARTIFACTS    - directory the leg artifacts were downloaded into (required)
#   OUT_DIR      - staging directory to write into (default: runs)
#   RUN_ID       - workflow run to attribute reconstructed records to
#                  (default: $GITHUB_RUN_ID)
#   RCC_READ_DIR - where the branch clone is cached (default:
#                  $RUNNER_TEMP/rcc-harvest)
#   BRANCH       - default: rcc2

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
. "${here}/rcc-lib.sh"

ARTIFACTS="${ARTIFACTS:?ARTIFACTS is required}"
OUT_DIR="${OUT_DIR:-runs}"
RUN_ID="${RUN_ID:-${GITHUB_RUN_ID:-}}"
RCC_READ_DIR="${RCC_READ_DIR:-${RUNNER_TEMP:-/tmp}/rcc-harvest}"
BRANCH="${BRANCH:-rcc2}"

if [ -z "${RUN_ID}" ]; then
  echo "RUN_ID or GITHUB_RUN_ID is required" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
removals="${OUT_DIR}/.remove"
: > "${removals}"

stage() { # <path-on-branch> -> the staging path, parents created
  local path="${OUT_DIR}/$1"
  mkdir -p "$(dirname "${path}")"
  printf '%s' "${path}"
}

# ------------------------------------------------------------- the branch ----
# Absent is not the same as unreachable. An absent branch means nothing has been
# decided yet and every record here is new; a branch we cannot read would have us
# treat a newer verdict as absent and overwrite it, which is the one thing this
# script exists to avoid.
rcc_clone_init "${RCC_READ_DIR}"
tip=""
rc=0
rcc_branch_probe "${RCC_READ_DIR}" "${BRANCH}" || rc=$?
case "${rc}" in
  0)
    tip="$(rcc_fetch_tip "${RCC_READ_DIR}" "${BRANCH}" '--filter=blob:limit=16k')" || {
      echo "Could not fetch ${BRANCH}; refusing to reconcile against an unknown branch." >&2
      exit 1
    }
    ;;
  2) echo "No ${BRANCH} branch yet; every record in the artifacts is new." ;;
  *)
    echo "Could not reach the remote to read ${BRANCH}." >&2
    exit 1
    ;;
esac

# What the branch says about a commit, as "<state> <run-id>"; empty when the
# commit is new. Tolerates a malformed record rather than aborting: this loop is
# the only path by which a dead leg's results reach the branch, and one
# unreadable line must not take the other twenty-six commits down with it.
branch_record() { # <sha>
  [ -n "${tip}" ] || return 0
  git -C "${RCC_READ_DIR}" cat-file -p "${tip}:$(rcc_part_path "$1")" 2>/dev/null \
    | jq -r '"\(.status.state // "") \(.run.id // 0)"' 2>/dev/null || true
}

# Presence only, and answered from the tree: the log blob itself is exactly what
# the fetch filter left behind, and asking for it would drag a megabyte over the
# wire to learn something `ls-tree` already knows.
branch_has_log() { # <sha>
  [ -n "${tip}" ] || return 1
  [ -n "$(git -C "${RCC_READ_DIR}" ls-tree "${tip}" -- "$(rcc_log_path "$1")")" ]
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

while IFS= read -r index_file; do
  shard_dir="$(dirname "${index_file}")"
  while IFS= read -r line; do
    sha="$(jq -r '.commit' <<<"${line}")"
    state="$(jq -r '.state' <<<"${line}")"
    known_record="$(branch_record "${sha}")"
    previous="${known_record%% *}"
    previous_run="${known_record##* }"
    [ "${known_record}" = "${previous}" ] && previous_run=0
    case "${previous_run}" in ''|*[!0-9]*) previous_run=0 ;; esac

    # Same verdict as the branch already carries: nothing to add. This is the
    # common case -- the leg published it hours ago -- and it is what makes this
    # script safe to run again with the same artifacts.
    if [ -n "${previous}" ] && [ "${previous}" = "${state}" ]; then
      published=$(( published + 1 ))
      # A published record whose log never made it is still worth completing --
      # and a log left over from a verdict this one overturned is worth removing,
      # which is the case the leg's own publish cannot see (it compares blob ids,
      # and a success simply has no log to compare).
      if [ "${state}" = "failure" ]; then
        if [ -f "${shard_dir}/${sha}.log" ] && ! branch_has_log "${sha}"; then
          cp -f "${shard_dir}/${sha}.log" "$(stage "$(rcc_log_path "${sha}")")"
          logs=$(( logs + 1 ))
        fi
      elif branch_has_log "${sha}"; then
        echo "Commit ${sha}: ${state}, dropping the log left by an earlier verdict"
        rcc_log_path "${sha}" >> "${removals}"
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
      # The stale log goes with the stale verdict; the new one is staged below if
      # this verdict is a failure too, and a staged file wins over the removal.
      rcc_log_path "${sha}" >> "${removals}"
      replaced=$(( replaced + 1 ))
    else
      recorded=$(( recorded + 1 ))
    fi

    part="$(stage "$(rcc_part_path "${sha}")")"
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
      cp -f "${shard_dir}/${sha}.log" "$(stage "$(rcc_log_path "${sha}")")"
      logs=$(( logs + 1 ))
    fi
  done < "${index_file}"
done < <(find "${ARTIFACTS}" -name 'index.ndjson' | LC_ALL=C sort)

# A path staged for addition must not also be listed for removal: additions are
# applied first, so the removal would undo a record this run means to publish.
# Reconciled through a scratch file outside OUT_DIR, because everything inside it
# except `.remove` is something scripts/rcc-publish.sh would publish.
if [ -s "${removals}" ]; then
  scratch="$(mktemp -d)"
  LC_ALL=C sort -u "${removals}" -o "${removals}"
  ( cd "${OUT_DIR}" && find . -type f ! -path './.remove' | sed 's#^\./##' ) \
    | LC_ALL=C sort -u > "${scratch}/staged"
  LC_ALL=C comm -23 "${removals}" "${scratch}/staged" > "${scratch}/keep"
  mv -f "${scratch}/keep" "${removals}"
  rm -rf "${scratch}"
fi

echo "Published by the legs: ${published}, reconciled here: ${recorded}," \
  "replaced: ${replaced}, superseded by a newer run: ${superseded}," \
  "logs staged: ${logs}, removals staged: $(wc -l < "${removals}" | tr -d ' ')"
