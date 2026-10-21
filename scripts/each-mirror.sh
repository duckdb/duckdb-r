#!/bin/bash
# Copy the fork's per-commit verdicts onto the same commits in the canonical
# repository, as commit statuses with context `each-rcc (fork)`, for every open
# pull request whose head is in the fork. A pull request's commit list then
# shows each commit's verdict, linked to the leg in the fork that decided it.
#
# It runs in the canonical repository (.github/workflows/each-mirror.yaml),
# because a workflow in the fork cannot write a status there with its own
# token, and the canonical repository's own token can: the store it reads is
# public, so no secret crosses between the two repositories.
#
# **What it copies.** The commits of each open pull request from the fork, read
# with git as `<base>..refs/pull/<n>/head` rather than from the API, whose list
# of a pull request's commits stops at 250. Of those, the ones the verdict store
# holds a record for, `runs2.d/<xx>/<sha>.ndjson` on the fork's `rcc2` branch,
# whose newest line wins: its state, its `target_url` (the leg's job in the
# fork) and its description become the status.
#
# **Idempotent, and bounded per run.** A watermark file, kept between runs in
# the Actions cache, holds `<sha> <blob>` for every record already confirmed on
# its commit, where `<blob>` is the record's git object id. A commit is a
# candidate only when its record is not there as it is now: new to a pull
# request, newly judged, or judged again. A candidate's current status is read
# before anything is written, 100 commits to one GraphQL query, and a status
# already there with the same state and URL is confirmed and never posted
# again. So a lost cache costs one query per hundred commits, not a request per
# commit, and a run reads at most MAX_READS candidates; the rest wait for the
# next run.
#
# **Rate-limited writes.** GitHub allows about 500 content-creating requests an
# hour, so a run posts at most MAX_WRITES statuses, PAUSE seconds apart, and
# stops at the first refusal rather than pressing on into the secondary limit.
# What it did not post stays a candidate.
#
# See handbook/operations/ci/per-commit/upstream/README.md.
#
# Usage:
#   GH_TOKEN=<token> scripts/each-mirror.sh
#
# Environment variables:
#   GH_TOKEN      - token with pull-requests:read and statuses:write on REPO
#                   (required)
#   REPO          - the canonical repository (default: $GITHUB_REPOSITORY)
#   FORK          - the fork whose pull requests and store are read
#                   (default: krlmlr/duckdb-r)
#   CONTEXT       - the status context (default: "each-rcc (fork)")
#   RCC_BRANCH    - the store's branch in the fork (default: rcc2)
#   RCC_REMOTE    - where the store is fetched from
#                   (default: https://github.com/$FORK)
#   STORE_DIR     - a records-only clone of the store, kept between calls
#                   (default: $RUNNER_TEMP/each-mirror-store)
#   STATE         - the watermark file (default: $RUNNER_TEMP/each-mirror/state)
#   MAX_READS     - candidates whose status a run reads (default: 3000)
#   MAX_WRITES    - statuses a run posts (default: 300)
#   PAUSE         - seconds between two posts (default: 7.5)
#   DRY_RUN       - if non-empty, print the posts instead of sending them
#
# Runs in a clone of REPO, whose `origin` serves `refs/pull/<n>/head`.

set -euo pipefail

: "${GH_TOKEN:?GH_TOKEN is required}"
REPO="${REPO:-${GITHUB_REPOSITORY:?REPO or GITHUB_REPOSITORY is required}}"
FORK="${FORK:-krlmlr/duckdb-r}"
CONTEXT="${CONTEXT:-each-rcc (fork)}"
RCC_BRANCH="${RCC_BRANCH:-rcc2}"
export RCC_REMOTE="${RCC_REMOTE:-https://github.com/${FORK}}"
STORE_DIR="${STORE_DIR:-${RUNNER_TEMP:-/tmp}/each-mirror-store}"
STATE="${STATE:-${RUNNER_TEMP:-/tmp}/each-mirror/state}"
MAX_READS="${MAX_READS:-3000}"
MAX_WRITES="${MAX_WRITES:-300}"
PAUSE="${PAUSE:-7.5}"

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=rcc-lib.sh
. "${here}/rcc-lib.sh"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

report() {
  echo "$*"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    printf '%s\n\n' "$*" >> "${GITHUB_STEP_SUMMARY}"
  fi
}

# ------------------------------------------------- the commits that matter --

# Open pull requests whose head is in the fork: number and base branch.
gh api --paginate "repos/${REPO}/pulls?state=open&per_page=100" |
  jq -r --arg fork "${FORK}" \
    '.[] | select(.head.repo.full_name == $fork) | [.number, .base.ref] | @tsv' \
    > "${work}/pulls"

# Their commits, newest first and each once, so a capped run reads the commits
# a reviewer is looking at before the ones below them.
: > "${work}/commits"
pulls=0
while IFS=$'\t' read -r number base; do
  if ! git fetch -q origin "+refs/pull/${number}/head:refs/each-mirror/pull/${number}" \
    "+refs/heads/${base}:refs/each-mirror/base/${number}"; then
    echo "::warning::each-mirror: could not fetch pull request #${number} or its base ${base}; skipped"
    continue
  fi
  git rev-list "refs/each-mirror/base/${number}..refs/each-mirror/pull/${number}" >> "${work}/commits"
  pulls=$((pulls + 1))
done < "${work}/pulls"
awk '!seen[$0]++' "${work}/commits" > "${work}/commits.uniq"

# ------------------------------------------------------------ the records --

# A records-only clone: every record and no harvested log (scripts/rcc-lib.sh).
# In a subshell, because the helper exports GIT_NO_LAZY_FETCH, and the clone of
# REPO this runs in may be a partial one that fetches lazily.
(rcc_clone_init "${STORE_DIR}")
tip="$(rcc_fetch_tip "${STORE_DIR}" "${RCC_BRANCH}" --filter=blob:limit=16k)" || {
  echo "each-mirror: could not fetch ${RCC_BRANCH} from ${RCC_REMOTE}" >&2
  exit 1
}

# `<sha> <blob>` for every commit of an open pull request the store judged, in
# the commits' order.
git -C "${STORE_DIR}" ls-tree -r "${tip}" -- runs2.d |
  sed -n 's#^[0-7]* blob \([0-9a-f]*\)\truns2\.d/[0-9a-f][0-9a-f]/\([0-9a-f]\{40\}\)\.ndjson$#\2 \1#p' \
    > "${work}/records"
awk 'FILENAME == ARGV[1] { blob[$1] = $2; next } $1 in blob { print $1, blob[$1] }' \
  "${work}/records" "${work}/commits.uniq" > "${work}/judged"

# Candidates: a record the watermark does not hold as it is now. Every join
# here tells its files apart by name, because `NR == FNR` holds for the second
# file too when the first is empty.
mkdir -p "$(dirname "${STATE}")"
touch "${STATE}"
awk 'FILENAME == ARGV[1] { done[$0]; next } !($0 in done)' "${STATE}" "${work}/judged" > "${work}/candidates.all"
head -n "${MAX_READS}" "${work}/candidates.all" > "${work}/candidates"

# What each candidate's record says: `<sha>\t<state>\t<url>\t<description>`.
# One `cat-file --batch` for all of them; a record's lines follow the line that
# names its blob, and the newest one wins.
cut -d' ' -f2 "${work}/candidates" |
  git -C "${STORE_DIR}" cat-file --batch='%(objectname)' |
  jq -nrR '
    reduce inputs as $l ({cur: null, out: {}};
      if ($l | test("^[0-9a-f]{40}$")) then .cur = $l
      else (try ($l | fromjson) catch null) as $r
        | if ($r | type) == "object" then .out[.cur] = $r else . end
      end)
    | .out | to_entries[]
    | select(.value.status.state | IN("success", "failure", "error", "pending"))
    | [.key, .value.status.state, (.value.status.target_url // ""),
       (.value.status.description // "")] | @tsv' > "${work}/wanted.byblob"
awk -F'\t' -v OFS='\t' 'FILENAME == ARGV[1] { sha[$2] = $1; next } ($1 in sha) { $1 = sha[$1]; print }' \
  <(tr ' ' '\t' < "${work}/candidates") "${work}/wanted.byblob" > "${work}/wanted"

# ---------------------------------------------- what the commits show now --

# `<sha>\t<state>\t<url>` for every candidate that carries a status in this
# context, read 100 commits to a query.
owner="${REPO%%/*}"
name="${REPO#*/}"
: > "${work}/shown"
split -l 100 "${work}/candidates" "${work}/batch."
for batch in "${work}"/batch.*; do
  [ -s "${batch}" ] || continue
  # shellcheck disable=SC2016  # GraphQL variables, not shell ones
  query='query($owner: String!, $name: String!, $context: String!) { repository(owner: $owner, name: $name) {'
  i=0
  while read -r sha _; do
    query+=" c${i}: object(oid: \"${sha}\") { ...S }"
    i=$((i + 1))
  done < "${batch}"
  # shellcheck disable=SC2016
  query+=' } } fragment S on Commit { status { context(name: $context) { state targetUrl } } }'
  gh api graphql -f query="${query}" -f owner="${owner}" -f name="${name}" -f context="${CONTEXT}" |
    jq -r '.data.repository | to_entries[]
      | select(.value.status.context != null)
      | [(.key | ltrimstr("c")), (.value.status.context.state | ascii_downcase),
         (.value.status.context.targetUrl // "")] | @tsv' |
    awk -F'\t' -v OFS='\t' 'FILENAME == ARGV[1] { sha[FNR - 1] = $1; next } { print sha[$1], $2, $3 }' \
      <(cut -d' ' -f1 "${batch}") - >> "${work}/shown"
done

# ----------------------------------------------------------------- write --

# A status already shown with the same state and URL is confirmed as it is;
# every other one is posted, up to MAX_WRITES of them.
awk -F'\t' -v OFS='\t' 'FILENAME == ARGV[1] { shown[$1] = $2 "\t" $3; next }
  { print ((shown[$1] == ($2 "\t" $3)) ? "same" : "post"), $0 }' \
  "${work}/shown" "${work}/wanted" > "${work}/plan"

# After a refusal or past the cap nothing more is posted, and what is already
# shown is still confirmed.
: > "${work}/confirmed"
posted=0 same=0 failed=''
while IFS=$'\t' read -r verdict sha state url desc; do
  if [ "${verdict}" = same ]; then
    same=$((same + 1))
    echo "${sha}" >> "${work}/confirmed"
    continue
  fi
  if [ -n "${failed}" ] || [ "${posted}" -ge "${MAX_WRITES}" ]; then
    continue
  fi
  [ "${posted}" -eq 0 ] || sleep "${PAUSE}"
  args=(-f state="${state}" -f context="${CONTEXT}" -f description="${desc}")
  [ -z "${url}" ] || args+=(-f target_url="${url}")
  if [ -n "${DRY_RUN:-}" ]; then
    echo "[dry-run] POST repos/${REPO}/statuses/${sha} ${state} ${url}"
  elif ! gh api -X POST "repos/${REPO}/statuses/${sha}" "${args[@]}" > /dev/null; then
    failed="${sha}"
    continue
  fi
  posted=$((posted + 1))
  echo "${sha}" >> "${work}/confirmed"
done < "${work}/plan"

# The watermark: what it held for commits still in an open pull request, and
# what this run confirmed, as the record now stands. A dry run confirms nothing.
if [ -z "${DRY_RUN:-}" ]; then
  awk 'FILENAME == ARGV[1] { keep[$0]; next } ($0 in keep)' "${work}/judged" "${STATE}" > "${work}/state"
  awk 'FILENAME == ARGV[1] { ok[$1]; next } ($1 in ok)' "${work}/confirmed" "${work}/candidates" >> "${work}/state"
  LC_ALL=C sort -u "${work}/state" > "${STATE}"
fi

candidates_all="$(wc -l < "${work}/candidates.all" | tr -d ' ')"
read_now="$(wc -l < "${work}/candidates" | tr -d ' ')"
report "each-mirror: ${pulls} pull request(s) from ${FORK}," \
  "$(wc -l < "${work}/commits.uniq" | tr -d ' ') commit(s), $(wc -l < "${work}/judged" | tr -d ' ') judged;" \
  "${candidates_all} not confirmed yet, ${read_now} read this run;" \
  "${same} already shown, ${posted} posted, $((read_now - same - posted)) left for the next run."
if [ -n "${failed}" ]; then
  report "each-mirror: the post for ${failed} was refused; stopped there, the rest waits for the next run."
  exit 1
fi
