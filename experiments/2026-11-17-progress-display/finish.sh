#!/bin/sh
# Runs finish.R under gdb with breakpoints on RProgressBarDisplay::Update()
# and ::Finish() that print UPDATE with gdb's thread number and FINISH, then
# once more without gdb, and writes finish.txt beside itself: per scenario and
# run, the R callback's calls, the reads that got any, and under gdb the
# engine's calls into the display, how many came from a thread other than
# R's (gdb's thread 1), and the phase of every Finish(). Finish() calls
# Update(100), so every Finish() is counted as an Update() too.
#
# Usage, with the library that holds the duckdb under test named in R_LIBS,
# which R reads also when gdb starts it:
#   R_LIBS=/path/to/library experiments/2026-11-17-progress-display/finish.sh
#
# Needs: gdb, R with duckdb and nanoarrow.
# Handbook: handbook/usage/interactive/README.md

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
gdbcmds=$(mktemp)
raw=$(mktemp)
plain=$(mktemp)
trap 'rm -f "$gdbcmds" "$raw" "$plain"' EXIT

cat >"$gdbcmds" <<'EOF'
set breakpoint pending on
set pagination off
handle SIGPIPE SIGSEGV SIGUSR1 SIGUSR2 nostop noprint pass
break RProgressBarDisplay::Finish
commands
silent
printf "FINISH\n"
continue
end
break RProgressBarDisplay::Update
commands
silent
printf "UPDATE %d\n", $_thread
continue
end
run
EOF

R -d "gdb -batch -x $gdbcmds" --vanilla --no-echo -f "$here/finish.R" 2>&1 |
  grep -E '^(FINISH|UPDATE|=== |callback )' >"$raw"
R --vanilla --no-echo -f "$here/finish.R" 2>&1 |
  grep -E '^(=== |callback )' >"$plain"

summarize() {
  awk '
  /^=== scenario / { sc = $3; order[++n] = sc; next }
  /^=== reads / { reads[sc] = $3; next }
  /^FINISH/ { pending = 1; next }
  /^UPDATE / { if (sc != "") { updates[sc]++; if ($2 != 1) offthread[sc]++ }; next }
  /^callback / {
    calls[sc]++
    if (!((sc, $2) in seen)) { seen[sc, $2] = 1; if ($2 ~ /^read_/) withcalls[sc]++ }
    if (pending) { fin[sc] = fin[sc] " " $2; pending = 0 }
  }
  END {
    for (i = 1; i <= n; i++) {
      sc = order[i]
      r = (sc in reads) ? sprintf(", reads with calls %d of %d", withcalls[sc], reads[sc]) : ""
      f = (sc in fin) ? ", Finish() in:" fin[sc] : ""
      u = (sc in updates) ? sprintf(", %d Update() calls (%d off R'"'"'s thread)", updates[sc], offthread[sc] + 0) : ""
      printf "%s: %d callbacks%s%s%s\n", sc, calls[sc], u, r, f
    }
  }
' "$1"
}

{
  echo "# Per scenario: callbacks, reads with any callback (of all reads), and the phase each Finish() came in."
  echo "# set_buffer is the SET before a stream, open is dbGetQueryArrow(), read_<k> the k-th \$get_next(), call the dbGetQuery() call."
  echo "# A statement run through dbGetQuery() or dbExecute() gets two, the first for the PREPARE the glue runs."
  echo
  echo "## Under gdb, with breakpoints on Update() and Finish()"
  echo
  summarize "$raw"
  echo
  echo "## Without gdb"
  echo
  summarize "$plain"
} >"$here/finish.txt"
