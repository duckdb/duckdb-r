#!/bin/bash
# Whether the verdict store on `rcc2` can be retired: the three measurements
# D6 of plan/PLAN-vendoring-simplification.md asks for, plus the writer check
# its "one wrinkle" clause asks for.
#
# Read-only. It fetches refs and reads the REST/GraphQL API; it never pushes,
# never dispatches a workflow, and writes only under $OUT.
#
#   experiments/2026-08-rcc2-read-path/run.sh
#
# Run it against the fork. `duckdb/duckdb-r` cannot answer any of this: both
# store workflows carry `if: github.repository == 'krlmlr/duckdb-r'`, so every
# run of them there is skipped, and the series refs and the store live in the
# fork besides.
#
# Do not dispatch `rcc-logs.yaml` or `rcc-consolidate.yaml` while measuring.
# The first is measurement 1's whole signal; the second rewrites the branch
# measurement 3 is weighing.
#
# Environment:
#   GH_TOKEN / GITHUB_TOKEN - token with contents:read and statuses:read
#   GITHUB_REPOSITORY       - default: krlmlr/duckdb-r
#   REMOTE                  - git remote holding the fork's refs (default: origin)
#   SINCE                   - measurement 1's cutoff (default: 2026-08-08, when
#                             #2578 made `rcc-logs.yaml` dispatch-only)
#   WIDEN                   - measurement 2's widening: how many of the store's
#                             newest records to check for a matching status
#                             (default 250; 0 disables)
#   OUT                     - scratch and output directory (default: a mktemp -d)
#
# Cost: measurement 3 needs the store's objects, so the `rcc2` fetch moves the
# whole branch (~220 MB today). Measurement 2 spends one REST call per commit
# in flight plus one per widened record; the fork's limit is 15000/hour.

set -euo pipefail

REPO="${GITHUB_REPOSITORY:-krlmlr/duckdb-r}"
REMOTE="${REMOTE:-origin}"
SINCE="${SINCE:-2026-08-08}"
WIDEN="${WIDEN:-250}"
OUT="${OUT:-$(mktemp -d)}"
TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
: "${TOKEN:?GH_TOKEN or GITHUB_TOKEN is required}"

mkdir -p "${OUT}/statuses" "${OUT}/wide"

api() { # <path-and-query> -> the response body
  curl -sS --retry 3 \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/$1"
}

echo "measured at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "repository:  ${REPO}"
echo "remote:      ${REMOTE} -> $(git ls-remote --get-url "${REMOTE}")"
echo

# The store and the series refs, from the fork. `rcc2` is fetched whole because
# measurement 3 weighs its objects and measurement 2 reads its records.
git fetch -q "${REMOTE}" "+refs/heads/rcc2:refs/remotes/${REMOTE}/rcc2" \
  '+refs/heads/*-dev:refs/remotes/'"${REMOTE}"'/*-dev' \
  '+refs/heads/*-green:refs/remotes/'"${REMOTE}"'/*-green' \
  '+refs/heads/*-build:refs/remotes/'"${REMOTE}"'/*-build' \
  '+refs/heads/*-build-base:refs/remotes/'"${REMOTE}"'/*-build-base'

# Live series, discovered the way scripts/series-check.sh discovers them: a
# `*-build` ref that is not a `*-build-base`, and whose `-dev` and `-green`
# both exist.
series=()
while IFS= read -r b; do
  s=${b#refs/heads/}; s=${s%-build}
  case "$s" in *-build-base) continue ;; esac
  git rev-parse -q --verify "refs/remotes/${REMOTE}/$s-dev" >/dev/null || continue
  git rev-parse -q --verify "refs/remotes/${REMOTE}/$s-green" >/dev/null || continue
  series+=("$s")
done < <(git ls-remote --heads "${REMOTE}" '*-build' | cut -f2)

# ------------------------------------------------------- 1. has it been felt --
# Every `workflow_dispatch` of `rcc-logs.yaml` is a firing saying it needed the
# store and found it incomplete. The `push` and `schedule` runs are not that:
# `push` is the workflow exercising itself on a change to its own paths, and
# `schedule` stopped with #2578.

echo "=== 1. dispatches of rcc-logs.yaml (the gap being felt) ==="
api "repos/${REPO}/actions/workflows/rcc-logs.yaml/runs?per_page=100" \
  | jq -r '"runs of any event: \(.total_count)",
           (.workflow_runs | group_by(.event)[] | "  \(.[0].event): \(length)")'
echo "every workflow_dispatch run, oldest last:"
api "repos/${REPO}/actions/workflows/rcc-logs.yaml/runs?event=workflow_dispatch&per_page=100" \
  | jq -r --arg since "${SINCE}" '
      "  total: \(.total_count)   since \($since): \([.workflow_runs[]|select(.created_at >= $since)]|length)",
      (.workflow_runs[] | "  \(.created_at)  run \(.id)  by \(.triggering_actor.login)  \(.conclusion)")'
echo

# ----------------------------------------------- 2. would the replacement agree --
# Two answers per commit in flight:
#   record  - scripts/rcc-decided.sh, which is what selection reads today;
#   status  - the `rcc` commit status, which is what D6 would read instead.
# `pending` and absent are undecided on both sides. A commit decided on one
# side and not the other is what would break D6's status read.

echo "=== 2. record vs status over every live series' <S>-green..<S>-dev ==="
: > "${OUT}/inflight"
for S in "${series[@]}"; do
  n=$(git rev-list --count "${REMOTE}/$S-green..${REMOTE}/$S-dev")
  echo "  ${S}: ${n} in flight"
  git rev-list "${REMOTE}/$S-green..${REMOTE}/$S-dev" | sed "s/^/$S /" >> "${OUT}/inflight"
done
awk '{print $2}' "${OUT}/inflight" | LC_ALL=C sort -u > "${OUT}/inflight.shas"
echo "  total: $(wc -l < "${OUT}/inflight.shas") commits"

GITHUB_REPOSITORY="${REPO}" RCC_READ_DIR="${OUT}/rcc-read" \
  "$(git rev-parse --show-toplevel)/scripts/rcc-decided.sh" \
  | LC_ALL=C sort > "${OUT}/decided"
echo "  records in the store: $(wc -l < "${OUT}/decided")"

# One REST call per commit, against `/statuses` rather than `/status`: it costs
# the same and returns every post rather than the rolled-up latest, which is
# what the writer check below needs. D6's own read is the batched GraphQL query
# below; this is the same answer by a route every token serves.
fetch_statuses() { # <sha-list-file> <dir>
  export TOKEN
  < "$1" xargs -P 8 -I{} sh -c '
    out="'"$2"'/{}.json"
    [ -s "$out" ] && exit 0
    curl -sS --retry 3 -H "Authorization: Bearer ${TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/'"${REPO}"'/commits/{}/statuses?per_page=100" > "$out"'
}

latest_rcc() { # <status-json> -> the newest rcc state, "none" if there is none
  jq -r 'map(select(.context=="rcc")) | if length==0 then "none" else .[0].state end' "$1"
}

record_state() { # <sha> -> the record's own state, empty if there is no record
  git show "${REMOTE}/rcc2:runs2.d/${1:0:2}/$1.ndjson" 2>/dev/null | jq -r '.status.state'
}

fetch_statuses "${OUT}/inflight.shas" "${OUT}/statuses"

: > "${OUT}/status-state"
while IFS= read -r sha; do
  echo "${sha} $(latest_rcc "${OUT}/statuses/${sha}.json")"
done < "${OUT}/inflight.shas" > "${OUT}/status-state"

awk '$2=="success" || $2=="failure" {print $1}' "${OUT}/status-state" \
  | LC_ALL=C sort > "${OUT}/status-decided"
comm -12 "${OUT}/inflight.shas" "${OUT}/decided" > "${OUT}/record-decided"

echo "  status side: $(awk '{print $2}' "${OUT}/status-state" | sort | uniq -c | tr '\n' ' ')"
echo "  decided by status: $(wc -l < "${OUT}/status-decided")   by record: $(wc -l < "${OUT}/record-decided")"
echo "  disagreements:"
comm -23 "${OUT}/status-decided" "${OUT}/record-decided" | while IFS= read -r sha; do
  echo "    STATUS WITHOUT RECORD  ${sha}  status=$(grep -m1 "^${sha} " "${OUT}/status-state" | cut -d' ' -f2)"
done
comm -13 "${OUT}/status-decided" "${OUT}/record-decided" | while IFS= read -r sha; do
  echo "    RECORD WITHOUT STATUS  ${sha}  record=$(record_state "${sha}")  status=$(grep -m1 "^${sha} " "${OUT}/status-state" | cut -d' ' -f2)"
done
while IFS= read -r sha; do
  r=$(record_state "${sha}"); s=$(grep -m1 "^${sha} " "${OUT}/status-state" | cut -d' ' -f2)
  [ "$r" = "$s" ] || echo "    STATE MISMATCH  ${sha}  record=${r}  status=${s}"
done < "${OUT}/record-decided"
echo "    (no lines above means the two answers agree on every commit in flight)"

# The batched query D6 would actually make, recovered from this repository's own
# history -- scripts/each-plan.sh read statuses exactly this way before D1
# (#2440). It costs ~1 request per 100 commits against REST's 1 per commit,
# which is why the pre-D1 planner batched: a backfill cannot be enumerated over
# REST at all. Some tokens serve only a pinned set of GraphQL operations; when
# this one does not, the REST answer above stands on its own and the run says so.
echo "  cross-check by the batched GraphQL query D6 would use:"
owner="${REPO%%/*}"; name="${REPO##*/}"
: > "${OUT}/graphql-state"
graphql_ok=1
i=0; q=""
flush() {
  [ -z "$q" ] && return 0
  local body
  # jq -n --arg does the JSON escaping, so the query carries plain `"`.
  body=$(jq -n --arg q "query { repository(owner: \"${owner}\", name: \"${name}\") {${q} } }" '{query: $q}' \
    | curl -sS --retry 3 -X POST -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" -d @- https://api.github.com/graphql)
  if ! jq -e '.data.repository' >/dev/null 2>&1 <<<"${body}"; then
    graphql_ok=0
    echo "    unavailable: $(jq -r '.message // (.errors[0].message) // "no data"' <<<"${body}" | head -c 160)"
    q=""; return 0
  fi
  jq -r '.data.repository | to_entries[] | select(.value != null)
         | "\(.value.oid) \(.value.status.context.state // "NONE" | ascii_downcase)"' \
    <<<"${body}" >> "${OUT}/graphql-state"
  q=""
}
while IFS= read -r sha; do
  q+=" c${i}: object(oid: \"${sha}\") { ... on Commit { oid status { context(name: \"rcc\") { state createdAt } } } }"
  i=$(( i + 1 ))
  if [ $(( i % 100 )) -eq 0 ]; then flush; [ "${graphql_ok}" -eq 1 ] || break; fi
done < "${OUT}/inflight.shas"
[ "${graphql_ok}" -eq 1 ] && flush
if [ "${graphql_ok}" -eq 1 ]; then
  LC_ALL=C sort "${OUT}/graphql-state" -o "${OUT}/graphql-state"
  if diff -q <(LC_ALL=C sort "${OUT}/status-state") "${OUT}/graphql-state" >/dev/null; then
    echo "    agrees with the REST read on all $(wc -l < "${OUT}/graphql-state") commits"
  else
    echo "    DIFFERS from the REST read:"
    diff <(LC_ALL=C sort "${OUT}/status-state") "${OUT}/graphql-state" | sed 's/^/      /'
  fi
fi
echo

# The wrinkle D6 names: the `rcc` context is not the leg's alone.
# `R-CMD-check-status.yaml` writes the same context for the ordinary check, and
# branch protection reads it. `each-shard.sh` describes its posts
# "each-rcc / shard N"; `R-CMD-check-status.yaml` describes its own with the
# triggering run's name. So the descriptions say who wrote what, and a series
# branch that shows anything but the leg is a status D6 would misread.
echo "=== 2b. who writes the rcc context on these commits ==="
cat "${OUT}"/statuses/*.json \
  | jq -r '.[] | "\(.context)|\(.creator.login)|\(.description)"' \
  | sed 's/shard [0-9]*/shard N/' | sort | uniq -c | sed 's/^/  /'
echo
echo "  R-CMD-check.yaml runs from the branch it checks, so each series ref"
echo "  carries its own push filter. A filter matching the branch's own name is"
echo "  the template check firing there, and R-CMD-check-status.yaml writing rcc:"
for S in "${series[@]}"; do
  for r in "$S-dev" "$S-build"; do
    pats=$(git show "${REMOTE}/$r:.github/workflows/R-CMD-check.yaml" 2>/dev/null \
           | sed -n '/^on:/,/^  pull_request:/p' | grep -E "^ +- " | sed "s/^ *- *//; s/['\"]//g")
    [ -z "${pats}" ] && { echo "    ${r}: <no workflow file>"; continue; }
    # GitHub applies these in order, a leading `!` excluding what it matches.
    hit=""
    while IFS= read -r p; do
      case "$p" in
        '!'*) [[ "$r" == ${p#!} ]] && hit="" ;;
        *)    [[ "$r" == $p ]] && hit="$p" ;;
      esac
    done <<< "${pats}"
    echo "    ${r}: [$(tr '\n' ' ' <<< "${pats}" | sed 's/ $//')]"
    if [ -n "${hit}" ]; then
      echo "      FIRES ON ITSELF via '${hit}' -- a second writer of the rcc context"
    fi
  done
done
echo
echo "  and what the template check has actually written in this fork:"
api "repos/${REPO}/actions/workflows/R-CMD-check.yaml/runs?per_page=100" > "${OUT}/rcc-workflow-runs.json"
jq -r '"    runs of the `rcc` workflow: \(.total_count)",
       (.workflow_runs[] | select(.head_branch | test("-dev$|-build$|-green$|-base$"))
        | "    on a series ref: \(.created_at)  \(.head_branch)  \(.event)  head=\(.head_sha[0:9])  \(.conclusion)")' \
  "${OUT}/rcc-workflow-runs.json"

# Whatever it stamped is a status D6 would read. Whether that matters depends on
# one thing: can the SHA reach a `<S>-green..<S>-dev` range, which is all
# selection ever asks about?
jq -r '.workflow_runs[] | select(.head_branch | test("-dev$|-build$|-green$|-base$")) | .head_sha' \
  "${OUT}/rcc-workflow-runs.json" | LC_ALL=C sort -u > "${OUT}/template-stamped.shas"
while IFS= read -r sha; do
  [ -z "${sha}" ] && continue
  echo "    ${sha}"
  api "repos/${REPO}/commits/${sha}/statuses?per_page=100" \
    | jq -r 'map(select(.context=="rcc"))
             | "      rcc statuses: \(length), newest \(if length==0 then "none" else "\(.[0].state) (\(.[0].description))" end)"'
  echo "      record on rcc2: $(git cat-file -e "${REMOTE}/rcc2:runs2.d/${sha:0:2}/${sha}.ndjson" 2>/dev/null && echo yes || echo NO)"
  inflight=$(grep -c "^${sha}$" "${OUT}/inflight.shas" || true)
  echo "      in a <S>-green..<S>-dev range now: $([ "${inflight}" -gt 0 ] && echo YES || echo no)"
  for S in "${series[@]}"; do
    git merge-base --is-ancestor "${sha}" "${REMOTE}/$S-dev" 2>/dev/null \
      && echo "      ancestor of ${S}-dev"
  done
done < "${OUT}/template-stamped.shas"

# A buffer commit is re-minted when it is consumed onto `-dev`, so its SHA never
# enters selection's range. That is the bound on the leak above, and it is a
# property to check rather than assume.
echo "    SHAs shared between (<S>-build-base..<S>-build) and (<S>-green..<S>-dev):"
for S in "${series[@]}"; do
  git rev-parse -q --verify "${REMOTE}/$S-build-base" >/dev/null 2>&1 || continue
  n=$(comm -12 \
        <(git rev-list "${REMOTE}/$S-build-base..${REMOTE}/$S-build" 2>/dev/null | LC_ALL=C sort) \
        <(git rev-list "${REMOTE}/$S-green..${REMOTE}/$S-dev" 2>/dev/null | LC_ALL=C sort) | wc -l)
  echo "      ${S}: ${n}"
done
echo

# The widening. The range above is bounded by `-green`, so most of it is not
# built yet and only a handful of commits are decided at all -- a thin sample
# for a go/no-go. The store's newest records are the same question with the
# sample the range cannot give: every one of them is decided by construction,
# so each is a chance for a record to exist where a status does not.
if [ "${WIDEN}" -gt 0 ]; then
  echo "=== 2c. widening: the store's ${WIDEN} newest records, each against its status ==="
  git ls-tree -r "${REMOTE}/rcc2" -- runs2.d | awk '$4 ~ /\.ndjson$/ {print $3}' \
    | git cat-file --batch \
    | jq -rR 'fromjson? | "\(.status.created_at // .run.created_at // "") \(.commit)"' \
    | grep -v '^ ' | LC_ALL=C sort > "${OUT}/record-times"
  tail -n "${WIDEN}" "${OUT}/record-times" | awk '{print $2}' > "${OUT}/wide.shas"
  fetch_statuses "${OUT}/wide.shas" "${OUT}/wide"
  agree=0; bad=0
  while IFS= read -r sha; do
    s=$(latest_rcc "${OUT}/wide/${sha}.json"); r=$(record_state "${sha}")
    case "$s" in
      success|failure)
        if [ "$s" = "$r" ]; then agree=$(( agree + 1 ))
        else bad=$(( bad + 1 )); echo "    STATE MISMATCH  ${sha}  record=${r}  status=${s}"; fi ;;
      *) bad=$(( bad + 1 )); echo "    RECORD WITHOUT DECIDED STATUS  ${sha}  record=${r}  status=${s}" ;;
    esac
  done < "${OUT}/wide.shas"
  echo "  agree: ${agree}   disagree: ${bad}   (of $(wc -l < "${OUT}/wide.shas"))"
  echo "  writers seen here:"
  cat "${OUT}"/wide/*.json | jq -r '.[] | "\(.context)|\(.creator.login)|\(.description)"' \
    | sed 's/shard [0-9]*/shard N/' | sort -u | sed 's/^/    /'
  echo
fi

# ------------------------------------------------------ 3. what keeping it costs --
# Consolidation is manual and RCC_RETENTION_DAYS is 180, so nothing has been
# pruned unless someone dispatched it -- which is a thing to check, not assume.

echo "=== 3. what the store costs to keep ==="
tip=$(git rev-parse "${REMOTE}/rcc2")
echo "  tip:     ${tip}  $(git log -1 --format='%ci  %s' "${tip}")"
echo "  commits: $(git rev-list --count "${tip}")"
git rev-list --max-parents=0 "${tip}" | while IFS= read -r r; do
  echo "  root:    ${r}  $(git log -1 --format='%ci  %s' "${r}")"
done
echo "  records: $(git ls-tree -r --name-only "${tip}" -- runs2.d | grep -c '\.ndjson$')"
echo "  logs:    $(git ls-tree -r --name-only "${tip}" -- logs2.d | grep -c '\.log$')"
git rev-list --objects "${tip}" | cut -d' ' -f1 \
  | git cat-file --batch-check='%(objecttype) %(objectsize) %(objectsize:disk)' \
  | awk '{n[$1]++; s[$1]+=$2; d[$1]+=$3; N++; S+=$2; D+=$3}
         END {for (t in n) printf "  %-8s %7d objects  %8.1f MB  (%.1f MB packed)\n", t, n[t], s[t]/1048576, d[t]/1048576;
              printf "  %-8s %7d objects  %8.1f MB  (%.1f MB packed)\n", "total", N, S/1048576, D/1048576}'
echo "  oldest record: $(head -1 "${OUT}/record-times" 2>/dev/null || echo "run with WIDEN>0")"
echo "  newest record: $(tail -1 "${OUT}/record-times" 2>/dev/null || echo "run with WIDEN>0")"
echo "  retention window: RCC_RETENTION_DAYS=$(sed -n 's/^RCC_RETENTION_DAYS="\${RCC_RETENTION_DAYS:-\([0-9]*\)}"/\1/p' "$(git rev-parse --show-toplevel)/scripts/rcc-lib.sh") days"
echo "  runs of rcc-consolidate.yaml (nothing is pruned without one):"
api "repos/${REPO}/actions/workflows/rcc-consolidate.yaml/runs?per_page=100" \
  | jq -r '"    total: \(.total_count)",
           (.workflow_runs[]? | "    \(.created_at)  \(.event)  by \(.triggering_actor.login)  \(.conclusion)")'

echo
echo "output kept in ${OUT}"
