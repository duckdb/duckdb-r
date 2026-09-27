#!/bin/sh
# Install the duckdb wheel and the frame libraries into the cache, and write the shared source files:
# the same 50,000,000 rows as Parquet and as CSV, produced by the engine itself.
set -e
pip install --quiet --target /cache/site duckdb pyarrow pandas numpy polars
PYTHONPATH=/cache/site python - <<'PY'
import duckdb, pyarrow, pandas, polars, os
con = duckdb.connect()
q = "SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range(50000000) t(i)"
if not os.path.exists("/data/src.parquet"): con.execute(f"COPY ({q}) TO '/data/src.parquet' (FORMAT PARQUET)")
if not os.path.exists("/data/src.csv"): con.execute(f"COPY ({q}) TO '/data/src.csv' (FORMAT CSV, HEADER true)")
print("ready: duckdb", duckdb.__version__, "pyarrow", pyarrow.__version__, "pandas", pandas.__version__, "polars", polars.__version__,
      "parquet MB", os.path.getsize("/data/src.parquet") // 2**20, "csv MB", os.path.getsize("/data/src.csv") // 2**20)
PY
