#!/bin/bash
# fold-loop.sh: continue a stopped series-fold in /workspace/v2, resolving the known lag() conflict on its own
cd /workspace/v2
S=/home/user/duckdb-r/scripts/series-fold.sh
while :; do
  u=$(git diff --name-only --diff-filter=U)
  if [ "$u" = "src/relational.cpp" ] && git diff src/relational.cpp | grep -q default_offset; then
    python3 /workspace/bin/resolve_lag.py && clang-format -i src/relational.cpp && git add src/relational.cpp || exit 1
  elif [ -n "$u" ]; then
    echo "STOPPED on: $u"; exit 1
  fi
  if $S --continue; then echo "FOLD DONE $(git rev-parse HEAD)"; exit 0; fi
  [ -n "$(git diff --name-only --diff-filter=U)" ] || { echo "STOPPED without conflict"; exit 1; }
done
