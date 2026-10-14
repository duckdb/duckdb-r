#!/bin/bash
# gate-all.sh <from> <to> <log>: the glue gate at every commit of from..to (first parent, from included).
# A commit whose glue and engine headers are byte-identical to the previous commit's has the same result,
# which is reused and marked as such.
set -uo pipefail
from=$1 to=$2 log=$3
wt=/workspace/g
[ -d $wt ] || git -C /home/user/duckdb-r worktree add --detach -q $wt "$to"
cd $wt
prev_key='' prev_res=''
for c in $(git rev-list --reverse --first-parent "$from^..$to"); do
  key=$(git ls-tree -r "$c" -- src configure configure.win | grep -E '\.(h|hpp|hh|inc|ipp|tcc|def)$|	src/[^/]+\.(cpp|h|hpp)$|	src/include/|	src/vendor/|	configure|	src/Makevars' | git hash-object --stdin)
  if [ "$key" = "$prev_key" ]; then
    echo "$c $prev_res same-inputs" >> "$log"; continue
  fi
  git checkout -q -f --detach "$c" && git clean -qfdx src
  out=$(/workspace/bin/gate.sh 2>/dev/null); st=$?
  case $st in 0) res=ok ;; 1) res="FAIL:$(echo $out | tr ' ' ',')" ;; *) res=NORUN ;; esac
  echo "$c $res checked" >> "$log"
  prev_key=$key prev_res=$res
done
echo "GATE DONE" >> "$log"
