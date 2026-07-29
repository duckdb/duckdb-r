#!/bin/bash
# Consolidate the orphan `rcc` branch: reconcile its two record layouts, drop
# logs older than a month, and squash the whole history to two commits.
#
# Run by hand (`.github/workflows/rcc-consolidate.yaml`, `workflow_dispatch`),
# never on a schedule. Everything else that writes to this branch is designed to
# race safely; this one rewrites it, so it is the one place that wants an
# operator who knows nothing else is mid-flight. The force-push carries a lease,
# so if something did land in between, the push is refused rather than silently
# discarding it.
#
# ## Who owns what on the `rcc` branch
#
# | Writer | Adds | Rewrites |
# |---|---|---|
# | an `each-rcc` leg | its own record and log | nothing |
# | the run's fan-in | records a leg could not publish | nothing |
# | `rcc-logs.yaml` | records for commits it finds undecided | nothing |
# | `rcc-merge.sh`, from the two above | the aggregate's missing lines | a line a retry made stale |
# | **this script** | — | **all of it** |
#
# Everything routine is additive, which is what lets it run concurrently without
# coordination (see scripts/rcc-merge.sh). The three destructive operations --
# making the layouts agree, deleting logs, discarding history -- are collected
# here instead, where they happen once and under supervision.
#
# ## Do we need both `runs2.d/` and `runs2.ndjson`?
#
# Yes, and after this runs they hold exactly the same records:
#
#   * `runs2.d/<xx>/<sha>.ndjson` is the *write* surface. One file per commit is
#     what makes twenty legs able to publish at once without a lock.
#   * `runs2.ndjson` is the *read* surface. One file is what makes "what happened
#     to every commit in this range" a single fetch rather than N.
#
# In normal operation the two drift a little -- records that predate the split
# live only in the aggregate, and a record published seconds ago may not be
# merged into it yet. Readers cope by trying the per-commit file and falling back
# (`scripts/series-check.sh`). This script removes the drift: it backfills every
# aggregate-only record into `runs2.d/`, then regenerates the aggregate from the
# parts, so afterwards the parts are complete and the aggregate is exactly their
# concatenation.
#
# ## What it drops
#
# Logs, and only logs. `logs2/<sha>.log` is ~1 MB of harvested output per failed
# commit and about 90% of the branch's 220 MB; a record is ~2 KB. A log's value
# is that `scripts/series-check.sh` classifies a failure by what it contains, and
# that matters for a commit the series loop is still working on -- not for one
# decided months ago and long since repaired. Records are never dropped, so the
# verdict survives even when the evidence does not, and `.timing.failed_stages`
# still says which gate broke.
#
# Usage:
#   OUT_DIR=runs scripts/rcc-consolidate.sh            # report, change nothing
#   OUT_DIR=runs APPLY=1 scripts/rcc-consolidate.sh    # rewrite and force-push
#
# Environment variables:
#   OUT_DIR             - the `rcc` worktree to consolidate (default: runs)
#   LOG_RETENTION_DAYS  - keep logs for records at most this old (default: 30);
#                         0 keeps every log
#   APPLY               - if non-empty, commit and force-push; otherwise report
#                         what would change and leave the branch alone
#   BRANCH              - branch to rewrite (default: rcc)
#   REMOTE              - remote to push to (default: origin)

set -euo pipefail

OUT_DIR="${OUT_DIR:-runs}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-30}"
APPLY="${APPLY:-}"
BRANCH="${BRANCH:-rcc}"
REMOTE="${REMOTE:-origin}"

here="$(cd "$(dirname "$0")" && pwd)"

[ -d "${OUT_DIR}" ] || { echo "OUT_DIR does not exist: ${OUT_DIR}" >&2; exit 1; }

git_out() { git -C "${OUT_DIR}" "$@"; }

# Every shape this branch can legitimately have, up front. The bootstrap path in
# scripts/rcc-part-push.sh creates it with `runs2.d/` alone, and the pre-split
# shape had `runs2.ndjson` alone, so neither is an error -- but under `set -e`
# every probe below would abort on the missing one, and `2>/dev/null` would hide
# why. An operator dispatching the dry run to *find out* what state the branch is
# in deserves a report rather than a bare redirection error.
mkdir -p "${OUT_DIR}/logs2" "${OUT_DIR}/runs2.d"
[ -e "${OUT_DIR}/runs2.ndjson" ] || : > "${OUT_DIR}/runs2.ndjson"

count_files() { # <dir> <name-glob>
  [ -d "$1" ] || { echo 0; return 0; }
  find "$1" -type f -name "$2" | wc -l | tr -d ' '
}

before_tip="$(git_out rev-parse HEAD)"
before_commits="$(git_out rev-list --count HEAD)"
before_bytes="$(git_out rev-list --disk-usage --objects HEAD 2>/dev/null || echo 0)"
before_logs="$(count_files "${OUT_DIR}/logs2" '*.log')"

echo "== ${BRANCH} before =="
echo "   commits:  ${before_commits}"
echo "   records:  $(wc -l < "${OUT_DIR}/runs2.ndjson" | tr -d ' ') in runs2.ndjson," \
  "$(count_files "${OUT_DIR}/runs2.d" '*.ndjson') in runs2.d/"
echo "   logs:     ${before_logs}"
echo "   objects:  $(( before_bytes / 1048576 )) MB"
echo

# ---------------------------------------------------------------- analysis ---
# Everything up to the APPLY gate only reads, so a dry run is genuinely dry: it
# reports exactly what the real thing would do, against an untouched worktree.
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

part_shas() {
  find "${OUT_DIR}/runs2.d" -type f -name '*.ndjson' 2>/dev/null \
    | sed 's#.*/##; s#\.ndjson$##' | LC_ALL=C sort -u
}
aggregate_shas() {
  awk '
    match($0, /"commit"[[:space:]]*:[[:space:]]*"[0-9a-f]+"/) {
      sha = substr($0, RSTART, RLENGTH)
      sub(/^"commit"[[:space:]]*:[[:space:]]*"/, "", sha)
      sub(/"$/, "", sha)
      print sha
    }
  ' "${OUT_DIR}/runs2.ndjson" 2>/dev/null | LC_ALL=C sort -u
}

part_shas > "${work}/parts"
aggregate_shas > "${work}/aggregate"
aggregate_only="$(LC_ALL=C comm -13 "${work}/parts" "${work}/aggregate" | wc -l | tr -d ' ')"

echo "== reconciling the two layouts =="
echo "   ${aggregate_only} record(s) live only in runs2.ndjson and will be split into runs2.d/"
echo "   the aggregate is then rebuilt as exactly the concatenation of the parts"
echo

# --------------------------------------------------------------- log triage ---
# `<sha> <timestamp>` for every record, from whichever layout holds it. Both
# fields are hex and RFC 3339, so a space-separated table is safe -- and `join`
# over it beats a lookup per log file by two orders of magnitude at this size.
{
  find "${OUT_DIR}/runs2.d" -type f -name '*.ndjson' -print0 2>/dev/null | xargs -0 cat 2>/dev/null
  cat "${OUT_DIR}/runs2.ndjson" 2>/dev/null
} | jq -r '"\(.commit) \(.status.created_at // .run.created_at // "")"' \
  | LC_ALL=C sort -u -k1,1 > "${work}/dates"

find "${OUT_DIR}/logs2" -type f -name '*.log' 2>/dev/null \
  | sed 's#.*/##; s#\.log$##' | LC_ALL=C sort > "${work}/logs"

echo "== dropping logs older than ${LOG_RETENTION_DAYS} day(s) =="
: > "${work}/doomed"
dropped=0
orphans=0
if [ "${LOG_RETENTION_DAYS}" -gt 0 ]; then
  cutoff="$(date -u -d "${LOG_RETENTION_DAYS} days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -u -v "-${LOG_RETENTION_DAYS}d" +%Y-%m-%dT%H:%M:%SZ)"
  echo "   cutoff: ${cutoff}"

  # A log whose commit has no record at all: nothing reads it, and nothing can
  # date it. It goes too.
  LC_ALL=C comm -23 "${work}/logs" <(cut -d' ' -f1 "${work}/dates") > "${work}/doomed"
  orphans="$(wc -l < "${work}/doomed" | tr -d ' ')"

  LC_ALL=C join "${work}/logs" "${work}/dates" \
    | awk -v cut="${cutoff}" 'NF > 1 && $2 != "" && $2 < cut { print $1 }' >> "${work}/doomed"
  dropped=$(( $(wc -l < "${work}/doomed" | tr -d ' ') - orphans ))
else
  echo "   retention disabled, keeping every log"
fi
kept=$(( before_logs - dropped - orphans ))
echo "   ${dropped} aged out, ${orphans} orphaned (no record), ${kept} kept"
echo

if [ -z "${APPLY}" ]; then
  echo "== dry run =="
  echo "   Nothing was changed. Re-run with APPLY=1 to rewrite ${BRANCH} and"
  echo "   force-push it as two commits."
  exit 0
fi

# ----------------------------------------------------------------- rewrite ---
# Only now does anything change. BACKFILL splits every aggregate-only record into
# a part; this is the one place that migration is right, because the branch is
# being rewritten anyway and there is no flag-day commit to avoid.
OUT_DIR="${OUT_DIR}" BACKFILL=1 "${here}/rcc-merge.sh"

# With the parts complete, the aggregate becomes exactly their concatenation,
# ordered by when each verdict was written and then by SHA -- so it still reads
# chronologically the way it always has, and two consolidations of the same state
# produce the same bytes. Sorting a `<timestamp> <sha>` table and then `cat`ting
# the files in that order keeps the JSON itself out of the pipeline, where any
# escaping would mangle it.
# Tab-delimited, and the SHA taken by field number rather than by word
# splitting: a record with no timestamp yields an empty first field, and
# `read a b` would then put the SHA in the wrong variable.
{
  find "${OUT_DIR}/runs2.d" -type f -name '*.ndjson' -print0 | xargs -0 cat
} | jq -r '[(.status.created_at // .run.created_at // ""), .commit] | @tsv' \
  | LC_ALL=C sort > "${work}/order"
cut -f2 < "${work}/order" \
  | while IFS= read -r sha; do
      printf '%s/runs2.d/%s/%s.ndjson\n' "${OUT_DIR}" "${sha:0:2}" "${sha}"
    done > "${work}/paths"
tr '\n' '\0' < "${work}/paths" | xargs -0 cat > "${work}/runs2.ndjson"
mv -f "${work}/runs2.ndjson" "${OUT_DIR}/runs2.ndjson"
echo "Aggregate rebuilt: $(wc -l < "${OUT_DIR}/runs2.ndjson" | tr -d ' ') record(s)"

while IFS= read -r sha; do
  rm -f "${OUT_DIR}/logs2/${sha}.log"
done < "${work}/doomed"

# ------------------------------------------------------------------- squash ---
# Two commits: an empty root, and everything. The root is *inherited* when the
# branch already has one -- consolidating twice must not keep minting new roots,
# or every consolidation would invalidate every clone twice over.
git_out add -A
tree="$(git_out write-tree)"

initial=""
while IFS= read -r root; do
  [ "$(git_out log -1 --format=%s "${root}")" = "Initial" ] || continue
  [ -z "$(git_out ls-tree "${root}")" ] || continue
  initial="${root}"
  break
done < <(git_out rev-list --max-parents=0 HEAD)

if [ -n "${initial}" ]; then
  echo "Inheriting the existing empty root ${initial:0:9}"
else
  empty_tree="$(git_out hash-object -t tree /dev/null)"
  initial="$(git_out commit-tree "${empty_tree}" -m "Initial")"
  echo "Minting an empty root ${initial:0:9}"
fi

message="rcc: consolidated $(date -u +%Y-%m-%dT%H:%M:%SZ)

$(wc -l < "${OUT_DIR}/runs2.ndjson" | tr -d ' ') records, ${kept} logs.
Dropped ${dropped} log(s) past ${LOG_RETENTION_DAYS} days and ${orphans} without a record.
Replaces ${before_commits} commits."

new="$(git_out commit-tree "${tree}" -p "${initial}" -m "${message}")"
after_bytes="$(git_out rev-list --disk-usage --objects "${new}" 2>/dev/null || echo 0)"

echo
echo "== ${BRANCH} after =="
echo "   commits:  2 (was ${before_commits})"
echo "   records:  $(wc -l < "${OUT_DIR}/runs2.ndjson" | tr -d ' ')"
echo "   logs:     ${kept} (was ${before_logs})"
echo "   objects:  $(( after_bytes / 1048576 )) MB (was $(( before_bytes / 1048576 )) MB)"
echo

# The lease is what makes "run it manually" a guarantee rather than a hope: a
# writer that landed between our read and this push moves the ref off
# `before_tip`, and the push is refused instead of discarding it.
echo "Force-pushing ${new:0:9} to ${REMOTE}/${BRANCH} (lease on ${before_tip:0:9})"
git_out push --force-with-lease="refs/heads/${BRANCH}:${before_tip}" \
  "${REMOTE}" "${new}:refs/heads/${BRANCH}"

echo "Done. Existing clones need \`git fetch --force\` or a fresh clone."
