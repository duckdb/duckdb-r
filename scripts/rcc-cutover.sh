#!/bin/bash
# One-shot: build the `rcc2` verdict store from what the old `rcc` branch holds.
#
# `rcc` accumulated four layouts, one per generation of the harvest -- the legacy
# `runs.json` / `runs.ndjson` / `logs/<run-id>.log`, then `runs2.ndjson`, then
# `runs2.d/<xx>/<sha>.ndjson` beside it, with `logs2/<sha>.log` flat throughout
# -- and every log ever harvested, in every commit of its history, at ~220 MB.
# Making that agree with itself in place was possible (the consolidation did it)
# but it left the branch's whole history behind, and every reader still carrying
# a fallback for the layout underneath.
#
# So this does not migrate `rcc`. It reads it once and writes `rcc2` as two
# commits: an empty root called `Initial`, and everything that survives. `rcc` is
# left exactly as it is, to die of its own accord -- nothing writes to it once
# the producers are on `rcc2`, and it can be deleted whenever someone is sure.
#
# What survives:
#
#   * every record, from `runs2.d/` and from `runs2.ndjson`, at
#     `runs2.d/<xx>/<sha>.ndjson`. A commit in both keeps its part: a verdict
#     lands in the part first, so the part is the newer of the two wherever they
#     differ;
#   * every log, at `logs2.d/<xx>/<sha>.log` -- the same 256-way fan-out the
#     records use, so adding one rewrites one small tree rather than a tree with
#     2.5k entries in it;
#   * a legacy `logs/<run-id>.log`, as that run's commit's log, but only when the
#     run decided exactly one commit. Those are the pre-matrix era, one run per
#     commit, so the mapping is usually unambiguous -- and where it is not, a
#     run-level log attributed to one of the commits it covers would be worse
#     than no log at all.
#
# Then everything older than the retention window goes, records and logs alike,
# which is what the store enforces from here on (scripts/rcc-consolidate.sh).
# Nothing else is carried: `runs.json` and `runs.ndjson` are the pre-`runs2`
# layout and every record in them predates the window by months. A record dropped
# is a rebuild at worst, never a wrong verdict.
#
# Usage:
#   OUT_DIR=runs scripts/rcc-cutover.sh            # report, change nothing
#   OUT_DIR=runs APPLY=1 scripts/rcc-cutover.sh    # write and push rcc2
#
# Run from a terminal, once. The runbook -- how to get the worktree, and when to
# run it relative to the producers -- is in
# handbook/operations/ci/per-commit/store/README.md.
#
# OUT_DIR is a worktree of the **source** branch (`rcc`), and is rewritten in
# place: the transformation is a few thousand `mv`s within one filesystem, which
# is what keeps this affordable against a 220 MB tree. The result is committed
# onto `rcc2`; the worktree's own branch ref is never moved and nothing is pushed
# to `rcc`, though its index and working tree are left rewritten -- the worktree
# is scratch, and this is the last thing that runs in it.
#
# Environment variables:
#   OUT_DIR             - worktree of the source branch (default: runs)
#   SRC_BRANCH          - the branch OUT_DIR holds (default: rcc); named for the
#                         report only, never written
#   BRANCH              - the branch to create (default: rcc2)
#   REMOTE              - remote to push to (default: origin)
#   RCC_RETENTION_DAYS  - keep records and logs at most this old (default: 30)
#   APPLY               - if non-empty, commit and push; otherwise report what
#                         would happen and leave everything alone
#   FORCE               - if non-empty, push even when BRANCH already exists on
#                         the remote, replacing it. Off by default: a second
#                         cutover would otherwise discard everything the
#                         producers have published since the first.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
. "${here}/rcc-lib.sh"

OUT_DIR="${OUT_DIR:-runs}"
SRC_BRANCH="${SRC_BRANCH:-rcc}"
BRANCH="${BRANCH:-rcc2}"
REMOTE="${REMOTE:-origin}"
APPLY="${APPLY:-}"
FORCE="${FORCE:-}"

[ -d "${OUT_DIR}" ] || { echo "OUT_DIR does not exist: ${OUT_DIR}" >&2; exit 1; }

git_out() { git -C "${OUT_DIR}" "$@"; }

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

count() { wc -l < "$1" | tr -d ' '; }

aggregate="${OUT_DIR}/runs2.ndjson"

# ------------------------------------------------------------------ before ---
before_commits="$(git_out rev-list --count HEAD)"
before_bytes="$(git_out rev-list --disk-usage --objects HEAD 2>/dev/null || echo 0)"

rcc_record_shas "${OUT_DIR}" > "${work}/parts"
{ find "${OUT_DIR}/logs2" -maxdepth 1 -type f -name '*.log' 2>/dev/null || true; } \
  | sed 's#.*/##; s#\.log$##' | LC_ALL=C sort -u > "${work}/flat-logs"
# Named by *run* id, not by commit: that is the whole difficulty with them.
{ find "${OUT_DIR}/logs" -maxdepth 1 -type f -name '*.log' 2>/dev/null || true; } \
  | sed 's#.*/##; s#\.log$##' | LC_ALL=C sort -u > "${work}/legacy-runs"

aggregate_lines=0
[ -s "${aggregate}" ] && aggregate_lines="$(count "${aggregate}")"

echo "== ${SRC_BRANCH} as it stands =="
echo "   commits:  ${before_commits}"
echo "   records:  ${aggregate_lines} in runs2.ndjson, $(count "${work}/parts") in runs2.d/"
echo "   logs:     $(count "${work}/flat-logs") in logs2/," \
  "$(count "${work}/legacy-runs") in logs/ (by run id)"
echo "   objects:  $(( before_bytes / 1048576 )) MB"
echo

# --------------------------------------------------------- what would move ---
# The aggregate's records with no part: what the split-out layout never caught up
# with, and the whole reason every reader carried a fallback.
: > "${work}/aggregate"
if [ -s "${aggregate}" ]; then
  jq -rR 'fromjson? | .commit' "${aggregate}" | LC_ALL=C sort -u > "${work}/aggregate"
fi
LC_ALL=C comm -13 "${work}/parts" "${work}/aggregate" > "${work}/aggregate-only"

# `<run-id> <sha>` for every record either layout holds, reduced to the run ids
# that decided exactly one commit -- the only ones a run-level log can be
# attributed to.
{
  { find "${OUT_DIR}/runs2.d" -type f -name '*.ndjson' -exec cat {} + 2>/dev/null || true; }
  cat "${aggregate}" 2>/dev/null || true
} | jq -rR 'fromjson? | "\(.run.id // 0) \(.commit)"' \
  | LC_ALL=C sort -u > "${work}/run-commits"
awk '{ n[$1]++; sha[$1] = $2 } END { for (r in n) if (n[r] == 1) print r, sha[r] }' \
  "${work}/run-commits" | LC_ALL=C sort > "${work}/run-unique"

# The legacy logs that map to one commit, minus the commits that already have a
# per-commit log -- the flat one is the commit's own output and always wins.
LC_ALL=C join "${work}/legacy-runs" "${work}/run-unique" > "${work}/legacy-move"
awk 'NR == FNR { has[$0] = 1; next } !($2 in has)' \
  "${work}/flat-logs" "${work}/legacy-move" > "${work}/legacy-move.keep"
mv -f "${work}/legacy-move.keep" "${work}/legacy-move"

echo "== distributing =="
echo "   $(count "${work}/aggregate-only") record(s) live only in runs2.ndjson" \
  "and become parts"
echo "   $(count "${work}/flat-logs") log(s) move from logs2/ into logs2.d/<xx>/"
echo "   $(count "${work}/legacy-move") of $(count "${work}/legacy-runs") legacy" \
  "log(s) name a run that decided exactly one commit and move too; the rest are dropped"
echo "   runs.json, runs.ndjson and the aggregate itself are dropped outright"
echo

# Everything that would end up in the store, with the timestamp retention reads.
# Both layouts, deduplicated by commit: which of two copies of the same record
# answers is immaterial here, because they differ in their verdict, never in when
# it was written.
{
  { find "${OUT_DIR}/runs2.d" -type f -name '*.ndjson' -exec cat {} + 2>/dev/null || true; }
  cat "${aggregate}" 2>/dev/null || true
} | jq -rR "fromjson? | \"\\(.commit) \\(${RCC_RECORD_TIME_JQ})\"" \
  | LC_ALL=C sort -u -k1,1 > "${work}/dates"

aged=0
if [ "${RCC_RETENTION_DAYS}" -gt 0 ]; then
  aged="$(awk -v cut="$(rcc_cutoff "${RCC_RETENTION_DAYS}")" \
    'NF > 1 && $2 != "" && $2 < cut' "${work}/dates" | wc -l | tr -d ' ')"
fi
echo "== pruning past ${RCC_RETENTION_DAYS} day(s) =="
echo "   cutoff:  $(rcc_cutoff "${RCC_RETENTION_DAYS}")"
echo "   ${aged} of $(count "${work}/dates") record(s) age out, with their logs"
echo

if [ -z "${APPLY}" ]; then
  echo "== dry run =="
  echo "   Nothing was changed. Re-run with APPLY=1 to write ${BRANCH}."
  exit 0
fi

if git_out ls-remote --exit-code --heads "${REMOTE}" "${BRANCH}" > /dev/null 2>&1 \
   && [ -z "${FORCE}" ]; then
  {
    echo "${BRANCH} already exists on ${REMOTE}. The cutover is a one-shot;"
    echo "running it again would discard everything published there since."
    echo "Set FORCE=1 if that is genuinely what you want."
  } >&2
  exit 1
fi

# ---------------------------------------------------------------- rewrite ----
# In place, and by moving rather than copying: the logs are most of the branch's
# bytes and they are already the right files under the wrong names.

# One pass over the aggregate rather than one `grep` per record: at ~4.5k records
# against a 10 MB file, a lookup each is 45 GB of scanning to save a few lines of
# awk. The shard directories are pre-created because awk's redirection will not
# create them; git does not track empty ones, so the ones that stay empty cost
# nothing.
mkdir -p "${OUT_DIR}/runs2.d"/{0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f}{0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f}
if [ -s "${work}/aggregate-only" ]; then
  awk -v dir="${OUT_DIR}/runs2.d" -v want="${work}/aggregate-only" '
    BEGIN { while ((getline sha < want) > 0) wanted[sha] = 1 }
    match($0, /"commit"[[:space:]]*:[[:space:]]*"[0-9a-f]+"/) {
      sha = substr($0, RSTART, RLENGTH)
      sub(/^"commit"[[:space:]]*:[[:space:]]*"/, "", sha)
      sub(/"$/, "", sha)
      if (!(sha in wanted) || (sha in written)) next
      written[sha] = 1
      # Readers take the first record for a SHA, so a duplicated line in the
      # aggregate resolves the way it always did: the first one wins.
      f = dir "/" substr(sha, 1, 2) "/" sha ".ndjson"
      print > f
      close(f)
    }
  ' "${aggregate}"
fi
echo "Split $(count "${work}/aggregate-only") aggregate-only record(s) into runs2.d/"

moved=0
while IFS= read -r sha; do
  dest="${OUT_DIR}/$(rcc_log_path "${sha}")"
  mkdir -p "$(dirname "${dest}")"
  mv -f "${OUT_DIR}/logs2/${sha}.log" "${dest}"
  moved=$(( moved + 1 ))
done < "${work}/flat-logs"
echo "Moved ${moved} log(s) into logs2.d/"

recovered=0
while read -r run_id sha; do
  dest="${OUT_DIR}/$(rcc_log_path "${sha}")"
  mkdir -p "$(dirname "${dest}")"
  mv -f "${OUT_DIR}/logs/${run_id}.log" "${dest}"
  recovered=$(( recovered + 1 ))
done < "${work}/legacy-move"
echo "Recovered ${recovered} legacy log(s) from logs/"

rm -rf "${OUT_DIR}/logs" "${OUT_DIR}/logs2" \
  "${OUT_DIR}/runs.json" "${OUT_DIR}/runs.ndjson" "${aggregate}"

# ------------------------------------------------------------------ prune ----
rcc_prune "${OUT_DIR}" "${RCC_RETENTION_DAYS}" apply
echo "Pruned ${RCC_PRUNED_RECORDS} record(s) and ${RCC_PRUNED_LOGS} log(s) past" \
  "${RCC_RETENTION_DAYS} days (${RCC_ORPHAN_LOGS} of the logs had no record)"

# ----------------------------------------------------------------- commit ----
# Two commits on a history of their own: `rcc2` shares nothing with `rcc`, which
# is the point -- the old branch keeps its history and its 220 MB, and the new
# one starts at what it actually holds.
message="rcc2: cut over from ${SRC_BRANCH} $(date -u +%Y-%m-%dT%H:%M:%SZ)

${RCC_KEPT_RECORDS} records and ${RCC_KEPT_LOGS} logs, one file per commit under
runs2.d/<xx>/ and logs2.d/<xx>/.
Distributed from ${SRC_BRANCH} (${before_commits} commits) and pruned to
${RCC_RETENTION_DAYS} days."

# An empty root, minted here because this branch has no history to inherit one
# from. Every later consolidation inherits *this* root.
rcc_initial_root "${OUT_DIR}" "refs/heads/${BRANCH}"
git_out add -A
tree="$(git_out write-tree)"
new="$(git_out commit-tree "${tree}" -p "${RCC_INITIAL_ROOT}" -m "${message}")"
after_bytes="$(git_out rev-list --disk-usage --objects "${new}" 2>/dev/null || echo 0)"

echo
echo "== ${BRANCH} =="
echo "   commits:  2"
echo "   records:  ${RCC_KEPT_RECORDS}"
echo "   logs:     ${RCC_KEPT_LOGS}"
echo "   objects:  $(( after_bytes / 1048576 )) MB (${SRC_BRANCH}:" \
  "$(( before_bytes / 1048576 )) MB)"
echo

echo "Pushing ${new:0:9} to ${REMOTE}/${BRANCH}"
git_out push ${FORCE:+--force} "${REMOTE}" "${new}:refs/heads/${BRANCH}"

echo "Done. ${SRC_BRANCH} is untouched and can be deleted once nothing reads it."
