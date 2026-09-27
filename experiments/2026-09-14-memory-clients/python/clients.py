# The cross-client scenarios, Python side (the duckdb wheel): one scenario per process, one CSV line out.
import sys, os, time, duckdb
image, scenario = sys.argv[1], sys.argv[2]
def peak_mb():
    for line in open("/proc/self/status"):
        if line.startswith("VmHWM"):
            return int(line.split()[1]) / 1024
N = int(os.environ.get("ROWS", "50000000"))  # 50 million rows of two doubles are 800 MB
Q = f"SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range({N}) t(i)"
QS = f"SELECT i::DOUBLE AS a, ((i * 7919) % 1000003)::DOUBLE AS b FROM range({N}) t(i) ORDER BY b"
con = duckdb.connect()
t0 = time.time(); rows = 0
if scenario == "version":
    print(f"python,{image},version,{duckdb.__version__},{con.execute('SELECT version()').fetchone()[0]},"); raise SystemExit(0)
elif scenario == "materialize_df":
    df = con.execute(Q).df(); rows = len(df)
elif scenario == "materialize_arrow":
    tb = con.execute(Q).fetch_arrow_table(); rows = tb.num_rows
elif scenario == "materialize_numpy":
    d = con.execute(Q).fetchnumpy(); rows = len(d["a"])
elif scenario == "stream_fetchmany":
    cur = con.execute(Q)
    while True:
        ch = cur.fetchmany(1_000_000)
        if not ch: break
        rows += len(ch)
elif scenario in ("stream_arrow_reader", "stream_sorted_limited"):
    if scenario == "stream_sorted_limited": con.execute("SET memory_limit = '200MB'")
    reader = con.execute(QS if scenario == "stream_sorted_limited" else Q).fetch_record_batch(1_000_000)
    for batch in reader: rows += batch.num_rows
elif scenario == "stream_df_chunk":
    rel = con.sql(Q)
    while True:
        df = rel.fetch_df_chunk(vectors_per_chunk=500)
        if len(df) == 0: break
        rows += len(df)
else:
    raise SystemExit("unknown scenario " + scenario)
print(f"python,{image},{scenario},{rows},{round(peak_mb())},{time.time() - t0:.1f}")
