#!/bin/bash
# Usage: run-many.sh <lib> <template> <n> <label> <query> [pre]
# One fresh R process per run, each on a fresh copy of <template> (icu installed, not loaded).
# Prints a tally of "rc, result, icu loaded before, icu loaded after".
F=$(cd "$(dirname "$0")" && pwd)
export RLIB=$1; T=$2; N=$3; L=$4; export Q="$5"; export PRE="$6"
out=$(mktemp)
for i in $(seq 1 "$N"); do
  d=$(mktemp -d); cp -r "$T"/. "$d"/; export EXTDIR=$d
  o=$(Rscript "$F/one.R" 2>&1); rc=$?
  echo -e "rc=$rc\t$(echo "$o" | grep RESULT | cut -f2-)$( [ $rc -ne 0 ] && echo " | $(echo "$o" | tail -3 | tr '\n' ' ')")" >> "$out"
  rm -rf "$d"
done
echo "== $L"; sort "$out" | uniq -c; rm -f "$out"
