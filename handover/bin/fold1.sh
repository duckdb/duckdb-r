#!/bin/bash
cd /workspace/v2
S=/home/user/duckdb-r/scripts/series-fold.sh
f() { cat /workspace/fix-$1.txt; }
time $S land-v2-base \
  --fold "$(f 401):Landing v2 (finding 8): \`TIMESTAMP_TZ_NS\` is labeled with the session \`TimeZone\`, like \`TIMESTAMP_TZ\`, in \`duckdb_r_decorate()\` (\`src/transform.cpp\`); \`test-timezone.R\` checks it without icu." \
  --fold "$(f 405):Landing v2 (finding 5): \`rel_to_csv()\` refuses an empty file name, as \`rel_to_parquet()\` does (\`R/relational.R\`)." \
  --fold "$(f 653):Landing v2 (finding 9): \`RType::operator==()\` compares struct field names and factor levels exactly, with \`GetIdentifierName()\` (\`src/types.cpp\`), since an \`Identifier\` compares case-insensitively." \
  --fold "$(f 1033):Landing v2 (findings 2 and 6): an Arrow result keeps the client context it ran on, taken with \`TryGetContext()\`, so it reads after \`dbDisconnect()\` (\`RQueryResult\`, \`RArrowArrayStreamWrapper\`); a statement a finalizer frees is parked rather than destroyed, so a finalizer never takes the context lock, and \`dbClearResult()\` destroys it at once (\`src/statement.cpp\`)."
echo "FOLD EXIT $?"
