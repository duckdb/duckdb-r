#!/bin/sh
# How far Ctrl+C reaches, in the DuckDB CLI and in R, for work the engine
# executes itself and for a wait blocked inside an extension.
#
# Usage:
#   ./run.sh [path/to/duckdb-cli]
#
# Needs: python3, a duckdb CLI binary, and an R with the duckdb package
# installed. Writes transcript.txt beside itself.
#
# Each case types SQL or R at a real prompt on a pty, presses Ctrl+C some
# number of times, then types a marker. The marker running is the verdict:
# it means control came back to the user.

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cli=${1:-$here/duckdb}
port=8998
out=$here/transcript.txt

if [ ! -x "$cli" ]; then
  echo "no duckdb CLI at $cli; pass one as the first argument" >&2
  exit 2
fi

# The CLI's line editor rewrites what it is fed; TERM=dumb turns it off.
TERM=dumb
export TERM

: > "$out"

note() {
  printf '\n===== %s\n' "$1" | tee -a "$out"
}

drive() {
  python3 "$here/ctrlc.py" "$@" >> "$out" 2>> "$out" || true
}

R CMD SHLIB "$here/blocking_poll.c" > "$here/shlib.log" 2>&1

python3 "$here/hangserver.py" "$port" > "$here/hangserver.log" 2>&1 &
hangpid=$!
trap 'kill $hangpid 2>/dev/null || true' EXIT
sleep 1

sql_marker=$(printf "SELECT 'MARKER-RAN' AS marker;\r")
r_marker=$(printf "cat('MARKER-RAN\\\\n')\r")

scan="SELECT count(*) FROM range(1000000000000);"
prep="LOAD httpfs; SET http_timeout=600000; SET http_retries=0;"
attach="ATTACH 'http://127.0.0.1:$port/x.db' AS x (READ_ONLY);"

note "CLI, work the engine executes, 1 x Ctrl+C"
drive --prewait 4 --type "$(printf '%s\r' "$scan")" \
  --wait 5 --hits 1 --gap 4 --then "$sql_marker" --after 6 -- "$cli" -dark-mode

note "R, work the engine executes, 1 x Ctrl+C"
drive --prewait 4 \
  --type "$(printf 'con <- DBI::dbConnect(duckdb::duckdb())\r')" \
  --type "$(printf "DBI::dbGetQuery(con, \"%s\")\r" "SELECT count(*) FROM range(1000000000000)")" \
  --wait 6 --hits 1 --gap 4 --then "$r_marker" --after 6 -- \
  R --no-save --no-restore --quiet

note "CLI, wait blocked in httpfs, 1 x Ctrl+C"
drive --prewait 4 --type "$(printf '%s\r' "$prep")" --type "$(printf '%s\r' "$attach")" \
  --wait 5 --hits 1 --gap 5 --then "$sql_marker" --after 8 -- "$cli" -dark-mode

note "CLI, wait blocked in httpfs, 3 x Ctrl+C"
drive --prewait 4 --type "$(printf '%s\r' "$prep")" --type "$(printf '%s\r' "$attach")" \
  --wait 5 --hits 3 --gap 3 --then "$sql_marker" --after 6 -- "$cli" -dark-mode

note "R, wait blocked in httpfs, 5 x Ctrl+C"
drive --prewait 4 \
  --type "$(printf 'con <- DBI::dbConnect(duckdb::duckdb()); DBI::dbExecute(con, "%s")\r' "$prep")" \
  --type "$(printf "DBI::dbExecute(con, \"ATTACH 'http://127.0.0.1:$port/x.db' AS x (READ_ONLY)\")\r")" \
  --wait 6 --hits 5 --gap 3 --then "$r_marker" --after 8 -- \
  R --no-save --no-restore --quiet

note "R, C call that never asks R about interrupts, 2 x Ctrl+C"
drive --prewait 3 --type "$(printf "dyn.load('%s/blocking_poll.so')\r" "$here")" \
  --type "$(printf ".Call('block_unchecked', 60L)\r")" \
  --wait 5 --hits 2 --gap 3 --then "$r_marker" --after 6 -- \
  R --no-save --no-restore --quiet

note "R, same C call with R_CheckUserInterrupt(), 1 x Ctrl+C"
drive --prewait 3 --type "$(printf "dyn.load('%s/blocking_poll.so')\r" "$here")" \
  --type "$(printf ".Call('block_checked', 60L)\r")" \
  --wait 5 --hits 1 --gap 3 --then "$r_marker" --after 6 -- \
  R --no-save --no-restore --quiet

# Both prompts colour their output; strip the escapes so the record diffs.
sed -i 's/\x1b\[[0-9;?]*[a-zA-Z]//g; s/\r$//' "$out"

echo
echo "transcript: $out (MARKER-RAN in a case means control came back)"
