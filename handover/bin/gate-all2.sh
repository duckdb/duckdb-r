#!/bin/bash
# gate-all2.sh <from> <to> <log> [worktree]: the glue gate (glue_compiles() of scripts/series-forward-build.sh)
# at every commit of from..to, first parent, from included. A commit is checked when it changes a glue file,
# the build configuration, or a header in the include closure of the glue as last checked; otherwise its
# result is the previous commit's, since every file the compiler reads is the same.
set -uo pipefail
from=$1 to=$2 log=$3 wt=${4:-/workspace/g}
[ -d "$wt" ] || git -C /home/user/duckdb-r worktree add --detach -q "$wt" "$to"
cd "$wt"
closure=$(mktemp)
prev='' res=''
for c in $(git rev-list --reverse --first-parent "$from^..$to"); do
  check=1
  if [ -n "$prev" ] && [ -s "$closure" ]; then
    changed=$(git diff --name-only "$prev" "$c" -- src configure configure.win)
    if ! grep -qE '^src/[^/]+\.(cpp|hpp|h)$|^src/include/|^src/vendor/|^src/Makevars|^configure' <<<"$changed" &&
      ! grep -qxF -f "$closure" <<<"$changed"; then
      check=''
    fi
  fi
  if [ -z "$check" ]; then
    echo "$c $res same-inputs" >> "$log"
    prev=$c
    continue
  fi
  git checkout -q -f --detach "$c" && git clean -qfdx src
  out=$(/workspace/bin/gate.sh 2>/dev/null)
  st=$?
  case $st in 0) res=ok ;; 1) res="FAIL:$(echo $out | tr ' ' ',')" ;; *) res=NORUN ;; esac
  # The include closure of the glue at this commit, as paths in the repository
  flags=$(cd src && R CMD SHLIB -n cpp11.cpp 2>/dev/null | grep -m 1 -E -- '-c cpp11\.cpp' |
    sed -E 's/^ *(ccache )?g\+\+ //; s/ -c cpp11\.cpp -o cpp11\.o *$//')
  (cd src && for f in *.cpp; do eval "g++ $flags -MM $f" 2>/dev/null; done) | tr ' \\' '\n\n' |
    grep -E '^duckdb/' | sed 's|^|src/|' | sort -u > "$closure"
  echo "$c $res checked" >> "$log"
  prev=$c
done
rm -f "$closure"
echo "GATE DONE" >> "$log"
