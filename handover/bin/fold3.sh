#!/bin/bash
cd /workspace/v2 && git checkout -q --detach land-v2-pass2
/home/user/duckdb-r/scripts/series-fold.sh land-v2-pass2 \
  --fold "$(cat /workspace/fix-1539.txt):Landing v2 (finding 3): the default offset of 1 that \`rapi_expr_window()\` passes \`lag()\` and \`lead()\` is built with \`ConstantExpression::FromValue()\`, as this commit builds every constant (\`src/relational.cpp\`)." && echo "FOLD DONE $(git rev-parse HEAD)" || /workspace/bin/fold-loop.sh
