#!/bin/sh
label=$1; target=$2; s=$3
case "$s" in
  stream_stdin_csv) awk -v n="${ROWS:-50000000}" 'BEGIN { for (i = 1; i <= n; i++) printf "%d.0,%d.0\n", i, i * 2 }' | /cache/memingest "$label" "$target" "$s" ;;
  *)                /cache/memingest "$label" "$target" "$s" ;;
esac
