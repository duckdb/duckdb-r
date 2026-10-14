#!/bin/bash
cd /workspace/v2 && git checkout -q --detach land-v2-pass5
/home/user/duckdb-r/scripts/series-fold.sh land-v2-pass5 \
  --fold "$(cat /workspace/fix-2112.txt):Landing v2 (finding 1): \`rapi_execute_impl()\` decides whether an Arrow result streams with \`StreamsByDefault()\`, passed the statement type as written, as \`ExecuteArrow()\` in the engine's ADBC driver does; \`CanDrain()\` no longer asks it again of the result, which reports the EXECUTE that ran the statement and so never streamed (\`src/statement.cpp\`, \`src/arrow_export.cpp\`)." && echo "FOLD DONE $(git rev-parse HEAD)" || /workspace/bin/fold-loop.sh
