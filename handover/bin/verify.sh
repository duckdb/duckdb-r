#!/bin/bash
# verify.sh <list> <pos>...: for each position of <list>, a clean R CMD INSTALL and the whole suite in /workspace/vw,
# results appended to /workspace/verify.log, full output in /workspace/verify-<pos>.log
list=$1; shift
for pos in "$@"; do
  exec 9>/workspace/build.lock; flock 9
  c=$(sed -n "${pos}p" "$list")
  [ -d /workspace/vw ] || git -C /home/user/duckdb-r worktree add --detach -q /workspace/vw "$c"
  git -C /workspace/vw checkout -q -f --detach "$c" && git -C /workspace/vw clean -qfdx
  rm -rf /workspace/lib-vw
  if /workspace/bin/install.sh /workspace/vw /workspace/lib-vw > /dev/null; then
    /workspace/bin/test.sh /workspace/vw /workspace/lib-vw > /workspace/verify-$pos.log 2>&1
    # A test that runs a subprocess can fail to fork under memory pressure: rerun those files alone once
    forkfail=$(grep -B1 'Cannot fork' /workspace/verify-$pos.log | grep -oE "test-[A-Za-z0-9_.-]+\.R" | sort -u | sed 's/^test-//; s/\.R$//' | paste -sd'|')
    if [ -n "$forkfail" ]; then
      /workspace/bin/test.sh /workspace/vw /workspace/lib-vw "^($forkfail)\$" > /workspace/verify-$pos-rerun.log 2>&1
      echo "pos $pos ${c:0:10} reran after fork failures ($forkfail): $(grep SUMMARY /workspace/verify-$pos-rerun.log)" >> /workspace/verify.log
    fi
    echo "pos $pos ${c:0:10} $(grep SUMMARY /workspace/verify-$pos.log)" >> /workspace/verify.log
    sed -n '/^FAILING/,$p' /workspace/verify-$pos.log >> /workspace/verify.log
  else
    echo "pos $pos ${c:0:10} INSTALL FAILED" >> /workspace/verify.log
  fi
  exec 9>&-
done
