#!/bin/bash
# Plan the sharded per-commit `rcc` build for the checked-out branch.
#
# Selects the undecided commits -- on a series branch those in
# `<S>-green..HEAD` with no verdict on the `rcc` branch, elsewhere the
# first-parent history on or after $SINCE without one -- and
# partitions them into contiguous, cost-balanced shards (see
# `scripts/each-partition.py`, which also decides how many shards are worth
# paying for).
# One shard becomes one matrix leg in `.github/workflows/each.yaml`, and one
# leg builds its whole slice sequentially in a single job (see
# `scripts/each-shard.sh`). Shards are numbered along the history -- shard 1 is
# the oldest slice, shard N the branch tip -- and emitted in that same order,
# so the leg holding the oldest slice is the one queued first.
#
# Why shards instead of one dispatch per commit:
#   * a leg pays the ~4 min R/dependency setup once for ~20 commits, not once
#     per commit;
#   * consecutive commits in a leg share the runner's local ccache, where a
#     typical adjacent vendor commit is ~98% cached (VENDORING-LOOP.md, A.2);
#   * the whole batch is one workflow run: one thing to cancel, one set of logs.
#
# "Undecided" is read from the **verdict store**, not from commit statuses: a
# commit has been decided when the `rcc` branch carries a record for it, and the
# whole scan is one tree-only fetch (`scripts/rcc-decided.sh`). Statuses are a
# display surface on the commit list and decide nothing here -- which is what
# removes the reconciliation between two stores that used to answer this same
# question differently: no GraphQL scan, no `pending` state to age out, and
# nothing that has to be true about the status API for a plan to be correct.
#
# Usage:
#   GH_TOKEN=<token> scripts/each-plan.sh
#
# Local testing example (prints the plan, writes no outputs):
#   git checkout v1.5-variegata-dev
#   GH_TOKEN=$(gh auth token) OUT=/tmp/plan.json scripts/each-plan.sh
#
# Environment variables:
#   GH_TOKEN            - token with contents:read (required)
#   SINCE               - earliest commit date to consider (default: 2026-01-01)
#   OUT                 - plan file to write (default: plan.json)
#   FORCE               - if non-empty, ignore existing verdicts and replan all
#                         (a `retry-<S>-dev` branch replans its tip that way
#                         without this, which is the whole point of it)
#   SHARD_BUDGET_MINUTES- build-time target per leg, excluding job setup
#                         (default: 300; the GitHub job limit is 360, and
#                         scripts/each-shard.sh stops at its own deadline rather
#                         than being killed)
#   MAX_SHARDS          - matrix legs to emit (default: 250; GitHub generates at
#                         most 256 jobs per matrix)
#   MAX_PARALLEL        - legs to run concurrently (default: 8)
#   MAX_COMMITS         - hard cap on commits considered (default: 0 = no cap)
#   SPLIT_FACTOR        - runner-minutes the plan may cost, as a multiple of the
#                         fewest-legs plan, to shorten wall clock
#                         (default: 1.5; 1.0 disables rebalancing)
#   SETUP_MINUTES       - per-leg checkout, R and dependency install (default: 5)
#   FULL_BUILD_MINUTES  - a build on an empty ccache (default: 40)
#   FLOOR_MINUTES       - per-commit floor: link, install, R CMD check, gates
#                         (default: 6)
#   OBJECT_SECONDS      - marginal cost of recompiling one unity object
#                         (default: 9.7)
#
# The four constants are fitted to the 29 commits of runs 30406932093
# (main-fwd-dev, 24 commits over two legs) and 30422580063
# (v1.5-variegata-fwd-dev, 5 commits, one leg), RMSE 1.3 min over the 26 warm
# builds; see scripts/EACH.md section 3. Every leg still records
# duration_seconds per commit, and scripts/each-harvest.sh carries it onto the
# `rcc` branch, so the fit can be redone from a wider range at any time.

set -euo pipefail

SINCE="${SINCE:-2026-01-01}"
OUT="${OUT:-plan.json}"
FORCE="${FORCE:-}"
SHARD_BUDGET_MINUTES="${SHARD_BUDGET_MINUTES:-300}"
MAX_SHARDS="${MAX_SHARDS:-250}"
MAX_PARALLEL="${MAX_PARALLEL:-8}"
MAX_COMMITS="${MAX_COMMITS:-0}"
SPLIT_FACTOR="${SPLIT_FACTOR:-1.5}"
SETUP_MINUTES="${SETUP_MINUTES:-5}"
FULL_BUILD_MINUTES="${FULL_BUILD_MINUTES:-40}"
FLOOR_MINUTES="${FLOOR_MINUTES:-6}"
OBJECT_SECONDS="${OBJECT_SECONDS:-9.7}"

here="$(cd "$(dirname "$0")" && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

branch="$(git symbolic-ref --short -q HEAD || git rev-parse --short HEAD)"
echo "Branch: ${branch}"
echo "Considering commits on or after ${SINCE}"

# ---------------------------------------------------------------- enumerate --
# Bound the scan to the series' world when there is one:
# everything at or before `<S>-green` is trusted
# and never rebuilt, and if green exists but is not an ancestor of HEAD the
# branch is mid-surgery or on another lineage, so nothing is planned rather than
# flooding the queue with an unbounded scan.

# Reached from more than one early exit: a branch whose range cannot be bounded
# plans nothing at all rather than a little of everything.
plan_nothing() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
      echo 'matrix={"shard":["none"]}'
      echo "shards=0"
      echo "commits=0"
      echo "deferred=0"
      echo "max_parallel=1"
    } >> "${GITHUB_OUTPUT}"
  fi
}

RANGE=("HEAD")
retry=""
case "${branch}" in
  *-dev)
    series="${branch%-dev}"
    # `retry-<S>-dev` asks for one commit of series `<S>` to be judged again on
    # its own SHA -- the alternative is amending it, which re-mints every
    # descendant and throws away the runs that decided them. See
    # .claude/skills/series-loop.md.
    #
    # It is the series' own branch name with a prefix, so stripping the prefix
    # anchors the scan on `<S>-green`, the ref that already marks how far the
    # series is trusted. The retry branch needs no ref of its own for that: the
    # bound it needs is the bound the series already publishes. Only the tip is
    # forced, below -- the commit the branch was pushed at is the one being
    # asked about, and everything under it keeps the ordinary rule, so a run
    # lost further down the range is picked up in the same pass.
    case "${series}" in
      retry-*) series="${series#retry-}"; retry=1 ;;
    esac
    if git fetch -q origin \
        "+refs/heads/${series}-green:refs/remotes/origin/${series}-green" 2>/dev/null; then
      if git merge-base --is-ancestor "refs/remotes/origin/${series}-green" HEAD; then
        RANGE=("refs/remotes/origin/${series}-green..HEAD")
        echo "Series branch: scanning origin/${series}-green..HEAD"
      else
        echo "origin/${series}-green is not an ancestor of HEAD -- planning nothing"
        plan_nothing
        exit 0
      fi
    elif [ -n "${retry}" ]; then
      # Without the anchor the scan would fall back to first-parent history
      # since SINCE, reach past the series' seed into `main`, and queue a build
      # for every commit there that has no verdict. A retry branch
      # naming a series that has no green is not a request anyone can serve.
      echo "Retry branch names series ${series}, which has no green -- planning nothing"
      plan_nothing
      exit 0
    fi ;;
esac

# Oldest first. `awk 'NF'` re-emits every
# SHA newline-terminated, so the tip -- left unterminated by --pretty=format:
# under --reverse -- is not dropped, and empty input yields nothing.
git log --first-parent --reverse --pretty=format:"%H" --after="${SINCE}" "${RANGE[@]}" -- \
  | awk 'NF' > "${workdir}/all"

if [ "${MAX_COMMITS}" -gt 0 ]; then
  # Keep the newest MAX_COMMITS; the older ones are picked up by later runs.
  tail -n "${MAX_COMMITS}" "${workdir}/all" > "${workdir}/all.capped"
  mv "${workdir}/all.capped" "${workdir}/all"
fi

total="$(wc -l < "${workdir}/all" | tr -d ' ')"
echo "Commits in range: ${total}"

# ------------------------------------------------------------ read verdicts --
# Every commit the `rcc` branch holds a record for, in one tree-only fetch. A
# reachable store that says nothing about a commit is the answer "undecided";
# a store that cannot be reached is not an answer at all, and
# scripts/rcc-decided.sh exits non-zero for it rather than reporting an empty
# one, which under `set -e` stops the plan instead of replanning the world.
if [ -n "${EACH_DECIDED_FILE:-}" ]; then
  # Offline hook for testing the planner without a remote: one SHA per line.
  echo "Reading decided commits from ${EACH_DECIDED_FILE}"
  cp "${EACH_DECIDED_FILE}" "${workdir}/decided"
elif [ "${total}" -eq 0 ]; then
  : > "${workdir}/decided"
else
  "${here}/rcc-decided.sh" > "${workdir}/decided"
fi
echo "Verdicts on the rcc branch: $(wc -l < "${workdir}/decided" | tr -d ' ')"

# ---------------------------------------------------------------- select ----
# Keep a commit when the store has no record for it. A record is a decision and
# is left alone -- which is what keeps a rebase-and-force-push the way to
# re-trigger a commit, the SHA being what the record is keyed by.
#
# The tip of a `retry-<S>-dev` branch is the one exception: it is a decision the
# push exists to overturn. Only the tip, and only on that branch -- the rest of
# the range is the series' own history and keeps the ordinary rule.
#
# Driven by the enumeration, not by the record list, so a commit the store does
# not mention is replanned rather than silently dropped. Order stays
# oldest-first, which is what the partitioner and the shard driver rely on.
retry_tip=""
[ -n "${retry}" ] && retry_tip="$(git rev-parse HEAD)"
awk -v force="${FORCE}" -v retry_tip="${retry_tip}" '
  # The FILENAME guard matters: with an empty record list, FNR == NR is still
  # true for the first record of the second file.
  FNR == NR && FILENAME == ARGV[1] { decided[$1] = 1; next }
  {
    sha = $1
    if (force != "") { print sha, "replan-forced"; next }
    if (retry_tip != "" && sha == retry_tip) { print sha, "replan-retry"; next }
    if (!(sha in decided)) { print sha, "no-record"; next }
    print sha, "skip:decided"
  }
' "${workdir}/decided" "${workdir}/all" > "${workdir}/decisions"

awk '$2 !~ /^skip:/ { print $1 }' "${workdir}/decisions" > "${workdir}/todo"

# The commits that are in the plan *despite* already carrying a verdict -- a
# forced replan, or the tip of a retry branch. scripts/each-shard.sh skips a
# decided commit so that re-running a leg that died costs only what was lost,
# and this is the list that tells it which decisions are the point of the run
# rather than work already done. Carried in the plan rather than agreed on
# through the workflow, so the two cannot drift apart.
replanned="$(awk '$2 == "replan-forced" || $2 == "replan-retry" { print $1 }' \
  "${workdir}/decisions" | jq -Rsc 'split("\n") | map(select(length > 0))')"

todo="$(wc -l < "${workdir}/todo" | tr -d ' ')"
skipped=$(( total - todo ))
echo "Already decided: ${skipped}"
echo "To build: ${todo}"

# ------------------------------------------------------------------ weigh ----
# Cost per commit = fixed floor (link + install + R CMD check) plus the unity
# objects the commit invalidates, which scripts/each-cost.py derives from the
# include graph without building anything.
if [ "${todo}" -gt 0 ]; then
  echo "Building the unity-object reach map..."
  python3 "${here}/each-cost.py" map . > "${workdir}/cost-map.json"

  while IFS= read -r sha; do
    files="$(git diff --name-only "${sha}^" "${sha}" -- 2>/dev/null | tr '\n' ' ' || true)"
    printf '%s %s\n' "${sha}" "${files}"
  done < "${workdir}/todo" > "${workdir}/changed"

  python3 "${here}/each-cost.py" batch "${workdir}/cost-map.json" \
    < "${workdir}/changed" > "${workdir}/objects"
else
  : > "${workdir}/objects"
fi

# --------------------------------------------------------------- partition ---
# Greedy contiguous fill for the fewest legs under the deadline, then a rerun of
# that fill at shorter deadlines, keeping whichever plan finishes soonest at
# MAX_PARALLEL legs at a time and costs at most SPLIT_FACTOR times the runner
# minutes of the fewest-legs plan. See scripts/each-partition.py.
python3 "${here}/each-partition.py" \
  --budget "${SHARD_BUDGET_MINUTES}" \
  --setup "${SETUP_MINUTES}" \
  --full "${FULL_BUILD_MINUTES}" \
  --floor "${FLOOR_MINUTES}" \
  --object-seconds "${OBJECT_SECONDS}" \
  --max-shards "${MAX_SHARDS}" \
  --max-parallel "${MAX_PARALLEL}" \
  --split-factor "${SPLIT_FACTOR}" \
  < "${workdir}/objects" > "${workdir}/partition.json"

jq '.shards' "${workdir}/partition.json" > "${workdir}/shards.json"
shards="$(jq 'length' "${workdir}/shards.json")"
dropped="$(jq '.deferred' "${workdir}/partition.json")"

jq -r '"Fewest legs: \(.split.before.shards) shard(s), "
       + "~\(.split.before.makespan_minutes) min wall, "
       + "~\(.split.before.runner_minutes) min runner time",
       "Rebalanced at factor \(.split.factor) (\(.split.splits) extra leg(s)): "
       + "\(.split.after.shards) shard(s), "
       + "~\(.split.after.makespan_minutes) min wall, "
       + "~\(.split.after.runner_minutes) min runner time"' \
  "${workdir}/partition.json"

if [ "${dropped}" -gt 0 ]; then
  echo "Capped to ${MAX_SHARDS} shards; ${dropped} older commit(s) deferred to the next run"
fi

# Number and order now say the same thing:
#
#   * the *number* runs with history -- shard 1 holds the oldest commits of the
#     plan and shard N the branch tip, so a shard number reads the way the
#     commits do, and adjacent numbers are adjacent slices;
#   * the *order* of the array is oldest first, because that is the order
#     GitHub starts the legs in, and under MAX_PARALLEL throttling the oldest
#     undecided slice has to be decided first -- `<S>-green` only ever advances
#     over a contiguous run of green commits, so a decided tip above an
#     undecided gap moves nothing.
#
# So the matrix starts shard 1 and finishes with shard N.
jq -r 'to_entries | map(.value + {index: (.key + 1)})' \
  "${workdir}/shards.json" > "${workdir}/shards.final.json"

parallel="${MAX_PARALLEL}"
if [ "${parallel}" -gt "${shards}" ] && [ "${shards}" -gt 0 ]; then
  parallel="${shards}"
fi

jq -n \
  --arg branch "${branch}" \
  --arg since "${SINCE}" \
  --argjson replanned "${replanned}" \
  --argjson total "${total}" \
  --argjson skipped "${skipped}" \
  --argjson dropped "${dropped}" \
  --argjson budget "${SHARD_BUDGET_MINUTES}" \
  --argjson setup "${SETUP_MINUTES}" \
  --argjson full "${FULL_BUILD_MINUTES}" \
  --argjson floor "${FLOOR_MINUTES}" \
  --argjson objsec "${OBJECT_SECONDS}" \
  --slurpfile split "${workdir}/partition.json" \
  --slurpfile shards "${workdir}/shards.final.json" \
  '{
     branch: $branch,
     since: $since,
     commits_in_range: $total,
     commits_already_decided: $skipped,
     commits_deferred: $dropped,
     replanned_despite_verdict: $replanned,
     cost_model: {
       setup_minutes: $setup,
       full_build_minutes: $full,
       per_commit_floor_minutes: $floor,
       per_object_seconds: $objsec,
       shard_budget_minutes: $budget
     },
     split: $split[0].split,
     shards: $shards[0]
   }' > "${OUT}"

# An `include`-only matrix with an empty array is not a valid matrix, and the
# job's `if:` guard is not something to bet the run on -- emit a parseable
# placeholder instead. The guard is what keeps it from ever being built.
if [ "${shards}" -eq 0 ]; then
  matrix='{"shard":["none"]}'
else
  matrix="$(jq -c '{
    include: [ .shards[]
      | { shard: .index,
          label: ((.commits | length | tostring) + " commits, ~" + (.estimate_minutes | floor | tostring) + " min") } ]
  }' "${OUT}")"
fi

planned="$(jq '[.shards[].commits | length] | add // 0' "${OUT}")"

echo "Plan written to ${OUT}: ${shards} shard(s), ${planned} commit(s), max-parallel ${parallel}"
# Listed by number, which is oldest slice first, and that is also the order the
# legs are queued in.
jq -r '.shards | sort_by(.index)[]
       | "  shard \(.index): \(.commits | length) commits, ~\(.estimate_minutes) min"' "${OUT}"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "matrix=${matrix}"
    echo "shards=${shards}"
    echo "commits=${planned}"
    echo "deferred=${dropped}"
    echo "max_parallel=${parallel}"
  } >> "${GITHUB_OUTPUT}"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "## each-rcc plan"
    echo
    echo "| | |"
    echo "| --- | --- |"
    echo "| Branch | \`${branch}\` |"
    echo "| Commits since \`${SINCE}\` | ${total} |"
    echo "| Already decided | ${skipped} |"
    echo "| Planned | ${planned} |"
    echo "| Deferred (matrix cap) | ${dropped} |"
    echo "| Shards | ${shards} (max-parallel ${parallel}) |"
    echo
    if [ "${shards}" -gt 0 ]; then
      jq -r '.split |
        "| Plan | Shards | Wall clock | Runner time |",
        "| --- | --- | --- | --- |",
        "| Fewest legs | \(.before.shards) | ~\(.before.makespan_minutes) min | ~\(.before.runner_minutes) min |",
        "| Rebalanced, factor \(.factor) (+\(.splits) legs) | \(.after.shards) | ~\(.after.makespan_minutes) min | ~\(.after.runner_minutes) min |"' \
        "${OUT}"
      echo
      echo "| Shard | Commits | Estimate | Invalidated objects (max) |"
      echo "| --- | --- | --- | --- |"
      jq -r '.shards | sort_by(.index)[]
             | "| \(.index) | \(.commits | length) | ~\(.estimate_minutes) min | \([.commits[].objects] | max) |"' "${OUT}"
      echo
      echo "Shard 1 is the oldest slice; the legs are queued oldest first, so shard 1 starts first."
    fi
  } >> "${GITHUB_STEP_SUMMARY}"
fi
