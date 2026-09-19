#!/bin/sh
label=$1; target=$2; s=$3
cp /exp/node/ingest.mjs /cache/app/ingest.mjs
cmd="node --max-old-space-size=8192 /cache/app/ingest.mjs"
case "$s" in
  stream_stdin_csv) awk 'BEGIN { for (i = 1; i <= 50000000; i++) printf "%d.0,%d.0\n", i, i * 2 }' | $cmd "$label" "$target" "$s" ;;
  *)                $cmd "$label" "$target" "$s" ;;
esac
