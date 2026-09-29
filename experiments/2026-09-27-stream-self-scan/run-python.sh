#!/usr/bin/env bash
# Runs every case of self-scan.py under a ten-second timeout and prints what
# each printed and its exit status; 124 is the timeout's.
# Run from this directory; python.txt is its output.
set -u

python3 -c 'import duckdb, pyarrow; print("duckdb", duckdb.__version__, "pyarrow", pyarrow.__version__)'
for case in own-connection own-connection-relation cursor materialized; do
  echo "== $case"
  timeout 10 python3 self-scan.py "$case" 2>&1
  echo "exit status $?"
done
