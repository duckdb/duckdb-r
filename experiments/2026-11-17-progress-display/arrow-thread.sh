#!/bin/sh
# Runs arrow-thread.R once per route under gdb, with breakpoints on
# RProgressBarDisplay::Update() and ::Finish() and on
# RArrowArrayStreamWrapper::GetNext() that print the event, gdb's thread
# number and Update()'s percentage, and writes arrow-thread.txt beside itself:
# per route, the R callback's calls, the breakpoint counts per event and
# thread, and their sequence with consecutive runs collapsed.
#
# Usage, with DLIB naming the library that holds the duckdb under test and the
# libraries that hold nanoarrow, arrow and dplyr on R_LIBS or in the defaults:
#   DLIB=/path/to/library experiments/2026-11-17-progress-display/arrow-thread.sh
#
# Needs: gdb, R with duckdb, nanoarrow, arrow and dplyr (collect uses dplyr).
# Handbook: handbook/usage/interactive/README.md

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
gdbcmds=$(mktemp)
raw=$(mktemp)
trap 'rm -f "$gdbcmds" "$raw"' EXIT

cat >"$gdbcmds" <<'EOF'
set breakpoint pending on
set pagination off
handle SIGPIPE SIGSEGV SIGUSR1 SIGUSR2 nostop noprint pass
break RProgressBarDisplay::Update
commands
silent
printf "EVENT Update tid=%d pct=%.6g\n", $_thread, percentage
continue
end
break RProgressBarDisplay::Finish
commands
silent
printf "EVENT Finish tid=%d\n", $_thread
continue
end
break RArrowArrayStreamWrapper::GetNext
commands
silent
printf "EVENT GetNext tid=%d\n", $_thread
continue
end
run
EOF

arrow=$(Rscript -e 'cat(format(packageVersion("arrow")))')

{
  echo "# gdb breakpoints on RProgressBarDisplay::Update/Finish and RArrowArrayStreamWrapper::GetNext"
  echo "# duckdb from DLIB, arrow $arrow; dplyr must be installed for the collect route"
  echo "# query: SELECT i, i * 2 AS j FROM range(30000000) t(i) WHERE i % 3 = 0, max_streaming_buffer_size=16KiB, via dbGetQueryArrow()"
  echo "# script: arrow-thread.R, run once per mode by arrow-thread.sh under R -d gdb; tid=1 is R's thread."
  echo "# Finish calls Update(100), so each Finish also shows as one Update."
  echo "# On the routes read on R's thread the R callback count trails the Update() total by the calls"
  echo "# the setup statements make before calls <- numeric(); that gap is not dropped events."
  for mode in get_next as_arrow_table write_parquet write_dataset collect; do
    echo "== $mode"
    R -d "gdb -batch -x $gdbcmds" --vanilla --no-echo -f "$here/arrow-thread.R" --args "$mode" 2>&1 |
      grep -E '^(EVENT |calls after|MODE )' >"$raw"
    grep -E '^(calls after|MODE )' "$raw"
    echo "-- totals by event and thread"
    grep '^EVENT ' "$raw" | awk '{ print $2, $3 }' | sort | uniq -c | sort -k2,2 -k3,3
    echo "-- sequence (runs collapsed)"
    # A run is consecutive events of one kind on one thread; an Update run also
    # ends when its percentage enters the next tenth.
    awk '
      function flush() {
        if (n > 0) printf "  %d x %s %s (%s..%s)\n", n, ev, tid, first, last
        n = 0
      }
      /^EVENT / {
        pct = ($4 == "") ? "" : $4
        dec = (pct == "") ? -1 : int(substr(pct, 5) / 10)
        if (n > 0 && ($2 != ev || $3 != tid || (ev == "Update" && dec > lastdec))) flush()
        if (n == 0) { ev = $2; tid = $3; first = pct }
        last = pct; lastdec = dec; n++
      }
      END { flush() }
    ' "$raw"
  done
} >"$here/arrow-thread.txt"
