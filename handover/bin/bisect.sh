#!/bin/bash
# bisect.sh <pos> <filter> [extra test file from main...]: build v2 commit <pos> unfixed, run filtered tests
set -uo pipefail
pos=$1 filter=$2; shift 2
exec 9>/workspace/build.lock; flock 9
c=$(sed -n "${pos}p" /workspace/v2.list)
cd /workspace/b && git checkout -q -f --detach "$c" && git clean -qfd tests
for f in "$@"; do git -C /workspace/b show 61edbd384:tests/testthat/$f > tests/testthat/$f; done
rm -rf /workspace/lib-b
if /workspace/bin/install.sh /workspace/b /workspace/lib-b >/dev/null; then
  out=$(/workspace/bin/test.sh /workspace/b /workspace/lib-b "$filter" 2>&1)
  echo "$out" > /workspace/bisect-$pos.log
  echo "pos $pos ${c:0:10} $(grep SUMMARY <<<"$out")"
  sed -n '/^FAILING/,$p' <<<"$out"
else
  echo "pos $pos ${c:0:10} INSTALL FAILED"
fi
