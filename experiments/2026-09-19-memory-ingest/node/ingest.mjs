// The ingest scenarios, Node side (@duckdb/node-api): one scenario per process, one CSV line out.
// Usage: node ingest.mjs <image-label> <file|memory> <scenario>
import { DuckDBInstance, DuckDBDataChunk, DuckDBTableFunction, DOUBLE } from '@duckdb/node-api';
import { readFileSync, writeFileSync } from 'node:fs';
const [image, target, scenario] = process.argv.slice(2);
const stat = (key) => Math.round(+readFileSync('/proc/self/status', 'utf8').match(new RegExp(key + ':\\s+(\\d+)'))[1] / 1024);
const N = 50_000_000;
const instance = await DuckDBInstance.create(target === 'file' ? `/tmp/ingest-${process.pid}.duckdb` : ':memory:');
const conn = await instance.connect();
await conn.run("SET memory_limit = '300MB'");
const create = () => conn.run('CREATE TABLE t (a DOUBLE, b DOUBLE)');
const ctas = (src) => conn.run(`CREATE TABLE t AS SELECT a, b FROM ${src}`);
const count = async () => Number((await conn.runAndReadAll('SELECT count(*) FROM t')).getRows()[0][0]);
let base, t0;
const start = () => { writeFileSync('/proc/self/clear_refs', '5'); base = stat('VmRSS'); t0 = Date.now(); };
let rows;
if (scenario === 'stream_appender_rows') {
  await create(); start(); const app = await conn.createAppender('t');
  for (let i = 0; i < N; i++) { app.appendDouble(i); app.appendDouble(2 * i); app.endRow(); }
  app.closeSync(); rows = await count();
} else if (scenario === 'stream_appender_chunks' || scenario === 'frame_arrays_appender_chunks') {
  let A, B;
  if (scenario === 'frame_arrays_appender_chunks') { A = new Float64Array(N); B = new Float64Array(N); for (let i = 0; i < N; i++) { A[i] = i; B[i] = 2 * i; } }
  await create(); start(); const app = await conn.createAppender('t'); const chunk = DuckDBDataChunk.create([DOUBLE, DOUBLE]);
  for (let i = 0; i < N; i += 2048) {
    const n = Math.min(2048, N - i);
    const a = A ? Array.from(A.subarray(i, i + n)) : Array.from({ length: n }, (_, k) => i + k);
    const b = B ? Array.from(B.subarray(i, i + n)) : Array.from({ length: n }, (_, k) => 2 * (i + k));
    chunk.setColumns([a, b]); app.appendDataChunk(chunk);
  }
  app.closeSync(); rows = await count();
} else if (scenario === 'stream_table_function') {
  start();
  conn.registerTableFunction(DuckDBTableFunction.create({
    name: 'gen', parameterTypes: [],
    bindFunction: (info) => { info.addResultColumn('a', DOUBLE); info.addResultColumn('b', DOUBLE); },
    initFunction: (info) => { info.setInitData({ i: 0 }); },
    mainFunction: (info, output) => {
      const st = info.getInitData(); const n = Math.min(2048, N - st.i); output.rowCount = n;
      if (n === 0) return;
      const va = output.getColumnVector(0), vb = output.getColumnVector(1);
      for (let k = 0; k < n; k++) { va.setItem(k, st.i + k); vb.setItem(k, 2 * (st.i + k)); }
      va.flush(); vb.flush(); st.i += n;
    },
  }));
  await ctas('gen()'); rows = await count();
} else if (scenario === 'stream_stdin_csv') { await create(); start(); await conn.run("COPY t FROM '/dev/stdin' (FORMAT CSV, HEADER false)"); rows = await count(); }
else if (scenario === 'file_read_parquet') { start(); await ctas("read_parquet('/data/src.parquet')"); rows = await count(); }
else if (scenario === 'file_read_csv') { start(); await ctas("read_csv('/data/src.csv')"); rows = await count(); }
else if (scenario === 'engine_generate') { start(); await ctas(`(SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range(${N}) t(i))`); rows = await count(); }
else { throw new Error('unknown scenario ' + scenario); }
const peak = stat('VmHWM');
console.log(`node,${image},${scenario},${target},${rows},${base},${peak},${peak - base},${((Date.now() - t0) / 1000).toFixed(1)}`);
process.exit(0);
