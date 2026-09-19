#!/bin/sh
label=$1; target=$2; s=$3
case "$s" in
  stream_stdin_csv)   awk 'BEGIN { for (i = 1; i <= 50000000; i++) printf "%d.0,%d.0\n", i, i * 2 }' | python /exp/python/ingest.py "$label" "$target" "$s" ;;
  stream_stdin_arrow|stream_stdin_arrow_syspool) python /exp/python/producer_arrow.py | python /exp/python/ingest.py "$label" "$target" "$s" ;;
  *)                  python /exp/python/ingest.py "$label" "$target" "$s" ;;
esac
