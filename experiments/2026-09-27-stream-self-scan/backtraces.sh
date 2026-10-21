#!/usr/bin/env bash
# Where a scan of a stream on its own connection waits, with no R glue in the
# way: the Python client, and R on the build before #2775, whose streams
# were the engine's own. Starts each scan, lets it wait, and prints every
# thread's stack with gdb, the library path replaced by a placeholder.
# Run from this directory as `backtraces.sh <pre-#2775 library>`;
# backtraces.txt is its output.
set -euo pipefail

lib=$1
script=$(mktemp --suffix=.R)
trap 'rm -f "$script"' EXIT
cat >"$script" <<'EOF'
library(DBI)
con <- dbConnect(duckdb::duckdb())
stream <- dbGetQueryArrow(con, "SELECT i FROM range(3000000) t(i)")
duckdb::duckdb_register_arrow(con, "s", arrow::as_record_batch_reader(stream))
dbGetQuery(con, "SELECT count(*) AS n FROM s")
EOF

stacks() {
  "$@" >/dev/null 2>&1 &
  local pid=$!
  sleep 5
  gdb -p "$pid" -batch -ex "thread apply all bt 30" 2>/dev/null |
    sed "s|$lib|<pre-#2775 build library>|g"
  kill "$pid"
}

echo "=== Python: self-scan.py own-connection"
stacks python3 self-scan.py own-connection
echo "=== R, build before #2775"
stacks env R_LIBS="$lib" Rscript "$script"
