// The cross-client scenarios, Node side (@duckdb/node-api): one scenario per process, one CSV line out.
import { DuckDBInstance } from '@duckdb/node-api';
import { readFileSync } from 'node:fs';
const [image, scenario] = process.argv.slice(2);
const peakMB = () => Math.round(+readFileSync('/proc/self/status', 'utf8').match(/VmHWM:\s+(\d+)/)[1] / 1024);
const N = Number(process.env.ROWS ?? 50_000_000); // 50 million rows of two doubles are 800 MB
const Q = `SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range(${N}) t(i)`;
const QS = `SELECT i::DOUBLE AS a, ((i * 7919) % 1000003)::DOUBLE AS b FROM range(${N}) t(i) ORDER BY b`;
const instance = await DuckDBInstance.create(':memory:');
const conn = await instance.connect();
const t0 = Date.now();
let rows = 0;
const drain = async (result) => { for (;;) { const chunk = await result.fetchChunk(); if (!chunk || chunk.rowCount === 0) break; rows += chunk.rowCount; } };
if (scenario === 'version') { const r = await conn.runAndReadAll('SELECT version()'); const { createRequire } = await import('node:module'); console.log(`node,${image},version,${createRequire(import.meta.url)('@duckdb/node-api/package.json').version},${r.getRows()[0][0]},`); process.exit(0); }
else if (scenario === 'materialize_columns') { const reader = await conn.runAndReadAll(Q); rows = reader.getColumns()[0].length; }
else if (scenario === 'materialize_chunks') { const reader = await conn.runAndReadAll(Q); rows = reader.currentRowCount; }
else if (scenario === 'run_fetch_discard') { await drain(await conn.run(Q)); }
else if (scenario === 'stream_fetch_discard') { await drain(await conn.stream(Q)); }
else if (scenario === 'stream_sorted_limited') { await conn.run("SET memory_limit = '200MB'"); await drain(await conn.stream(QS)); }
else { throw new Error('unknown scenario ' + scenario); }
console.log(`node,${image},${scenario},${rows},${peakMB()},${((Date.now() - t0) / 1000).toFixed(1)}`);
