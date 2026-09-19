# The ingest scenarios, Python side (the duckdb wheel): one scenario per process, one CSV line out.
# Usage: python ingest.py <image-label> <file|memory> <scenario>
import sys, time, tempfile, duckdb, numpy as np
image, target, scenario = sys.argv[1:4]
def stat(key):
    for line in open("/proc/self/status"):
        if line.startswith(key): return int(line.split()[1]) / 1024
def hwm(): return stat("VmHWM")
# Writing 5 to clear_refs resets the kernel's peak-RSS counter to the current RSS, so the peak
# measured afterwards is the measured step's own, not the source frame's construction.
def reset_peak(): open("/proc/self/clear_refs", "w").write("5")
N = 50_000_000
con = duckdb.connect(tempfile.mktemp(suffix=".duckdb") if target == "file" else ":memory:")
con.execute("SET memory_limit = '300MB'")
def arrays(n=N):
    rng = np.random.default_rng(1); return rng.random(n), rng.random(n)
def create(): con.execute("CREATE TABLE t (a DOUBLE, b DOUBLE)")
def ctas(src): con.execute(f"CREATE TABLE t AS SELECT a, b FROM {src}")
def count(): return con.execute("SELECT count(*) FROM t").fetchone()[0]
base = t0 = None
def start():
    global base, t0
    import gc; gc.collect(); reset_peak(); base = stat("VmRSS"); t0 = time.time()
rows = None
if scenario in ("frame_pandas_register", "frame_pandas_register_only", "frame_pandas_append", "frame_parquet_roundtrip"):
    import pandas as pd
    a, b = arrays(); df = pd.DataFrame({"a": a, "b": b}); del a, b
    if scenario == "frame_pandas_register":
        start(); con.register("src", df); ctas("src"); rows = count()
    elif scenario == "frame_pandas_register_only":
        start(); con.register("src", df); rows = con.execute("SELECT count(*), sum(a) FROM src").fetchone()[0]
    elif scenario == "frame_pandas_append":
        create(); start(); con.append("t", df); rows = count()
    else:
        start(); f = tempfile.mktemp(suffix=".parquet"); df.to_parquet(f); ctas(f"read_parquet('{f}')"); rows = count()
elif scenario == "frame_arrow_register":
    import pyarrow as pa
    a, b = arrays(); tb = pa.table({"a": a, "b": b}); del a, b
    start(); con.register("src", tb); ctas("src"); rows = count()
elif scenario == "frame_polars_register":
    import polars as pl
    a, b = arrays(); pdf = pl.DataFrame({"a": a, "b": b}); del a, b
    start(); con.register("src", pdf); ctas("src"); rows = count()
elif scenario in ("stream_arrow_reader_generator", "stream_arrow_reader_generator_syspool"):
    import pyarrow as pa
    if scenario.endswith("_syspool"): pa.set_memory_pool(pa.system_memory_pool())
    schema = pa.schema([("a", pa.float64()), ("b", pa.float64())])
    def gen():
        rng = np.random.default_rng(1)
        for _ in range(50): yield pa.record_batch([rng.random(1_000_000), rng.random(1_000_000)], schema=schema)
    start(); con.register("src", pa.RecordBatchReader.from_batches(schema, gen())); ctas("src"); rows = count()
elif scenario == "chunks_pandas_append":
    import pandas as pd
    create(); start(); rng = np.random.default_rng(1)
    for _ in range(50): con.append("t", pd.DataFrame({"a": rng.random(1_000_000), "b": rng.random(1_000_000)}))
    rows = count()
elif scenario == "stream_stdin_csv":
    create(); start(); con.execute("COPY t FROM '/dev/stdin' (FORMAT CSV, HEADER false)"); rows = count()
elif scenario in ("stream_stdin_arrow", "stream_stdin_arrow_syspool"):
    import pyarrow as pa
    if scenario.endswith("_syspool"): pa.set_memory_pool(pa.system_memory_pool())
    start(); con.register("src", pa.ipc.open_stream(sys.stdin.buffer)); ctas("src"); rows = count()
elif scenario == "file_read_parquet":
    start(); ctas("read_parquet('/data/src.parquet')"); rows = count()
elif scenario == "file_read_csv":
    start(); ctas("read_csv('/data/src.csv')"); rows = count()
elif scenario == "engine_generate":
    start(); ctas(f"(SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range({N}) t(i))"); rows = count()
else:
    raise SystemExit("unknown scenario " + scenario)
peak = hwm()
print(f"python,{image},{scenario},{target},{rows},{round(base)},{round(peak)},{round(peak - base)},{time.time() - t0:.1f}")
