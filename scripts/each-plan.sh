#!/bin/bash
# Plan the sharded per-commit `rcc` build for the checked-out branch.
#
# Selects exactly the commits `scripts/each-rcc.sh` would dispatch -- on a
# series branch the commits in `<S>-green..HEAD` without an `rcc` commit-status,
# elsewhere the first-parent history on or after $SINCE without one -- and
# partitions them into contiguous, cost-balanced shards (see
# `scripts/each-partition.py`, which also decides how many shards are worth
# paying for).
# One shard becomes one matrix leg in `.github/workflows/each.yaml`, and one
# leg builds its whole slice sequentially in a single job (see
# `scripts/each-shard.sh`).
#
# Why shards instead of one dispatch per commit:
#   * a leg pays the ~4 min R/dependency setup once for ~20 commits, not once
#     per commit;
#   * consecutive commits in a leg share the runner's local ccache, where a
#     typical adjacent vendor commit is ~98% cached (VENDORING-LOOP.md, A.2);
#   * the whole batch is one workflow run: one thing to cancel, one set of logs.
#
# Statuses are read in GraphQL batches of $BATCH commits rather than one REST
# call each. This matters: GITHUB_TOKEN is limited to 1000 REST requests per
# hour per repository, so a 3000-commit backfill cannot be enumerated over REST
# at all, while the same scan costs ~30 GraphQL requests.
#
# Usage:
#   GH_TOKEN=<token> scripts/each-plan.sh
#
# Local testing example (prints the plan, writes no outputs):
#   git checkout v1.5-variegata-dev
#   GH_TOKEN=$(gh auth token) OUT=/tmp/plan.json scripts/each-plan.sh
#
# Environment variables:
#   GH_TOKEN            - token with statuses:read (required)
#   SINCE               - earliest commit date to consider (default: 2026-01-01)
#   OUT                 - plan file to write (default: plan.json)
#   FORCE               - if non-empty, ignore existing statuses and replan all
#                         (implied on a `retry-<sha>-dev` branch, which exists
#                         to have one already-decided commit judged again)
#   PENDING_TTL_HOURS   - a `pending` status older than this is treated as
#                         abandoned and the commit is replanned (default: 6,
#                         matching MAX_AGE_HOURS in scripts/vendor-gate.sh)
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
#                         (default: 1.5; 1.0 disables splitting)
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
PENDING_TTL_HOURS="${PENDING_TTL_HOURS:-6}"
SHARD_BUDGET_MINUTES="${SHARD_BUDGET_MINUTES:-300}"
MAX_SHARDS="${MAX_SHARDS:-250}"
MAX_PARALLEL="${MAX_PARALLEL:-8}"
MAX_COMMITS="${MAX_COMMITS:-0}"
SPLIT_FACTOR="${SPLIT_FACTOR:-1.5}"
SETUP_MINUTES="${SETUP_MINUTES:-5}"
FULL_BUILD_MINUTES="${FULL_BUILD_MINUTES:-40}"
FLOOR_MINUTES="${FLOOR_MINUTES:-6}"
OBJECT_SECONDS="${OBJECT_SECONDS:-9.7}"
BATCH="${BATCH:-100}"

here="$(cd "$(dirname "$0")" && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

branch="$(git symbolic-ref --short -q HEAD || git rev-parse --short HEAD)"
echo "Branch: ${branch}"
echo "Considering commits on or after ${SINCE}"

# ---------------------------------------------------------------- enumerate --
# Bound the scan to the series' world when there is one, mirroring
# scripts/each-rcc.sh exactly: everything at or before `<S>-green` is trusted
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
bounded=""
case "${branch}" in
  *-dev)
    series="${branch%-dev}"
    if git fetch -q origin \
        "+refs/heads/${series}-green:refs/remotes/origin/${series}-green" 2>/dev/null; then
      if git merge-base --is-ancestor "refs/remotes/origin/${series}-green" HEAD; then
        RANGE=("refs/remotes/origin/${series}-green..HEAD")
        bounded=1
        echo "Series branch: scanning origin/${series}-green..HEAD"
      else
        echo "origin/${series}-green is not an ancestor of HEAD -- planning nothing"
        plan_nothing
        exit 0
      fi
    fi ;;
esac

# A `retry-<sha>` pair asks for a commit that already carries a verdict to be
# judged again, on its own SHA. The alternative is amending it, which re-mints
# every descendant and throws away the runs that decided them; a rerun that
# leaves the chain alone is worth a forced replan. See
# .claude/skills/series-loop.md.
#
# The `retry-<sha>-green` sibling is what makes the request safe to honour: it
# pins the range to the single commit under retry. Without it the scan falls
# back to first-parent history since SINCE, which reaches past the series' seed
# into `main`, where no commit carries an `rcc` status -- so an unbounded retry
# branch would queue a build for every one of them. Force only when the range
# is bounded, and refuse outright when it is not.
case "${branch}" in
  retry-*-dev)
    if [ -z "${bounded}" ]; then
      echo "Retry branch without an origin/${branch%-dev}-green sibling -- planning nothing"
      plan_nothing
      exit 0
    fi
    if [ -z "${FORCE}" ]; then
      FORCE="retry"
      echo "Retry branch: replanning the range regardless of existing statuses"
    fi ;;
esac

# Oldest first, exactly as scripts/each-rcc.sh scans. `awk 'NF'` re-emits every
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

# ------------------------------------------------------------- read statuses --
# One GraphQL request per $BATCH commits. Emits "<sha> <state> <age-seconds>";
# state is lowercase, "none" when the commit carries no rcc status at all.
read_statuses() {
  local -a shas=()
  local sha

  flush_batch() {
    [ "${#shas[@]}" -eq 0 ] && return 0

    local query='query { repository(owner: "'"${owner}"'", name: "'"${repo}"'") {'
    local i=0
    for sha in "${shas[@]}"; do
      query+=" c${i}: object(oid: \"${sha}\") { ... on Commit { oid status { context(name: \"rcc\") { state createdAt } } } }"
      i=$(( i + 1 ))
    done
    query+=' } }'

    gh api graphql -f query="${query}" --jq '
      .data.repository
      | to_entries[]
      | select(.value != null)
      | [ .value.oid,
          (.value.status.context.state // "NONE" | ascii_downcase),
          (.value.status.context.createdAt // "") ]
      | @tsv'

    shas=()
  }

  while IFS= read -r sha; do
    shas+=("${sha}")
    if [ "${#shas[@]}" -ge "${BATCH}" ]; then
      flush_batch
    fi
  done
  flush_batch
}

if [ -n "${EACH_STATES_FILE:-}" ]; then
  # Offline hook for testing the planner without a token: lines of
  # "<sha> <state> [<createdAt>]". Commits absent from the file count as
  # having no status, which is also what a partial GraphQL response means.
  echo "Reading rcc statuses from ${EACH_STATES_FILE}"
  cp "${EACH_STATES_FILE}" "${workdir}/states"
elif [ "${total}" -eq 0 ]; then
  : > "${workdir}/states"
else
  owner="${GITHUB_REPOSITORY%%/*}"
  repo="${GITHUB_REPOSITORY##*/}"
  if [ -z "${GITHUB_REPOSITORY:-}" ]; then
    owner="$(gh repo view --json owner --jq .owner.login)"
    repo="$(gh repo view --json name --jq .name)"
  fi
  read_statuses < "${workdir}/all" > "${workdir}/states"
fi

# ---------------------------------------------------------------- select ----
# Keep a commit when it has no status, or a `pending` status old enough that the
# run that wrote it is gone. Every other state (success, failure, error) is a
# decision and is left alone -- the same rule scripts/each-rcc.sh applies, which
# is what keeps a rebase-and-force-push the way to re-trigger a commit.
#
# Driven by the enumeration, not by the status list, so a commit the status scan
# did not report is replanned rather than silently dropped. Order stays
# oldest-first, which is what the partitioner and the shard driver rely on.
now="$(date -u +%s)"
awk -v now="${now}" -v ttl_hours="${PENDING_TTL_HOURS}" -v force="${FORCE}" '
  function to_epoch(s,   cmd, out) {
    # RFC 3339 -> epoch. GNU date first, BSD date second; "" when absent.
    if (s == "") return 0
    cmd = "date -u -d \"" s "\" +%s 2>/dev/null || date -u -j -f %Y-%m-%dT%H:%M:%SZ \"" s "\" +%s 2>/dev/null"
    cmd | getline out
    close(cmd)
    return out + 0
  }
  # The FILENAME guard matters: with an empty status file, FNR == NR is still
  # true for the first record of the second file.
  FNR == NR && FILENAME == ARGV[1] { state[$1] = $2; created[$1] = $3; next }
  {
    sha = $1
    s = (sha in state) ? state[sha] : "none"
    if (force != "") { print sha, "replan-forced"; next }
    if (s == "none" || s == "expected") { print sha, "no-status"; next }
    if (s == "pending" && now - to_epoch(created[sha]) > ttl_hours * 3600) {
      print sha, "stale-pending"
      next
    }
    print sha, "skip:" s
  }
' "${workdir}/states" "${workdir}/all" > "${workdir}/decisions"

awk '$2 !~ /^skip:/ { print $1 }' "${workdir}/decisions" > "${workdir}/todo"

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
# Greedy contiguous fill for the fewest legs under the deadline, then split the
# longest legs to shorten wall clock, up to SPLIT_FACTOR times the runner cost
# and never past MAX_PARALLEL. See scripts/each-partition.py.
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
       "After \(.split.splits) split(s) at factor \(.split.factor): "
       + "\(.split.after.shards) shard(s), "
       + "~\(.split.after.makespan_minutes) min wall, "
       + "~\(.split.after.runner_minutes) min runner time"' \
  "${workdir}/partition.json"

if [ "${dropped}" -gt 0 ]; then
  echo "Capped to ${MAX_SHARDS} shards; ${dropped} older commit(s) deferred to the next run"
fi

# Newest first: under MAX_PARALLEL throttling the tip of the branch is decided
# first, which is what scripts/vendor-gate.sh and the promotion flow wait on.
jq -r 'reverse | to_entries | map(.value + {index: .key}) | .' \
  "${workdir}/shards.json" > "${workdir}/shards.final.json"

parallel="${MAX_PARALLEL}"
if [ "${parallel}" -gt "${shards}" ] && [ "${shards}" -gt 0 ]; then
  parallel="${shards}"
fi

jq -n \
  --arg branch "${branch}" \
  --arg since "${SINCE}" \
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
jq -r '.shards[] | "  shard \(.index): \(.commits | length) commits, ~\(.estimate_minutes) min"' "${OUT}"

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
        "| After \(.splits) split(s), factor \(.factor) | \(.after.shards) | ~\(.after.makespan_minutes) min | ~\(.after.runner_minutes) min |"' \
        "${OUT}"
      echo
      echo "| Shard | Commits | Estimate | Invalidated objects (max) |"
      echo "| --- | --- | --- | --- |"
      jq -r '.shards[] | "| \(.index) | \(.commits | length) | ~\(.estimate_minutes) min | \([.commits[].objects] | max) |"' "${OUT}"
    fi
  } >> "${GITHUB_STEP_SUMMARY}"
fi
