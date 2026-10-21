# The same scans through the Python client, which shares the engine and none
# of the R glue. Run as `python3 self-scan.py <case>`; run-python.sh runs
# every case under a ten-second timeout.
import sys

import duckdb

SQL = "SELECT i FROM range(3000000) t(i)"
case = sys.argv[1]
con = duckdb.connect()

if case == "own-connection":
    # A streaming reader, scanned by name on the connection it came from.
    reader = con.execute(SQL).to_arrow_reader()
    print(con.execute("SELECT count(*) FROM reader").fetchall())
elif case == "own-connection-relation":
    # The same through the relational API.
    reader = con.sql(SQL).to_arrow_reader()
    print(con.execute("SELECT count(*) FROM reader").fetchall())
elif case == "cursor":
    # A cursor is a second connection to the same database.
    reader = con.cursor().execute(SQL).to_arrow_reader()
    print(con.execute("SELECT count(*) FROM reader").fetchall())
elif case == "materialized":
    # An Arrow table holds the whole result before the scan starts.
    tab = con.execute(SQL).to_arrow_table()
    print(con.execute("SELECT count(*) FROM tab").fetchall())
