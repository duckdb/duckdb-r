// The cross-client scenarios, Rust side (the duckdb crate, bundled engine): one scenario per process, one CSV line out.
use duckdb::Connection;
use std::time::Instant;

fn peak_mb() -> f64 {
    let s = std::fs::read_to_string("/proc/self/status").unwrap();
    for l in s.lines() {
        if l.starts_with("VmHWM") {
            let kb: f64 = l.split_whitespace().nth(1).unwrap().parse().unwrap();
            return kb / 1024.0;
        }
    }
    0.0
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let (image, scenario) = (&args[1], &args[2]);
    // ROWS scales the result: 50 million rows of two doubles are 800 MB.
    let n: usize = std::env::var("ROWS").ok().and_then(|s| s.parse().ok()).unwrap_or(50_000_000);
    let q = &format!("SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range({}) t(i)", n);
    let qs = &format!("SELECT i::DOUBLE AS a, ((i * 7919) % 1000003)::DOUBLE AS b FROM range({}) t(i) ORDER BY b", n);
    let conn = Connection::open_in_memory().unwrap();
    let t0 = Instant::now();
    let mut rows: usize = 0;
    match scenario.as_str() {
        "version" => {
            let v: String = conn.query_row("SELECT version()", [], |r| r.get(0)).unwrap();
            println!("rust,{},version,duckdb-crate,{},", image, v);
            return;
        }
        "materialize_arrow" => {
            let mut stmt = conn.prepare(q).unwrap();
            let batches: Vec<_> = stmt.query_arrow([]).unwrap().collect();
            rows = batches.iter().map(|b| b.num_rows()).sum();
        }
        "materialize_vec" => {
            let mut stmt = conn.prepare(q).unwrap();
            let v: Vec<(f64, f64)> = stmt
                .query_map([], |r| Ok((r.get(0)?, r.get(1)?)))
                .unwrap()
                .map(|x| x.unwrap())
                .collect();
            rows = v.len();
        }
        "stream_arrow" | "stream_sorted_limited" => {
            let query = if scenario == "stream_sorted_limited" {
                conn.execute_batch("SET memory_limit = '200MB'").unwrap();
                qs
            } else {
                q
            };
            let mut stmt = conn.prepare(query).unwrap();
            for b in stmt.query_arrow([]).unwrap() {
                rows += b.num_rows();
            }
        }
        "stream_rows" => {
            let mut stmt = conn.prepare(q).unwrap();
            let mut rs = stmt.query([]).unwrap();
            while let Some(r) = rs.next().unwrap() {
                let _a: f64 = r.get(0).unwrap();
                rows += 1;
            }
        }
        _ => panic!("unknown scenario {}", scenario),
    }
    println!("rust,{},{},{},{},{:.1}", image, scenario, rows, peak_mb().round(), t0.elapsed().as_secs_f64());
}
