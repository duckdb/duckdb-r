#!/bin/sh
# Wraps one scenario: the pipe routes get their producer, the rest run bare.
label=$1; target=$2; s=$3
case "$s" in
  stream_stdin_csv)   awk 'BEGIN { for (i = 1; i <= 50000000; i++) printf "%d.0,%d.0\n", i, i * 2 }' | Rscript /exp/r/ingest.R "$label" "$target" "$s" ;;
  stream_stdin_arrow|stream_stdin_arrow_1thread|stream_stdin_arrow_dbAppendTableArrow) Rscript /exp/r/producer_arrow.R | Rscript /exp/r/ingest.R "$label" "$target" "$s" ;;
  *)                  Rscript /exp/r/ingest.R "$label" "$target" "$s" ;;
esac
