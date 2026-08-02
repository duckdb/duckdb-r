#!/bin/bash
# Publish one commit's `rcc` record -- and its log, if it failed -- to the orphan
# `rcc` branch, straight from the matrix leg that decided it.
#
# This is what makes the fan-in in scripts/each-harvest.sh a *reconciler* rather
# than the only writer. A leg builds up to ~27 commits over five hours, and until
# now every one of their records waited for the whole run to finish before it
# reached the branch: the tip's verdict, which the series loop gates on, landed
# only once the slowest leg was done. Worse, the records lived nowhere durable in
# the meantime -- a cancelled run took the leg's artifact with it, and the
# scheduled backstop can only reconstruct a *run*-level log in place of the
# per-commit one. Publishing per commit fixes both: a verdict is on the branch
# seconds after it exists.
#
# Doing that from N concurrent legs is only safe because of the layout in
# scripts/rcc-merge.sh. Every record is its own file, `runs2.d/<xx>/<sha>`,
# and every log already was, so two legs writing at the same moment write
# different paths and there is nothing to conflict on. A loser of the ref race
# just re-reads the tip and re-commits its one file; it never re-derives
# anything, and it never touches `runs2.ndjson` -- which is the expensive file,
# and the only one two writers could genuinely disagree about.
#
# A record already on the branch is normally left alone, so re-publishing the
# same verdict is free. The exception is a **retry**
# (.claude/skills/series-loop.md), where a commit is deliberately rebuilt on its
# own SHA to overturn a verdict that was never about its tree: then the newer
# verdict wins, and the stale record and its log are replaced. Two writers can
# only collide on that path if they are deciding the *same* commit at the same
# moment, which the planner does not produce -- and if it somehow happened, the
# retry loop would converge on whichever wrote last.
#
# "And its log" needs saying explicitly, because a retry that *succeeds* has no
# log to hand over -- logs are kept for failures only. So the record changing to a
# non-failure is what removes the log the previous verdict left; comparing what we
# were given would never notice it, there being nothing to compare.
#
# The branch is reached through a blobless, shallow, checkout-less clone and
# written with plumbing, because the point is to *not* pay for it. The `rcc`
# branch is ~218 MB (2.5k harvested failure logs of a megabyte each), and a leg
# needs exactly none of those bytes to add one file: `--filter=blob:none`
# fetches trees only (~200 KB), `read-tree`/`update-index`/`commit-tree` build
# the commit from the index alone, and the push sends the one new blob.
#
# Failure here is never fatal to the leg. The artifact upload and the fan-in stay
# in place as the backstop, so a leg that cannot reach the branch still gets its
# results collected the old way, one run later.
#
# Usage:
#   scripts/rcc-part-push.sh <sha> <record-file> [<log-file>]
#
# <record-file> is the single-line NDJSON record for <sha>; <log-file>, when
# given, is published as `logs2/<sha>.log`.
#
# Environment variables:
#   GH_TOKEN / GITHUB_TOKEN - token with contents:write on the repository
#   GITHUB_REPOSITORY       - owner/repo (required)
#   GITHUB_SERVER_URL       - default: https://github.com
#   RCC_DIR                 - where the branch clone is cached between calls
#                             (default: $RUNNER_TEMP/rcc-parts); must be outside
#                             the workspace, which scripts/each-shard.sh wipes
#   BRANCH                  - default: rcc
#   ATTEMPTS                - pushes to try before giving up (default: 20; a
#                             retry is a tree fetch and one staged file and the
#                             backoff caps at 8 s, so the whole budget is ~2 min
#                             against a build measured in tens of them. See the
#                             race numbers in handbook/operations/ci/per-commit/store/README.md, and
#                             scripts/rcc-parts-test.sh, which produced them.

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: $0 <sha> <record-file> [<log-file>]" >&2
  exit 1
fi

SHA="$1"
RECORD="$2"
LOG="${3:-}"

RCC_DIR="${RCC_DIR:-${RUNNER_TEMP:-/tmp}/rcc-parts}"
BRANCH="${BRANCH:-rcc}"
ATTEMPTS="${ATTEMPTS:-20}"

case "${SHA}" in
  [0-9a-f][0-9a-f][0-9a-f][0-9a-f]*) ;;
  *) echo "not a commit sha: ${SHA}" >&2; exit 1 ;;
esac

[ -s "${RECORD}" ] || { echo "record file is empty: ${RECORD}" >&2; exit 1; }

# Absolute, because every git call below runs with -C "${RCC_DIR}".
RECORD="$(cd "$(dirname "${RECORD}")" && pwd)/$(basename "${RECORD}")"
if [ -n "${LOG}" ] && [ -s "${LOG}" ]; then
  LOG="$(cd "$(dirname "${LOG}")" && pwd)/$(basename "${LOG}")"
else
  LOG=""
fi

part_path="runs2.d/${SHA:0:2}/${SHA}.ndjson"
log_path="logs2/${SHA}.log"

# Read from the record rather than taken as an argument, so the caller cannot
# disagree with the record it just wrote.
state="$(jq -r '.status.state // ""' "${RECORD}" 2>/dev/null || true)"

# A blobless clone backfills on demand, and the demand is easy to trigger by
# accident: plain `git write-tree` verifies that every index entry's object is
# present, which on this branch means quietly fetching all ~2.5k harvested logs
# -- 220 MB, per leg (measured). `--missing-ok` is what keeps it from doing so;
# this is the guard that turns any *other* path to the same mistake into a loud
# failure instead of a silent download. The leg treats a failed publish as
# non-fatal, so failing loudly costs one deferred record and nothing else.
export GIT_NO_LAZY_FETCH=1

git_rcc() { git -C "${RCC_DIR}" "$@"; }

# ------------------------------------------------------------------- clone ----
# The remote URL carries the token the way actions/checkout does. GITHUB_TOKEN is
# a registered secret, so Actions masks it in the log; nothing here echoes it.
# RCC_REMOTE overrides it outright, which is how the test harness points this at
# a local bare repository.
remote_url() {
  if [ -n "${RCC_REMOTE:-}" ]; then
    printf '%s' "${RCC_REMOTE}"
    return
  fi
  local base="${GITHUB_SERVER_URL:-https://github.com}"
  local token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
  local repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY or RCC_REMOTE is required}"
  if [ -n "${token}" ]; then
    printf 'https://x-access-token:%s@%s/%s' "${token}" "${base#https://}" "${repo}"
  else
    printf '%s/%s' "${base}" "${repo}"
  fi
}

if [ ! -d "${RCC_DIR}/.git" ]; then
  mkdir -p "$(dirname "${RCC_DIR}")"
  # A `git init` plus a filtered fetch, rather than `git clone --filter`, so the
  # branch not existing yet is an ordinary outcome rather than a clone failure:
  # the first leg to publish creates it as an orphan root commit.
  git init -q "${RCC_DIR}"
  git_rcc remote add origin "$(remote_url)"
  if [ -n "${GITHUB_ACTOR:-}" ]; then
    git_rcc config user.name "${GITHUB_ACTOR}"
    git_rcc config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
  else
    git_rcc config user.name "github-actions[bot]"
    git_rcc config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  fi
fi

# `--filter=blob:none` is a server capability; a remote without it (or an old
# client) still works, just with the blobs we did not want. Recorded so the
# fallback is only paid once per leg rather than per commit.
fetch_tip() {
  local filter="--filter=blob:none"
  [ -f "${RCC_DIR}/.no-filter" ] && filter=""
  if git_rcc fetch -q --depth 1 ${filter} origin \
       "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}" 2>/dev/null; then
    return 0
  fi
  if [ -n "${filter}" ]; then
    : > "${RCC_DIR}/.no-filter"
    if git_rcc fetch -q --depth 1 origin \
         "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}" 2>/dev/null; then
      return 0
    fi
  fi
  # No such branch on the remote yet, or the fetch failed. Either way, build on
  # nothing: a rejected push will re-enter here with the winner's tip.
  return 1
}

# ------------------------------------------------------------------- commit ---
# Stage from the index only -- no working tree is ever materialised, so none of
# the branch's blobs have to be fetched.
#
# Comparing blob ids rather than existence is what lets a retry overwrite: the
# id is already in the index, so "is this byte-for-byte what the branch has?" is
# answered without fetching the blob. Identical content stages nothing, which
# keeps a re-publish free; different content replaces it.
stage_if_changed() { # <path-on-branch> <source-file>
  local blob current
  blob="$(git_rcc hash-object -w --stdin < "$2")"
  current="$(git_rcc ls-files --format='%(objectname)' -- "$1")"
  [ "${current}" = "${blob}" ] && return 1
  git_rcc update-index --add --cacheinfo "100644,${blob},$1"
  return 0
}

# Removing an index entry needs no blob either, so this is as cheap as staging.
unstage_if_present() { # <path-on-branch>
  git_rcc ls-files --error-unmatch -- "$1" > /dev/null 2>&1 || return 1
  git_rcc update-index --force-remove -- "$1"
  return 0
}

attempt=1
while :; do
  tip=""
  if fetch_tip; then
    tip="$(git_rcc rev-parse "refs/remotes/origin/${BRANCH}")"
  fi

  if [ -n "${tip}" ]; then
    git_rcc read-tree "${tip}"
  else
    git_rcc read-tree --empty
  fi

  staged=0
  stage_if_changed "${part_path}" "${RECORD}" && staged=$(( staged + 1 ))
  if [ -n "${LOG}" ]; then
    stage_if_changed "${log_path}" "${LOG}" && staged=$(( staged + 1 ))
  elif [ "${state}" != "failure" ]; then
    # No log to publish and no failure to explain: any log on the branch belongs
    # to a verdict this record overturns.
    if unstage_if_present "${log_path}"; then
      echo "${SHA:0:9}: ${state:-decided}, dropping the log left by an earlier verdict"
      staged=$(( staged + 1 ))
    fi
  fi

  if [ "${staged}" -eq 0 ]; then
    echo "${SHA:0:9}: already published on ${BRANCH}, nothing to do"
    exit 0
  fi

  # `--missing-ok`: see GIT_NO_LAZY_FETCH above. Every entry in this index came
  # either from the remote's own tree or from the blob written a few lines up, so
  # there is nothing for the existence check to catch.
  tree="$(git_rcc write-tree --missing-ok)"
  if [ -n "${tip}" ]; then
    commit="$(git_rcc commit-tree "${tree}" -p "${tip}" \
      -m "each-rcc: ${SHA:0:9} (run ${GITHUB_RUN_ID:-local})")"
  else
    commit="$(git_rcc commit-tree "${tree}" \
      -m "each-rcc: ${SHA:0:9} (run ${GITHUB_RUN_ID:-local})")"
  fi

  if git_rcc push -q origin "${commit}:refs/heads/${BRANCH}"; then
    echo "${SHA:0:9}: published to ${BRANCH} on attempt ${attempt} (${staged} file(s))"
    exit 0
  fi

  if [ "${attempt}" -ge "${ATTEMPTS}" ]; then
    echo "${SHA:0:9}: could not publish to ${BRANCH} after ${ATTEMPTS} attempts;" \
      "the fan-in will collect it from the artifact" >&2
    exit 1
  fi

  # Jittered, so two legs rejected in the same instant do not retry in lockstep.
  # The first retry is near-immediate: losing the race means someone else has
  # already finished pushing, and all this one has to redo is a tree fetch and
  # one staged file. There is no re-derivation to wait out, which is the whole
  # point of one file per record.
  backoff=$(( attempt - 1 ))
  [ "${backoff}" -gt 8 ] && backoff=8
  sleep $(( backoff + RANDOM % 2 ))
  attempt=$(( attempt + 1 ))
done
