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
# It keeps its vectors in its own closure, where `[<-` modifies them in place:
# a callback that copies them on every call, as one that assigns into an
# environment's member does, takes milliseconds and thins out the calls.
now <- function() as.numeric(Sys.time())
recorder <- local({
  n <- 0L
  t <- numeric(1e6)
  v <- numeric(1e6)
  p <- integer(1e6)
  cur <- 0L
  t0 <- 0
  list(
    reset = function(start) {
      n <<- 0L
      cur <<- 0L
      t0 <<- start
    },
    set_phase = function(i) cur <<- i,
    callback = function(x) {
      n <<- n + 1L
      if (n > length(t)) {
        t <<- c(t, numeric(length(t)))
        v <<- c(v, numeric(length(v)))
        p <<- c(p, integer(length(p)))
      }
      t[n] <<- now() - t0
      v[n] <<- x
      p[n] <<- cur
    },
    get = function() {
      list(n = n, t = t[seq_len(n)], v = v[seq_len(n)], p = p[seq_len(n)])
    }
  )
})
rec <- new.env()
rec_reset <- function() {
  rec$phases <- character()
  rec$t0 <- now()
  recorder$reset(rec$t0)
}
phase <- function(name) {
  rec$phases <- c(rec$phases, name)
  recorder$set_phase(length(rec$phases))
}
options(duckdb.progress_display = recorder$callback)

all_calls <- list()
fmt <- function(x) formatC(x, format = "f", digits = 2)

# Prints one run: per phase, the number of calls, the span of the phase,
# and a trace of (seconds since the query started: percentage) sampled at
# most every `step` seconds (the first call in each step), always with the
# first and the last call.
report <- function(
  scenario,
  api,
  threads,
  rows,
  wall,
  phase_spans,
  step = 0.25
) {
  got <- recorder$get()
  n <- got$n
  t <- got$t
  v <- got$v
  p <- got$p
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
    keep <- sel[!duplicated(floor((t[sel] - t[sel[1]]) / step))]
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
#> date:       2026-11-17 19:11 UTC
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

n_rows <- 40000000L
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
#> table t: 40,000,000 rows (i, k, x); table u: 10,000,000 rows (k, y)
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
#> │ ~1 row                                           │
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
#> ## scan_filter | get | threads=1 | rows=398,634 | wall=2.71s | calls=395 (of them =100: 2)
#>   dbGetQuery   0.00..2.71s: 395 calls, longest silence 0.01s, trace 0.00:100.0 0.26:5.1 0.51:9.6 0.76:13.9 1.01:18.2 1.26:22.6 1.51:27.0 1.75:31.6 2.01:36.9 2.25:41.4 2.50:45.8 2.71:100.0
#> 
#> ## scan_filter | arrow | threads=1 | rows=398,634 | wall=2.77s | calls=396 (of them =100: 2)
#>   open         0.00..0.01s: 1 calls, longest silence 0.01s, trace 0.01:100.0
#>   read 1       0.01..2.77s: 395 calls, longest silence 0.03s, trace 0.01:0.0 0.26:4.2 0.51:8.6 0.76:13.6 1.02:18.1 1.26:22.5 1.51:27.0 1.76:31.3 2.02:35.7 2.26:40.1 2.52:45.3 2.74:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | send | threads=1 | rows=398,634 | wall=2.90s | calls=395 (of them =100: 2)
#>   send         0.00..2.90s: 395 calls, longest silence 0.03s, trace 0.00:100.0 0.26:4.0 0.51:8.1 0.76:12.2 1.01:17.2 1.25:22.6 1.50:26.2 1.76:30.2 2.01:34.5 2.26:38.9 2.50:43.2 2.75:47.4 2.90:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | get | threads=4 | rows=398,634 | wall=2.67s | calls=535180 (of them =100: 2)
#>   dbGetQuery   0.00..2.67s: 535180 calls, longest silence 0.00s, trace 0.00:100.0 0.25:5.4 0.50:10.9 0.75:15.5 1.00:19.9 1.25:24.9 1.50:29.5 1.75:34.0 2.00:38.4 2.25:42.9 2.50:47.1 2.66:100.0
#> 
#> ## scan_filter | arrow | threads=4 | rows=398,634 | wall=2.79s | calls=529537 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.01s, trace 0.00:100.0
#>   read 1       0.02..2.79s: 529536 calls, longest silence 0.07s, trace 0.02:0.1 0.31:4.2 0.52:9.1 0.77:13.5 1.02:17.8 1.27:22.2 1.52:26.5 1.77:30.8 2.02:35.3 2.27:39.8 2.52:44.3 2.77:49.8 2.78:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | send | threads=4 | rows=398,634 | wall=2.85s | calls=395 (of them =100: 2)
#>   send         0.00..2.85s: 395 calls, longest silence 0.02s, trace 0.00:100.0 0.25:4.5 0.51:8.5 0.76:12.7 1.01:16.6 1.26:21.3 1.51:25.2 1.75:28.6 2.00:32.7 2.25:37.6 2.50:43.2 2.75:47.9 2.85:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> group_by: SELECT k, sum(x) AS s, count(*) AS n FROM t GROUP BY k
#> 
#> ## group_by | get | threads=1 | rows=9,817,025 | wall=4.23s | calls=493 (of them =100: 2)
#>   dbGetQuery   0.00..4.23s: 493 calls, longest silence 0.35s, trace 0.00:100.0 0.25:5.4 0.50:8.7 0.76:14.3 1.05:16.1 1.26:21.5 1.51:27.2 1.76:32.6 2.00:37.8 2.26:42.7 2.50:48.5 2.76:54.2 3.01:60.2 3.26:66.4 3.50:72.3 3.75:93.2 3.88:100.0
#> 
#> ## group_by | arrow | threads=1 | rows=9,817,025 | wall=3.83s | calls=532 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s, trace 0.00:100.0
#>   read 1       0.00..3.66s: 412 calls, longest silence 0.24s, trace 0.00:0.0 0.26:6.0 0.51:10.5 0.76:15.7 1.01:16.1 1.26:23.2 1.51:28.4 1.76:34.4 2.01:39.9 2.25:45.9 2.51:52.1 2.76:58.4 3.01:64.4 3.26:70.5 3.51:75.9 3.65:93.8
#>   read 2       3.66..3.68s: 15 calls, longest silence 0.01s, trace 3.66:93.8 3.68:94.6
#>   read 3       3.68..3.70s: 12 calls, longest silence 0.00s, trace 3.68:94.6 3.70:95.2
#>   read 4       3.70..3.72s: 15 calls, longest silence 0.00s, trace 3.70:95.3 3.72:96.0
#>   read 5       3.72..3.74s: 12 calls, longest silence 0.00s, trace 3.72:96.1 3.73:96.7
#>   read 6       3.74..3.76s: 15 calls, longest silence 0.00s, trace 3.74:96.7 3.76:97.5
#>   read 7       3.76..3.78s: 12 calls, longest silence 0.00s, trace 3.76:97.5 3.77:98.1
#>   read 8       3.78..3.80s: 15 calls, longest silence 0.00s, trace 3.78:98.2 3.80:98.9
#>   read 9       3.80..3.82s: 15 calls, longest silence 0.00s, trace 3.80:99.0 3.82:99.7
#>   read 10      3.82..3.83s: 8 calls, longest silence 0.00s, trace 3.82:99.8 3.82:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## group_by | send | threads=1 | rows=9,817,025 | wall=4.32s | calls=493 (of them =100: 2)
#>   send         0.00..3.89s: 493 calls, longest silence 0.21s, trace 0.00:100.0 0.26:5.0 0.51:8.9 0.76:15.3 1.00:17.3 1.26:23.4 1.51:29.4 1.76:35.2 2.01:41.1 2.25:46.3 2.51:52.9 2.76:59.0 3.00:65.0 3.25:71.1 3.51:77.1 3.68:100.0
#>   10 further reads with no calls, 0.43s in all
#> 
#> ## group_by | get | threads=4 | rows=9,817,025 | wall=2.34s | calls=278281 (of them =100: 2)
#>   dbGetQuery   0.00..2.34s: 278281 calls, longest silence 0.22s, trace 0.00:100.0 0.25:37.7 0.50:74.1 0.75:81.4 1.00:85.0 1.25:87.8 1.50:91.1 1.75:94.8 2.00:98.2 2.12:100.0
#> 
#> ## group_by | arrow | threads=4 | rows=9,817,025 | wall=2.16s | calls=17733 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s, trace 0.00:100.0
#>   read 1       0.00..0.73s: 12766 calls, longest silence 0.02s, trace 0.00:0.0 0.25:38.4 0.50:78.6 0.73:81.4
#>   read 2       0.73..0.91s: 15 calls, longest silence 0.03s, trace 0.75:81.6 0.91:83.7
#>   read 3       0.91..1.04s: 12 calls, longest silence 0.02s, trace 0.93:83.9 1.04:85.6
#>   read 4       1.04..1.21s: 15 calls, longest silence 0.02s, trace 1.07:85.9 1.21:88.1
#>   read 5       1.21..1.35s: 4859 calls, longest silence 0.02s, trace 1.22:88.3 1.35:90.0
#>   read 6       1.35..1.54s: 15 calls, longest silence 0.03s, trace 1.37:90.2 1.54:92.4
#>   read 7       1.54..1.72s: 15 calls, longest silence 0.02s, trace 1.56:92.6 1.72:94.8
#>   read 8       1.72..1.89s: 12 calls, longest silence 0.03s, trace 1.75:95.1 1.88:96.7
#>   read 9       1.89..2.07s: 15 calls, longest silence 0.03s, trace 1.90:96.9 2.07:99.1
#>   read 10      2.07..2.16s: 8 calls, longest silence 0.03s, trace 2.09:99.3 2.15:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## group_by | send | threads=4 | rows=9,817,025 | wall=2.67s | calls=322 (of them =100: 2)
#>   send         0.00..2.18s: 322 calls, longest silence 0.24s, trace 0.00:100.0 0.25:52.2 0.53:80.5 0.76:83.9 1.02:86.6 1.26:89.8 1.51:93.9 1.76:97.3 1.94:100.0
#>   10 further reads with no calls, 0.49s in all
#> 
#> order_by: SELECT i, x FROM t WHERE i % 4 = 0 ORDER BY x
#> 
#> ## order_by | get | threads=1 | rows=10,000,000 | wall=2.32s | calls=494 (of them =100: 2)
#>   dbGetQuery   0.00..2.32s: 494 calls, longest silence 1.02s, trace 0.00:100.0 0.25:5.7 0.50:11.5 0.75:16.1 1.82:33.3 2.00:48.0 2.22:100.0
#> 
#> ## order_by | arrow | threads=1 | rows=10,000,000 | wall=2.12s | calls=520 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s, trace 0.00:100.0
#>   read 1       0.00..1.74s: 414 calls, longest silence 0.99s, trace 0.00:0.0 0.26:6.2 0.51:12.3 1.67:33.3 1.74:38.8
#>   read 2       1.74..1.78s: 12 calls, longest silence 0.01s, trace 1.74:39.2 1.78:42.1
#>   read 3       1.78..1.82s: 12 calls, longest silence 0.01s, trace 1.78:42.5 1.82:45.4
#>   read 4       1.82..1.86s: 12 calls, longest silence 0.01s, trace 1.82:45.8 1.86:48.7
#>   read 5       1.86..1.90s: 12 calls, longest silence 0.01s, trace 1.86:49.1 1.90:52.0
#>   read 6       1.90..1.95s: 12 calls, longest silence 0.01s, trace 1.91:52.4 1.94:55.3
#>   read 7       1.95..2.00s: 12 calls, longest silence 0.01s, trace 1.95:55.6 1.99:58.6
#>   read 8       2.00..2.04s: 12 calls, longest silence 0.01s, trace 2.00:58.9 2.04:61.9
#>   read 9       2.04..2.09s: 12 calls, longest silence 0.01s, trace 2.05:62.2 2.09:65.2
#>   read 10      2.09..2.12s: 9 calls, longest silence 0.01s, trace 2.09:65.5 2.11:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## order_by | send | threads=1 | rows=10,000,000 | wall=2.45s | calls=494 (of them =100: 2)
#>   send         0.00..1.94s: 494 calls, longest silence 0.91s, trace 0.00:100.0 0.25:6.6 0.50:13.5 1.53:33.3 1.75:58.4 1.84:100.0
#>   10 further reads with no calls, 0.51s in all
#> 
#> ## order_by | get | threads=4 | rows=10,000,000 | wall=1.03s | calls=3321 (of them =100: 2)
#>   dbGetQuery   0.00..1.03s: 3321 calls, longest silence 0.21s, trace 0.00:100.0 0.38:28.8 0.50:39.9 0.76:56.0 0.93:100.0
#> 
#> ## order_by | arrow | threads=4 | rows=10,000,000 | wall=1.06s | calls=16242 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s, trace 0.00:100.0
#>   read 1       0.00..0.57s: 16135 calls, longest silence 0.27s, trace 0.00:0.0 0.45:28.5 0.50:35.1 0.57:38.4
#>   read 2       0.57..0.63s: 12 calls, longest silence 0.01s, trace 0.58:38.7 0.63:41.7
#>   read 3       0.63..0.69s: 12 calls, longest silence 0.01s, trace 0.63:42.0 0.68:45.0
#>   read 4       0.69..0.74s: 12 calls, longest silence 0.01s, trace 0.69:45.3 0.74:48.2
#>   read 5       0.74..0.80s: 12 calls, longest silence 0.01s, trace 0.75:48.6 0.80:51.5
#>   read 6       0.80..0.86s: 12 calls, longest silence 0.01s, trace 0.81:51.9 0.85:54.8
#>   read 7       0.86..0.91s: 12 calls, longest silence 0.01s, trace 0.86:55.2 0.91:58.1
#>   read 8       0.91..0.97s: 12 calls, longest silence 0.01s, trace 0.92:58.5 0.97:61.4
#>   read 9       0.97..1.03s: 12 calls, longest silence 0.01s, trace 0.98:61.8 1.02:64.7
#>   read 10      1.03..1.06s: 10 calls, longest silence 0.01s, trace 1.03:65.1 1.06:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## order_by | send | threads=4 | rows=10,000,000 | wall=1.77s | calls=115483 (of them =100: 2)
#>   send         0.00..1.18s: 115483 calls, longest silence 0.24s, trace 0.00:100.0 0.42:28.7 0.50:37.6 0.75:52.8 0.99:100.0
#>   10 further reads with no calls, 0.59s in all
#> 
#> join: SELECT t.k, x, y FROM t JOIN u ON t.k = u.k WHERE x < 0.01
#> 
#> ## join | get | threads=1 | rows=399,630 | wall=0.54s | calls=590 (of them =100: 2)
#>   dbGetQuery   0.00..0.54s: 590 calls, longest silence 0.01s, trace 0.00:100.0 0.25:33.8 0.50:66.9 0.53:100.0
#> 
#> ## join | arrow | threads=1 | rows=399,630 | wall=0.45s | calls=591 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s, trace 0.00:100.0
#>   read 1       0.00..0.45s: 590 calls, longest silence 0.01s, trace 0.00:0.0 0.25:40.1 0.44:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | send | threads=1 | rows=399,630 | wall=0.45s | calls=590 (of them =100: 2)
#>   send         0.00..0.45s: 590 calls, longest silence 0.01s, trace 0.00:100.0 0.25:38.4 0.44:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | get | threads=4 | rows=399,630 | wall=0.29s | calls=397 (of them =100: 2)
#>   dbGetQuery   0.00..0.29s: 397 calls, longest silence 0.01s, trace 0.00:100.0 0.25:65.9 0.29:100.0
#> 
#> ## join | arrow | threads=4 | rows=399,630 | wall=0.35s | calls=49732 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s, trace 0.00:100.0
#>   read 1       0.00..0.35s: 49731 calls, longest silence 0.01s, trace 0.00:0.0 0.25:59.4 0.34:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | send | threads=4 | rows=399,630 | wall=0.35s | calls=4006 (of them =100: 2)
#>   send         0.00..0.35s: 4006 calls, longest silence 0.00s, trace 0.00:100.0 0.25:57.5 0.35:100.0
#>   1 further reads with no calls, 0.00s in all
```

``` r

dir <- tempfile("serve")
dir.create(dir)
parquet <- file.path(dir, "remote.parquet")
# One thread and a seed again, so that the remote file is the same every run.
invisible(dbExecute(con, "SET threads = 1"))
invisible(dbExecute(con, "SELECT setseed(0.43)"))
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
#> ## remote_only | get | threads=1 | rows=1 | wall=4.19s | calls=253 (of them =100: 2)
#>   dbGetQuery   0.00..4.19s: 253 calls, longest silence 0.06s, trace 0.06:100.0 0.32:0.0 0.56:10.0 0.82:10.0 1.07:20.1 1.31:20.1 1.56:30.1 1.82:40.1 2.07:40.1 2.31:50.2 2.56:55.3 2.82:60.2 3.07:70.2 3.31:70.2 3.58:80.3 3.82:90.3 4.06:90.3 4.19:100.0
#> 
#> ## remote_only | arrow | threads=1 | rows=1 | wall=4.19s | calls=253 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s, trace 0.06:100.0
#>   read 1       0.11..4.19s: 252 calls, longest silence 0.02s, trace 0.11:0.0 0.38:0.0 0.62:10.0 0.87:10.0 1.11:20.1 1.38:30.1 1.62:30.1 1.87:40.1 2.13:40.1 2.38:50.2 2.62:60.2 2.87:60.2 3.13:70.2 3.38:72.8 3.62:80.3 3.87:90.3 4.13:90.3 4.19:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_only | get | threads=4 | rows=1 | wall=2.97s | calls=265 (of them =100: 2)
#>   dbGetQuery   0.00..2.97s: 265 calls, longest silence 0.06s, trace 0.06:100.0 0.31:0.0 0.56:17.6 0.82:17.6 1.07:17.6 1.31:17.6 1.57:50.2 1.82:57.7 2.06:87.8 2.32:97.5 2.56:97.5 2.81:97.5 2.97:100.0
#> 
#> ## remote_only | arrow | threads=4 | rows=1 | wall=2.99s | calls=184 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s, trace 0.06:100.0
#>   read 1       0.11..2.99s: 183 calls, longest silence 0.02s, trace 0.11:0.0 0.38:0.0 0.62:15.1 0.87:15.1 1.13:15.1 1.37:15.1 1.63:50.2 1.88:55.2 2.12:75.3 2.37:75.3 2.63:75.3 2.87:75.3 2.99:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_heavy_expr: SELECT count(*) AS n FROM read_parquet('http://127.0.0.1:8919/remote.parquet') WHERE hash(repeat(i::VARCHAR, 40)) % 7 = 0
#> 
#> ## remote_heavy_expr | get | threads=1 | rows=1 | wall=2.37s | calls=144 (of them =100: 2)
#>   dbGetQuery   0.00..2.37s: 144 calls, longest silence 0.06s, trace 0.06:100.0 0.31:0.0 0.57:5.1 0.81:9.2 1.07:13.4 1.31:16.7 1.57:20.1 1.81:23.4 2.07:26.8 2.31:30.9 2.37:100.0
#> 
#> ## remote_heavy_expr | arrow | threads=1 | rows=1 | wall=2.37s | calls=143 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s, trace 0.06:100.0
#>   read 1       0.11..2.37s: 142 calls, longest silence 0.04s, trace 0.11:0.0 0.37:3.3 0.62:6.7 0.86:10.0 1.12:13.4 1.37:16.7 1.63:20.1 1.87:24.3 2.12:28.5 2.37:33.3 2.37:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_heavy_expr | get | threads=4 | rows=1 | wall=1.78s | calls=166 (of them =100: 2)
#>   dbGetQuery   0.00..1.78s: 166 calls, longest silence 0.06s, trace 0.06:100.0 0.32:0.0 0.57:5.0 0.82:5.0 1.06:5.0 1.32:5.0 1.57:19.5 1.78:100.0
#> 
#> ## remote_heavy_expr | arrow | threads=4 | rows=1 | wall=1.73s | calls=2186 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s, trace 0.06:100.0
#>   read 1       0.11..1.73s: 2185 calls, longest silence 0.03s, trace 0.11:0.0 0.36:5.9 0.62:5.9 0.87:5.9 1.13:5.9 1.37:14.3 1.62:32.1 1.73:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_join_columns: SELECT count(*) AS n, sum(k) AS sk, sum(z) AS s FROM read_parquet('http://127.0.0.1:8919/remote.parquet')
#> 
#> ## remote_join_columns | get | threads=1 | rows=1 | wall=6.72s | calls=380 (of them =100: 2)
#>   dbGetQuery   0.00..6.72s: 380 calls, longest silence 0.06s, trace 0.06:100.0 0.32:0.0 0.56:0.0 0.82:10.0 1.06:10.0 1.33:10.0 1.56:20.1 1.82:20.1 2.07:20.1 2.32:30.1 2.56:30.1 2.82:40.1 3.06:40.1 3.32:40.1 3.56:50.2 3.82:50.2 4.06:50.2 4.32:60.2 4.56:60.2 4.82:70.2 5.06:70.2 5.32:70.2 5.56:80.3 5.82:80.3 6.06:90.3 6.32:90.3 6.56:90.3 6.72:100.0
#> 
#> ## remote_join_columns | arrow | threads=1 | rows=1 | wall=6.72s | calls=380 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s, trace 0.06:100.0
#>   read 1       0.11..6.72s: 379 calls, longest silence 0.02s, trace 0.11:0.0 0.38:0.0 0.62:0.0 0.86:10.0 1.13:10.0 1.37:10.0 1.62:20.1 1.87:20.1 2.12:30.1 2.36:30.1 2.63:30.1 2.88:40.1 3.13:40.1 3.37:40.1 3.62:50.2 3.86:50.2 4.12:60.2 4.36:60.2 4.63:60.2 4.88:70.2 5.13:70.2 5.37:70.2 5.62:80.3 5.86:80.3 6.12:90.3 6.36:90.3 6.63:90.3 6.72:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_join_columns | get | threads=4 | rows=1 | wall=3.10s | calls=272 (of them =100: 2)
#>   dbGetQuery   0.00..3.10s: 272 calls, longest silence 0.06s, trace 0.06:100.0 0.31:0.0 0.56:0.0 0.82:15.1 1.06:15.1 1.32:15.1 1.57:15.1 1.81:47.7 2.07:55.2 2.31:55.2 2.57:87.8 2.83:95.3 3.07:97.5 3.09:100.0
#> 
#> ## remote_join_columns | arrow | threads=4 | rows=1 | wall=3.49s | calls=679 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s, trace 0.06:100.0
#>   read 1       0.11..3.49s: 678 calls, longest silence 0.02s, trace 0.11:0.0 0.38:0.0 0.62:0.0 0.88:15.1 1.12:15.1 1.37:15.1 1.63:15.1 1.88:52.7 2.12:55.2 2.38:55.2 2.62:87.8 2.88:90.3 3.13:95.0 3.37:95.0 3.48:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_build_local_probe: SELECT count(*) AS n, sum(x * z) AS s FROM t JOIN read_parquet('http://127.0.0.1:8919/remote.parquet') r ON t.k = r.k
#> 
#> ## remote_build_local_probe | get | threads=1 | rows=1 | wall=8.87s | calls=1151 (of them =100: 2)
#>   dbGetQuery   0.00..8.87s: 1151 calls, longest silence 0.18s, trace 0.06:100.0 0.32:0.0 0.56:0.0 0.81:0.7 1.07:0.7 1.31:0.7 1.57:1.4 1.81:1.4 2.06:1.4 2.31:2.1 2.57:2.1 2.81:2.8 3.07:2.8 3.32:2.8 3.57:3.5 3.81:3.5 4.06:3.5 4.31:4.1 4.58:4.1 4.81:4.8 5.06:4.8 5.32:4.8 5.56:5.5 5.82:5.5 6.06:5.7 6.31:6.2 6.56:6.2 6.92:6.9 7.06:10.9 7.31:19.8 7.56:30.1 7.81:39.7 8.06:48.7 8.31:54.2 8.56:64.1 8.81:73.5 8.87:100.0
#> 
#> ## remote_build_local_probe | arrow | threads=1 | rows=1 | wall=8.90s | calls=1152 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s, trace 0.06:100.0
#>   read 1       0.11..8.90s: 1151 calls, longest silence 0.20s, trace 0.11:0.0 0.38:0.0 0.62:0.0 0.87:0.7 1.13:0.7 1.37:0.7 1.63:1.4 1.88:1.4 2.11:2.1 2.38:2.1 2.62:2.1 2.88:2.8 3.12:2.8 3.38:2.8 3.63:3.5 3.87:3.5 4.12:4.1 4.36:4.1 4.63:4.1 4.88:4.8 5.13:4.8 5.37:4.8 5.62:5.5 5.87:5.5 6.12:6.2 6.36:6.2 6.63:6.2 6.94:6.9 7.12:11.4 7.37:19.4 7.61:29.2 7.87:38.8 8.12:48.2 8.37:57.8 8.62:65.6 8.87:74.7 8.90:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_build_local_probe | get | threads=4 | rows=1 | wall=3.63s | calls=3872 (of them =100: 2)
#>   dbGetQuery   0.00..3.63s: 3872 calls, longest silence 0.06s, trace 0.06:100.0 0.32:0.0 0.56:0.0 0.82:1.0 1.07:1.0 1.31:1.0 1.57:1.0 1.81:3.8 2.08:3.8 2.32:3.8 2.56:6.6 2.82:6.6 3.06:6.7 3.31:23.1 3.56:64.9 3.62:100.0
#> 
#> ## remote_build_local_probe | arrow | threads=4 | rows=1 | wall=3.63s | calls=2803 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s, trace 0.06:100.0
#>   read 1       0.11..3.63s: 2802 calls, longest silence 0.02s, trace 0.11:0.0 0.38:0.0 0.62:0.0 0.87:1.0 1.13:1.0 1.38:1.0 1.62:1.0 1.87:3.6 2.13:3.8 2.37:3.8 2.63:6.4 2.87:6.6 3.12:6.7 3.36:30.1 3.62:73.4 3.63:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_then_sort: SELECT k, sum(z) AS s FROM read_parquet('http://127.0.0.1:8919/remote.parquet') GROUP BY k ORDER BY s
#> 
#> ## remote_then_sort | get | threads=1 | rows=2,754,617 | wall=7.44s | calls=423 (of them =100: 2)
#>   dbGetQuery   0.00..7.44s: 423 calls, longest silence 0.28s, trace 0.06:100.0 0.31:0.0 0.56:0.0 0.82:4.4 1.06:4.4 1.31:4.4 1.56:8.9 1.82:8.9 2.06:8.9 2.33:13.3 2.57:13.3 2.81:16.6 3.07:17.7 3.31:17.7 3.57:22.2 3.81:22.2 4.06:22.2 4.32:26.6 4.56:26.6 4.82:26.6 5.07:31.0 5.31:31.0 5.57:35.5 5.82:35.5 6.06:35.5 6.31:39.9 6.57:39.9 6.82:39.9 7.31:72.1 7.41:100.0
#> 
#> ## remote_then_sort | arrow | threads=1 | rows=2,754,617 | wall=7.35s | calls=425 (of them =100: 2)
#>   open         0.00..0.12s: 1 calls, longest silence 0.06s, trace 0.06:100.0
#>   read 1       0.12..7.30s: 407 calls, longest silence 0.25s, trace 0.12:0.0 0.38:0.0 0.63:0.0 0.87:4.4 1.14:4.4 1.38:4.4 1.62:8.9 1.88:8.9 2.12:10.0 2.39:13.3 2.63:13.3 2.87:17.7 3.14:17.7 3.38:17.7 3.63:22.2 3.87:22.2 4.14:22.2 4.38:26.6 4.62:26.6 4.89:31.0 5.13:31.0 5.37:31.0 5.63:35.5 5.87:35.5 6.12:35.5 6.37:39.9 6.64:39.9 6.88:42.1 7.24:72.1 7.30:88.8
#>   read 2       7.30..7.34s: 12 calls, longest silence 0.01s, trace 7.31:89.8 7.34:98.8
#>   read 3       7.34..7.35s: 5 calls, longest silence 0.01s, trace 7.35:99.8 7.35:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_then_sort | get | threads=4 | rows=2,754,617 | wall=3.46s | calls=21198 (of them =100: 2)
#>   dbGetQuery   0.00..3.46s: 21198 calls, longest silence 0.07s, trace 0.06:100.0 0.31:0.0 0.56:0.0 0.81:6.6 1.07:6.6 1.31:6.6 1.58:6.6 1.81:10.2 2.07:24.4 2.31:24.4 2.57:42.1 2.81:42.1 3.08:43.1 3.31:75.8 3.42:100.0
#> 
#> ## remote_then_sort | arrow | threads=4 | rows=2,754,617 | wall=3.45s | calls=11678 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s, trace 0.06:100.0
#>   read 1       0.11..3.38s: 11659 calls, longest silence 0.08s, trace 0.11:0.0 0.38:0.0 0.62:0.0 0.87:6.6 1.13:6.6 1.37:6.6 1.62:6.6 1.87:21.1 2.12:24.4 2.36:24.4 2.63:38.8 2.88:42.1 3.13:46.8 3.37:84.3 3.38:86.6
#>   read 2       3.38..3.43s: 12 calls, longest silence 0.01s, trace 3.38:87.7 3.42:96.7
#>   read 3       3.43..3.45s: 6 calls, longest silence 0.01s, trace 3.43:97.7 3.44:100.0
#>   1 further reads with no calls, 0.00s in all
```

``` r

# The first 10,000,000 rows of t, the table finish.R streams.
invisible(dbExecute(
  con,
  "CREATE TABLE s AS SELECT i, x FROM t WHERE i < 10000000"
))
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
    "SELECT i, x FROM s WHERE i % 2 = 0",
    4L,
    chunk = 1e5
  )
}
#> 
#> max_streaming_buffer_size = 976KiB 
#> 
#> ## buffer_976KiB | arrow | threads=4 | rows=5,000,000 | wall=0.15s | calls=3451 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s, trace 0.00:100.0
#>   read 1       0.00..0.01s: 2263 calls, longest silence 0.00s, trace 0.00:0.0 0.01:1.8
#>   read 2       0.01..0.02s: 3 calls, longest silence 0.00s, trace 0.02:2.3 0.02:3.1
#>   read 3       0.02..0.02s: 350 calls, longest silence 0.00s, trace 0.02:3.1 0.02:4.8
#>   read 4       0.02..0.02s: 3 calls, longest silence 0.00s, trace 0.02:5.3 0.02:6.1
#>   read 5       0.02..0.03s: 3 calls, longest silence 0.00s, trace 0.03:6.5 0.03:7.4
#>   read 6       0.03..0.03s: 3 calls, longest silence 0.00s, trace 0.03:7.8 0.03:8.7
#>   read 7       0.03..0.03s: 3 calls, longest silence 0.00s, trace 0.03:9.1 0.03:9.9
#>   read 8       0.03..0.04s: 3 calls, longest silence 0.00s, trace 0.03:10.3 0.04:11.2
#>   read 9       0.04..0.04s: 3 calls, longest silence 0.00s, trace 0.04:11.6 0.04:12.5
#>   read 10      0.04..0.04s: 4 calls, longest silence 0.00s, trace 0.04:12.9 0.04:14.2
#>   read 11      0.04..0.05s: 3 calls, longest silence 0.00s, trace 0.04:14.6 0.05:15.4
#>   read 12      0.05..0.05s: 3 calls, longest silence 0.00s, trace 0.05:15.9 0.05:16.7
#>   read 13      0.05..0.05s: 402 calls, longest silence 0.00s, trace 0.05:16.7 0.05:18.2
#>   read 14      0.05..0.06s: 3 calls, longest silence 0.00s, trace 0.05:18.6 0.06:19.5
#>   read 15      0.06..0.06s: 3 calls, longest silence 0.00s, trace 0.06:19.9 0.06:20.7
#>   read 16      0.06..0.06s: 3 calls, longest silence 0.00s, trace 0.06:21.1 0.06:22.0
#>   read 17      0.06..0.06s: 3 calls, longest silence 0.00s, trace 0.06:22.4 0.06:23.3
#>   read 18      0.06..0.07s: 3 calls, longest silence 0.00s, trace 0.06:23.7 0.07:24.5
#>   read 19      0.07..0.07s: 3 calls, longest silence 0.00s, trace 0.07:25.0 0.07:25.8
#>   read 20      0.07..0.07s: 133 calls, longest silence 0.00s, trace 0.07:26.2 0.07:27.5
#>   read 21      0.07..0.08s: 3 calls, longest silence 0.00s, trace 0.07:27.9 0.08:28.8
#>   read 22      0.08..0.08s: 3 calls, longest silence 0.00s, trace 0.08:29.2 0.08:30.1
#>   read 23      0.08..0.08s: 3 calls, longest silence 0.00s, trace 0.08:30.5 0.08:31.3
#>   read 24      0.08..0.08s: 3 calls, longest silence 0.00s, trace 0.08:31.8 0.08:32.6
#>   read 25      0.08..0.09s: 3 calls, longest silence 0.00s, trace 0.09:33.0 0.09:33.9
#>   read 26      0.09..0.09s: 3 calls, longest silence 0.00s, trace 0.09:34.3 0.09:35.1
#>   read 27      0.09..0.09s: 4 calls, longest silence 0.00s, trace 0.09:35.6 0.09:36.8
#>   read 28      0.09..0.10s: 3 calls, longest silence 0.00s, trace 0.09:37.3 0.10:38.1
#>   read 29      0.10..0.10s: 3 calls, longest silence 0.00s, trace 0.10:38.5 0.10:39.4
#>   read 30      0.10..0.10s: 161 calls, longest silence 0.00s, trace 0.10:39.8 0.10:40.7
#>   read 31      0.10..0.10s: 3 calls, longest silence 0.00s, trace 0.10:41.1 0.10:41.9
#>   read 32      0.10..0.11s: 3 calls, longest silence 0.00s, trace 0.10:42.4 0.11:43.2
#>   read 33      0.11..0.11s: 3 calls, longest silence 0.00s, trace 0.11:43.6 0.11:44.5
#>   read 34      0.11..0.11s: 4 calls, longest silence 0.00s, trace 0.11:44.9 0.11:46.2
#>   read 35      0.11..0.11s: 3 calls, longest silence 0.00s, trace 0.11:46.6 0.11:47.4
#>   read 36      0.11..0.12s: 3 calls, longest silence 0.00s, trace 0.11:47.9 0.12:48.7
#>   read 37      0.12..0.12s: 3 calls, longest silence 0.00s, trace 0.12:49.1 0.12:50.0
#>   read 38      0.12..0.12s: 3 calls, longest silence 0.00s, trace 0.12:50.4 0.12:51.3
#>   read 39      0.12..0.12s: 3 calls, longest silence 0.00s, trace 0.12:51.7 0.12:52.5
#>   read 40      0.12..0.13s: 3 calls, longest silence 0.00s, trace 0.12:52.9 0.13:53.8
#>   read 41      0.13..0.13s: 4 calls, longest silence 0.00s, trace 0.13:54.2 0.13:55.5
#>   read 42      0.13..0.13s: 3 calls, longest silence 0.00s, trace 0.13:55.9 0.13:56.8
#>   read 43      0.13..0.13s: 3 calls, longest silence 0.00s, trace 0.13:57.2 0.13:58.0
#>   read 44      0.13..0.14s: 3 calls, longest silence 0.00s, trace 0.13:58.4 0.14:59.3
#>   read 45      0.14..0.14s: 3 calls, longest silence 0.00s, trace 0.14:59.7 0.14:60.6
#>   read 46      0.14..0.14s: 3 calls, longest silence 0.00s, trace 0.14:61.0 0.14:61.8
#>   read 47      0.14..0.14s: 3 calls, longest silence 0.00s, trace 0.14:62.3 0.14:63.1
#>   read 48      0.14..0.15s: 4 calls, longest silence 0.00s, trace 0.14:63.5 0.15:64.8
#>   read 49      0.15..0.15s: 3 calls, longest silence 0.00s, trace 0.15:65.2 0.15:66.1
#>   read 50      0.15..0.15s: 4 calls, longest silence 0.00s, trace 0.15:66.5 0.15:100.0
#>   1 further reads with no calls, 0.00s in all
#> 
#> max_streaming_buffer_size = 10MiB 
#> 
#> ## buffer_10MiB | arrow | threads=4 | rows=5,000,000 | wall=0.14s | calls=3726 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s, trace 0.00:100.0
#>   read 1       0.00..0.02s: 3630 calls, longest silence 0.00s, trace 0.00:0.0 0.02:10.1
#>   read 5       0.02..0.03s: 7 calls, longest silence 0.00s, trace 0.02:10.8 0.03:14.5
#>   read 8       0.03..0.04s: 7 calls, longest silence 0.00s, trace 0.03:15.1 0.04:18.9
#>   read 11      0.04..0.04s: 7 calls, longest silence 0.00s, trace 0.04:19.5 0.04:23.2
#>   read 15      0.05..0.05s: 7 calls, longest silence 0.00s, trace 0.05:23.9 0.05:27.6
#>   read 18      0.06..0.06s: 7 calls, longest silence 0.00s, trace 0.06:28.3 0.06:32.0
#>   read 21      0.06..0.07s: 7 calls, longest silence 0.00s, trace 0.07:32.7 0.07:36.4
#>   read 25      0.07..0.08s: 7 calls, longest silence 0.00s, trace 0.07:37.1 0.08:40.8
#>   read 28      0.08..0.09s: 7 calls, longest silence 0.00s, trace 0.08:41.4 0.09:45.2
#>   read 31      0.09..0.10s: 7 calls, longest silence 0.00s, trace 0.09:45.8 0.10:49.5
#>   read 34      0.10..0.11s: 7 calls, longest silence 0.00s, trace 0.10:50.2 0.11:53.9
#>   read 38      0.11..0.12s: 7 calls, longest silence 0.00s, trace 0.11:54.6 0.12:58.3
#>   read 41      0.12..0.12s: 7 calls, longest silence 0.00s, trace 0.12:59.0 0.12:62.7
#>   read 44      0.13..0.13s: 11 calls, longest silence 0.00s, trace 0.13:63.4 0.13:100.0
#>   37 further reads with no calls, 0.03s in all
#> 
#> max_streaming_buffer_size = 1GiB 
#> 
#> ## buffer_1GiB | arrow | threads=4 | rows=5,000,000 | wall=0.17s | calls=27922 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s, trace 0.00:100.0
#>   read 1       0.00..0.14s: 27921 calls, longest silence 0.00s, trace 0.00:0.0 0.14:100.0
#>   50 further reads with no calls, 0.03s in all
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
