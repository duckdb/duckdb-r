#!/bin/bash
cd /workspace/v2 && git checkout -q --detach land-v2-pass4
/home/user/duckdb-r/scripts/series-fold.sh land-v2-pass4 \
  --fold "$(cat /workspace/fix-2062.txt):Landing v2 (finding 1): this commit refuses any statement on a connection while a result is open there, and a streamed Arrow result is one. The glue keeps \`main\`'s behaviour instead: it tracks the open Arrow results by client context (\`ROpenResult\`), and before it starts a statement there, in \`rapi_prepare()\`, \`rapi_execute()\`, the relational API, registration and ALTREP materialization, it ends them with \`EndOpenResults()\`, so their next read reports that another statement invalidated them (\`src/arrow_export.cpp\`)." && echo "FOLD DONE $(git rev-parse HEAD)" || /workspace/bin/fold-loop.sh
