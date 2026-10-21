#!/bin/bash
# Wraps one scenario; a `_gogc20` suffix runs it with GOGC=20 and keeps the suffix in the recorded name.
# pipefail, so a binary killed at the memory cap is reported as such rather than as sed's success.
set -o pipefail
label=$1; target=$2; s=$3; g=100
case "$s" in *_gogc20) g=20; s=${s%_gogc20} ;; esac
case "$s" in
  stream_stdin_csv) awk -v n="${ROWS:-50000000}" 'BEGIN { for (i = 1; i <= n; i++) printf "%d.0,%d.0\n", i, i * 2 }' | GOGC=$g /cache/memingest "$label" "$target" "$s" | sed "s/,$s,/,$3,/" ;;
  *)                GOGC=$g /cache/memingest "$label" "$target" "$s" | sed "s/,$s,/,$3,/" ;;
esac
