// The ingest scenarios, Rust side (the duckdb crate, bundled engine): one scenario per process, one CSV line out.
use duckdb::arrow::{array::Float64Array, datatypes::{DataType, Field, Schema}, record_batch::RecordBatch};
use duckdb::vtab::arrow::{arrow_recordbatch_to_query_params, ArrowVTab};
use duckdb::Connection;
use std::sync::Arc;
use std::time::Instant;

// ROWS scales the data: 50 million rows of two doubles are 800 MB.
fn n_rows() -> usize {
    std::env::var("ROWS").ok().and_then(|s| s.parse().ok()).unwrap_or(50_000_000)
}

fn stat(key: &str) -> f64 {
    let s = std::fs::read_to_string("/proc/self/status").unwrap();
    for l in s.lines() {
        if l.starts_with(key) {
            let kb: f64 = l.split_whitespace().nth(1).unwrap().parse().unwrap();
            return kb / 1024.0;
        }
    }
    0.0
}

fn schema() -> Arc<Schema> {
    Arc::new(Schema::new(vec![Field::new("a", DataType::Float64, false), Field::new("b", DataType::Float64, false)]))
}

fn batch(a: Vec<f64>, b: Vec<f64>) -> RecordBatch {
    RecordBatch::try_new(schema(), vec![Arc::new(Float64Array::from(a)), Arc::new(Float64Array::from(b))]).unwrap()
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let (image, target, scenario) = (&args[1], &args[2], &args[3]);
    let conn = if target == "file" {
        Connection::open(format!("/tmp/ingest-{}.duckdb", std::process::id())).unwrap()
    } else {
        Connection::open_in_memory().unwrap()
    };
    conn.execute_batch("SET memory_limit = '300MB'").unwrap();
    let create = |c: &Connection| c.execute_batch("CREATE TABLE t (a DOUBLE, b DOUBLE)").unwrap();
    let count = |c: &Connection| -> i64 { c.query_row("SELECT count(*) FROM t", [], |r| r.get(0)).unwrap() };
    let mut base = 0.0;
    let mut t0 = Instant::now();
    let mut start = || {
        std::fs::write("/proc/self/clear_refs", "5").unwrap();
        base = stat("VmRSS");
        t0 = Instant::now();
    };
    let rows: i64;
    match scenario.as_str() {
        "stream_appender_rows" => {
            create(&conn);
            start();
            let mut app = conn.appender("t").unwrap();
            for i in 0..n_rows() {
                app.append_row([i as f64, 2.0 * i as f64]).unwrap();
            }
            app.flush().unwrap();
            drop(app);
            rows = count(&conn);
        }
        "frame_vec_appender" => {
            let a: Vec<f64> = (0..n_rows()).map(|i| i as f64).collect();
            let b: Vec<f64> = (0..n_rows()).map(|i| 2.0 * i as f64).collect();
            create(&conn);
            start();
            let mut app = conn.appender("t").unwrap();
            for i in 0..n_rows() {
                app.append_row([a[i], b[i]]).unwrap();
            }
            app.flush().unwrap();
            drop(app);
            rows = count(&conn);
        }
        "stream_append_record_batches" => {
            create(&conn);
            start();
            let mut app = conn.appender("t").unwrap();
            for j in 0..n_rows() / 1_000_000 {
                let a: Vec<f64> = (0..1_000_000).map(|k| (j * 1_000_000 + k) as f64).collect();
                let b: Vec<f64> = a.iter().map(|x| 2.0 * x).collect();
                app.append_record_batch(batch(a, b)).unwrap();
            }
            app.flush().unwrap();
            drop(app);
            rows = count(&conn);
        }
        "frame_arrow_vtab" => {
            let a: Vec<f64> = (0..n_rows()).map(|i| i as f64).collect();
            let b: Vec<f64> = (0..n_rows()).map(|i| 2.0 * i as f64).collect();
            start();
            conn.register_table_function::<ArrowVTab>("arrow").unwrap();
            let params = arrow_recordbatch_to_query_params(batch(a, b));
            conn.execute("CREATE TABLE t AS SELECT a, b FROM arrow(?, ?)", params).unwrap();
            rows = count(&conn);
        }
        "stream_stdin_csv" => {
            create(&conn);
            start();
            conn.execute_batch("COPY t FROM '/dev/stdin' (FORMAT CSV, HEADER false)").unwrap();
            rows = count(&conn);
        }
        "file_read_parquet" => {
            start();
            conn.execute_batch("CREATE TABLE t AS SELECT a, b FROM read_parquet('/data/src.parquet')").unwrap();
            rows = count(&conn);
        }
        "file_read_csv" => {
            start();
            conn.execute_batch("CREATE TABLE t AS SELECT a, b FROM read_csv('/data/src.csv')").unwrap();
            rows = count(&conn);
        }
        "engine_generate" => {
            start();
            conn.execute_batch(&format!("CREATE TABLE t AS SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range({}) t(i)", n_rows())).unwrap();
            rows = count(&conn);
        }
        _ => panic!("unknown scenario {}", scenario),
    }
    let peak = stat("VmHWM");
    println!("rust,{},{},{},{},{},{},{},{:.1}", image, scenario, target, rows, base.round(), peak.round(), (peak - base).round(), t0.elapsed().as_secs_f64());
}
