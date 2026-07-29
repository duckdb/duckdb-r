#!/bin/bash
# Commit the orphan `rcc` worktree and push it, re-deriving on conflict.
#
# Several writers publish to the `rcc` branch: one fan-in job per
# `.github/workflows/each.yaml` run (via `scripts/each-harvest.sh`) and the
# scheduled backstop in `.github/workflows/rcc-logs.yaml` (via
# `scripts/rcc-logs.sh`). Nothing serialises them, by choice: the obvious
# serialiser is a shared concurrency group, but a GitHub concurrency group is
# not a lock -- only one run may be *pending* per group, so a third writer
# queued behind the second cancels it outright, and a cancelled fan-in takes
# the only copy of its per-commit logs with it. Concurrent writers that retry
# lose strictly less than serialised writers that get evicted. So a push can be
# rejected as non-fast-forward at any time, and this script is what survives
# that.
#
# The recovery is deliberately *not* a rebase. Both writers append to
# `runs2.ndjson`, so a real race means both sides added lines at EOF with no
# separating context -- a textual conflict on essentially every collision.
# Instead we take the remote as the new base and re-run the producer:
#
#   push rejected -> fetch -> reset --hard origin/rcc -> clean -> re-derive
#
# That is cheap and correct because both producers are idempotent and dedupe
# against `runs2.ndjson`: whatever the other writer already recorded is skipped,
# and only the records that are genuinely still missing are recomputed. It also
# repairs the bootstrap race, where two runs each create an orphan `rcc` with
# unrelated histories and no rebase could help.
#
# Usage:
#   scripts/rcc-push.sh <commit-message> [-- <re-derive command>...]
#
# Run from the repository root (the re-derive command inherits that directory,
# and `scripts/rcc-logs.sh` reads the *source* refs from there). Without a
# re-derive command the retry still resets onto the remote, so it degrades to
# "push whatever the remote now has" rather than looping on a doomed push.
#
# Examples:
#   scripts/rcc-push.sh "rcc-logs: refresh $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
#     -- bash scripts/rcc-logs.sh
#   scripts/rcc-push.sh "each-rcc: results from run ${GITHUB_RUN_ID}" \
#     -- bash scripts/each-harvest.sh
#
# Environment variables:
#   OUT_DIR   - the `rcc` worktree to commit (default: runs), matching the
#               OUT_DIR the producers write to
#   BRANCH    - branch to push to (default: rcc)
#   ATTEMPTS  - pushes to try before giving up (default: 6, enough headroom for
#               every plausible number of concurrent writers now that none of
#               them are serialised; the backoff caps the wait at ~1 min)

set -euo pipefail

OUT_DIR="${OUT_DIR:-runs}"
BRANCH="${BRANCH:-rcc}"
ATTEMPTS="${ATTEMPTS:-6}"

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <commit-message> [-- <re-derive command>...]" >&2
  exit 1
fi

message="$1"
shift

if [ "$#" -gt 0 ]; then
  if [ "$1" != "--" ]; then
    echo "expected \`--\` before the re-derive command, got: $1" >&2
    exit 1
  fi
  shift
fi
rederive=("$@")

if [ ! -d "${OUT_DIR}" ]; then
  echo "OUT_DIR does not exist: ${OUT_DIR}" >&2
  exit 1
fi

git_out() {
  git -C "${OUT_DIR}" "$@"
}

attempt=1
# Set once we hold a commit the remote has not accepted yet. Without it, an
# iteration that stages nothing -- a retry after a failed *fetch*, where the
# commit is already made and the tree is clean -- would look like "nothing to
# do" and exit 0 with the records still unpushed.
pending=0

while :; do
  git_out add -A
  if git_out diff --cached --quiet; then
    if [ "${pending}" -eq 0 ]; then
      # Either nothing was collected, or the other writer already published
      # everything this run had to add. Both are success.
      echo "No changes; nothing to commit."
      exit 0
    fi
  else
    git_out commit -q -m "${message}"
    pending=1
  fi

  if git_out push origin "HEAD:refs/heads/${BRANCH}"; then
    echo "Pushed to ${BRANCH} on attempt ${attempt}."
    exit 0
  fi

  if [ "${attempt}" -ge "${ATTEMPTS}" ]; then
    echo "git push failed after ${ATTEMPTS} attempts" >&2
    exit 1
  fi

  # Jittered so two writers rejected in the same instant do not back off in
  # lockstep and collide again on the retry.
  sleep $(( 2 ** attempt + RANDOM % 5 ))
  attempt=$(( attempt + 1 ))

  # Re-base on whatever is on the remote now. A failed fetch is treated as a
  # transient error: keep our commit and just retry the push.
  if git_out fetch --no-tags origin \
       "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}"; then
    echo "Push rejected; resetting onto origin/${BRANCH} and re-deriving."
    git_out reset -q --hard "refs/remotes/origin/${BRANCH}"
    # `reset --hard` leaves files we had staged as *new* behind as untracked;
    # drop them so the producer starts from the remote's exact state.
    git_out clean -qfd
    pending=0
    if [ "${#rederive[@]}" -gt 0 ]; then
      "${rederive[@]}"
    fi
  else
    echo "Could not fetch origin/${BRANCH}; retrying the push as-is."
  fi
done
