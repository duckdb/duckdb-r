#!/bin/bash
# bisect-variant.sh <pos>: build pass-7 commit <pos> (with the invalidation-policy stub where it needs it) and run main's test-variant.R
pos=$1
exec 9>/workspace/build.lock; flock 9
c=$(sed -n "${pos}p" /workspace/p7.list)
cd /workspace/b && git checkout -q -f --detach "$c" && git clean -qfd tests
[ "$pos" -lt 148 ] && git apply /workspace/stub.patch
git -C /workspace/b show 61edbd384:tests/testthat/test-variant.R > tests/testthat/test-variant.R
rm -rf /workspace/lib-b
if /workspace/bin/install.sh /workspace/b /workspace/lib-b >/dev/null; then
  out=$(/workspace/bin/test.sh /workspace/b /workspace/lib-b variant 2>&1)
  echo "$out" > /workspace/variant-$pos.log
  echo "variant pos $pos ${c:0:10} $(grep -o '"[^"]*"' R/version.R | head -1) $(grep SUMMARY <<<"$out")"
else
  echo "variant pos $pos ${c:0:10} INSTALL FAILED"
fi
git checkout -q -f -- src
