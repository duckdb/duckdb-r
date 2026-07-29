#!/bin/bash
# Reconcile `runs2.ndjson` on the orphan `rcc` branch with the per-commit records
# in `runs2.d/`: append the ones it lacks, replace the ones it has stale.
#
# `runs2.d/<xx>/<sha>.ndjson` holds one record per commit -- exactly one line, the
# same line `runs2.ndjson` has always been appended with. Records land there first
# because a directory of one file per commit is conflict-free by construction:
# several writers publish to this branch -- every leg of an `each-rcc` matrix,
# that run's fan-in, and the scheduled backstop in
# `.github/workflows/rcc-logs.yaml` -- and two of them recording different commits
# write different paths, so there is nothing to merge. Only `runs2.ndjson`, being
# one file, could ever be the subject of a disagreement.
#
# This is the step that keeps that one file current, and it is deliberately an
# **extension of the existing layout rather than a migration of it**:
#
#   * the ~4.5k records that predate `runs2.d/` stay exactly where they are, in
#     the order they were collected, byte for byte. Nothing rewrites them, so
#     there is no flag-day commit reshuffling the branch's principal file, and no
#     window in which a reader sees it half-changed;
#   * new records are appended, so the diff of every future commit is the records
#     it added. `git log -p` on the branch stays readable, and git's delta stays
#     local -- measured at a few KiB per update against a 10 MB file;
#   * a record that exists only in `runs2.ndjson` is left alone. Readers look up
#     the per-commit file first and fall back to the aggregate
#     (`scripts/series-check.sh`), so the two together are the whole truth and
#     neither has to be complete on its own.
#
# The merge needs nothing but the branch: it compares the parts against the
# aggregate and reconciles the difference. So it is idempotent, and losing a push
# race is cheap: reset onto the winner, recompute (now against a smaller
# difference, because the winner reconciled part of it), retry. Nothing is
# re-derived and no producer runs again. It is also why serialising this step
# would be safe if it ever had to be: an evicted merge loses nothing, because
# everything it was going to write is already on the branch as a part.
#
# Two kinds of difference:
#
#   * a part with no line in the aggregate -- appended;
#   * a part whose line in the aggregate says something else -- **replaced** in
#     place. That is a retry (.claude/skills/series-loop.md), where a commit was
#     rebuilt on its own SHA to overturn a verdict that was never about its tree.
#     Appending would not do: readers take the first line for a SHA
#     (`scripts/series-check.sh` greps with `-m 1`), so a second one is invisible.
#     The part is the newer of the two by construction -- it is what the leg or
#     the fan-in just wrote -- so the part wins.
#
# Usage:
#   OUT_DIR=runs scripts/rcc-merge.sh
#
# Environment variables:
#   OUT_DIR  - the `rcc` worktree to operate on (default: runs)
#   BACKFILL - if non-empty, also split records that exist only in
#              `runs2.ndjson` out into `runs2.d/`. Off by default and needed by
#              nothing: it would rewrite thousands of files in a single commit to
#              save readers one fallback lookup on commits nobody looks up any
#              more. It is here so that "the aggregate could be fully derived"
#              stays a choice rather than a road not taken.

set -euo pipefail

OUT_DIR="${OUT_DIR:-runs}"
PARTS_DIR="${OUT_DIR}/runs2.d"
AGGREGATE="${OUT_DIR}/runs2.ndjson"

# 256 fan-out directories, so adding a record rewrites one small tree instead of
# one tree with every record in it -- which matters because the matrix legs add
# one per commit built. Git does not track empty directories, so pre-creating them
# all costs nothing on the branch.
mkdir -p "${PARTS_DIR}"/{0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f}{0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f}
[ -e "${AGGREGATE}" ] || : > "${AGGREGATE}"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

list_parts() {
  find "${PARTS_DIR}" -type f -name '*.ndjson' \
    | sed 's#.*/##; s#\.ndjson$##' \
    | LC_ALL=C sort -u > "${work}/parts"
}

# One awk pass over the aggregate rather than one jq per line: at 4.5k records and
# growing, the process spawns dominate. Every record ever written begins with its
# own commit, but match on the field rather than the position, so a hand-edited
# line still counts.
list_aggregate() {
  awk '
    match($0, /"commit"[[:space:]]*:[[:space:]]*"[0-9a-f]+"/) {
      sha = substr($0, RSTART, RLENGTH)
      sub(/^"commit"[[:space:]]*:[[:space:]]*"/, "", sha)
      sub(/"$/, "", sha)
      print sha
    }
  ' "${AGGREGATE}" | LC_ALL=C sort -u > "${work}/aggregate"
}

list_parts
list_aggregate

# ------------------------------------------------------------------ backfill --
# Opt-in, and the only thing in this script that touches an existing record.
if [ -n "${BACKFILL:-}" ]; then
  backfilled=0
  while IFS= read -r sha; do
    part="${PARTS_DIR}/${sha:0:2}/${sha}.ndjson"
    [ -f "${part}" ] && continue
    grep -m 1 "\"commit\"[[:space:]]*:[[:space:]]*\"${sha}\"" "${AGGREGATE}" > "${part}"
    backfilled=$(( backfilled + 1 ))
  done < <(LC_ALL=C comm -13 "${work}/parts" "${work}/aggregate")
  echo "Backfilled ${backfilled} aggregate-only record(s) into runs2.d/"
  list_parts
fi

# --------------------------------------------------------------------- merge --
LC_ALL=C comm -23 "${work}/parts" "${work}/aggregate" > "${work}/missing"
missing="$(wc -l < "${work}/missing" | tr -d ' ')"

# Parts whose line in the aggregate is stale. Comparing whole lines rather than
# just the verdict catches a retry that changed anything about the record, and
# costs one pass over a file we are about to read anyway.
: > "${work}/changed"
awk -v dir="${PARTS_DIR}" '
  match($0, /"commit"[[:space:]]*:[[:space:]]*"[0-9a-f]+"/) {
    sha = substr($0, RSTART, RLENGTH)
    sub(/^"commit"[[:space:]]*:[[:space:]]*"/, "", sha)
    sub(/"$/, "", sha)
    part = dir "/" substr(sha, 1, 2) "/" sha ".ndjson"
    if ((getline line < part) <= 0) { close(part); next }
    close(part)
    if (line != $0) print sha
  }
' "${AGGREGATE}" > "${work}/changed"
changed="$(wc -l < "${work}/changed" | tr -d ' ')"

if [ "${missing}" -eq 0 ] && [ "${changed}" -eq 0 ]; then
  echo "Aggregate: up to date, $(wc -l < "${AGGREGATE}" | tr -d ' ') record(s)"
  exit 0
fi

# A replacement is a rewrite, so it only happens when there is one to make: the
# common path stays a pure append, and a pure append is what keeps git's delta
# local.
if [ "${changed}" -gt 0 ]; then
  awk -v dir="${PARTS_DIR}" -v changed="${work}/changed" '
    BEGIN { while ((getline sha < changed) > 0) stale[sha] = 1 }
    {
      if (!match($0, /"commit"[[:space:]]*:[[:space:]]*"[0-9a-f]+"/)) { print; next }
      sha = substr($0, RSTART, RLENGTH)
      sub(/^"commit"[[:space:]]*:[[:space:]]*"/, "", sha)
      sub(/"$/, "", sha)
      if (!(sha in stale)) { print; next }
      part = dir "/" substr(sha, 1, 2) "/" sha ".ndjson"
      if ((getline line < part) > 0) print line; else print
      close(part)
    }
  ' "${AGGREGATE}" > "${work}/rewritten"
  mv -f "${work}/rewritten" "${AGGREGATE}"
fi

if [ "${missing}" -gt 0 ]; then
  # Appended in SHA order, which is the order `comm` emits, so a merge redone
  # against a new tip produces the same bytes for the records it still has to add.
  while IFS= read -r sha; do
    printf '%s/%s/%s.ndjson\n' "${PARTS_DIR}" "${sha:0:2}" "${sha}"
  done < "${work}/missing" > "${work}/paths"

  # One `cat` for the batch rather than one per record. `xargs -r` is GNU-only,
  # and emptiness is already ruled out; every path here is hex, so newline
  # separation is safe.
  tr '\n' '\0' < "${work}/paths" | xargs -0 cat >> "${AGGREGATE}"
fi

echo "Aggregate: appended ${missing}, replaced ${changed}, now" \
  "$(wc -l < "${AGGREGATE}" | tr -d ' ') record(s)"
