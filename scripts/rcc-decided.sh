#!/bin/bash
# Print the SHA of every commit the verdict store has decided, one per line.
#
# The verdict store is the orphan `rcc` branch: one record per commit at
# `runs2.d/<xx>/<sha>.ndjson`, published by the leg that decided it within
# seconds of the verdict existing (scripts/rcc-part-push.sh, scripts/EACH.md
# section 3). Presence is the whole question -- a commit with a record has been
# decided, a commit without one has not -- so the answer is one `ls-tree` over a
# tree-only fetch rather than a request per commit.
#
# This is what work selection reads: scripts/each-plan.sh to choose what to
# build, scripts/each-shard.sh to skip what a previous attempt already decided.
# Both used to read commit statuses instead, which made the record store and the
# status store two answers to the same question that had to be reconciled --
# newest-writer rules, a `PENDING_TTL_HOURS` heuristic, and a backstop that
# derived records *from* statuses. One store needs none of that. Statuses stay,
# as a display surface on the commit list.
#
# Parts only, no aggregate. Records that predate the per-commit layout live in
# `runs2.ndjson` alone, and are not looked up here: every one of them belongs to
# a commit decided before the sharded matrix existed, which is far below every
# series' green, and green is what bounds the planner's range. Should one ever
# fall inside a range, the cost is a rebuild rather than a wrong verdict, and
# `BACKFILL=1 scripts/rcc-merge.sh` splits the pre-split records into parts once
# and for good.
#
# Reachability is not the same question as emptiness, and the two exit
# differently: no `rcc` branch on the remote means nothing has been decided yet
# (empty output, success), while a remote that cannot be reached is an error --
# answering "nothing is decided" there would replan every commit in range.
#
# Usage:
#   scripts/rcc-decided.sh > decided.txt
#
# Environment variables:
#   GH_TOKEN / GITHUB_TOKEN - token with contents:read on the repository
#   GITHUB_REPOSITORY       - owner/repo (required unless RCC_REMOTE is set)
#   GITHUB_SERVER_URL       - default: https://github.com
#   RCC_REMOTE              - remote URL, overriding the two above; how the test
#                             harness points this at a local bare repository
#   RCC_READ_DIR            - where the branch clone is cached between calls
#                             (default: $RUNNER_TEMP/rcc-read); must be outside
#                             the workspace, which scripts/each-shard.sh wipes.
#                             Deliberately not RCC_DIR: that one belongs to
#                             scripts/rcc-part-push.sh, which configures a commit
#                             identity in it that this script has no business
#                             creating or depending on.
#   BRANCH                  - default: rcc

set -euo pipefail

RCC_READ_DIR="${RCC_READ_DIR:-${RUNNER_TEMP:-/tmp}/rcc-read}"
BRANCH="${BRANCH:-rcc}"

# A blobless clone backfills on demand, and `ls-tree` is not supposed to trigger
# any such demand. This turns a path that would quietly fetch ~220 MB of
# harvested logs into a loud failure instead; see scripts/rcc-part-push.sh, which
# pays for the same guard.
export GIT_NO_LAZY_FETCH=1

git_rcc() { git -C "${RCC_READ_DIR}" "$@"; }

# The remote URL carries the token the way actions/checkout does. GITHUB_TOKEN is
# a registered secret, so Actions masks it in the log; nothing here echoes it.
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

if [ ! -d "${RCC_READ_DIR}/.git" ]; then
  mkdir -p "$(dirname "${RCC_READ_DIR}")"
  git init -q "${RCC_READ_DIR}"
  git_rcc remote add origin "$(remote_url)"
else
  git_rcc remote set-url origin "$(remote_url)"
fi

# `--exit-code` distinguishes the two: 2 is "no such branch", anything else
# non-zero is "could not ask".
rc=0
git_rcc ls-remote --exit-code --heads origin "${BRANCH}" >/dev/null 2>&1 || rc=$?
case "${rc}" in
  0) ;;
  2)
    echo "rcc-decided: no ${BRANCH} branch on the remote -- nothing is decided yet" >&2
    exit 0
    ;;
  *)
    echo "rcc-decided: cannot reach the remote to read the ${BRANCH} branch" >&2
    exit 1
    ;;
esac

# `--filter=blob:none` is a server capability; a remote without it (or an old
# client) still works, just with the blobs we did not want. Recorded so the
# fallback is only paid once per caller rather than per call.
fetch_tip() {
  local filter="--filter=blob:none"
  [ -f "${RCC_READ_DIR}/.no-filter" ] && filter=""
  if git_rcc fetch -q --depth 1 ${filter} origin \
       "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}" 2>/dev/null; then
    return 0
  fi
  [ -n "${filter}" ] || return 1
  : > "${RCC_READ_DIR}/.no-filter"
  git_rcc fetch -q --depth 1 origin \
    "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}" 2>/dev/null
}

if ! fetch_tip; then
  echo "rcc-decided: could not fetch ${BRANCH} from the remote" >&2
  exit 1
fi

# Anything that is not a well-formed part path is not a verdict, and is dropped
# rather than guessed at.
git_rcc ls-tree -r --name-only "refs/remotes/origin/${BRANCH}" -- runs2.d |
  sed -n 's#^runs2\.d/[0-9a-f][0-9a-f]/\([0-9a-f]\{40\}\)\.ndjson$#\1#p'
