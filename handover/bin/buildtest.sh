#!/bin/bash
# buildtest.sh <worktree> <lib> <log> [filter]: clean install and test, serialized with the other builds
exec 9>/workspace/build.lock; flock 9
rm -rf "$2"
if /workspace/bin/install.sh "$1" "$2" > /dev/null; then
  /workspace/bin/test.sh "$1" "$2" "${4:-}" > "$3" 2>&1
  echo "$(git -C "$1" rev-parse --short HEAD) $(grep SUMMARY "$3")"
  sed -n '/^FAILING/,$p' "$3"
else
  echo "$(git -C "$1" rev-parse --short HEAD) INSTALL FAILED ($2.install.log)"
fi
