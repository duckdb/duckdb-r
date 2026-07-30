#!/bin/bash
# Commit the orphan `rcc` worktree and push it, re-deriving on conflict.
#
# Several writers publish to the `rcc` branch: one fan-in job per
# `.github/workflows/each.yaml` run (via `scripts/each-harvest.sh`) and the
# scheduled backstop in `.github/workflows/rcc-logs.yaml` (via
# `scripts/rcc-logs.sh`). Nothing serialises them, by choice: the obvious
# serialiser is a shared concurrency group, but a GitHub concurrency group is
# not a lock -- only one run may be *pending* per group, so a third writer
# queued behind the second cancels it outright, and a cancelled fan-in used to
# take the only copy of its per-commit logs with it. Concurrent writers that
# retry lose strictly less than serialised writers that get evicted. So a push
# can be rejected as non-fast-forward at any time, and this script is what
# survives that.
#
# (That argument has weakened, deliberately. Now that the legs publish their own
# records and logs as they go, an evicted writer loses much less than it used to,
# and serialising the once-per-run writers would be defensible. It is still not
# done, because retrying is cheap and needs no coordination -- but the reason is
# now "no benefit" rather than "actively harmful".)
#
# The recovery is deliberately *not* a rebase. `runs2.ndjson` is one file every
# writer extends, so a real race means both sides changed it with no separating
# context -- a textual conflict on essentially every collision. Instead we take
# the remote as the new base and re-run the producer:
#
#   push rejected -> fetch -> reset --hard origin/rcc -> clean -> re-derive
#
# That is cheap and correct because both producers are idempotent and dedupe
# against what is already on the branch: whatever the other writer recorded is
# skipped, and only the records that are genuinely still missing are recomputed.
# It also repairs the bootstrap race, where two runs each create an orphan `rcc`
# with unrelated histories and no rebase could help.
#
# What has changed is how often that has to happen. Records live one per file in
# `runs2.d/` now, so the only file two writers can disagree about is
# `runs2.ndjson` -- and that one is not merged either. It is brought up to date
# here on every attempt by appending the records it is missing
# (scripts/rcc-merge.sh), which needs nothing but the branch, so a retry against
# a new tip simply appends fewer of them. The matrix legs, which publish after
# every commit and are by far the most frequent writers, never come through this
# script at all; they add one file and never touch the aggregate
# (scripts/rcc-part-push.sh). This path is left for the two writers that were
# already once-per-run.
#
# Usage:
#   scripts/rcc-push.sh <commit-message> [-- <re-derive command>...]
#
# Run from the repository root (the re-derive command inherits that directory,
# and `scripts/rcc-logs.sh` reads the *source* refs from there).
#
# The re-derive command is what makes the reset non-destructive, so losing a race
# without one is a failure, not a no-op: the reset discards whatever this writer
# had staged and nothing puts it back. That used to be reported as
# "No changes; nothing to commit." and exit 0 -- success, with the records gone.
# It now says what was dropped and exits non-zero. Both real callers pass a
# command; this is about not lying when someone does not.
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

here="$(cd "$(dirname "$0")" && pwd)"

attempt=1
# Set once we hold a commit the remote has not accepted yet. Without it, an
# iteration that stages nothing -- a retry after a failed *fetch*, where the
# commit is already made and the tree is clean -- would look like "nothing to
# do" and exit 0 with the records still unpushed.
pending=0
# Set once a rejected push has reset us onto the remote, which is the point past
# which "nothing staged" can mean "our work was thrown away" rather than
# "there was nothing to do".
reset=0

while :; do
  # Appended to rather than merged, on every attempt: after a reset this sees the
  # winner's records already in the aggregate and appends only what is still
  # missing, which is what makes the reset safe.
  OUT_DIR="${OUT_DIR}" "${here}/rcc-merge.sh"

  git_out add -A
  if git_out diff --cached --quiet; then
    if [ "${pending}" -eq 0 ]; then
      if [ "${reset}" -eq 1 ] && [ "${#rederive[@]}" -eq 0 ]; then
        echo "Lost the push race and no re-derive command was given, so the" \
          "records staged here were discarded by the reset and nothing" \
          "recreated them. Re-run with a re-derive command." >&2
        exit 1
      fi
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
    reset=1
    if [ "${#rederive[@]}" -gt 0 ]; then
      "${rederive[@]}"
    fi
  else
    echo "Could not fetch origin/${BRANCH}; retrying the push as-is."
  fi
done
