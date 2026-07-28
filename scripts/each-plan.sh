#!/bin/bash
# Plan the sharded per-commit `rcc` build for the checked-out branch.
#
# Selects exactly the commits `scripts/each-rcc.sh` would dispatch -- on a
# series branch the commits in `<S>-green..HEAD` without an `rcc` commit-status,
# elsewhere the first-parent history on or after $SINCE without one -- and
# partitions them into contiguous, cost-balanced shards.
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
#   PENDING_TTL_HOURS   - a `pending` status older than this is treated as
#                         abandoned and the commit is replanned (default: 6,
#                         matching MAX_AGE_HOURS in scripts/vendor-gate.sh)
#   SHARD_BUDGET_MINUTES- wall-clock target per leg (default: 300; the GitHub
#                         job limit is 360, and scripts/each-shard.sh stops at
#                         its own deadline rather than being killed)
#   MAX_SHARDS          - matrix legs to emit (default: 250; GitHub generates at
#                         most 256 jobs per matrix)
#   MAX_PARALLEL        - legs to run concurrently (default: 8)
#   MAX_COMMITS         - hard cap on commits considered (default: 0 = no cap)
#   COLD_MINUTES        - one cold build per leg (default: 22)
#   FLOOR_MINUTES       - per-commit floor: link, install, R CMD check
#                         (default: 11)
#   OBJECT_SECONDS      - marginal cost of recompiling one unity object
#                         (default: 4.3)
#
# The two compile-bound constants are the pre-2026 measurements (36 / 7) scaled
# by the 1.64x that raising MAKEFLAGS from -j2 to every core buys on a 4-vCPU
# runner (see .github/workflows/install/action.yml). FLOOR_MINUTES is left alone:
# it is mostly link plus the serial test run, and although dropping the
# post-link `nm` sweep shortens it too, by how much is not yet measured.
# scripts/each-shard.sh records duration_seconds per commit so all three can be
# replaced with observations after the first real run.

set -euo pipefail

SINCE="${SINCE:-2026-01-01}"
OUT="${OUT:-plan.json}"
FORCE="${FORCE:-}"
PENDING_TTL_HOURS="${PENDING_TTL_HOURS:-6}"
SHARD_BUDGET_MINUTES="${SHARD_BUDGET_MINUTES:-300}"
MAX_SHARDS="${MAX_SHARDS:-250}"
MAX_PARALLEL="${MAX_PARALLEL:-8}"
MAX_COMMITS="${MAX_COMMITS:-0}"
COLD_MINUTES="${COLD_MINUTES:-22}"
FLOOR_MINUTES="${FLOOR_MINUTES:-11}"
OBJECT_SECONDS="${OBJECT_SECONDS:-4.3}"
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
RANGE=("HEAD")
case "${branch}" in
  *-dev)
    series="${branch%-dev}"
    if git fetch -q origin \
        "+refs/heads/${series}-green:refs/remotes/origin/${series}-green" 2>/dev/null; then
      if git merge-base --is-ancestor "refs/remotes/origin/${series}-green" HEAD; then
        RANGE=("refs/remotes/origin/${series}-green..HEAD")
        echo "Series branch: scanning origin/${series}-green..HEAD"
      else
        echo "origin/${series}-green is not an ancestor of HEAD -- planning nothing"
        if [ -n "${GITHUB_OUTPUT:-}" ]; then
          {
            echo 'matrix={"shard":["none"]}'
            echo "shards=0"
            echo "commits=0"
            echo "deferred=0"
            echo "max_parallel=1"
          } >> "${GITHUB_OUTPUT}"
        fi
        exit 0
      fi
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
# Contiguous greedy fill: walk oldest -> newest and close a shard as soon as one
# more commit would exceed the budget. Contiguity is the point -- it is what
# makes consecutive checkouts in a leg cheap -- so this is not bin packing, and
# greedy is optimal for "fewest contiguous parts under a fixed budget".
# A single commit heavier than the budget still gets its own shard rather than
# being dropped; the leg's own deadline handles the overrun.
awk -v cold="${COLD_MINUTES}" -v floor="${FLOOR_MINUTES}" -v objsec="${OBJECT_SECONDS}" \
    -v budget="${SHARD_BUDGET_MINUTES}" '
  {
    w = floor + $2 * objsec / 60
    if (n > 0 && cold + used + w > budget) {
      shard++
      used = 0
      n = 0
    }
    used += w
    n++
    printf "%d %s %.2f %d\n", shard, $1, w, $2
  }
' "${workdir}/objects" > "${workdir}/assigned"

# Rebuild as JSON: one object per shard, commits oldest-first inside a shard.
jq -R -s '
  [ splits("\n") | select(length > 0) | split(" ")
    | { shard: (.[0] | tonumber), sha: .[1], weight: (.[2] | tonumber), objects: (.[3] | tonumber) } ]
  | group_by(.shard)
  | map({
      index: .[0].shard,
      commits: map({sha: .sha, objects: .objects, weight_minutes: .weight}),
      estimate_minutes: ((map(.weight) | add) * 10 | round / 10)
    })
' "${workdir}/assigned" > "${workdir}/shards.json"

shards="$(jq 'length' "${workdir}/shards.json")"
echo "Shards before capping: ${shards}"

# Newest first: under MAX_PARALLEL throttling the tip of the branch is decided
# first, which is what scripts/vendor-gate.sh and the promotion flow wait on.
# Capping drops the *oldest* shards; the next run replans them.
dropped=0
if [ "${shards}" -gt "${MAX_SHARDS}" ]; then
  dropped="$(jq --argjson keep "${MAX_SHARDS}" \
    '[ .[0:(length - $keep)][].commits | length ] | add // 0' "${workdir}/shards.json")"
  jq --argjson keep "${MAX_SHARDS}" '.[(length - $keep):]' \
    "${workdir}/shards.json" > "${workdir}/capped.json"
  mv "${workdir}/capped.json" "${workdir}/shards.json"
  shards="${MAX_SHARDS}"
  echo "Capped to ${MAX_SHARDS} shards; ${dropped} older commit(s) deferred to the next run"
fi

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
  --argjson cold "${COLD_MINUTES}" \
  --argjson floor "${FLOOR_MINUTES}" \
  --argjson objsec "${OBJECT_SECONDS}" \
  --slurpfile shards "${workdir}/shards.final.json" \
  '{
     branch: $branch,
     since: $since,
     commits_in_range: $total,
     commits_already_decided: $skipped,
     commits_deferred: $dropped,
     cost_model: {
       cold_build_minutes: $cold,
       per_commit_floor_minutes: $floor,
       per_object_seconds: $objsec,
       shard_budget_minutes: $budget
     },
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
      echo "| Shard | Commits | Estimate | Invalidated objects (max) |"
      echo "| --- | --- | --- | --- |"
      jq -r '.shards[] | "| \(.index) | \(.commits | length) | ~\(.estimate_minutes) min | \([.commits[].objects] | max) |"' "${OUT}"
    fi
  } >> "${GITHUB_STEP_SUMMARY}"
fi
