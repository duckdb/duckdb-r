#!/bin/bash
cd /workspace/v2
time /home/user/duckdb-r/scripts/series-fold.sh land-v2-pass1 \
  --fold "$(cat /workspace/fix-202.txt):Landing v2 (finding 3): \`rapi_expr_window()\` passes \`lag()\` and \`lead()\` the default offset of 1 before a default given without an offset, which the engine would otherwise read as the offset (\`src/relational.cpp\`)."
echo "FOLD EXIT $?"
