``` r
# Records every call the engine makes to the progress callback, per query
# phase, for local queries read whole or streamed, for a query with a slow
# remote part and a slow local part, and for a stream under different
# streaming buffer sizes.
#
# Usage, from the repository root, with the duckdb under test first on the
# library path:
#   PROGRESS_EXPERIMENT_DIR=$PWD/experiments/2026-11-17-progress-display \
#     Rscript scripts/render-reprex.R \
#     experiments/2026-11-17-progress-display/run.R run
#
# Needs: duckdb, nanoarrow, python3, and DuckDB's extension repository for
# httpfs. Renders run.md. Every call goes to the CSV file PROGRESS_CALLS_CSV
# names, consecutive calls with the same phase and percentage collapsed into
# one row, or to a temporary file if it names none.
#
# Handbook: handbook/usage/interactive/README.md

suppressPackageStartupMessages(library(duckdb))

here <- Sys.getenv("PROGRESS_EXPERIMENT_DIR", getwd())
calls_csv <- Sys.getenv("PROGRESS_CALLS_CSV", tempfile(fileext = ".csv"))
```

``` r

# The callback receives one number: the engine's Update() passes the
# percentage, its Finish() passes 100 (src/connection.cpp).
rec <- new.env()
rec_reset <- function() {
  rec$n <- 0L
  rec$t <- numeric(4e6)
  rec$v <- numeric(4e6)
  rec$p <- integer(4e6)
  rec$phases <- character()
  rec$t0 <- now()
}
now <- function() as.numeric(Sys.time())
phase <- function(name) {
  rec$phases <- c(rec$phases, name)
  rec$cur <- length(rec$phases)
}
callback <- function(x) {
  n <- rec$n + 1L
  rec$n <- n
  rec$t[n] <- now() - rec$t0
  rec$v[n] <- x
  rec$p[n] <- rec$cur
}
options(duckdb.progress_display = callback)

all_calls <- list()
fmt <- function(x) formatC(x, format = "f", digits = 2)

# Prints one run: per phase, the number of calls, the span of the phase,
# and a trace of (seconds since the query started: percentage) sampled at
# most every `step` seconds, always with the first and the last call.
report <- function(
  scenario,
  api,
  threads,
  rows,
  wall,
  phase_spans,
  step = 0.25
) {
  n <- rec$n
  t <- rec$t[seq_len(n)]
  v <- rec$v[seq_len(n)]
  p <- rec$p[seq_len(n)]
  cat(sprintf(
    "\n## %s | %s | threads=%d | rows=%s | wall=%ss | calls=%d (of them =100: %d)\n",
    scenario,
    api,
    threads,
    format(rows, big.mark = ",", scientific = FALSE),
    fmt(wall),
    n,
    sum(v >= 100)
  ))
  silent <- 0L
  silent_time <- 0
  for (i in seq_along(rec$phases)) {
    span <- phase_spans[[i]]
    sel <- which(p == i)
    if (length(sel) == 0) {
      silent <- silent + 1L
      silent_time <- silent_time + (span[2] - span[1])
      if (
        !startsWith(rec$phases[i], "read ") &&
          !startsWith(rec$phases[i], "fetch ")
      ) {
        cat(sprintf(
          "  %-12s %s..%ss: no calls\n",
          rec$phases[i],
          fmt(span[1]),
          fmt(span[2])
        ))
      }
      next
    }
    keep <- sel[1]
    for (j in sel[-1]) {
      if (t[j] - t[keep[length(keep)]] >= step) keep <- c(keep, j)
    }
    if (keep[length(keep)] != sel[length(sel)]) {
      keep <- c(keep, sel[length(sel)])
    }
    gaps <- diff(c(span[1], t[sel], span[2]))
    cat(sprintf(
      "  %-12s %s..%ss: %d calls, longest silence %ss, trace %s\n",
      rec$phases[i],
      fmt(span[1]),
      fmt(span[2]),
      length(sel),
      fmt(max(gaps)),
      paste0(
        fmt(t[keep]),
        ":",
        formatC(v[keep], format = "f", digits = 1),
        collapse = " "
      )
    ))
  }
  if (silent > 0) {
    cat(sprintf(
      "  %d further reads with no calls, %ss in all\n",
      silent,
      fmt(silent_time)
    ))
  }
  # Run-length encode consecutive calls with the same phase and percentage.
  if (n > 0) {
    key <- paste(p, v)
    brk <- c(TRUE, key[-1] != key[-n])
    grp <- cumsum(brk)
    all_calls[[length(all_calls) + 1L]] <<- data.frame(
      scenario = scenario,
      api = api,
      threads = threads,
      phase = rec$phases[p[brk]],
      t_first = round(tapply(t, grp, min), 4),
      t_last = round(tapply(t, grp, max), 4),
      n = as.integer(tabulate(grp)),
      pct = v[brk]
    )
  }
}

# Runs `sql` through one API and reports it.
#   get:   dbGetQuery()
#   arrow: dbGetQueryArrow() then $get_next() until it returns NULL
#   send:  dbSendQuery() then dbFetch(n = ) until done
run <- function(con, scenario, api, sql, threads, chunk = 1e6) {
  dbExecute(con, sprintf("SET threads = %d", threads))
  invisible(gc())
  spans <- list()
  mark <- function(name) {
    if (length(spans)) {
      spans[[length(spans)]][2] <<- now() - rec$t0
    }
    phase(name)
    spans[[length(spans) + 1L]] <<- c(now() - rec$t0, NA)
  }
  rec_reset()
  rows <- 0
  if (api == "get") {
    mark("dbGetQuery")
    rows <- nrow(dbGetQuery(con, sql))
  } else if (api == "arrow") {
    mark("open")
    stream <- dbGetQueryArrow(con, sql, chunk_size = chunk)
    k <- 0L
    repeat {
      k <- k + 1L
      mark(paste("read", k))
      batch <- stream$get_next()
      if (is.null(batch)) {
        break
      }
      rows <- rows + batch$length
    }
    stream$release()
  } else if (api == "send") {
    mark("send")
    res <- dbSendQuery(con, sql)
    k <- 0L
    repeat {
      k <- k + 1L
      mark(paste("fetch", k))
      rows <- rows + nrow(dbFetch(res, n = chunk))
      if (dbHasCompleted(res)) break
    }
    dbClearResult(res)
  }
  mark("end")
  wall <- spans[[length(spans)]][1]
  rec$phases <- rec$phases[-length(rec$phases)]
  spans <- spans[-length(spans)]
  report(scenario, api, threads, rows, wall, spans)
}
```

``` r

con <- dbConnect(duckdb(shared_home = FALSE))
info <- dbGetQuery(
  con,
  "SELECT version() AS v, current_setting('max_streaming_buffer_size') AS buf"
)
cat("# Progress display callback trace\n\n")
#> # Progress display callback trace
cat("date:      ", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), "\n")
#> date:       2026-11-17 19:00 UTC
cat("duckdb:    ", format(packageVersion("duckdb")), "\n")
#> duckdb:     2.0.0.9000
cat("engine:    ", info$v, "\n")
#> engine:     v2.0.0
cat("R:         ", R.version.string, "\n")
#> R:          R version 4.5.3 (2026-03-11)
cat("nanoarrow: ", format(packageVersion("nanoarrow")), "\n")
#> nanoarrow:  0.9.0
cat(
  "OS:        ",
  paste(Sys.info()[c("sysname", "release", "machine")], collapse = " "),
  "\n"
)
#> OS:         Linux 6.18.44-fc-v553 x86_64
cpu <- grep("^model name", readLines("/proc/cpuinfo"), value = TRUE)
cat("CPU:       ", sub(".*: ", "", cpu[1]), "x", length(cpu), "\n")
#> CPU:        Intel(R) Xeon(R) Processor @ 2.10GHz x 4
cat("default max_streaming_buffer_size:", info$buf, "\n")
#> default max_streaming_buffer_size: 10.0 MiB
cat("times are seconds since the R call that issued the query\n")
#> times are seconds since the R call that issued the query

n_rows <- 10000000L
# One thread and a seed, so that random() gives the same tables every run.
invisible(dbExecute(con, "SET threads = 1"))
invisible(dbExecute(con, "SELECT setseed(0.42)"))
invisible(dbExecute(
  con,
  sprintf(
    "CREATE TABLE t AS SELECT i, hash(i) %% %d AS k, random() AS x FROM range(%d) r(i)",
    n_rows %/% 4L,
    n_rows
  )
))
invisible(dbExecute(
  con,
  sprintf(
    "CREATE TABLE u AS SELECT i AS k, random() AS y FROM range(%d) r(i)",
    n_rows %/% 4L
  )
))
cat(sprintf(
  "table t: %s rows (i, k, x); table u: %s rows (k, y)\n",
  format(n_rows, big.mark = ","),
  format(n_rows %/% 4L, big.mark = ",")
))
#> table t: 10,000,000 rows (i, k, x); table u: 2,500,000 rows (k, y)
```

``` r

local_queries <- c(
  scan_filter = "SELECT i, x FROM t WHERE hash(i::VARCHAR || 'salt') % 100 = 0",
  group_by = "SELECT k, sum(x) AS s, count(*) AS n FROM t GROUP BY k",
  order_by = "SELECT i, x FROM t WHERE i % 4 = 0 ORDER BY x",
  join = "SELECT t.k, x, y FROM t JOIN u ON t.k = u.k WHERE x < 0.01"
)

cat("\n# a. Large local queries\n")
#> 
#> # a. Large local queries
# The optimizer's row estimate for the filtered scan, which weighs its share.
cat(
  grep(
    "Filters|rows",
    dbGetQuery(con, paste("EXPLAIN", local_queries[["scan_filter"]]))[[2]],
    value = TRUE
  ),
  sep = "\n"
)
#> ╭─ Seq Scan ───────────────────────────────────────╮
#> │ Table: memory.main.t                             │
#> │ Type: Sequential Scan                            │
#> │ Projections: i, x                                │
#> │ Filters:                                         │
#> │ (hash((CAST(i AS VARCHAR) || 'salt')) % 100) = 0 │
#> │ ~2 rows                                          │
#> ╰──────────────────────────────────────────────────╯
for (name in names(local_queries)) {
  cat("\n", name, ": ", local_queries[[name]], "\n", sep = "")
  for (threads in c(1L, 4L)) {
    for (api in c("get", "arrow", "send")) {
      run(con, name, api, local_queries[[name]], threads)
    }
  }
}
#> 
#> scan_filter: SELECT i, x FROM t WHERE hash(i::VARCHAR || 'salt') % 100 = 0
#> 
#> ## scan_filter | get | threads=1 | rows=99,688 | wall=10.20s | calls=103 (of them =100: 2)
#>   dbGetQuery   0.00..10.19s: 103 calls, longest silence 0.16s, trace 0.00:100.0 0.34:1.4 0.69:3.4 1.00:5.5 1.30:7.5 1.60:9.6 1.92:11.6 2.24:13.7 2.52:15.8 2.83:17.8 3.11:19.9 3.43:21.9 3.74:24.0 3.99:25.4 4.35:27.4 4.69:29.5 5.03:31.5 5.31:33.6 5.64:35.6 5.89:37.0 6.20:39.0 6.50:41.1 6.80:43.2 7.10:45.2 7.36:47.3 7.62:49.3 7.87:51.4 8.14:53.4 8.42:55.5 8.71:57.5 9.02:59.6 9.27:61.6 9.60:64.4 9.87:66.4 10.12:100.0
#> 
#> ## scan_filter | arrow | threads=1 | rows=99,688 | wall=8.57s | calls=104 (of them =100: 2)
#>   open         0.00..0.13s: 1 calls, longest silence 0.12s, trace 0.01:100.0
#>   read 1       0.13..8.57s: 103 calls, longest silence 0.11s, trace 0.13:0.0 0.46:2.1 0.78:4.8 1.09:7.5 1.40:10.3 1.65:12.3 1.93:14.4 2.21:16.4 2.54:19.2 2.80:21.2 3.07:23.3 3.38:25.4 3.70:28.1 4.02:30.8 4.28:32.9 4.60:35.6 4.85:37.7 5.15:40.4 5.44:43.2 5.76:45.9 6.06:48.0 6.32:50.0 6.58:52.1 6.89:54.8 7.21:57.5 7.51:60.3 7.79:63.0 8.10:65.8 8.42:66.7 8.49:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | send | threads=1 | rows=99,688 | wall=10.19s | calls=103 (of them =100: 2)
#>   send         0.00..10.19s: 103 calls, longest silence 0.15s, trace 0.00:100.0 0.26:1.4 0.60:3.4 0.93:5.5 1.25:7.5 1.55:9.6 1.87:11.6 2.17:13.7 2.49:15.8 2.79:17.8 3.10:19.9 3.42:21.9 3.76:24.0 4.06:26.0 4.38:28.1 4.68:30.1 5.04:32.2 5.37:34.3 5.75:36.3 6.09:38.4 6.38:40.4 6.65:42.5 6.91:44.5 7.19:46.6 7.46:48.6 7.73:50.7 8.01:52.7 8.29:54.8 8.54:56.9 8.79:58.9 9.07:61.0 9.36:63.0 9.63:65.1 9.96:66.7 10.11:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | get | threads=4 | rows=99,688 | wall=0.95s | calls=14 (of them =100: 2)
#>   dbGetQuery   0.00..0.95s: 14 calls, longest silence 0.10s, trace 0.00:100.0 0.26:15.2 0.57:41.4 0.83:64.9 0.89:100.0
#> 
#> ## scan_filter | arrow | threads=4 | rows=99,688 | wall=0.99s | calls=11 (of them =100: 2)
#>   open         0.00..0.13s: 1 calls, longest silence 0.13s, trace 0.00:100.0
#>   read 1       0.13..0.99s: 10 calls, longest silence 0.10s, trace 0.13:0.5 0.40:23.7 0.65:46.6 0.90:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | send | threads=4 | rows=99,688 | wall=0.92s | calls=10 (of them =100: 2)
#>   send         0.00..0.92s: 10 calls, longest silence 0.11s, trace 0.00:100.0 0.31:17.7 0.58:46.0 0.85:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> group_by: SELECT k, sum(x) AS s, count(*) AS n FROM t GROUP BY k
#> 
#> ## group_by | get | threads=1 | rows=2,454,520 | wall=11.25s | calls=130 (of them =100: 2)
#>   dbGetQuery   0.00..11.25s: 130 calls, longest silence 0.17s, trace 0.00:100.0 0.33:1.5 0.60:3.8 0.85:6.1 1.11:8.4 1.37:10.6 1.63:12.9 1.93:15.2 2.20:17.5 2.49:19.7 2.78:22.0 3.10:24.3 3.43:26.6 3.70:28.9 3.99:31.1 4.29:33.4 4.54:35.7 4.88:38.7 5.15:41.0 5.41:43.3 5.69:45.5 5.97:47.8 6.31:50.1 6.56:52.4 6.82:54.6 7.08:56.9 7.41:60.0 7.69:62.2 7.98:64.5 8.28:66.8 8.57:69.8 8.85:72.9 9.11:91.3 9.38:92.8 9.64:94.3 9.94:95.7 10.25:97.2 10.55:98.7 10.85:100.0 11.08:100.0
#> 
#> ## group_by | arrow | threads=1 | rows=2,454,520 | wall=6.77s | calls=140 (of them =100: 2)
#>   open         0.00..0.04s: 1 calls, longest silence 0.04s, trace 0.00:100.0
#>   read 1       0.04..5.94s: 120 calls, longest silence 0.13s, trace 0.04:0.0 0.32:2.3 0.65:6.8 0.92:11.4 1.25:15.9 1.54:20.5 1.80:25.1 2.14:29.6 2.42:34.9 2.67:38.7 3.00:43.3 3.32:47.8 3.61:52.4 3.92:56.9 4.23:61.5 4.56:66.0 4.85:70.6 5.15:73.9 5.43:93.2 5.69:94.8 5.91:96.0
#>   read 2       5.94..6.60s: 15 calls, longest silence 0.10s, trace 5.95:96.3 6.22:97.9 6.49:99.4 6.58:99.8
#>   read 3       6.60..6.77s: 4 calls, longest silence 0.10s, trace 6.60:100.0 6.75:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## group_by | send | threads=1 | rows=2,454,520 | wall=6.64s | calls=130 (of them =100: 2)
#>   send         0.00..6.45s: 130 calls, longest silence 0.14s, trace 0.00:100.0 0.30:3.0 0.60:7.6 0.91:12.1 1.18:15.2 1.46:19.7 1.76:24.3 2.04:28.9 2.34:33.4 2.63:38.0 2.92:42.5 3.23:47.1 3.51:51.6 3.82:56.2 4.14:60.7 4.44:65.3 4.77:69.8 5.09:73.9 5.36:92.8 5.66:95.0 5.94:97.6 6.20:99.8 6.33:100.0
#>   3 further reads with no calls, 0.19s in all
#> 
#> ## group_by | get | threads=4 | rows=2,454,520 | wall=0.84s | calls=25 (of them =100: 2)
#>   dbGetQuery   0.00..0.84s: 25 calls, longest silence 0.12s, trace 0.00:100.0 0.28:73.9 0.54:88.3 0.78:100.0
#> 
#> ## group_by | arrow | threads=4 | rows=2,454,520 | wall=1.43s | calls=39 (of them =100: 2)
#>   open         0.00..0.05s: 1 calls, longest silence 0.05s, trace 0.00:100.0
#>   read 1       0.05..0.78s: 21 calls, longest silence 0.13s, trace 0.05:0.0 0.33:79.6 0.65:84.3 0.77:87.9
#>   read 2       0.78..1.39s: 15 calls, longest silence 0.12s, trace 0.80:88.9 1.06:93.6 1.37:99.3 1.38:99.6
#>   read 3       1.39..1.43s: 2 calls, longest silence 0.02s, trace 1.40:100.0 1.41:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## group_by | send | threads=4 | rows=2,454,520 | wall=0.87s | calls=24 (of them =100: 2)
#>   send         0.00..0.77s: 24 calls, longest silence 0.12s, trace 0.00:100.0 0.26:74.7 0.52:92.9 0.71:100.0
#>   3 further reads with no calls, 0.09s in all
#> 
#> order_by: SELECT i, x FROM t WHERE i % 4 = 0 ORDER BY x
#> 
#> ## order_by | get | threads=1 | rows=2,500,000 | wall=4.43s | calls=130 (of them =100: 2)
#>   dbGetQuery   0.00..4.43s: 130 calls, longest silence 0.28s, trace 0.00:100.0 0.27:1.0 0.53:2.7 0.83:3.7 1.08:5.3 1.34:7.4 1.62:9.0 1.87:11.1 2.17:12.9 2.44:14.8 2.71:16.2 2.96:18.5 3.43:40.0 3.68:53.4 4.01:66.7 4.27:80.0 4.31:100.0
#> 
#> ## order_by | arrow | threads=1 | rows=2,500,000 | wall=4.29s | calls=136 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.02s, trace 0.00:100.0
#>   read 1       0.02..3.85s: 122 calls, longest silence 0.21s, trace 0.02:0.0 0.34:1.9 0.59:3.9 0.86:5.6 1.12:7.8 1.39:9.5 1.71:11.7 1.96:14.0 2.22:15.6 2.48:17.7 2.77:19.3 3.02:40.0 3.36:50.0 3.62:57.4 3.84:66.3
#>   read 2       3.85..4.29s: 13 calls, longest silence 0.10s, trace 3.86:68.0 4.11:78.5 4.27:100.0
#>   2 further reads with no calls, 0.00s in all
#> 
#> ## order_by | send | threads=1 | rows=2,500,000 | wall=4.06s | calls=130 (of them =100: 2)
#>   send         0.00..3.99s: 130 calls, longest silence 0.26s, trace 0.00:100.0 0.31:2.1 0.65:4.5 0.91:6.6 1.21:8.2 1.46:10.7 1.72:12.1 2.04:14.2 2.30:16.2 2.55:17.9 2.81:19.1 3.16:40.0 3.45:50.0 3.74:70.1 3.97:100.0
#>   3 further reads with no calls, 0.07s in all
#> 
#> ## order_by | get | threads=4 | rows=2,500,000 | wall=0.37s | calls=11 (of them =100: 2)
#>   dbGetQuery   0.00..0.37s: 11 calls, longest silence 0.08s, trace 0.00:100.0 0.27:61.6 0.34:100.0
#> 
#> ## order_by | arrow | threads=4 | rows=2,500,000 | wall=1.10s | calls=30 (of them =100: 2)
#>   open         0.00..0.04s: 1 calls, longest silence 0.04s, trace 0.00:100.0
#>   read 1       0.04..0.70s: 18 calls, longest silence 0.12s, trace 0.04:0.0 0.31:53.8 0.64:64.4 0.69:66.3
#>   read 2       0.70..1.09s: 11 calls, longest silence 0.10s, trace 0.71:68.0 0.97:76.9 1.08:100.0
#>   2 further reads with no calls, 0.00s in all
#> 
#> ## order_by | send | threads=4 | rows=2,500,000 | wall=0.46s | calls=13 (of them =100: 2)
#>   send         0.00..0.39s: 13 calls, longest silence 0.10s, trace 0.00:100.0 0.27:70.3 0.37:100.0
#>   3 further reads with no calls, 0.07s in all
#> 
#> join: SELECT t.k, x, y FROM t JOIN u ON t.k = u.k WHERE x < 0.01
#> 
#> ## join | get | threads=1 | rows=99,800 | wall=4.64s | calls=155 (of them =100: 2)
#>   dbGetQuery   0.00..4.64s: 155 calls, longest silence 0.12s, trace 0.00:100.0 0.27:2.8 0.52:5.7 0.78:8.1 1.09:12.0 1.34:14.9 1.63:18.4 1.89:22.3 2.14:24.8 2.40:28.6 2.67:31.5 2.94:34.4 3.25:40.8 3.50:48.9 3.77:55.1 4.04:63.3 4.30:70.5 4.59:100.0 4.63:100.0
#> 
#> ## join | arrow | threads=1 | rows=99,800 | wall=4.34s | calls=156 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.02s, trace 0.00:100.0
#>   read 1       0.02..4.34s: 155 calls, longest silence 0.11s, trace 0.02:0.0 0.27:2.8 0.53:5.7 0.87:9.6 1.20:13.8 1.47:17.7 1.75:20.9 2.04:24.4 2.39:28.6 2.64:32.5 2.90:35.3 3.23:44.4 3.48:55.1 3.77:61.5 4.09:72.3 4.32:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | send | threads=1 | rows=99,800 | wall=4.49s | calls=155 (of them =100: 2)
#>   send         0.00..4.49s: 155 calls, longest silence 0.11s, trace 0.00:100.0 0.25:2.5 0.57:5.7 0.82:9.6 1.07:13.1 1.33:16.3 1.64:20.9 1.91:24.0 2.24:27.2 2.50:30.4 2.76:33.9 3.01:39.8 3.32:46.2 3.60:55.1 3.90:62.4 4.15:71.4 4.45:100.0 4.48:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | get | threads=4 | rows=99,800 | wall=0.21s | calls=7 (of them =100: 2)
#>   dbGetQuery   0.00..0.21s: 7 calls, longest silence 0.08s, trace 0.00:100.0 0.20:100.0
#> 
#> ## join | arrow | threads=4 | rows=99,800 | wall=0.16s | calls=6 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.02s, trace 0.00:100.0
#>   read 1       0.02..0.16s: 5 calls, longest silence 0.08s, trace 0.02:0.0 0.14:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | send | threads=4 | rows=99,800 | wall=0.23s | calls=6 (of them =100: 2)
#>   send         0.00..0.23s: 6 calls, longest silence 0.09s, trace 0.00:100.0 0.14:100.0
#>   1 further reads with no calls, 0.00s in all
```

``` r

dir <- tempfile("serve")
dir.create(dir)
parquet <- file.path(dir, "remote.parquet")
invisible(dbExecute(
  con,
  sprintf(
    "COPY (SELECT i, hash(i) %% 5000000 AS k, random() AS z FROM range(4000000) r(i))
   TO '%s' (FORMAT parquet, ROW_GROUP_SIZE 100000)",
    parquet
  )
))
rate <- 2000000L
port <- 8919L
system2(
  "python3",
  c(
    "-I",
    shQuote(file.path(here, "throttle_server.py")),
    shQuote(dir),
    port,
    rate
  ),
  wait = FALSE
)
Sys.sleep(1)
url <- sprintf("http://127.0.0.1:%d/remote.parquet", port)
invisible(dbExecute(con, "INSTALL httpfs"))
invisible(dbExecute(con, "LOAD httpfs"))
print(dbGetQuery(
  con,
  "SELECT extension_name, extension_version, install_mode
   FROM duckdb_extensions() WHERE extension_name = 'httpfs'"
))
#>   extension_name extension_version install_mode
#> 1         httpfs        77392a7207   REPOSITORY
# Every query fetches the file again rather than from the engine's cache.
invisible(dbExecute(con, "SET enable_external_file_cache = false"))
cat(sprintf(
  "\n# b. Remote and local\n\nremote file: %s, %s bytes, 4,000,000 rows in row groups of 100,000, served at %s bytes/s\n",
  url,
  format(file.size(parquet), big.mark = ","),
  format(rate, big.mark = ",")
))
#> 
#> # b. Remote and local
#> 
#> remote file: http://127.0.0.1:8919/remote.parquet, 68,234,357 bytes, 4,000,000 rows in row groups of 100,000, served at 2,000,000 bytes/s

remote_queries <- c(
  # The remote scan alone.
  remote_only = "SELECT count(*) AS n, sum(z) AS s FROM read_parquet('%s')",
  # The remote scan feeds a heavy expression in the same pipeline.
  remote_heavy_expr = "SELECT count(*) AS n FROM read_parquet('%s') WHERE hash(repeat(i::VARCHAR, 40)) %% 7 = 0",
  # The remote columns the join below reads, alone, to time the remote part.
  remote_join_columns = "SELECT count(*) AS n, sum(k) AS sk, sum(z) AS s FROM read_parquet('%s')",
  # The remote file is the join's build side, the local table its probe side:
  # two pipelines, the remote one first.
  remote_build_local_probe = "SELECT count(*) AS n, sum(x * z) AS s FROM t JOIN read_parquet('%s') r ON t.k = r.k",
  # The remote scan feeds an aggregate, then a large local sort of the groups.
  remote_then_sort = "SELECT k, sum(z) AS s FROM read_parquet('%s') GROUP BY k ORDER BY s"
)
for (name in names(remote_queries)) {
  sql <- sprintf(remote_queries[[name]], url)
  cat("\n", name, ": ", sql, "\n", sep = "")
  for (threads in c(1L, 4L)) {
    for (api in c("get", "arrow")) {
      run(con, name, api, sql, threads)
    }
  }
}
#> 
#> remote_only: SELECT count(*) AS n, sum(z) AS s FROM read_parquet('http://127.0.0.1:8919/remote.parquet')
#> 
#> ## remote_only | get | threads=1 | rows=1 | wall=5.04s | calls=117 (of them =100: 2)
#>   dbGetQuery   0.00..5.04s: 117 calls, longest silence 0.13s, trace 0.06:100.0 0.33:0.0 0.59:0.0 0.88:10.0 1.14:15.1 1.40:20.1 1.67:25.1 1.94:32.6 2.20:40.1 2.56:45.2 2.87:52.7 3.13:60.2 3.39:65.2 3.65:70.2 3.91:77.8 4.16:82.8 4.42:87.8 4.67:95.3 4.95:100.0 5.02:100.0
#> 
#> ## remote_only | arrow | threads=1 | rows=1 | wall=5.15s | calls=122 (of them =100: 2)
#>   open         0.00..0.16s: 1 calls, longest silence 0.10s, trace 0.06:100.0
#>   read 1       0.16..5.15s: 121 calls, longest silence 0.14s, trace 0.16:0.0 0.42:0.0 0.70:2.6 0.96:10.0 1.26:17.7 1.53:20.1 1.82:30.1 2.17:37.7 2.47:45.2 2.74:50.2 3.00:55.2 3.26:62.7 3.53:67.7 3.79:72.8 4.04:82.8 4.39:85.4 4.66:92.8 4.94:100.0 5.14:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_only | get | threads=4 | rows=1 | wall=3.09s | calls=60 (of them =100: 2)
#>   dbGetQuery   0.00..3.09s: 60 calls, longest silence 0.16s, trace 0.06:100.0 0.40:0.0 0.66:10.1 0.92:12.5 1.20:12.5 1.48:12.5 1.84:52.7 2.14:80.3 2.48:92.5 2.85:92.5 3.07:100.0
#> 
#> ## remote_only | arrow | threads=4 | rows=1 | wall=2.27s | calls=42 (of them =100: 2)
#>   open         0.00..0.12s: 1 calls, longest silence 0.07s, trace 0.06:100.0
#>   read 1       0.12..2.27s: 41 calls, longest silence 0.14s, trace 0.12:0.0 0.39:0.0 0.66:20.1 0.96:20.1 1.22:20.1 1.51:20.1 1.76:60.2 2.03:95.3 2.16:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_heavy_expr: SELECT count(*) AS n FROM read_parquet('http://127.0.0.1:8919/remote.parquet') WHERE hash(repeat(i::VARCHAR, 40)) % 7 = 0
#> 
#> ## remote_heavy_expr | get | threads=1 | rows=1 | wall=3.47s | calls=66 (of them =100: 2)
#>   dbGetQuery   0.00..3.47s: 66 calls, longest silence 0.16s, trace 0.06:100.0 0.33:0.0 0.65:3.4 0.93:6.7 1.27:10.1 1.52:13.4 1.77:15.9 2.06:19.3 2.32:21.8 2.60:26.0 2.91:29.3 3.23:32.6 3.45:100.0
#> 
#> ## remote_heavy_expr | arrow | threads=1 | rows=1 | wall=3.44s | calls=69 (of them =100: 2)
#>   open         0.00..0.13s: 1 calls, longest silence 0.07s, trace 0.06:100.0
#>   read 1       0.13..3.44s: 68 calls, longest silence 0.14s, trace 0.13:0.0 0.39:0.0 0.68:5.0 0.95:7.6 1.21:10.1 1.47:13.4 1.78:16.7 2.15:20.9 2.51:25.1 2.82:28.5 3.12:31.8 3.39:66.7 3.43:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_heavy_expr | get | threads=4 | rows=1 | wall=1.92s | calls=34 (of them =100: 2)
#>   dbGetQuery   0.00..1.92s: 34 calls, longest silence 0.15s, trace 0.06:100.0 0.39:5.9 0.74:5.9 0.99:5.9 1.32:5.9 1.59:19.2 1.91:100.0
#> 
#> ## remote_heavy_expr | arrow | threads=4 | rows=1 | wall=1.90s | calls=36 (of them =100: 2)
#>   open         0.00..0.15s: 1 calls, longest silence 0.09s, trace 0.06:100.0
#>   read 1       0.15..1.90s: 35 calls, longest silence 0.16s, trace 0.15:0.0 0.42:5.4 0.70:5.9 1.05:5.9 1.40:9.6 1.68:27.0 1.88:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_join_columns: SELECT count(*) AS n, sum(k) AS sk, sum(z) AS s FROM read_parquet('http://127.0.0.1:8919/remote.parquet')
#> 
#> ## remote_join_columns | get | threads=1 | rows=1 | wall=7.38s | calls=150 (of them =100: 2)
#>   dbGetQuery   0.00..7.38s: 150 calls, longest silence 0.17s, trace 0.06:100.0 0.38:0.0 0.77:0.0 1.02:10.0 1.36:10.0 1.68:20.1 1.94:20.1 2.26:22.6 2.53:30.1 2.90:30.1 3.16:40.1 3.51:40.1 3.77:50.2 4.06:50.2 4.35:55.2 4.69:60.2 5.02:62.8 5.30:70.2 5.63:70.2 5.92:80.3 6.17:80.3 6.46:85.4 6.71:90.3 6.97:90.3 7.29:100.0 7.37:100.0
#> 
#> ## remote_join_columns | arrow | threads=1 | rows=1 | wall=7.46s | calls=156 (of them =100: 2)
#>   open         0.00..0.16s: 1 calls, longest silence 0.10s, trace 0.06:100.0
#>   read 1       0.16..7.46s: 155 calls, longest silence 0.18s, trace 0.16:0.0 0.43:0.0 0.72:0.0 0.97:2.6 1.24:10.0 1.50:10.0 1.79:20.1 2.17:20.1 2.45:27.6 2.70:30.1 3.03:32.7 3.29:40.1 3.62:40.1 3.92:50.2 4.19:50.2 4.50:57.8 4.77:60.2 5.06:62.7 5.36:70.2 5.72:70.2 5.97:80.3 6.29:80.3 6.56:87.8 6.83:90.3 7.16:92.9 7.42:100.0 7.44:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_join_columns | get | threads=4 | rows=1 | wall=3.10s | calls=53 (of them =100: 2)
#>   dbGetQuery   0.00..3.10s: 53 calls, longest silence 0.19s, trace 0.06:100.0 0.36:0.0 0.65:0.0 0.91:17.6 1.21:17.6 1.56:17.6 1.89:55.2 2.18:57.7 2.57:95.3 2.82:97.8 3.08:100.0
#> 
#> ## remote_join_columns | arrow | threads=4 | rows=1 | wall=3.13s | calls=57 (of them =100: 2)
#>   open         0.00..0.13s: 1 calls, longest silence 0.07s, trace 0.06:100.0
#>   read 1       0.13..3.13s: 56 calls, longest silence 0.15s, trace 0.13:0.0 0.41:0.0 0.71:0.0 0.97:15.1 1.23:15.1 1.49:15.1 1.82:47.7 2.11:55.2 2.37:55.2 2.63:90.3 2.91:95.3 3.12:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_build_local_probe: SELECT count(*) AS n, sum(x * z) AS s FROM t JOIN read_parquet('http://127.0.0.1:8919/remote.parquet') r ON t.k = r.k
#> 
#> ## remote_build_local_probe | get | threads=1 | rows=1 | wall=15.92s | calls=393 (of them =100: 2)
#>   dbGetQuery   0.00..15.92s: 393 calls, longest silence 0.17s, trace 0.06:100.0 0.37:0.0 0.72:0.0 0.97:1.6 1.25:1.6 1.56:1.6 1.81:3.3 2.08:3.3 2.34:4.1 2.61:4.9 2.88:4.9 3.14:6.6 3.42:6.6 3.72:7.0 3.98:8.2 4.28:8.2 4.53:9.8 4.81:9.8 5.10:10.7 5.36:11.5 5.68:11.9 5.99:13.1 6.28:13.1 6.59:14.3 6.84:14.8 7.10:15.2 7.35:16.3 7.65:16.6 7.91:17.6 8.16:18.9 8.46:20.0 8.72:21.1 8.99:22.1 9.25:23.3 9.50:24.4 9.79:25.4 10.04:26.5 10.42:27.6 10.69:29.1 11.03:30.2 11.29:31.5 11.55:32.8 11.83:34.3 12.09:35.9 12.37:37.9 12.69:39.7 12.95:41.4 13.26:43.3 13.52:45.5 13.78:46.9 14.12:48.2 14.39:49.9 14.65:51.4 14.92:53.3 15.30:54.8 15.56:56.5 15.89:100.0 15.90:100.0
#> 
#> ## remote_build_local_probe | arrow | threads=1 | rows=1 | wall=16.08s | calls=399 (of them =100: 2)
#>   open         0.00..0.12s: 1 calls, longest silence 0.07s, trace 0.06:100.0
#>   read 1       0.12..16.08s: 398 calls, longest silence 0.15s, trace 0.12:0.0 0.39:0.0 0.64:0.0 0.90:0.0 1.17:1.6 1.43:1.6 1.70:2.9 1.96:3.3 2.23:3.3 2.48:4.9 2.74:4.9 3.00:4.9 3.27:6.6 3.53:6.6 3.83:7.4 4.10:8.2 4.38:8.6 4.66:9.8 4.92:9.8 5.18:10.7 5.49:11.5 5.80:11.9 6.07:13.1 6.33:13.1 6.62:14.4 6.92:14.8 7.18:15.6 7.49:16.3 7.84:17.3 8.11:18.3 8.36:19.3 8.62:20.6 8.95:21.9 9.20:23.3 9.52:24.3 9.78:25.8 10.07:26.8 10.35:27.8 10.61:28.8 10.87:29.6 11.14:30.5 11.40:31.7 11.69:32.8 11.98:34.9 12.33:36.6 12.59:38.5 12.86:40.2 13.18:41.9 13.46:43.6 13.73:45.0 13.99:46.5 14.33:48.2 14.60:50.3 14.89:52.0 15.14:53.5 15.41:55.2 15.66:56.9 16.02:100.0 16.03:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_build_local_probe | get | threads=4 | rows=1 | wall=3.10s | calls=57 (of them =100: 2)
#>   dbGetQuery   0.00..3.10s: 57 calls, longest silence 0.17s, trace 0.06:100.0 0.34:0.0 0.68:0.0 1.01:3.3 1.26:3.3 1.67:3.3 1.96:9.4 2.25:9.8 2.62:16.0 2.92:54.0 2.97:100.0
#> 
#> ## remote_build_local_probe | arrow | threads=4 | rows=1 | wall=3.58s | calls=69 (of them =100: 2)
#>   open         0.00..0.13s: 1 calls, longest silence 0.07s, trace 0.06:100.0
#>   read 1       0.13..3.58s: 68 calls, longest silence 0.16s, trace 0.13:0.0 0.41:0.0 0.79:1.6 1.09:2.5 1.46:2.5 1.82:2.5 2.07:9.0 2.32:9.0 2.64:10.7 2.89:15.6 3.25:26.7 3.52:57.1 3.56:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_then_sort: SELECT k, sum(z) AS s FROM read_parquet('http://127.0.0.1:8919/remote.parquet') GROUP BY k ORDER BY s
#> 
#> ## remote_then_sort | get | threads=1 | rows=2,754,617 | wall=9.89s | calls=206 (of them =100: 2)
#>   dbGetQuery   0.00..9.89s: 206 calls, longest silence 0.36s, trace 0.06:100.0 0.35:0.0 0.67:0.0 0.92:3.4 1.18:4.4 1.47:4.4 1.74:8.9 2.07:8.9 2.34:12.2 2.67:13.3 3.02:15.5 3.31:17.7 3.67:18.8 3.92:22.2 4.27:22.2 4.54:26.6 4.84:26.6 5.11:28.9 5.36:31.0 5.65:31.0 5.94:35.5 6.21:35.5 6.46:36.6 6.79:39.9 7.04:39.9 7.40:44.2 7.65:54.5 7.91:55.9 8.17:57.4 8.74:72.1 8.99:77.4 9.29:85.8 9.56:94.3 9.79:100.0
#> 
#> ## remote_then_sort | arrow | threads=1 | rows=2,754,617 | wall=9.82s | calls=209 (of them =100: 2)
#>   open         0.00..0.13s: 1 calls, longest silence 0.07s, trace 0.06:100.0
#>   read 1       0.13..9.30s: 191 calls, longest silence 0.27s, trace 0.13:0.0 0.46:0.0 0.80:0.0 1.10:4.4 1.40:4.4 1.67:7.8 2.01:8.9 2.33:12.2 2.65:13.3 2.98:15.5 3.25:17.7 3.63:18.8 3.97:22.2 4.29:23.3 4.59:26.6 4.93:26.6 5.18:31.0 5.51:31.0 5.77:33.3 6.04:35.5 6.38:36.6 6.67:39.9 7.03:39.9 7.33:44.2 7.58:54.7 7.84:55.9 8.09:57.4 8.56:72.1 8.88:78.4 9.14:85.4 9.29:88.8
#>   read 2       9.30..9.66s: 12 calls, longest silence 0.09s, trace 9.31:89.8 9.57:98.6 9.65:98.8
#>   read 3       9.66..9.82s: 5 calls, longest silence 0.08s, trace 9.67:99.8 9.73:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_then_sort | get | threads=4 | rows=2,754,617 | wall=3.07s | calls=60 (of them =100: 2)
#>   dbGetQuery   0.00..3.07s: 60 calls, longest silence 0.16s, trace 0.06:100.0 0.38:0.0 0.65:0.0 0.93:8.9 1.23:8.9 1.49:8.9 1.75:8.9 2.02:25.5 2.32:26.6 2.67:54.4 2.92:94.5 2.95:100.0
#> 
#> ## remote_then_sort | arrow | threads=4 | rows=2,754,617 | wall=4.41s | calls=89 (of them =100: 2)
#>   open         0.00..0.13s: 1 calls, longest silence 0.08s, trace 0.06:100.0
#>   read 1       0.13..3.85s: 73 calls, longest silence 0.14s, trace 0.13:0.0 0.41:0.0 0.77:0.0 1.04:6.6 1.40:6.6 1.72:6.6 2.09:24.4 2.44:24.4 2.70:41.0 3.03:42.1 3.35:73.3 3.62:83.1 3.83:88.8
#>   read 2       3.85..4.26s: 12 calls, longest silence 0.10s, trace 3.86:89.8 4.11:96.5 4.25:98.8
#>   read 3       4.26..4.41s: 3 calls, longest silence 0.09s, trace 4.27:99.8 4.32:100.0
#>   1 further reads with no calls, 0.00s in all
```

``` r

cat(
  "\n# c. max_streaming_buffer_size, a stream of a cheap 5,000,000-row scan read in chunks of 100,000 rows\n"
)
#> 
#> # c. max_streaming_buffer_size, a stream of a cheap 5,000,000-row scan read in chunks of 100,000 rows
for (buf in c("976KiB", "10MiB", "1GiB")) {
  invisible(dbExecute(
    con,
    sprintf("SET max_streaming_buffer_size = '%s'", buf)
  ))
  cat("\nmax_streaming_buffer_size =", buf, "\n")
  run(
    con,
    paste0("buffer_", buf),
    "arrow",
    "SELECT i, x FROM t WHERE i % 2 = 0",
    4L,
    chunk = 1e5
  )
}
#> 
#> max_streaming_buffer_size = 976KiB 
#> 
#> ## buffer_976KiB | arrow | threads=4 | rows=5,000,000 | wall=5.01s | calls=159 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.01s, trace 0.00:100.0
#>   read 1       0.02..0.07s: 4 calls, longest silence 0.01s, trace 0.02:0.0 0.06:2.1
#>   read 2       0.07..0.19s: 3 calls, longest silence 0.08s, trace 0.07:2.5 0.17:3.4
#>   read 3       0.19..0.32s: 3 calls, longest silence 0.10s, trace 0.20:3.8 0.30:4.7
#>   read 4       0.32..0.37s: 3 calls, longest silence 0.02s, trace 0.32:5.1 0.36:5.9
#>   read 5       0.37..0.50s: 3 calls, longest silence 0.09s, trace 0.38:6.3 0.49:7.2
#>   read 6       0.50..0.55s: 3 calls, longest silence 0.02s, trace 0.50:7.6 0.53:8.5
#>   read 7       0.55..0.69s: 4 calls, longest silence 0.09s, trace 0.55:8.9 0.67:10.2
#>   read 8       0.69..0.83s: 3 calls, longest silence 0.08s, trace 0.69:10.6 0.74:11.4
#>   read 9       0.83..0.87s: 3 calls, longest silence 0.01s, trace 0.83:11.9 0.85:12.7
#>   read 10      0.87..0.98s: 3 calls, longest silence 0.08s, trace 0.87:13.1 0.90:14.0
#>   read 11      0.98..1.02s: 3 calls, longest silence 0.01s, trace 0.98:14.4 1.01:15.2
#>   read 12      1.02..1.13s: 3 calls, longest silence 0.08s, trace 1.02:15.7 1.05:16.5
#>   read 13      1.13..1.17s: 3 calls, longest silence 0.01s, trace 1.13:16.9 1.15:17.8
#>   read 14      1.17..1.30s: 4 calls, longest silence 0.09s, trace 1.17:17.8 1.29:19.5
#>   read 15      1.30..1.36s: 3 calls, longest silence 0.02s, trace 1.30:19.9 1.34:20.7
#>   read 16      1.36..1.48s: 3 calls, longest silence 0.09s, trace 1.36:21.2 1.46:22.0
#>   read 17      1.48..1.52s: 3 calls, longest silence 0.02s, trace 1.48:22.4 1.51:23.3
#>   read 18      1.52..1.64s: 3 calls, longest silence 0.09s, trace 1.52:23.7 1.55:24.5
#>   read 19      1.64..1.73s: 3 calls, longest silence 0.03s, trace 1.64:25.0 1.70:25.8
#>   read 20      1.73..1.90s: 4 calls, longest silence 0.12s, trace 1.73:26.2 1.88:27.5
#>   read 21      1.90..1.94s: 3 calls, longest silence 0.02s, trace 1.90:27.9 1.93:28.8
#>   read 22      1.94..2.09s: 3 calls, longest silence 0.11s, trace 1.95:29.2 1.98:30.1
#>   read 23      2.09..2.17s: 3 calls, longest silence 0.04s, trace 2.09:30.5 2.16:31.3
#>   read 24      2.17..2.32s: 3 calls, longest silence 0.10s, trace 2.17:31.7 2.22:32.6
#>   read 25      2.32..2.36s: 3 calls, longest silence 0.01s, trace 2.32:33.0 2.34:33.9
#>   read 26      2.36..2.49s: 3 calls, longest silence 0.08s, trace 2.36:34.3 2.45:35.1
#>   read 27      2.49..2.58s: 4 calls, longest silence 0.03s, trace 2.49:35.6 2.56:36.8
#>   read 28      2.58..2.70s: 3 calls, longest silence 0.09s, trace 2.58:37.2 2.69:38.1
#>   read 29      2.70..2.75s: 3 calls, longest silence 0.02s, trace 2.70:38.5 2.73:39.4
#>   read 30      2.75..2.89s: 3 calls, longest silence 0.09s, trace 2.75:39.8 2.85:40.6
#>   read 31      2.89..2.95s: 3 calls, longest silence 0.03s, trace 2.89:41.1 2.93:41.9
#>   read 32      2.95..3.09s: 3 calls, longest silence 0.11s, trace 2.95:42.3 3.07:43.2
#>   read 33      3.09..3.14s: 3 calls, longest silence 0.02s, trace 3.09:43.6 3.12:44.4
#>   read 34      3.14..3.34s: 4 calls, longest silence 0.12s, trace 3.14:44.9 3.32:46.1
#>   read 35      3.34..3.39s: 3 calls, longest silence 0.02s, trace 3.34:46.6 3.38:47.4
#>   read 36      3.39..3.54s: 3 calls, longest silence 0.11s, trace 3.39:47.8 3.52:48.7
#>   read 37      3.54..3.68s: 3 calls, longest silence 0.09s, trace 3.54:49.1 3.58:49.9
#>   read 38      3.68..3.75s: 3 calls, longest silence 0.03s, trace 3.68:50.4 3.73:51.2
#>   read 39      3.75..3.92s: 3 calls, longest silence 0.10s, trace 3.75:51.6 3.82:52.5
#>   read 40      3.92..4.01s: 4 calls, longest silence 0.03s, trace 3.92:52.9 3.98:54.2
#>   read 41      4.01..4.13s: 3 calls, longest silence 0.09s, trace 4.01:54.6 4.12:55.4
#>   read 42      4.13..4.18s: 3 calls, longest silence 0.02s, trace 4.13:55.9 4.16:56.7
#>   read 43      4.18..4.30s: 3 calls, longest silence 0.09s, trace 4.18:57.1 4.28:58.0
#>   read 44      4.30..4.38s: 3 calls, longest silence 0.04s, trace 4.30:58.4 4.35:59.3
#>   read 45      4.38..4.50s: 3 calls, longest silence 0.09s, trace 4.38:59.7 4.49:60.5
#>   read 46      4.50..4.55s: 3 calls, longest silence 0.02s, trace 4.50:60.9 4.53:61.8
#>   read 47      4.55..4.74s: 4 calls, longest silence 0.11s, trace 4.55:62.2 4.69:63.1
#>   read 48      4.74..4.80s: 3 calls, longest silence 0.03s, trace 4.74:63.9 4.79:64.8
#>   read 49      4.80..4.96s: 3 calls, longest silence 0.12s, trace 4.81:65.2 4.95:66.0
#>   read 50      4.96..5.01s: 3 calls, longest silence 0.02s, trace 4.96:66.5 5.00:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> max_streaming_buffer_size = 10MiB 
#> 
#> ## buffer_10MiB | arrow | threads=4 | rows=5,000,000 | wall=3.38s | calls=90 (of them =100: 2)
#>   open         0.00..0.04s: 1 calls, longest silence 0.03s, trace 0.00:100.0
#>   read 1       0.04..0.07s: 1 calls, longest silence 0.03s, trace 0.04:0.0
#>   read 4       0.07..0.30s: 7 calls, longest silence 0.09s, trace 0.07:9.4 0.29:13.1
#>   read 7       0.31..0.51s: 7 calls, longest silence 0.10s, trace 0.31:13.8 0.49:17.5
#>   read 10      0.51..0.76s: 7 calls, longest silence 0.11s, trace 0.51:18.2 0.74:21.9
#>   read 14      0.76..1.05s: 7 calls, longest silence 0.12s, trace 0.76:22.6 0.93:26.3
#>   read 17      1.05..1.31s: 7 calls, longest silence 0.11s, trace 1.05:27.0 1.29:30.7
#>   read 20      1.32..1.54s: 7 calls, longest silence 0.10s, trace 1.32:31.3 1.51:35.0
#>   read 24      1.54..1.57s: 1 calls, longest silence 0.03s, trace 1.54:35.0
#>   read 27      1.57..1.89s: 7 calls, longest silence 0.12s, trace 1.57:40.1 1.87:43.8
#>   read 30      1.90..2.23s: 7 calls, longest silence 0.11s, trace 1.90:44.5 2.11:48.2
#>   read 33      2.23..2.46s: 7 calls, longest silence 0.12s, trace 2.23:48.9 2.44:52.6
#>   read 37      2.46..2.69s: 7 calls, longest silence 0.11s, trace 2.47:53.2 2.68:57.0
#>   read 40      2.70..2.91s: 7 calls, longest silence 0.11s, trace 2.70:57.6 2.90:61.3
#>   read 43      2.92..3.18s: 7 calls, longest silence 0.12s, trace 2.92:62.0 3.16:65.7
#>   read 47      3.19..3.37s: 3 calls, longest silence 0.12s, trace 3.19:66.4 3.35:100.0
#>   36 further reads with no calls, 0.04s in all
#> 
#> max_streaming_buffer_size = 1GiB 
#> 
#> ## buffer_1GiB | arrow | threads=4 | rows=5,000,000 | wall=0.24s | calls=7 (of them =100: 2)
#>   open         0.00..0.03s: 1 calls, longest silence 0.03s, trace 0.00:100.0
#>   read 1       0.03..0.20s: 6 calls, longest silence 0.08s, trace 0.03:0.0 0.19:100.0
#>   50 further reads with no calls, 0.04s in all
invisible(dbExecute(con, "RESET max_streaming_buffer_size"))

system(sprintf("pkill -f 'throttle_server.py .* %d'", port))
write.csv(do.call(rbind, all_calls), calls_csv, row.names = FALSE)
cat("every call written to", basename(calls_csv), "\n")
#> every call written to calls.csv
dbDisconnect(con)
```

<sup>Created on 2026-11-17 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

<details style="margin-bottom:10px;">

<summary>

Session info
</summary>

``` r
sessioninfo::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────
#>  setting  value
#>  version  R version 4.5.3 (2026-03-11)
#>  os       Ubuntu 24.04.5 LTS
#>  system   x86_64, linux-gnu
#>  ui       X11
#>  language (EN)
#>  collate  C.UTF-8
#>  ctype    C.UTF-8
#>  tz       Etc/UTC
#>  date     2026-11-17
#>  pandoc   3.10.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.10.19 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  cli           3.6.6      2026-04-09 [2] RSPM
#>  DBI         * 1.3.0      2026-02-25 [2] RSPM
#>  digest        0.6.39     2025-11-19 [2] RSPM
#>  duckdb      * 2.0.0.9000 2026-11-17 [1] local
#>  evaluate      1.0.5      2025-08-27 [2] RSPM
#>  fastmap       1.2.0      2024-05-15 [2] RSPM
#>  fs            2.1.0      2026-04-18 [2] RSPM
#>  glue          1.8.1      2026-04-17 [2] RSPM
#>  htmltools     0.5.9      2025-12-04 [2] RSPM
#>  knitr         1.52       2026-09-06 [2] RSPM
#>  lifecycle     1.0.5      2026-01-08 [2] RSPM
#>  nanoarrow     0.9.0      2026-08-04 [1] RSPM (R 4.5.0)
#>  otel          0.3.0      2026-11-07 [2] RSPM
#>  reprex        2.1.1      2024-07-06 [2] RSPM
#>  rlang         1.3.0      2026-07-05 [2] RSPM
#>  rmarkdown     2.32       2026-09-01 [2] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [2] RSPM
#>  withr         3.0.3      2026-06-19 [2] RSPM
#>  xfun          0.62       2026-10-16 [2] RSPM
#>  yaml          2.3.12     2025-12-10 [2] RSPM
#> 
#>  [1] <branch build library>
#>  [2] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [3] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

</details>
