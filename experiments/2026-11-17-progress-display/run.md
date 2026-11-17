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
# httpfs. Renders run.md, and writes calls.csv (every call, consecutive calls
# with the same phase and percentage collapsed into one row) beside itself.
#
# Handbook: handbook/usage/interactive/README.md

suppressPackageStartupMessages(library(duckdb))

here <- Sys.getenv("PROGRESS_EXPERIMENT_DIR", getwd())
calls_csv <- file.path(here, "calls.csv")
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
#> date:       2026-11-17 18:46 UTC
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
#> ## scan_filter | get | threads=1 | rows=99,688 | wall=9.06s | calls=103 (of them =100: 2)
#>   dbGetQuery   0.00..9.05s: 103 calls, longest silence 0.17s, trace 0.00:100.0 0.36:1.4 0.65:3.4 0.96:5.5 1.28:7.5 1.55:9.6 1.83:11.6 2.13:13.7 2.42:15.8 2.72:17.8 3.02:20.5 3.29:22.6 3.57:24.7 3.86:26.7 4.12:28.8 4.41:31.5 4.72:34.3 5.02:37.0 5.31:39.7 5.57:41.8 5.83:43.8 6.09:45.9 6.35:48.0 6.67:50.0 6.95:52.7 7.22:54.8 7.55:57.5 7.87:60.3 8.18:63.0 8.44:65.1 8.71:66.7 8.97:100.0
#> 
#> ## scan_filter | arrow | threads=1 | rows=99,688 | wall=8.63s | calls=104 (of them =100: 2)
#>   open         0.00..0.12s: 1 calls, longest silence 0.11s, trace 0.01:100.0
#>   read 1       0.12..8.63s: 103 calls, longest silence 0.10s, trace 0.12:0.0 0.44:2.1 0.77:4.8 1.03:6.9 1.28:8.9 1.55:11.0 1.82:13.0 2.12:15.1 2.40:17.1 2.73:19.9 3.06:22.6 3.34:24.7 3.65:27.4 3.90:29.5 4.22:32.2 4.53:34.9 4.84:37.7 5.12:40.4 5.44:43.2 5.75:45.9 6.03:48.0 6.35:50.7 6.64:52.7 6.97:55.5 7.28:58.2 7.53:60.3 7.80:62.3 8.13:65.1 8.43:66.7 8.55:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | send | threads=1 | rows=99,688 | wall=8.93s | calls=103 (of them =100: 2)
#>   send         0.00..8.93s: 103 calls, longest silence 0.14s, trace 0.00:100.0 0.30:1.4 0.58:3.4 0.84:5.5 1.12:7.5 1.37:9.6 1.68:11.6 2.03:13.7 2.38:15.8 2.68:17.8 3.01:19.9 3.27:21.9 3.59:24.7 3.92:27.4 4.23:30.1 4.56:32.9 4.84:34.9 5.12:37.7 5.43:39.7 5.68:41.8 5.94:43.8 6.25:46.6 6.55:49.3 6.85:52.1 7.11:54.1 7.43:56.9 7.73:59.6 8.05:62.3 8.36:65.1 8.62:66.7 8.85:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | get | threads=4 | rows=99,688 | wall=0.89s | calls=14 (of them =100: 2)
#>   dbGetQuery   0.00..0.89s: 14 calls, longest silence 0.07s, trace 0.00:100.0 0.28:17.6 0.58:47.9 0.82:100.0
#> 
#> ## scan_filter | arrow | threads=4 | rows=99,688 | wall=0.95s | calls=13 (of them =100: 2)
#>   open         0.00..0.13s: 1 calls, longest silence 0.12s, trace 0.00:100.0
#>   read 1       0.13..0.95s: 12 calls, longest silence 0.08s, trace 0.13:0.5 0.41:25.6 0.73:55.4 0.87:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | send | threads=4 | rows=99,688 | wall=0.94s | calls=11 (of them =100: 2)
#>   send         0.00..0.94s: 11 calls, longest silence 0.10s, trace 0.00:100.0 0.26:15.1 0.59:44.8 0.84:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> group_by: SELECT k, sum(x) AS s, count(*) AS n FROM t GROUP BY k
#> 
#> ## group_by | get | threads=1 | rows=2,454,520 | wall=10.40s | calls=130 (of them =100: 2)
#>   dbGetQuery   0.00..10.40s: 130 calls, longest silence 0.19s, trace 0.00:100.0 0.26:0.8 0.58:3.0 0.89:5.3 1.19:7.6 1.52:9.9 1.79:12.1 2.06:14.4 2.36:15.9 2.64:18.2 2.93:20.5 3.19:22.8 3.49:25.8 3.80:28.9 4.10:31.9 4.43:34.9 4.71:38.0 4.99:41.0 5.26:44.0 5.51:47.1 5.79:50.1 6.05:52.4 6.32:54.6 6.63:57.7 6.93:60.7 7.20:63.8 7.52:66.8 7.84:69.8 8.14:72.9 8.42:91.3 8.70:92.8 8.97:94.3 9.24:95.7 9.52:97.2 9.77:98.7 10.04:100.0 10.26:100.0
#> 
#> ## group_by | arrow | threads=1 | rows=2,454,520 | wall=6.91s | calls=140 (of them =100: 2)
#>   open         0.00..0.04s: 1 calls, longest silence 0.04s, trace 0.00:100.0
#>   read 1       0.04..6.10s: 120 calls, longest silence 0.12s, trace 0.04:0.0 0.34:3.0 0.62:6.8 0.93:11.4 1.29:15.9 1.57:20.5 1.89:25.1 2.24:29.6 2.56:34.2 2.91:38.7 3.23:43.3 3.50:47.1 3.77:50.9 4.02:54.6 4.28:59.2 4.55:63.8 4.85:68.3 5.17:72.9 5.46:92.0 5.74:94.0 6.00:95.9 6.08:96.0
#>   read 2       6.10..6.71s: 15 calls, longest silence 0.09s, trace 6.10:96.3 6.35:98.2 6.67:99.8
#>   read 3       6.71..6.91s: 4 calls, longest silence 0.09s, trace 6.71:100.0 6.83:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## group_by | send | threads=1 | rows=2,454,520 | wall=6.26s | calls=130 (of them =100: 2)
#>   send         0.00..6.11s: 130 calls, longest silence 0.11s, trace 0.00:100.0 0.26:3.0 0.54:7.6 0.82:12.1 1.07:15.2 1.35:19.0 1.65:23.5 1.99:28.1 2.30:32.7 2.61:37.2 2.90:41.8 3.15:46.3 3.43:50.9 3.74:55.4 4.02:60.0 4.31:64.5 4.56:69.1 4.86:73.6 5.13:92.4 5.40:94.6 5.65:97.6 5.96:100.0 6.08:100.0
#>   3 further reads with no calls, 0.15s in all
#> 
#> ## group_by | get | threads=4 | rows=2,454,520 | wall=0.94s | calls=25 (of them =100: 2)
#>   dbGetQuery   0.00..0.94s: 25 calls, longest silence 0.11s, trace 0.00:100.0 0.26:51.6 0.51:81.7 0.77:98.5 0.87:100.0
#> 
#> ## group_by | arrow | threads=4 | rows=2,454,520 | wall=1.56s | calls=40 (of them =100: 2)
#>   open         0.00..0.04s: 1 calls, longest silence 0.04s, trace 0.00:100.0
#>   read 1       0.04..0.89s: 22 calls, longest silence 0.11s, trace 0.04:0.0 0.30:73.9 0.56:81.0 0.83:85.7 0.85:85.7
#>   read 2       0.89..1.52s: 15 calls, longest silence 0.09s, trace 0.91:88.9 1.17:94.7 1.43:99.6
#>   read 3       1.52..1.56s: 2 calls, longest silence 0.02s, trace 1.53:100.0 1.54:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## group_by | send | threads=4 | rows=2,454,520 | wall=0.66s | calls=19 (of them =100: 2)
#>   send         0.00..0.57s: 19 calls, longest silence 0.10s, trace 0.00:100.0 0.26:80.9 0.54:100.0
#>   3 further reads with no calls, 0.09s in all
#> 
#> order_by: SELECT i, x FROM t WHERE i % 4 = 0 ORDER BY x
#> 
#> ## order_by | get | threads=1 | rows=2,500,000 | wall=4.19s | calls=130 (of them =100: 2)
#>   dbGetQuery   0.00..4.19s: 130 calls, longest silence 0.30s, trace 0.00:100.0 0.26:0.8 0.57:2.9 0.82:4.9 1.10:6.8 1.37:8.0 1.69:10.1 2.01:12.5 2.26:14.6 2.52:16.2 2.77:18.5 3.24:40.0 3.51:50.0 3.77:65.1 4.04:76.8 4.11:100.0
#> 
#> ## order_by | arrow | threads=1 | rows=2,500,000 | wall=4.52s | calls=136 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.01s, trace 0.00:100.0
#>   read 1       0.02..4.03s: 122 calls, longest silence 0.19s, trace 0.02:0.0 0.34:1.9 0.62:4.1 0.90:6.0 1.19:8.0 1.45:9.9 1.74:11.7 2.00:13.4 2.26:15.2 2.54:16.9 2.80:18.7 3.19:40.0 3.50:50.0 3.77:57.4 3.94:66.3
#>   read 2       4.03..4.52s: 13 calls, longest silence 0.11s, trace 4.07:68.0 4.32:74.9 4.51:100.0
#>   2 further reads with no calls, 0.00s in all
#> 
#> ## order_by | send | threads=1 | rows=2,500,000 | wall=4.03s | calls=130 (of them =100: 2)
#>   send         0.00..3.95s: 130 calls, longest silence 0.22s, trace 0.00:100.0 0.27:1.2 0.52:2.9 0.78:4.5 1.06:6.8 1.32:8.8 1.60:11.3 1.85:13.4 2.11:15.2 2.42:17.7 2.68:19.3 3.00:40.0 3.25:51.7 3.55:66.7 3.81:80.0 3.85:100.0
#>   3 further reads with no calls, 0.08s in all
#> 
#> ## order_by | get | threads=4 | rows=2,500,000 | wall=0.41s | calls=10 (of them =100: 2)
#>   dbGetQuery   0.00..0.41s: 10 calls, longest silence 0.09s, trace 0.00:100.0 0.26:59.7 0.32:100.0
#> 
#> ## order_by | arrow | threads=4 | rows=2,500,000 | wall=0.98s | calls=30 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.01s, trace 0.00:100.0
#>   read 1       0.02..0.55s: 18 calls, longest silence 0.09s, trace 0.02:0.0 0.31:55.8 0.54:66.3
#>   read 2       0.55..0.98s: 11 calls, longest silence 0.11s, trace 0.56:68.0 0.84:78.5 0.96:100.0
#>   2 further reads with no calls, 0.00s in all
#> 
#> ## order_by | send | threads=4 | rows=2,500,000 | wall=0.44s | calls=12 (of them =100: 2)
#>   send         0.00..0.37s: 12 calls, longest silence 0.10s, trace 0.00:100.0 0.26:78.0 0.27:100.0
#>   3 further reads with no calls, 0.07s in all
#> 
#> join: SELECT t.k, x, y FROM t JOIN u ON t.k = u.k WHERE x < 0.01
#> 
#> ## join | get | threads=1 | rows=100,812 | wall=4.57s | calls=155 (of them =100: 2)
#>   dbGetQuery   0.00..4.57s: 155 calls, longest silence 0.11s, trace 0.00:100.0 0.26:1.8 0.60:5.0 0.85:8.8 1.12:11.7 1.40:14.1 1.65:17.3 1.92:20.9 2.24:24.8 2.51:28.6 2.77:32.2 3.02:34.4 3.28:39.8 3.55:46.0 3.86:55.1 4.11:65.0 4.37:72.2 4.56:100.0
#> 
#> ## join | arrow | threads=1 | rows=100,812 | wall=4.24s | calls=156 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.02s, trace 0.00:100.0
#>   read 1       0.02..4.24s: 155 calls, longest silence 0.12s, trace 0.02:0.0 0.31:2.5 0.63:7.1 0.90:11.3 1.17:15.2 1.47:19.8 1.79:24.0 2.08:28.3 2.41:32.5 2.67:35.3 2.93:41.6 3.22:48.8 3.48:59.5 3.75:65.0 4.01:75.8 4.16:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | send | threads=1 | rows=100,812 | wall=4.65s | calls=155 (of them =100: 2)
#>   send         0.00..4.65s: 155 calls, longest silence 0.12s, trace 0.00:100.0 0.26:2.8 0.52:5.3 0.78:8.5 1.09:11.7 1.34:14.9 1.60:18.0 1.85:21.9 2.11:25.1 2.43:29.0 2.72:33.6 3.00:37.1 3.31:45.1 3.56:52.4 3.81:57.7 4.13:68.6 4.39:74.0 4.64:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | get | threads=4 | rows=100,812 | wall=0.22s | calls=6 (of them =100: 2)
#>   dbGetQuery   0.00..0.22s: 6 calls, longest silence 0.09s, trace 0.00:100.0 0.21:100.0
#> 
#> ## join | arrow | threads=4 | rows=100,812 | wall=0.20s | calls=7 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.02s, trace 0.00:100.0
#>   read 1       0.02..0.20s: 6 calls, longest silence 0.08s, trace 0.02:0.0 0.18:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | send | threads=4 | rows=100,812 | wall=0.20s | calls=6 (of them =100: 2)
#>   send         0.00..0.20s: 6 calls, longest silence 0.09s, trace 0.00:100.0 0.11:100.0
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
#> ## remote_only | get | threads=1 | rows=1 | wall=4.94s | calls=118 (of them =100: 2)
#>   dbGetQuery   0.00..4.94s: 118 calls, longest silence 0.13s, trace 0.06:100.0 0.39:0.0 0.69:2.6 0.95:10.0 1.21:15.2 1.52:20.1 1.80:30.1 2.05:32.6 2.31:40.1 2.57:47.7 2.84:52.7 3.09:60.2 3.34:65.2 3.60:72.8 3.87:77.8 4.13:82.8 4.39:90.3 4.65:95.4 4.91:100.0 4.92:100.0
#> 
#> ## remote_only | arrow | threads=1 | rows=1 | wall=4.89s | calls=115 (of them =100: 2)
#>   open         0.00..0.16s: 1 calls, longest silence 0.10s, trace 0.06:100.0
#>   read 1       0.16..4.89s: 114 calls, longest silence 0.13s, trace 0.16:0.0 0.41:0.0 0.69:7.7 0.94:10.0 1.22:20.1 1.48:25.1 1.75:30.1 2.02:37.6 2.29:40.1 2.54:50.2 2.79:52.7 3.06:60.2 3.34:67.7 3.63:72.8 3.92:80.3 4.17:87.8 4.44:92.8 4.72:100.0 4.85:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_only | get | threads=4 | rows=1 | wall=3.06s | calls=60 (of them =100: 2)
#>   dbGetQuery   0.00..3.06s: 60 calls, longest silence 0.12s, trace 0.06:100.0 0.32:0.0 0.66:15.1 0.93:15.1 1.24:15.1 1.54:15.1 1.85:55.2 2.12:75.3 2.41:75.3 2.73:75.3 3.03:75.3 3.04:100.0
#> 
#> ## remote_only | arrow | threads=4 | rows=1 | wall=3.01s | calls=59 (of them =100: 2)
#>   open         0.00..0.12s: 1 calls, longest silence 0.07s, trace 0.06:100.0
#>   read 1       0.12..3.01s: 58 calls, longest silence 0.12s, trace 0.12:0.0 0.40:0.0 0.65:15.1 0.95:15.1 1.21:15.1 1.52:15.1 1.81:50.2 2.09:72.8 2.40:72.8 2.67:92.5 2.96:92.5 2.98:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_heavy_expr: SELECT count(*) AS n FROM read_parquet('http://127.0.0.1:8919/remote.parquet') WHERE hash(repeat(i::VARCHAR, 40)) % 7 = 0
#> 
#> ## remote_heavy_expr | get | threads=1 | rows=1 | wall=3.29s | calls=66 (of them =100: 2)
#>   dbGetQuery   0.00..3.29s: 66 calls, longest silence 0.14s, trace 0.06:100.0 0.41:0.9 0.67:5.0 0.93:7.5 1.24:11.7 1.50:15.1 1.77:18.4 2.10:21.8 2.41:25.1 2.77:29.3 3.09:33.3 3.26:100.0
#> 
#> ## remote_heavy_expr | arrow | threads=1 | rows=1 | wall=3.23s | calls=63 (of them =100: 2)
#>   open         0.00..0.15s: 1 calls, longest silence 0.09s, trace 0.06:100.0
#>   read 1       0.15..3.23s: 62 calls, longest silence 0.16s, trace 0.15:0.0 0.42:0.0 0.69:5.0 0.96:8.4 1.31:11.7 1.64:15.1 1.93:19.2 2.21:22.6 2.48:25.9 2.75:29.3 3.01:32.6 3.21:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_heavy_expr | get | threads=4 | rows=1 | wall=1.68s | calls=33 (of them =100: 2)
#>   dbGetQuery   0.00..1.68s: 33 calls, longest silence 0.14s, trace 0.06:100.0 0.40:7.3 0.65:7.5 0.96:7.5 1.22:7.5 1.57:20.9 1.67:100.0
#> 
#> ## remote_heavy_expr | arrow | threads=4 | rows=1 | wall=1.77s | calls=35 (of them =100: 2)
#>   open         0.00..0.14s: 1 calls, longest silence 0.09s, trace 0.06:100.0
#>   read 1       0.14..1.77s: 34 calls, longest silence 0.12s, trace 0.14:0.0 0.42:5.8 0.69:6.7 0.95:6.7 1.26:6.7 1.52:20.1 1.67:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_join_columns: SELECT count(*) AS n, sum(k) AS sk, sum(z) AS s FROM read_parquet('http://127.0.0.1:8919/remote.parquet')
#> 
#> ## remote_join_columns | get | threads=1 | rows=1 | wall=7.44s | calls=155 (of them =100: 2)
#>   dbGetQuery   0.00..7.44s: 155 calls, longest silence 0.15s, trace 0.05:100.0 0.33:0.0 0.59:0.0 0.85:2.6 1.13:10.0 1.43:10.0 1.69:20.1 2.02:20.1 2.28:27.7 2.56:30.1 2.84:32.6 3.09:40.1 3.38:40.1 3.64:45.2 3.91:50.2 4.17:52.7 4.44:60.2 4.74:60.2 5.00:65.2 5.28:70.2 5.54:72.8 5.80:80.3 6.07:80.3 6.32:82.8 6.68:90.3 6.96:92.8 7.24:100.0 7.43:100.0
#> 
#> ## remote_join_columns | arrow | threads=1 | rows=1 | wall=7.35s | calls=167 (of them =100: 2)
#>   open         0.00..0.12s: 1 calls, longest silence 0.07s, trace 0.06:100.0
#>   read 1       0.12..7.35s: 166 calls, longest silence 0.13s, trace 0.12:0.0 0.41:0.0 0.66:0.0 0.94:5.1 1.19:10.0 1.51:10.0 1.77:20.1 2.03:20.1 2.34:25.1 2.62:30.1 2.87:30.1 3.15:40.1 3.42:40.1 3.67:45.2 3.95:50.2 4.23:50.2 4.51:60.2 4.77:60.2 5.05:65.2 5.32:70.2 5.62:70.2 5.87:80.3 6.15:80.3 6.42:85.3 6.69:90.3 6.94:90.3 7.20:100.0 7.33:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_join_columns | get | threads=4 | rows=1 | wall=3.28s | calls=63 (of them =100: 2)
#>   dbGetQuery   0.00..3.28s: 63 calls, longest silence 0.14s, trace 0.06:100.0 0.32:0.0 0.59:0.0 0.85:17.6 1.14:17.6 1.47:17.6 1.75:17.6 2.07:52.7 2.35:52.7 2.69:87.8 2.96:92.8 3.26:100.0
#> 
#> ## remote_join_columns | arrow | threads=4 | rows=1 | wall=3.26s | calls=64 (of them =100: 2)
#>   open         0.00..0.14s: 1 calls, longest silence 0.09s, trace 0.06:100.0
#>   read 1       0.14..3.26s: 63 calls, longest silence 0.14s, trace 0.14:0.0 0.43:0.0 0.68:0.0 1.01:15.1 1.29:15.1 1.62:15.1 1.93:50.2 2.21:55.2 2.47:55.2 2.72:95.3 2.99:95.3 3.24:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_build_local_probe: SELECT count(*) AS n, sum(x * z) AS s FROM t JOIN read_parquet('http://127.0.0.1:8919/remote.parquet') r ON t.k = r.k
#> 
#> ## remote_build_local_probe | get | threads=1 | rows=1 | wall=15.75s | calls=399 (of them =100: 2)
#>   dbGetQuery   0.00..15.75s: 399 calls, longest silence 0.13s, trace 0.06:100.0 0.33:0.0 0.62:0.0 0.89:0.4 1.15:1.6 1.44:1.6 1.70:3.3 2.02:3.3 2.30:3.7 2.57:4.9 2.83:4.9 3.08:6.2 3.35:6.6 3.61:7.0 3.89:8.2 4.21:8.2 4.50:9.4 4.76:9.8 5.04:10.7 5.33:11.5 5.60:11.9 5.86:12.7 6.12:13.1 6.42:13.9 6.74:14.8 7.08:15.6 7.42:16.3 7.67:16.9 7.93:17.9 8.18:18.7 8.44:20.0 8.74:21.0 9.00:22.1 9.28:23.1 9.55:24.1 9.87:25.4 10.13:26.4 10.47:27.9 10.74:29.1 11.00:30.2 11.29:31.3 11.56:32.5 11.81:34.3 12.07:35.7 12.32:37.2 12.58:38.7 12.90:41.2 13.17:42.9 13.53:44.8 13.81:46.1 14.07:47.8 14.32:49.1 14.58:51.0 14.83:52.2 15.11:53.7 15.37:55.8 15.66:100.0 15.73:100.0
#> 
#> ## remote_build_local_probe | arrow | threads=1 | rows=1 | wall=15.63s | calls=397 (of them =100: 2)
#>   open         0.00..0.12s: 1 calls, longest silence 0.07s, trace 0.06:100.0
#>   read 1       0.12..15.63s: 396 calls, longest silence 0.19s, trace 0.12:0.0 0.40:0.0 0.68:0.0 0.93:1.3 1.20:1.6 1.45:1.6 1.72:3.3 2.04:3.3 2.31:3.7 2.61:4.9 2.91:4.9 3.18:6.6 3.45:6.6 3.72:7.4 4.00:8.2 4.30:8.6 4.57:9.8 4.88:9.8 5.16:11.1 5.49:11.5 5.74:12.3 6.03:13.1 6.30:13.5 6.56:14.8 6.81:14.8 7.07:15.2 7.49:16.3 7.75:17.2 8.01:18.5 8.28:19.4 8.55:20.4 8.81:21.6 9.07:22.4 9.40:23.8 9.67:25.4 10.01:26.4 10.28:28.1 10.59:29.1 10.85:30.3 11.17:31.6 11.43:32.6 11.76:34.9 12.02:36.4 12.29:38.1 12.54:39.3 12.80:41.2 13.11:42.5 13.36:44.6 13.69:46.3 13.97:48.0 14.22:49.5 14.55:51.6 14.82:53.5 15.08:55.6 15.35:56.9 15.61:100.0 15.62:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_build_local_probe | get | threads=4 | rows=1 | wall=3.48s | calls=68 (of them =100: 2)
#>   dbGetQuery   0.00..3.48s: 68 calls, longest silence 0.14s, trace 0.06:100.0 0.33:0.0 0.59:0.0 0.88:2.9 1.13:2.9 1.41:2.9 1.67:2.9 1.94:8.6 2.24:9.4 2.51:10.2 2.83:16.0 3.21:28.4 3.46:100.0
#> 
#> ## remote_build_local_probe | arrow | threads=4 | rows=1 | wall=3.68s | calls=72 (of them =100: 2)
#>   open         0.00..0.17s: 1 calls, longest silence 0.11s, trace 0.06:100.0
#>   read 1       0.17..3.68s: 71 calls, longest silence 0.13s, trace 0.17:0.0 0.45:0.0 0.73:0.0 1.01:2.5 1.28:2.5 1.61:2.5 1.91:9.0 2.26:9.0 2.57:15.6 2.85:15.6 3.10:15.9 3.36:39.4 3.65:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_then_sort: SELECT k, sum(z) AS s FROM read_parquet('http://127.0.0.1:8919/remote.parquet') GROUP BY k ORDER BY s
#> 
#> ## remote_then_sort | get | threads=1 | rows=2,754,617 | wall=9.57s | calls=212 (of them =100: 2)
#>   dbGetQuery   0.00..9.57s: 212 calls, longest silence 0.28s, trace 0.06:100.0 0.33:0.0 0.59:0.0 0.85:0.0 1.12:4.4 1.43:4.4 1.70:8.9 1.99:8.9 2.31:11.1 2.58:13.3 2.84:13.3 3.13:17.7 3.42:17.7 3.69:21.1 3.94:22.2 4.22:22.2 4.47:26.6 4.73:26.6 5.01:27.7 5.27:31.0 5.52:31.0 5.79:33.3 6.05:35.5 6.36:36.6 6.63:39.9 6.89:39.9 7.22:42.1 7.48:54.2 7.74:55.4 8.07:57.2 8.56:72.1 8.81:79.5 9.07:88.0 9.34:96.4 9.55:100.0
#> 
#> ## remote_then_sort | arrow | threads=1 | rows=2,754,617 | wall=9.78s | calls=217 (of them =100: 2)
#>   open         0.00..0.15s: 1 calls, longest silence 0.09s, trace 0.06:100.0
#>   read 1       0.15..9.27s: 199 calls, longest silence 0.28s, trace 0.15:0.0 0.41:0.0 0.68:0.0 0.98:0.0 1.25:4.4 1.54:4.4 1.83:7.8 2.12:8.9 2.48:11.1 2.75:13.3 3.05:14.4 3.31:17.7 3.58:17.7 3.83:19.9 4.10:22.2 4.39:22.2 4.66:26.6 4.94:26.6 5.22:28.8 5.50:31.0 5.77:31.0 6.04:34.4 6.33:35.5 6.62:37.7 6.90:39.9 7.16:41.0 7.42:44.2 7.70:54.5 7.97:56.3 8.28:58.1 8.56:72.1 8.86:78.7 9.12:85.4 9.18:88.8
#>   read 2       9.27..9.65s: 12 calls, longest silence 0.08s, trace 9.28:89.8 9.53:96.5 9.57:98.8
#>   read 3       9.65..9.78s: 5 calls, longest silence 0.04s, trace 9.65:99.8 9.75:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_then_sort | get | threads=4 | rows=2,754,617 | wall=3.60s | calls=72 (of them =100: 2)
#>   dbGetQuery   0.00..3.60s: 72 calls, longest silence 0.14s, trace 0.06:100.0 0.31:0.0 0.65:0.0 0.91:6.6 1.22:6.6 1.51:6.6 1.85:21.8 2.12:24.4 2.42:24.4 2.69:41.0 3.00:42.1 3.36:72.1 3.55:100.0
#> 
#> ## remote_then_sort | arrow | threads=4 | rows=2,754,617 | wall=4.57s | calls=101 (of them =100: 2)
#>   open         0.00..0.14s: 1 calls, longest silence 0.09s, trace 0.05:100.0
#>   read 1       0.14..4.08s: 85 calls, longest silence 0.12s, trace 0.14:0.0 0.42:0.0 0.71:0.0 0.99:6.6 1.25:6.6 1.56:6.6 1.84:9.9 2.09:12.2 2.41:12.2 2.67:12.2 2.94:29.9 3.22:29.9 3.49:29.9 3.80:79.8 4.06:88.3
#>   read 2       4.08..4.45s: 12 calls, longest silence 0.09s, trace 4.09:89.8 4.38:96.5 4.43:98.8
#>   read 3       4.45..4.57s: 3 calls, longest silence 0.08s, trace 4.46:99.8 4.48:100.0
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
#> ## buffer_976KiB | arrow | threads=4 | rows=5,000,000 | wall=4.51s | calls=159 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.01s, trace 0.00:100.0
#>   read 1       0.02..0.08s: 4 calls, longest silence 0.02s, trace 0.02:0.0 0.06:2.1
#>   read 2       0.08..0.20s: 3 calls, longest silence 0.08s, trace 0.08:2.5 0.17:3.4
#>   read 3       0.20..0.32s: 3 calls, longest silence 0.08s, trace 0.20:3.8 0.30:4.7
#>   read 4       0.32..0.40s: 3 calls, longest silence 0.04s, trace 0.32:5.1 0.38:5.9
#>   read 5       0.40..0.54s: 3 calls, longest silence 0.08s, trace 0.41:6.3 0.53:7.2
#>   read 6       0.54..0.58s: 3 calls, longest silence 0.01s, trace 0.54:7.6 0.57:8.5
#>   read 7       0.58..0.73s: 4 calls, longest silence 0.09s, trace 0.58:8.9 0.70:10.2
#>   read 8       0.73..0.82s: 3 calls, longest silence 0.04s, trace 0.73:10.6 0.77:11.4
#>   read 9       0.82..0.94s: 3 calls, longest silence 0.10s, trace 0.82:11.9 0.93:12.7
#>   read 10      0.94..0.98s: 3 calls, longest silence 0.01s, trace 0.94:13.1 0.97:14.0
#>   read 11      0.98..1.09s: 3 calls, longest silence 0.08s, trace 0.98:14.4 1.07:15.2
#>   read 12      1.09..1.12s: 3 calls, longest silence 0.01s, trace 1.09:15.7 1.11:16.5
#>   read 13      1.12..1.24s: 3 calls, longest silence 0.09s, trace 1.13:16.9 1.23:17.8
#>   read 14      1.24..1.41s: 4 calls, longest silence 0.12s, trace 1.24:18.2 1.40:19.5
#>   read 15      1.41..1.46s: 3 calls, longest silence 0.02s, trace 1.41:19.9 1.44:20.7
#>   read 16      1.46..1.56s: 3 calls, longest silence 0.08s, trace 1.46:21.2 1.55:22.0
#>   read 17      1.56..1.64s: 3 calls, longest silence 0.03s, trace 1.56:22.4 1.61:23.3
#>   read 18      1.64..1.75s: 3 calls, longest silence 0.09s, trace 1.64:23.7 1.67:24.5
#>   read 19      1.75..1.83s: 3 calls, longest silence 0.04s, trace 1.75:25.0 1.82:25.8
#>   read 20      1.83..1.97s: 4 calls, longest silence 0.09s, trace 1.83:26.2 1.96:27.5
#>   read 21      1.97..2.01s: 3 calls, longest silence 0.01s, trace 1.97:27.9 2.00:28.8
#>   read 22      2.01..2.12s: 3 calls, longest silence 0.08s, trace 2.01:29.2 2.11:30.1
#>   read 23      2.12..2.17s: 3 calls, longest silence 0.02s, trace 2.13:30.5 2.16:31.3
#>   read 24      2.17..2.28s: 3 calls, longest silence 0.08s, trace 2.17:31.7 2.20:32.6
#>   read 25      2.28..2.32s: 3 calls, longest silence 0.02s, trace 2.28:33.0 2.31:33.9
#>   read 26      2.32..2.43s: 3 calls, longest silence 0.08s, trace 2.32:34.3 2.42:35.1
#>   read 27      2.43..2.48s: 4 calls, longest silence 0.02s, trace 2.43:35.6 2.47:36.8
#>   read 28      2.48..2.63s: 3 calls, longest silence 0.09s, trace 2.49:37.2 2.60:38.1
#>   read 29      2.63..2.71s: 3 calls, longest silence 0.04s, trace 2.63:38.5 2.69:39.4
#>   read 30      2.71..2.82s: 3 calls, longest silence 0.08s, trace 2.72:39.8 2.81:40.6
#>   read 31      2.82..2.87s: 3 calls, longest silence 0.02s, trace 2.83:41.1 2.86:41.9
#>   read 32      2.87..3.00s: 3 calls, longest silence 0.08s, trace 2.87:42.3 2.98:43.2
#>   read 33      3.00..3.07s: 3 calls, longest silence 0.04s, trace 3.00:43.6 3.05:44.4
#>   read 34      3.07..3.19s: 4 calls, longest silence 0.08s, trace 3.07:44.9 3.18:46.1
#>   read 35      3.19..3.30s: 3 calls, longest silence 0.08s, trace 3.19:46.6 3.22:47.4
#>   read 36      3.30..3.34s: 3 calls, longest silence 0.01s, trace 3.30:47.8 3.33:48.7
#>   read 37      3.34..3.45s: 3 calls, longest silence 0.08s, trace 3.34:49.1 3.37:49.9
#>   read 38      3.45..3.51s: 3 calls, longest silence 0.03s, trace 3.45:50.4 3.50:51.2
#>   read 39      3.51..3.66s: 3 calls, longest silence 0.07s, trace 3.52:51.6 3.58:52.5
#>   read 40      3.66..3.71s: 4 calls, longest silence 0.01s, trace 3.66:52.9 3.70:54.2
#>   read 41      3.71..3.81s: 3 calls, longest silence 0.08s, trace 3.71:54.6 3.80:55.4
#>   read 42      3.81..3.89s: 3 calls, longest silence 0.04s, trace 3.81:55.9 3.87:56.7
#>   read 43      3.89..3.99s: 3 calls, longest silence 0.07s, trace 3.89:57.1 3.98:58.0
#>   read 44      3.99..4.03s: 3 calls, longest silence 0.01s, trace 3.99:58.4 4.02:59.3
#>   read 45      4.03..4.15s: 3 calls, longest silence 0.09s, trace 4.03:59.7 4.13:60.5
#>   read 46      4.15..4.23s: 3 calls, longest silence 0.04s, trace 4.15:60.9 4.21:61.8
#>   read 47      4.23..4.35s: 4 calls, longest silence 0.08s, trace 4.23:62.2 4.34:63.5
#>   read 48      4.35..4.39s: 3 calls, longest silence 0.01s, trace 4.35:63.9 4.38:64.8
#>   read 49      4.39..4.48s: 3 calls, longest silence 0.07s, trace 4.39:65.2 4.47:66.0
#>   read 50      4.48..4.51s: 3 calls, longest silence 0.01s, trace 4.48:66.5 4.50:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> max_streaming_buffer_size = 10MiB 
#> 
#> ## buffer_10MiB | arrow | threads=4 | rows=5,000,000 | wall=2.71s | calls=90 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.02s, trace 0.00:100.0
#>   read 1       0.02..0.05s: 1 calls, longest silence 0.03s, trace 0.02:0.0
#>   read 4       0.05..0.26s: 7 calls, longest silence 0.08s, trace 0.05:9.4 0.25:13.1
#>   read 7       0.26..0.50s: 7 calls, longest silence 0.09s, trace 0.26:13.8 0.42:17.5
#>   read 10      0.50..0.70s: 7 calls, longest silence 0.08s, trace 0.50:18.2 0.61:21.9
#>   read 14      0.70..0.90s: 7 calls, longest silence 0.10s, trace 0.70:22.6 0.89:26.3
#>   read 17      0.90..1.06s: 7 calls, longest silence 0.08s, trace 0.91:27.0 1.05:30.7
#>   read 20      1.06..1.26s: 7 calls, longest silence 0.08s, trace 1.06:31.3 1.21:35.0
#>   read 24      1.26..1.29s: 1 calls, longest silence 0.03s, trace 1.26:35.0
#>   read 27      1.29..1.46s: 7 calls, longest silence 0.08s, trace 1.29:40.1 1.44:43.8
#>   read 30      1.46..1.74s: 7 calls, longest silence 0.10s, trace 1.46:44.5 1.67:48.2
#>   read 33      1.74..1.93s: 7 calls, longest silence 0.08s, trace 1.75:48.9 1.90:52.6
#>   read 37      1.94..2.13s: 7 calls, longest silence 0.08s, trace 1.94:53.2 2.12:57.0
#>   read 40      2.13..2.29s: 7 calls, longest silence 0.08s, trace 2.13:57.6 2.28:61.3
#>   read 43      2.30..2.53s: 7 calls, longest silence 0.10s, trace 2.30:62.0 2.51:65.7
#>   read 47      2.53..2.70s: 3 calls, longest silence 0.12s, trace 2.53:66.4 2.68:100.0
#>   36 further reads with no calls, 0.04s in all
#> 
#> max_streaming_buffer_size = 1GiB 
#> 
#> ## buffer_1GiB | arrow | threads=4 | rows=5,000,000 | wall=0.27s | calls=7 (of them =100: 2)
#>   open         0.00..0.04s: 1 calls, longest silence 0.04s, trace 0.00:100.0
#>   read 1       0.04..0.24s: 6 calls, longest silence 0.10s, trace 0.04:0.0 0.22:100.0
#>   50 further reads with no calls, 0.04s in all
invisible(dbExecute(con, "RESET max_streaming_buffer_size"))

system(sprintf("pkill -f 'throttle_server.py .* %d'", port))
write.csv(do.call(rbind, all_calls), calls_csv, row.names = FALSE)
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
