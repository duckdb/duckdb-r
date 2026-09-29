#!/usr/bin/env bash
# Where a reader from to_arrow_stream(), handed back to its own connection
# with to_duckdb(), waits: start the round trip in the background, let it
# hang, and print every thread's stack with gdb. Run from this directory.
set -euo pipefail

script=$(mktemp --suffix=.R)
trap 'rm -f "$script"' EXIT
cat >"$script" <<'EOF'
suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(dplyr, warn.conflicts = FALSE)
  library(arrow, warn.conflicts = FALSE)
})
source("to-arrow-stream.R")
con <- dbConnect(duckdb(shared_home = FALSE))
dbExecute(con, "CREATE TABLE nums AS SELECT range AS i FROM range(10)")
to_arrow_stream(tbl(con, "nums")) |> to_duckdb(con = con) |> collect()
EOF

timeout 120 Rscript "$script" >/dev/null 2>&1 &
sleep 15
pid=$(pgrep -f -- "--file=$script" | head -n 1)
gdb -p "$pid" -batch -ex "thread apply all bt 25" 2>/dev/null
kill "$pid"
