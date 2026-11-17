#!/bin/sh
# Runs finish.R under gdb with a breakpoint on RProgressBarDisplay::Finish()
# that prints FINISH, and writes finish.txt beside itself: every FINISH with
# the callback lines around it, and a count of the callbacks per phase.
#
# Usage, with the duckdb under test first on the library path:
#   experiments/2026-11-17-progress-display/finish.sh
#
# Needs: gdb, R with duckdb and nanoarrow.
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
break RProgressBarDisplay::Finish
commands
silent
printf "FINISH\n"
continue
end
run
EOF

R -d "gdb -batch -x $gdbcmds" --vanilla --no-echo -f "$here/finish.R" 2>&1 |
  grep -E '^(FINISH|=== |callback )' >"$raw"

{
  echo "# FINISH marks a call to RProgressBarDisplay::Finish(); the callback line after it is the 100 it passes."
  echo "# Lines before the first === come from the setup statements."
  echo
  echo "## Every FINISH, with the line before and after it"
  grep -n -B1 -A1 '^FINISH' "$raw" || true
  echo
  echo "## Callbacks per phase"
  awk '/^callback /{ $NF=""; n[$0]++ } END { for (k in n) print n[k], k }' "$raw" |
    sort -k3,3 -k4,4n
} >"$here/finish.txt"
