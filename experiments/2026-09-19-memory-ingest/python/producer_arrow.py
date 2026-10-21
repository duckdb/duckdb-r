# Producer for the Arrow-over-a-pipe route: fifty batches of a million rows as an IPC stream on stdout.
import sys, os, numpy as np, pyarrow as pa
schema = pa.schema([("a", pa.float64()), ("b", pa.float64())])
w = pa.ipc.new_stream(sys.stdout.buffer, schema); rng = np.random.default_rng(1)
for _ in range(int(os.environ.get("ROWS", "50000000")) // 1_000_000): w.write_batch(pa.record_batch([rng.random(1_000_000), rng.random(1_000_000)], schema=schema))
w.close()
