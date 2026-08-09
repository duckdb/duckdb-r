#!/bin/sh
# Tally scan.R over repeated attempts, per thread count and field type.
# Each attempt is its own process because the failure mode under measurement
# includes ending one: `error` counts an attempt R stopped, `killed` one a
# signal took (128 + the signal number, so 134 is SIGABRT).
#
# Usage: N_ROWS=3000000 run.sh [attempts]        (attempts default 10)
#
# Run it under `ulimit -c 0`: the killed attempts dump core otherwise, and
# the tally takes minutes longer than it measures.

set -u

attempts=${1:-10}
here=$(dirname "$0")

printf 'attempts per cell: %s\n' "$attempts"
printf 'rows: %s\n' "${N_ROWS:-5000000}"
printf 'R: %s\n' "$(Rscript -e 'cat(R.version.string)')"
printf 'duckdb: %s\n' "$(Rscript -e 'cat(as.character(packageVersion("duckdb")))')"
printf 'cores: %s\n\n' "$(nproc)"

for field in int str; do
  for threads in 1 2 4; do
    match=0
    mismatch=0
    error=0
    killed=0
    for _ in $(seq 1 "$attempts"); do
      out=$(N_ROWS="${N_ROWS:-5000000}" THREADS="$threads" FIELD="$field" \
        Rscript "$here/scan.R" 2>&1)
      rc=$?
      if [ "$rc" -gt 128 ]; then
        killed=$((killed + 1))
      elif [ "$rc" -ne 0 ]; then
        error=$((error + 1))
      elif printf '%s' "$out" | grep -q MISMATCH; then
        mismatch=$((mismatch + 1))
      else
        match=$((match + 1))
      fi
    done
    printf 'field=%s threads=%s  match=%s mismatch=%s error=%s killed=%s\n' \
      "$field" "$threads" "$match" "$mismatch" "$error" "$killed"
  done
done
