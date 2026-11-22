#!/bin/bash
# Rebuilds data.tsv beside itself: one row per commit the two runs planned,
# with the shard and position the plan gave it, the unity objects it
# invalidates, and the minutes its record on the `rcc2` branch reports
# (empty where the commit has no record from that run).
#
# The plans are recomputed, not downloaded, from the planner each run used:
# the same scripts at the same tips, with the constants of the time. The job
# names of both runs ("shard N (C commits, ~E min)") match the recomputed plans
# shard for shard, which is the check that the recomputation is the plan.
#
# Usage, from a clone of duckdb-r whose `origin` is krlmlr/duckdb-r:
#   experiments/2026-11-22-each-timing-refit/collect.sh
#
# Needs: git, jq, python3.
# Handbook: handbook/operations/ci/per-commit/planning/README.md

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(git -C "${here}" rev-parse --show-toplevel)"
work="$(mktemp -d)"
trap 'git -C "${repo}" worktree remove --force "${work}/tip" 2>/dev/null; rm -rf "${work}"' EXIT

run1=44932694459 # each-rcc on main-land-dev, planned from head1
run2=44932760627 # its follow-up, planned from head2
base=8a776546a172a7d30ff2ca98aa2f4d2c426ea64d  # main-land-green when run1 planned
head1=5405e828f060337d257cbd47f7152d9a2ac24f16
head2=a1a93d5beeff524ebad216187270b539a537357d

# By SHA, not by `main-land-dev`, which the landing deletes; the commits stay
# reachable from the branch it landed on, which is the fallback.
git -C "${repo}" fetch -q origin rcc2
git -C "${repo}" fetch -q origin "${head1}" "${head2}" \
  || git -C "${repo}" fetch -q origin main
for sha in "${head1}" "${head2}"; do
  if ! git -C "${repo}" cat-file -e "${sha}^{commit}" 2>/dev/null; then
    echo "collect.sh: commit ${sha} is not reachable from origin, by SHA or from main" >&2
    exit 1
  fi
done
git -C "${repo}" worktree add -q --detach "${work}/tip" "${head1}"
tip="${work}/tip"

# Weigh every commit run1 planned, with the reach map of its tip.
git -C "${tip}" rev-list --first-parent --reverse "${base}..${head1}" > "${work}/todo"
python3 "${tip}/scripts/each-cost.py" map "${tip}" > "${work}/map.json"
weigh() {
  while read -r sha; do
    printf '%s %s\n' "${sha}" "$(git -C "${tip}" diff --name-only "${sha}^" "${sha}" | tr '\n' ' ')"
  done | python3 "${tip}/scripts/each-cost.py" batch "${work}/map.json"
}
weigh < "${work}/todo" > "${work}/objects1"

# Both runs' records.
git -C "${repo}" archive origin/rcc2 runs2.d | tar -x -C "${work}"
find "${work}/runs2.d" -name '*.ndjson' -exec cat {} + \
  | jq -r --argjson a "${run1}" --argjson b "${run2}" \
      'select(.run.id == $a or .run.id == $b)
       | [.commit, .run.id, .timing.shard, .timing.duration_seconds] | @tsv' \
  > "${work}/records"

# run2 planned what run1 left without a record, plus the version bump at head2.
{ cat "${work}/objects1"; echo "${head2}" | weigh; } \
  | grep -vFf <(awk -v r="${run1}" '$2 == r { print $1 }' "${work}/records") \
  > "${work}/objects2"

# The constants both runs planned with, and the workflow's max-parallel.
for n in 1 2; do
  python3 "${tip}/scripts/each-partition.py" --budget 300 --setup 5 --full 40 \
    --floor 6 --object-seconds 9.7 --max-parallel 20 --split-factor 1.5 \
    < "${work}/objects${n}" > "${work}/plan${n}.json"
done

python3 - "${work}" "${run1}" "${run2}" > "${here}/data.tsv" <<'EOF'
import json, sys
work, runs = sys.argv[1], [int(r) for r in sys.argv[2:]]
records = {}
for line in open(f"{work}/records"):
    sha, run, shard, seconds = line.split()
    records[(sha, int(run))] = (int(shard), int(seconds))
print("run\tshard\tpos\tsha\tobjects\tminutes")
for n, run in enumerate(runs, 1):
    for shard, s in enumerate(json.load(open(f"{work}/plan{n}.json"))["shards"], 1):
        for pos, c in enumerate(s["commits"], 1):
            rec = records.get((c["sha"], run))
            assert rec is None or rec[0] == shard, (c["sha"], rec, shard)
            minutes = "" if rec is None else f"{rec[1] / 60:.2f}"
            print(f"{run}\t{shard}\t{pos}\t{c['sha']}\t{c['objects']}\t{minutes}")
EOF
