#!/bin/sh
# Install the duckdb wheel and its conversion targets into the cache.
set -e
pip install --quiet --target /cache/site duckdb pyarrow pandas numpy
PYTHONPATH=/cache/site python -c "import duckdb, pyarrow, pandas; print('ready: duckdb', duckdb.__version__, 'pyarrow', pyarrow.__version__, 'pandas', pandas.__version__)"
