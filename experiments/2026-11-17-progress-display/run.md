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
    edges <- c(span[1], t[sel], span[2])
    gaps <- diff(edges)
    g <- which.max(gaps)
    cat(sprintf(
      "  %-12s %s..%ss: %d calls, longest silence %ss (%s..%ss), trace %s\n",
      rec$phases[i],
      fmt(span[1]),
      fmt(span[2]),
      length(sel),
      fmt(gaps[g]),
      fmt(edges[g]),
      fmt(edges[g + 1]),
      paste0(
        fmt(t[keep]),
        ":",
        formatC(v[keep], format = "f", digits = 1),
        collapse = " "
      )
    ))
    # The highest value below 100 and the largest rise between two calls.
    below <- sel[v[sel] < 100]
    if (length(below) > 0) {
      top <- below[which.max(v[below])]
      rise <- if (length(below) > 1) which.max(diff(v[below])) else NA
      cat(sprintf(
        "  %-12s highest below 100: %s at %ss%s\n",
        "",
        sprintf("%.7g", v[top]),
        fmt(t[top]),
        if (is.na(rise)) {
          ""
        } else {
          sprintf(
            ", largest rise %s to %s at %ss",
            sprintf("%.7g", v[below[rise]]),
            sprintf("%.7g", v[below[rise + 1]]),
            fmt(t[below[rise + 1]])
          )
        }
      ))
    }
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
#> date:       2026-11-17 19:21 UTC
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
#> ## scan_filter | get | threads=1 | rows=398,634 | wall=2.77s | calls=395 (of them =100: 2)
#>   dbGetQuery   0.00..2.77s: 395 calls, longest silence 0.01s (1.79..1.80s), trace 0.00:100.0 0.26:4.4 0.51:8.6 0.76:13.0 1.01:18.0 1.26:23.5 1.50:29.0 1.76:33.5 2.00:37.4 2.25:41.7 2.51:46.2 2.76:50.0 2.76:100.0
#>                highest below 100: 50 at 2.76s, largest rise 40.70912 to 40.83968 at 2.20s
#> 
#> ## scan_filter | arrow | threads=1 | rows=398,634 | wall=2.90s | calls=396 (of them =100: 2)
#>   open         0.00..0.01s: 1 calls, longest silence 0.01s (0.00..0.01s), trace 0.01:100.0
#>   read 1       0.01..2.90s: 395 calls, longest silence 0.03s (2.87..2.90s), trace 0.02:0.0 0.27:4.4 0.52:8.5 0.77:12.8 1.02:17.3 1.28:22.1 1.52:26.6 1.77:30.7 2.02:35.1 2.27:39.4 2.52:43.8 2.77:48.3 2.87:100.0
#>                highest below 100: 50 at 2.87s, largest rise 40.70912 to 40.83968 at 2.35s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | send | threads=1 | rows=398,634 | wall=2.67s | calls=395 (of them =100: 2)
#>   send         0.00..2.67s: 395 calls, longest silence 0.02s (0.62..0.63s), trace 0.00:100.0 0.25:4.4 0.51:8.9 0.75:13.0 1.01:17.3 1.25:22.2 1.51:27.6 1.76:33.1 2.01:38.0 2.26:42.6 2.51:47.1 2.66:100.0
#>                highest below 100: 50 at 2.66s, largest rise 40.70912 to 40.83968 at 2.16s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | get | threads=4 | rows=398,634 | wall=2.75s | calls=548317 (of them =100: 2)
#>   dbGetQuery   0.00..2.75s: 548317 calls, longest silence 0.00s (2.75..2.75s), trace 0.00:100.0 0.25:4.5 0.50:9.1 0.75:13.5 1.00:19.0 1.25:23.7 1.50:28.1 1.75:32.4 2.00:36.9 2.25:41.5 2.50:46.0 2.75:100.0
#>                highest below 100: 50 at 2.75s, largest rise 25.08032 to 25.15456 at 1.34s
#> 
#> ## scan_filter | arrow | threads=4 | rows=398,634 | wall=2.91s | calls=565910 (of them =100: 2)
#>   open         0.00..0.02s: 1 calls, longest silence 0.01s (0.00..0.02s), trace 0.00:100.0
#>   read 1       0.02..2.91s: 565909 calls, longest silence 0.02s (2.89..2.91s), trace 0.02:0.1 0.27:4.3 0.52:8.1 0.77:11.9 1.02:15.9 1.27:20.6 1.52:24.6 1.77:29.0 2.02:33.0 2.27:37.3 2.52:41.8 2.77:47.3 2.89:100.0
#>                highest below 100: 50 at 2.89s, largest rise 45.53728 to 45.63968 at 2.69s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## scan_filter | send | threads=4 | rows=398,634 | wall=2.44s | calls=512438 (of them =100: 2)
#>   send         0.00..2.44s: 512438 calls, longest silence 0.00s (2.44..2.44s), trace 0.00:100.0 0.25:3.8 0.50:7.5 0.75:12.5 1.00:18.1 1.25:23.6 1.50:28.9 1.75:34.4 2.00:40.0 2.25:45.7 2.44:100.0
#>                highest below 100: 49.9584 at 2.44s, largest rise 44.66176 to 44.75392 at 2.21s
#>   1 further reads with no calls, 0.00s in all
#> 
#> group_by: SELECT k, sum(x) AS s, count(*) AS n FROM t GROUP BY k
#> 
#> ## group_by | get | threads=1 | rows=9,817,025 | wall=4.06s | calls=493 (of them =100: 2)
#>   dbGetQuery   0.00..4.06s: 493 calls, longest silence 0.28s (3.77..4.06s), trace 0.00:100.0 0.25:5.6 0.51:9.7 0.76:15.3 1.01:16.1 1.25:22.1 1.51:28.2 1.76:34.0 2.00:39.9 2.26:46.1 2.51:52.3 2.75:58.2 3.01:64.0 3.25:69.7 3.50:75.3 3.75:98.9 3.77:100.0
#>                highest below 100: 100 at 3.77s, largest rise 78.3815 to 92.79383 at 3.65s
#> 
#> ## group_by | arrow | threads=1 | rows=9,817,025 | wall=3.84s | calls=532 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s (0.00..0.00s), trace 0.00:100.0
#>   read 1       0.00..3.69s: 412 calls, longest silence 0.20s (0.83..1.03s), trace 0.00:0.0 0.26:5.8 0.51:9.5 0.76:14.5 1.03:16.1 1.26:21.5 1.50:28.0 1.76:34.4 2.01:41.5 2.26:48.3 2.51:54.0 2.76:60.0 3.01:64.8 3.26:69.9 3.51:74.5 3.69:93.8
#>                highest below 100: 93.75897 at 3.69s, largest rise 78.3815 to 92.79383 at 3.66s
#>   read 2       3.69..3.71s: 15 calls, longest silence 0.00s (3.70..3.71s), trace 3.69:93.8 3.71:94.6
#>                highest below 100: 94.56325 at 3.71s, largest rise 94.15585 to 94.23252 at 3.70s
#>   read 3       3.71..3.72s: 12 calls, longest silence 0.00s (3.71..3.71s), trace 3.71:94.6 3.72:95.2
#>                highest below 100: 95.20668 at 3.72s, largest rise 94.79927 to 94.87594 at 3.71s
#>   read 4       3.72..3.75s: 15 calls, longest silence 0.01s (3.74..3.74s), trace 3.72:95.3 3.75:96.0
#>                highest below 100: 96.01096 at 3.75s, largest rise 95.4427 to 95.51937 at 3.73s
#>   read 5       3.75..3.76s: 12 calls, longest silence 0.00s (3.75..3.76s), trace 3.75:96.1 3.76:96.7
#>                highest below 100: 96.65438 at 3.76s, largest rise 96.56869 to 96.64536 at 3.76s
#>   read 6       3.76..3.78s: 15 calls, longest silence 0.00s (3.77..3.77s), trace 3.76:96.7 3.78:97.5
#>                highest below 100: 97.45867 at 3.78s, largest rise 96.89041 to 96.96708 at 3.77s
#>   read 7       3.78..3.79s: 12 calls, longest silence 0.00s (3.79..3.79s), trace 3.78:97.5 3.79:98.1
#>                highest below 100: 98.10209 at 3.79s, largest rise 97.53383 to 97.6105 at 3.78s
#>   read 8       3.79..3.81s: 15 calls, longest silence 0.00s (3.80..3.80s), trace 3.79:98.2 3.81:98.9
#>                highest below 100: 98.90637 at 3.81s, largest rise 98.49897 to 98.57564 at 3.80s
#>   read 9       3.81..3.83s: 15 calls, longest silence 0.00s (3.82..3.82s), trace 3.81:99.0 3.83:99.7
#>                highest below 100: 99.71065 at 3.83s, largest rise 98.98154 to 99.05821 at 3.81s
#>   read 10      3.83..3.84s: 8 calls, longest silence 0.00s (3.83..3.83s), trace 3.83:99.8 3.84:100.0
#>                highest below 100: 100 at 3.84s, largest rise 99.78582 to 99.86249 at 3.83s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## group_by | send | threads=1 | rows=9,817,025 | wall=4.52s | calls=493 (of them =100: 2)
#>   send         0.00..4.14s: 493 calls, longest silence 0.23s (3.91..4.14s), trace 0.00:100.0 0.25:5.4 0.51:9.3 0.75:14.1 1.02:16.1 1.26:21.3 1.51:26.2 1.76:31.4 2.01:37.0 2.26:42.5 2.51:48.5 2.76:54.4 3.00:60.2 3.26:66.4 3.51:72.1 3.76:77.9 3.91:100.0
#>                highest below 100: 100 at 3.91s, largest rise 78.3815 to 92.79383 at 3.78s
#>   10 further reads with no calls, 0.38s in all
#> 
#> ## group_by | get | threads=4 | rows=9,817,025 | wall=2.41s | calls=300983 (of them =100: 2)
#>   dbGetQuery   0.00..2.41s: 300983 calls, longest silence 0.27s (2.14..2.41s), trace 0.00:100.0 0.25:42.1 0.50:78.9 0.75:83.1 1.00:86.9 1.25:89.0 1.50:92.2 1.75:95.3 2.00:98.3 2.14:100.0
#>                highest below 100: 100 at 2.14s, largest rise 65.86354 to 66.76248 at 0.40s
#> 
#> ## group_by | arrow | threads=4 | rows=9,817,025 | wall=2.38s | calls=12324 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s (0.00..0.00s), trace 0.00:100.0
#>   read 1       0.00..0.87s: 12201 calls, longest silence 0.05s (0.58..0.63s), trace 0.00:0.0 0.26:31.8 0.51:78.1 0.76:80.4 0.87:81.4
#>                highest below 100: 81.36787 at 0.87s, largest rise 30.71652 to 31.78803 at 0.26s
#>   read 2       0.87..1.10s: 15 calls, longest silence 0.04s (0.90..0.94s), trace 0.89:81.6 1.10:83.7
#>                highest below 100: 83.74918 at 1.10s, largest rise 82.93796 to 83.23857 at 1.05s
#>   read 3       1.10..1.29s: 12 calls, longest silence 0.03s (1.24..1.27s), trace 1.12:83.9 1.28:85.6
#>                highest below 100: 85.62965 at 1.28s, largest rise 85.13044 to 85.42906 at 1.27s
#>   read 4       1.29..1.52s: 15 calls, longest silence 0.03s (1.35..1.38s), trace 1.32:85.9 1.52:88.1
#>                highest below 100: 88.12256 at 1.52s, largest rise 86.81334 to 87.11379 at 1.43s
#>   read 5       1.52..1.67s: 12 calls, longest silence 0.03s (1.55..1.58s), trace 1.54:88.3 1.67:90.0
#>                highest below 100: 90.00289 at 1.67s, largest rise 89.69207 to 89.99236 at 1.67s
#>   read 6       1.67..1.85s: 15 calls, longest silence 0.03s (1.81..1.84s), trace 1.68:90.2 1.85:92.4
#>                highest below 100: 92.38092 at 1.85s, largest rise 90.18999 to 90.48995 at 1.71s
#>   read 7       1.85..2.03s: 15 calls, longest silence 0.02s (1.87..1.89s), trace 1.87:92.6 2.03:94.8
#>                highest below 100: 94.75581 at 2.03s, largest rise 93.06578 to 93.36588 at 1.93s
#>   read 8       2.03..2.17s: 12 calls, longest silence 0.03s (2.03..2.06s), trace 2.06:95.1 2.17:96.7
#>                highest below 100: 96.74654 at 2.17s, largest rise 95.43985 to 95.74081 at 2.10s
#>   read 9       2.17..2.31s: 15 calls, longest silence 0.02s (2.22..2.24s), trace 2.18:96.9 2.31:99.1
#>                highest below 100: 99.12341 at 2.31s, largest rise 98.81252 to 99.11288 at 2.31s
#>   read 10      2.31..2.38s: 11 calls, longest silence 0.02s (2.33..2.35s), trace 2.33:99.3 2.37:100.0
#>                highest below 100: 100 at 2.37s, largest rise 99.31019 to 99.61035 at 2.35s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## group_by | send | threads=4 | rows=9,817,025 | wall=2.97s | calls=286 (of them =100: 2)
#>   send         0.00..2.43s: 286 calls, longest silence 0.48s (1.95..2.43s), trace 0.00:100.0 0.25:57.3 0.52:80.5 0.75:83.9 1.00:87.0 1.25:90.5 1.50:94.1 1.75:97.5 1.95:100.0
#>                highest below 100: 100 at 1.95s, largest rise 50.73001 to 52.07843 at 0.23s
#>   10 further reads with no calls, 0.54s in all
#> 
#> order_by: SELECT i, x FROM t WHERE i % 4 = 0 ORDER BY x
#> 
#> ## order_by | get | threads=1 | rows=10,000,000 | wall=2.47s | calls=494 (of them =100: 2)
#>   dbGetQuery   0.00..2.47s: 494 calls, longest silence 1.11s (0.82..1.92s), trace 0.00:100.0 0.26:4.8 0.50:10.4 0.75:15.6 1.92:33.3 2.00:37.9 2.25:58.4 2.35:100.0
#>                highest below 100: 66.66667 at 2.35s, largest rise 16.65195 to 33.33333 at 1.92s
#> 
#> ## order_by | arrow | threads=1 | rows=10,000,000 | wall=2.11s | calls=520 (of them =100: 2)
#>   open         0.00..0.01s: 1 calls, longest silence 0.00s (0.00..0.00s), trace 0.00:100.0
#>   read 1       0.01..1.74s: 414 calls, longest silence 0.96s (0.71..1.67s), trace 0.01:0.0 0.26:6.3 0.51:12.2 1.67:33.3 1.74:38.8
#>                highest below 100: 38.82197 at 1.74s, largest rise 16.65195 to 33.33333 at 1.67s
#>   read 2       1.74..1.78s: 12 calls, longest silence 0.01s (1.77..1.77s), trace 1.74:39.2 1.78:42.1
#>                highest below 100: 42.11925 at 1.78s, largest rise 39.51147 to 39.85963 at 1.75s
#>   read 3       1.78..1.82s: 12 calls, longest silence 0.01s (1.78..1.79s), trace 1.79:42.5 1.82:45.4
#>                highest below 100: 45.41653 at 1.82s, largest rise 44.65877 to 45.00693 at 1.82s
#>   read 4       1.82..1.86s: 12 calls, longest silence 0.01s (1.82..1.83s), trace 1.83:45.8 1.86:48.7
#>                highest below 100: 48.71381 at 1.86s, largest rise 46.10603 to 46.45419 at 1.84s
#>   read 5       1.86..1.90s: 12 calls, longest silence 0.01s (1.89..1.90s), trace 1.87:49.1 1.90:52.0
#>                highest below 100: 52.01109 at 1.90s, largest rise 49.40331 to 49.75147 at 1.87s
#>   read 6       1.90..1.95s: 12 calls, longest silence 0.01s (1.93..1.94s), trace 1.91:52.4 1.95:55.3
#>                highest below 100: 55.30837 at 1.95s, largest rise 52.35243 to 52.70059 at 1.91s
#>   read 7       1.95..1.99s: 12 calls, longest silence 0.01s (1.96..1.97s), trace 1.95:55.6 1.99:58.6
#>                highest below 100: 58.60565 at 1.99s, largest rise 55.64971 to 55.99787 at 1.96s
#>   read 8       1.99..2.04s: 12 calls, longest silence 0.01s (2.01..2.02s), trace 2.00:58.9 2.04:61.9
#>                highest below 100: 61.90293 at 2.04s, largest rise 58.94699 to 59.29515 at 2.00s
#>   read 9       2.04..2.08s: 12 calls, longest silence 0.01s (2.05..2.06s), trace 2.04:62.2 2.08:65.2
#>                highest below 100: 65.20021 at 2.08s, largest rise 64.79061 to 65.13877 at 2.08s
#>   read 10      2.08..2.11s: 9 calls, longest silence 0.01s (2.10..2.10s), trace 2.09:65.5 2.11:100.0
#>                highest below 100: 66.66667 at 2.11s, largest rise 65.88971 to 66.23787 at 2.10s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## order_by | send | threads=1 | rows=10,000,000 | wall=2.32s | calls=494 (of them =100: 2)
#>   send         0.00..1.84s: 494 calls, longest silence 0.84s (0.60..1.44s), trace 0.00:100.0 0.25:6.6 0.50:14.0 1.44:33.3 1.50:39.9 1.75:100.0
#>                highest below 100: 66.66667 at 1.75s, largest rise 16.65195 to 33.33333 at 1.44s
#>   10 further reads with no calls, 0.48s in all
#> 
#> ## order_by | get | threads=4 | rows=10,000,000 | wall=1.09s | calls=217 (of them =100: 2)
#>   dbGetQuery   0.00..1.09s: 217 calls, longest silence 0.26s (0.22..0.48s), trace 0.00:100.0 0.48:33.3 0.51:34.7 0.75:51.1 1.00:100.0
#>                highest below 100: 66.66667 at 1.00s, largest rise 16.66667 to 33.33333 at 0.48s
#> 
#> ## order_by | arrow | threads=4 | rows=10,000,000 | wall=1.05s | calls=8149 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s (0.00..0.00s), trace 0.00:100.0
#>   read 1       0.00..0.49s: 8041 calls, longest silence 0.25s (0.16..0.41s), trace 0.00:0.0 0.41:33.3 0.49:38.0
#>                highest below 100: 38.00277 at 0.49s, largest rise 16.5376 to 33.33333 at 0.41s
#>   read 2       0.49..0.55s: 12 calls, longest silence 0.01s (0.53..0.53s), trace 0.50:38.3 0.54:41.3
#>                highest below 100: 41.30005 at 0.54s, largest rise 40.54229 to 40.89045 at 0.54s
#>   read 3       0.55..0.60s: 12 calls, longest silence 0.01s (0.58..0.59s), trace 0.55:41.6 0.60:44.6
#>                highest below 100: 44.59733 at 0.60s, largest rise 41.64139 to 41.98955 at 0.56s
#>   read 4       0.60..0.65s: 12 calls, longest silence 0.01s (0.63..0.64s), trace 0.61:44.9 0.65:47.9
#>                highest below 100: 47.89461 at 0.65s, largest rise 44.93867 to 45.28683 at 0.61s
#>   read 5       0.65..0.70s: 12 calls, longest silence 0.01s (0.68..0.69s), trace 0.66:48.2 0.70:51.2
#>                highest below 100: 51.19189 at 0.70s, largest rise 50.78229 to 51.13045 at 0.70s
#>   read 6       0.70..0.81s: 12 calls, longest silence 0.05s (0.73..0.78s), trace 0.71:51.5 0.81:54.5
#>                highest below 100: 54.48917 at 0.81s, largest rise 51.88139 to 52.22955 at 0.72s
#>   read 7       0.81..0.87s: 12 calls, longest silence 0.01s (0.83..0.84s), trace 0.82:54.8 0.87:57.8
#>                highest below 100: 57.78645 at 0.87s, largest rise 57.37685 to 57.72501 at 0.87s
#>   read 8       0.87..0.95s: 16 calls, longest silence 0.01s (0.93..0.94s), trace 0.88:58.1 0.95:62.2
#>                highest below 100: 62.18283 at 0.95s, largest rise 61.42507 to 61.77323 at 0.94s
#>   read 9       0.95..1.01s: 12 calls, longest silence 0.01s (0.95..0.96s), trace 0.96:62.5 1.01:65.5
#>                highest below 100: 65.48011 at 1.01s, largest rise 62.52416 to 62.87232 at 0.97s
#>   read 10      1.01..1.05s: 7 calls, longest silence 0.01s (1.01..1.03s), trace 1.03:65.8 1.05:100.0
#>                highest below 100: 66.66667 at 1.04s, largest rise 66.1696 to 66.51776 at 1.04s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## order_by | send | threads=4 | rows=10,000,000 | wall=1.58s | calls=11500 (of them =100: 2)
#>   send         0.00..1.05s: 11500 calls, longest silence 0.18s (0.19..0.37s), trace 0.00:100.0 0.37:20.1 0.50:39.3 0.75:57.0 0.89:100.0
#>                highest below 100: 66.66667 at 0.89s, largest rise 28.72533 to 33.33333 at 0.42s
#>   10 further reads with no calls, 0.53s in all
#> 
#> join: SELECT t.k, x, y FROM t JOIN u ON t.k = u.k WHERE x < 0.01
#> 
#> ## join | get | threads=1 | rows=399,630 | wall=0.47s | calls=590 (of them =100: 2)
#>   dbGetQuery   0.00..0.47s: 590 calls, longest silence 0.01s (0.20..0.22s), trace 0.00:100.0 0.25:37.6 0.47:100.0
#>                highest below 100: 100 at 0.47s, largest rise 71.89559 to 100 at 0.47s
#> 
#> ## join | arrow | threads=1 | rows=399,630 | wall=0.45s | calls=591 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s (0.00..0.00s), trace 0.00:100.0
#>   read 1       0.00..0.45s: 590 calls, longest silence 0.01s (0.43..0.45s), trace 0.00:0.0 0.25:40.8 0.43:100.0
#>                highest below 100: 100 at 0.43s, largest rise 71.89559 to 100 at 0.43s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | send | threads=1 | rows=399,630 | wall=0.44s | calls=590 (of them =100: 2)
#>   send         0.00..0.44s: 590 calls, longest silence 0.01s (0.19..0.20s), trace 0.00:100.0 0.25:40.1 0.44:100.0
#>                highest below 100: 100 at 0.44s, largest rise 71.89559 to 100 at 0.44s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | get | threads=4 | rows=399,630 | wall=0.42s | calls=5071 (of them =100: 2)
#>   dbGetQuery   0.00..0.42s: 5071 calls, longest silence 0.02s (0.14..0.16s), trace 0.00:100.0 0.25:53.9 0.41:100.0
#>                highest below 100: 100 at 0.41s, largest rise 71.89559 to 100 at 0.41s
#> 
#> ## join | arrow | threads=4 | rows=399,630 | wall=0.39s | calls=3730 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s (0.00..0.00s), trace 0.00:100.0
#>   read 1       0.01..0.39s: 3729 calls, longest silence 0.02s (0.37..0.39s), trace 0.01:0.0 0.26:55.8 0.37:100.0
#>                highest below 100: 100 at 0.37s, largest rise 71.89559 to 100 at 0.37s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## join | send | threads=4 | rows=399,630 | wall=0.39s | calls=363 (of them =100: 2)
#>   send         0.00..0.39s: 363 calls, longest silence 0.02s (0.06..0.08s), trace 0.00:100.0 0.25:53.1 0.38:100.0
#>                highest below 100: 100 at 0.38s, largest rise 71.89559 to 100 at 0.38s
#>   1 further reads with no calls, 0.00s in all

# The filtered scan's count alone, to compare its speed at one and four
# threads with the scan that returns its rows.
scan_count <- sub(
  "SELECT i, x",
  "SELECT count(*)",
  local_queries[["scan_filter"]]
)
cat("\nscan_filter_count: ", scan_count, "\n", sep = "")
#> 
#> scan_filter_count: SELECT count(*) FROM t WHERE hash(i::VARCHAR || 'salt') % 100 = 0
for (threads in c(1L, 4L)) {
  run(con, "scan_filter_count", "get", scan_count, threads)
}
#> 
#> ## scan_filter_count | get | threads=1 | rows=1 | wall=2.79s | calls=399 (of them =100: 2)
#>   dbGetQuery   0.00..2.79s: 399 calls, longest silence 0.03s (2.73..2.76s), trace 0.00:100.0 0.26:3.3 0.51:6.0 0.76:8.7 1.01:11.7 1.26:15.4 1.51:18.7 1.76:21.7 2.01:24.6 2.26:27.3 2.51:30.0 2.76:33.0 2.79:100.0
#>                highest below 100: 66.66667 at 2.79s, largest rise 33.33333 to 66.66667 at 2.79s
#> 
#> ## scan_filter_count | get | threads=4 | rows=1 | wall=0.68s | calls=302 (of them =100: 2)
#>   dbGetQuery   0.00..0.68s: 302 calls, longest silence 0.01s (0.02..0.03s), trace 0.01:100.0 0.26:13.0 0.51:25.5 0.67:100.0
#>                highest below 100: 66.66667 at 0.67s, largest rise 33.33333 to 66.66667 at 0.67s
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
#> ## remote_only | get | threads=1 | rows=1 | wall=4.20s | calls=256 (of them =100: 2)
#>   dbGetQuery   0.00..4.20s: 256 calls, longest silence 0.06s (0.00..0.06s), trace 0.06:100.0 0.31:0.0 0.56:10.0 0.82:10.0 1.07:20.1 1.31:20.1 1.56:30.1 1.82:40.1 2.06:40.1 2.32:50.2 2.56:52.7 2.81:60.2 3.07:70.2 3.32:70.2 3.56:80.3 3.81:90.3 4.07:90.3 4.20:100.0
#>                highest below 100: 99.99998 at 4.20s, largest rise 70.24636 to 72.80636 at 3.38s
#> 
#> ## remote_only | arrow | threads=1 | rows=1 | wall=4.20s | calls=255 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s (0.00..0.06s), trace 0.06:100.0
#>   read 1       0.11..4.20s: 254 calls, longest silence 0.02s (1.31..1.34s), trace 0.11:0.0 0.38:0.0 0.63:10.0 0.87:10.0 1.13:20.1 1.38:30.1 1.62:30.1 1.86:40.1 2.13:40.1 2.37:50.2 2.62:60.2 2.86:60.2 3.11:70.2 3.38:72.8 3.62:80.3 3.87:90.3 4.13:90.3 4.20:100.0
#>                highest below 100: 99.99998 at 4.20s, largest rise 70.24636 to 72.80636 at 3.38s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_only | get | threads=4 | rows=1 | wall=2.35s | calls=341 (of them =100: 2)
#>   dbGetQuery   0.00..2.35s: 341 calls, longest silence 0.06s (0.00..0.06s), trace 0.06:100.0 0.32:0.0 0.56:15.1 0.83:15.1 1.07:15.1 1.31:15.1 1.56:47.7 1.81:55.2 2.07:87.8 2.31:97.5 2.35:100.0
#>                highest below 100: 99.99998 at 2.35s, largest rise 27.59679 to 47.66718 at 1.56s
#> 
#> ## remote_only | arrow | threads=4 | rows=1 | wall=2.34s | calls=255 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s (0.06..0.11s), trace 0.06:100.0
#>   read 1       0.11..2.34s: 254 calls, longest silence 0.02s (0.14..0.16s), trace 0.11:0.0 0.38:0.0 0.63:15.1 0.87:15.1 1.13:15.1 1.38:15.1 1.62:47.7 1.88:55.2 2.13:87.8 2.34:100.0
#>                highest below 100: 99.99998 at 2.34s, largest rise 17.61279 to 47.66718 at 1.54s
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_heavy_expr: SELECT count(*) AS n FROM read_parquet('http://127.0.0.1:8919/remote.parquet') WHERE hash(repeat(i::VARCHAR, 40)) % 7 = 0
#> 
#> ## remote_heavy_expr | get | threads=1 | rows=1 | wall=2.35s | calls=155 (of them =100: 2)
#>   dbGetQuery   0.00..2.35s: 155 calls, longest silence 0.06s (0.00..0.06s), trace 0.06:100.0 0.32:0.0 0.57:5.0 0.81:9.2 1.06:13.4 1.32:16.7 1.56:20.1 1.82:23.4 2.08:27.6 2.31:31.8 2.35:100.0
#>                highest below 100: 66.66667 at 2.35s, largest rise 33.33333 to 66.66667 at 2.35s
#> 
#> ## remote_heavy_expr | arrow | threads=1 | rows=1 | wall=2.36s | calls=152 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s (0.06..0.11s), trace 0.06:100.0
#>   read 1       0.11..2.36s: 151 calls, longest silence 0.04s (2.26..2.30s), trace 0.11:0.0 0.37:2.6 0.62:6.7 0.88:10.0 1.13:13.4 1.38:16.7 1.62:20.1 1.88:25.1 2.12:29.3 2.36:100.0
#>                highest below 100: 66.66667 at 2.36s, largest rise 33.33333 to 66.66667 at 2.36s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_heavy_expr | get | threads=4 | rows=1 | wall=1.74s | calls=203 (of them =100: 2)
#>   dbGetQuery   0.00..1.74s: 203 calls, longest silence 0.06s (0.06..0.11s), trace 0.06:100.0 0.34:2.4 0.57:6.7 0.81:6.7 1.07:6.7 1.32:6.7 1.57:21.2 1.74:100.0
#>                highest below 100: 66.66667 at 1.74s, largest rise 33.33333 to 66.66667 at 1.74s
#> 
#> ## remote_heavy_expr | arrow | threads=4 | rows=1 | wall=1.75s | calls=2148 (of them =100: 2)
#>   open         0.00..0.12s: 1 calls, longest silence 0.06s (0.00..0.06s), trace 0.06:100.0
#>   read 1       0.12..1.75s: 2147 calls, longest silence 0.05s (1.32..1.37s), trace 0.12:0.0 0.38:4.8 0.63:5.9 0.88:5.9 1.12:5.9 1.37:10.4 1.63:31.4 1.75:100.0
#>                highest below 100: 66.66667 at 1.75s, largest rise 33.33333 to 66.66667 at 1.75s
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_join_columns: SELECT count(*) AS n, sum(k) AS sk, sum(z) AS s FROM read_parquet('http://127.0.0.1:8919/remote.parquet')
#> 
#> ## remote_join_columns | get | threads=1 | rows=1 | wall=6.72s | calls=381 (of them =100: 2)
#>   dbGetQuery   0.00..6.72s: 381 calls, longest silence 0.06s (0.00..0.06s), trace 0.06:100.0 0.31:0.0 0.56:0.0 0.82:10.0 1.06:10.0 1.32:10.0 1.56:20.1 1.82:20.1 2.06:20.1 2.32:30.1 2.56:30.1 2.81:40.1 3.06:40.1 3.32:40.1 3.56:50.2 3.82:50.2 4.06:50.2 4.32:60.2 4.56:60.2 4.81:70.2 5.06:70.2 5.32:70.2 5.57:80.3 5.82:80.3 6.07:90.3 6.32:90.3 6.56:90.3 6.71:100.0
#>                highest below 100: 99.99998 at 6.71s, largest rise 70.24636 to 72.80636 at 5.39s
#> 
#> ## remote_join_columns | arrow | threads=1 | rows=1 | wall=6.72s | calls=379 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s (0.06..0.11s), trace 0.06:100.0
#>   read 1       0.11..6.72s: 378 calls, longest silence 0.03s (2.73..2.76s), trace 0.11:0.0 0.38:0.0 0.62:0.0 0.88:10.0 1.12:10.0 1.36:10.0 1.62:20.1 1.87:20.1 2.12:30.1 2.36:30.1 2.63:30.1 2.86:40.1 3.13:40.1 3.37:40.1 3.62:50.2 3.87:50.2 4.12:60.2 4.36:60.2 4.63:60.2 4.86:70.2 5.12:70.2 5.37:70.2 5.62:80.3 5.87:80.3 6.12:90.3 6.36:90.3 6.63:90.3 6.72:100.0
#>                highest below 100: 99.99998 at 6.72s, largest rise 70.24636 to 72.80636 at 5.40s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_join_columns | get | threads=4 | rows=1 | wall=3.00s | calls=640 (of them =100: 2)
#>   dbGetQuery   0.00..3.00s: 640 calls, longest silence 0.06s (0.06..0.11s), trace 0.06:100.0 0.32:0.0 0.56:0.0 0.82:17.6 1.06:17.6 1.32:17.6 1.57:17.6 1.81:57.7 2.08:57.7 2.32:57.7 2.58:97.8 2.82:97.8 3.00:100.0
#>                highest below 100: 99.99998 at 3.00s, largest rise 17.56159 to 37.68318 at 1.79s
#> 
#> ## remote_join_columns | arrow | threads=4 | rows=1 | wall=3.49s | calls=200 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s (0.06..0.11s), trace 0.06:100.0
#>   read 1       0.11..3.49s: 199 calls, longest silence 0.02s (1.26..1.29s), trace 0.11:0.0 0.38:0.0 0.62:0.0 0.88:15.1 1.12:15.1 1.37:15.1 1.63:15.1 1.88:55.2 2.12:55.2 2.37:55.2 2.63:80.3 2.87:80.3 3.13:80.3 3.38:80.3 3.49:100.0
#>                highest below 100: 99.99998 at 3.49s, largest rise 25.39519 to 47.66718 at 1.80s
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_build_local_probe: SELECT count(*) AS n, sum(x * z) AS s FROM t JOIN read_parquet('http://127.0.0.1:8919/remote.parquet') r ON t.k = r.k
#> 
#> ## remote_build_local_probe | get | threads=1 | rows=1 | wall=9.06s | calls=1157 (of them =100: 2)
#>   dbGetQuery   0.00..9.06s: 1157 calls, longest silence 0.17s (6.73..6.90s), trace 0.06:100.0 0.32:0.0 0.56:0.0 0.83:0.7 1.07:0.7 1.31:0.7 1.57:1.4 1.81:1.4 2.08:1.4 2.32:2.1 2.56:2.1 2.81:2.8 3.08:2.8 3.32:2.8 3.57:3.5 3.82:3.5 4.06:3.5 4.31:4.1 4.58:4.1 4.81:4.8 5.07:4.8 5.32:4.8 5.57:5.5 5.81:5.5 6.06:5.7 6.32:6.2 6.56:6.2 6.90:6.9 7.06:11.9 7.31:18.8 7.56:27.7 7.81:35.3 8.06:43.7 8.31:52.4 8.56:60.0 8.81:68.3 9.06:75.7 9.06:100.0
#>                highest below 100: 100 at 9.06s, largest rise 75.76722 to 100 at 9.06s
#> 
#> ## remote_build_local_probe | arrow | threads=1 | rows=1 | wall=8.81s | calls=1151 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s (0.06..0.11s), trace 0.06:100.0
#>   read 1       0.11..8.81s: 1150 calls, longest silence 0.19s (6.74..6.93s), trace 0.11:0.0 0.38:0.0 0.62:0.0 0.87:0.7 1.13:0.7 1.37:0.7 1.63:1.4 1.87:1.4 2.13:2.1 2.38:2.1 2.62:2.1 2.87:2.8 3.12:2.8 3.38:2.8 3.62:3.5 3.88:3.5 4.12:4.1 4.38:4.1 4.62:4.1 4.88:4.8 5.12:4.8 5.38:4.8 5.62:5.5 5.88:5.5 6.12:6.2 6.38:6.2 6.62:6.2 6.93:6.9 7.12:11.8 7.37:21.0 7.61:32.0 7.87:42.8 8.12:50.7 8.36:60.8 8.62:68.9 8.81:100.0
#>                highest below 100: 100 at 8.81s, largest rise 75.76722 to 100 at 8.81s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_build_local_probe | get | threads=4 | rows=1 | wall=3.72s | calls=4420 (of them =100: 2)
#>   dbGetQuery   0.00..3.72s: 4420 calls, longest silence 0.06s (0.06..0.11s), trace 0.06:100.0 0.32:0.0 0.56:0.0 0.82:1.0 1.06:1.0 1.32:1.0 1.56:1.0 1.81:2.0 2.07:3.3 2.31:3.3 2.56:5.5 2.81:5.5 3.07:6.0 3.31:16.2 3.56:52.7 3.72:100.0
#>                highest below 100: 100 at 3.72s, largest rise 75.76722 to 100 at 3.72s
#> 
#> ## remote_build_local_probe | arrow | threads=4 | rows=1 | wall=3.93s | calls=1252 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s (0.00..0.06s), trace 0.06:100.0
#>   read 1       0.11..3.93s: 1251 calls, longest silence 0.02s (3.33..3.35s), trace 0.11:0.0 0.38:0.0 0.62:0.0 0.87:1.2 1.13:1.2 1.37:1.2 1.62:1.2 1.87:4.0 2.12:4.0 2.36:4.0 2.62:6.2 2.86:6.2 3.13:6.4 3.37:6.4 3.61:19.3 3.86:65.1 3.93:100.0
#>                highest below 100: 100 at 3.93s, largest rise 75.76722 to 100 at 3.93s
#>   1 further reads with no calls, 0.00s in all
#> 
#> remote_then_sort: SELECT k, sum(z) AS s FROM read_parquet('http://127.0.0.1:8919/remote.parquet') GROUP BY k ORDER BY s
#> 
#> ## remote_then_sort | get | threads=1 | rows=2,754,617 | wall=7.26s | calls=427 (of them =100: 2)
#>   dbGetQuery   0.00..7.26s: 427 calls, longest silence 0.21s (6.93..7.14s), trace 0.06:100.0 0.31:0.0 0.56:0.0 0.81:4.4 1.06:4.4 1.32:4.4 1.57:8.9 1.81:8.9 2.06:8.9 2.32:13.3 2.56:13.3 2.82:16.7 3.07:17.7 3.31:17.7 3.57:22.2 3.81:22.2 4.08:22.2 4.31:26.6 4.56:26.6 4.82:27.7 5.06:31.0 5.32:31.0 5.56:35.5 5.82:35.5 6.07:35.5 6.31:39.9 6.58:39.9 6.83:41.0 7.14:72.1 7.22:100.0
#>                highest below 100: 99.99999 at 7.22s, largest rise 58.05785 to 72.08245 at 7.14s
#> 
#> ## remote_then_sort | arrow | threads=1 | rows=2,754,617 | wall=7.36s | calls=432 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s (0.06..0.11s), trace 0.06:100.0
#>   read 1       0.11..7.30s: 414 calls, longest silence 0.27s (6.97..7.24s), trace 0.11:0.0 0.38:0.0 0.62:0.0 0.88:4.4 1.12:4.4 1.37:4.4 1.62:8.9 1.88:8.9 2.12:11.1 2.38:13.3 2.63:13.3 2.87:17.7 3.13:17.7 3.37:17.7 3.62:22.2 3.88:22.2 4.12:22.2 4.37:26.6 4.63:26.6 4.87:31.0 5.13:31.0 5.38:31.0 5.63:35.5 5.87:35.5 6.12:35.5 6.37:39.9 6.63:39.9 6.87:43.3 7.24:72.1 7.30:88.8
#>                highest below 100: 88.77036 at 7.30s, largest rise 58.05785 to 72.08245 at 7.24s
#>   read 2       7.30..7.35s: 12 calls, longest silence 0.01s (7.30..7.31s), trace 7.31:89.8 7.35:98.8
#>                highest below 100: 98.79556 at 7.35s, largest rise 93.1499 to 94.20846 at 7.33s
#>   read 3       7.35..7.36s: 5 calls, longest silence 0.01s (7.35..7.35s), trace 7.35:99.8 7.35:100.0
#>                highest below 100: 99.99999 at 7.35s, largest rise 99.83336 to 99.99999 at 7.35s
#>   1 further reads with no calls, 0.00s in all
#> 
#> ## remote_then_sort | get | threads=4 | rows=2,754,617 | wall=3.44s | calls=26794 (of them =100: 2)
#>   dbGetQuery   0.00..3.44s: 26794 calls, longest silence 0.07s (3.19..3.26s), trace 0.06:100.0 0.31:0.0 0.56:0.0 0.82:6.6 1.07:6.6 1.31:6.6 1.57:6.6 1.81:20.1 2.07:24.4 2.31:24.4 2.56:39.9 2.82:42.1 3.07:43.1 3.31:75.8 3.41:100.0
#>                highest below 100: 99.99999 at 3.41s, largest rise 56.59256 to 64.22801 at 3.26s
#> 
#> ## remote_then_sort | arrow | threads=4 | rows=2,754,617 | wall=3.31s | calls=6417 (of them =100: 2)
#>   open         0.00..0.11s: 1 calls, longest silence 0.06s (0.06..0.11s), trace 0.06:100.0
#>   read 1       0.11..3.23s: 6397 calls, longest silence 0.08s (3.08..3.16s), trace 0.11:0.0 0.37:0.0 0.62:0.0 0.87:7.8 1.13:7.8 1.37:7.8 1.62:7.8 1.86:25.5 2.13:25.5 2.37:25.5 2.63:43.2 2.87:43.2 3.16:68.8 3.23:86.4
#>                highest below 100: 86.36265 at 3.23s, largest rise 25.48421 to 37.85321 at 2.48s
#>   read 2       3.23..3.28s: 12 calls, longest silence 0.01s (3.26..3.27s), trace 3.23:87.4 3.28:96.4
#>                highest below 100: 96.38785 at 3.28s, largest rise 94.08392 to 95.14248 at 3.28s
#>   read 3       3.28..3.31s: 7 calls, longest silence 0.01s (3.28..3.29s), trace 3.29:97.4 3.30:100.0
#>                highest below 100: 99.99999 at 3.30s, largest rise 97.42565 to 98.48422 at 3.30s
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
#> ## buffer_976KiB | arrow | threads=4 | rows=5,000,000 | wall=0.18s | calls=2340 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s (0.00..0.00s), trace 0.00:100.0
#>   read 1       0.00..0.01s: 539 calls, longest silence 0.00s (0.01..0.01s), trace 0.00:0.1 0.01:2.2
#>                highest below 100: 2.157227 at 0.01s, largest rise 2.08896 to 2.116267 at 0.01s
#>   read 2       0.01..0.01s: 3 calls, longest silence 0.00s (0.01..0.01s), trace 0.01:2.6 0.01:3.5
#>                highest below 100: 3.454293 at 0.01s, largest rise 2.607787 to 3.03104 at 0.01s
#>   read 3       0.01..0.01s: 3 calls, longest silence 0.00s (0.01..0.01s), trace 0.01:3.9 0.01:4.7
#>                highest below 100: 4.724053 at 0.01s, largest rise 4.3008 to 4.724053 at 0.01s
#>   read 4       0.01..0.02s: 3 calls, longest silence 0.00s (0.02..0.02s), trace 0.02:5.1 0.02:6.0
#>                highest below 100: 5.993813 at 0.02s, largest rise 5.57056 to 5.993813 at 0.02s
#>   read 5       0.02..0.02s: 3 calls, longest silence 0.00s (0.02..0.02s), trace 0.02:6.4 0.02:7.3
#>                highest below 100: 7.263573 at 0.02s, largest rise 6.417067 to 6.84032 at 0.02s
#>   read 6       0.02..0.02s: 3 calls, longest silence 0.00s (0.02..0.02s), trace 0.02:7.7 0.02:8.5
#>                highest below 100: 8.533333 at 0.02s, largest rise 7.686827 to 8.11008 at 0.02s
#>   read 7       0.02..0.03s: 3 calls, longest silence 0.00s (0.03..0.03s), trace 0.03:9.0 0.03:9.8
#>                highest below 100: 9.803093 at 0.03s, largest rise 8.956587 to 9.37984 at 0.03s
#>   read 8       0.03..0.03s: 4 calls, longest silence 0.00s (0.03..0.03s), trace 0.03:10.2 0.03:11.5
#>                highest below 100: 11.49611 at 0.03s, largest rise 10.6496 to 11.07285 at 0.03s
#>   read 9       0.03..0.04s: 3 calls, longest silence 0.00s (0.03..0.03s), trace 0.03:11.9 0.04:12.8
#>                highest below 100: 12.76587 at 0.04s, largest rise 12.34261 to 12.76587 at 0.04s
#>   read 10      0.04..0.04s: 3 calls, longest silence 0.00s (0.04..0.04s), trace 0.04:13.2 0.04:14.0
#>                highest below 100: 14.03563 at 0.04s, largest rise 13.61237 to 14.03563 at 0.04s
#>   read 11      0.04..0.04s: 3 calls, longest silence 0.00s (0.04..0.04s), trace 0.04:14.5 0.04:15.3
#>                highest below 100: 15.30539 at 0.04s, largest rise 14.45888 to 14.88213 at 0.04s
#>   read 12      0.04..0.04s: 3 calls, longest silence 0.00s (0.04..0.04s), trace 0.04:15.7 0.04:16.6
#>                highest below 100: 16.57515 at 0.04s, largest rise 15.72864 to 16.15189 at 0.04s
#>   read 13      0.05..0.05s: 3 calls, longest silence 0.00s (0.05..0.05s), trace 0.05:17.0 0.05:17.8
#>                highest below 100: 17.84491 at 0.05s, largest rise 16.9984 to 17.42165 at 0.05s
#>   read 14      0.05..0.05s: 3 calls, longest silence 0.00s (0.05..0.05s), trace 0.05:18.3 0.05:19.1
#>                highest below 100: 19.11467 at 0.05s, largest rise 18.26816 to 18.69141 at 0.05s
#>   read 15      0.05..0.06s: 4 calls, longest silence 0.00s (0.05..0.06s), trace 0.05:19.5 0.06:20.8
#>                highest below 100: 20.80768 at 0.06s, largest rise 19.53792 to 19.96117 at 0.06s
#>   read 16      0.06..0.06s: 3 calls, longest silence 0.00s (0.06..0.06s), trace 0.06:21.2 0.06:22.1
#>                highest below 100: 22.07744 at 0.06s, largest rise 21.65419 to 22.07744 at 0.06s
#>   read 17      0.06..0.07s: 3 calls, longest silence 0.00s (0.06..0.07s), trace 0.06:22.5 0.07:23.3
#>                highest below 100: 23.3472 at 0.07s, largest rise 22.50069 to 22.92395 at 0.06s
#>   read 18      0.07..0.07s: 3 calls, longest silence 0.00s (0.07..0.07s), trace 0.07:23.8 0.07:24.6
#>                highest below 100: 24.61696 at 0.07s, largest rise 23.77045 to 24.19371 at 0.07s
#>   read 19      0.07..0.07s: 3 calls, longest silence 0.00s (0.07..0.07s), trace 0.07:25.0 0.07:25.9
#>                highest below 100: 25.88672 at 0.07s, largest rise 25.04021 to 25.46347 at 0.07s
#>   read 20      0.07..0.08s: 3 calls, longest silence 0.00s (0.07..0.07s), trace 0.07:26.3 0.08:27.2
#>                highest below 100: 27.15648 at 0.08s, largest rise 26.30997 to 26.73323 at 0.07s
#>   read 21      0.08..0.08s: 161 calls, longest silence 0.00s (0.08..0.08s), trace 0.08:27.6 0.08:28.4
#>                highest below 100: 28.41259 at 0.08s, largest rise 27.57973 to 28.00299 at 0.08s
#>   read 22      0.08..0.08s: 140 calls, longest silence 0.00s (0.08..0.08s), trace 0.08:28.9 0.08:29.8
#>                highest below 100: 29.81888 at 0.08s, largest rise 29.36832 to 29.81888 at 0.08s
#>   read 23      0.08..0.09s: 4 calls, longest silence 0.00s (0.08..0.09s), trace 0.08:30.2 0.09:31.5
#>                highest below 100: 31.51189 at 0.09s, largest rise 30.66539 to 31.08864 at 0.09s
#>   read 24      0.09..0.09s: 3 calls, longest silence 0.00s (0.09..0.09s), trace 0.09:31.9 0.09:32.8
#>                highest below 100: 32.78165 at 0.09s, largest rise 32.3584 to 32.78165 at 0.09s
#>   read 25      0.09..0.09s: 287 calls, longest silence 0.00s (0.09..0.09s), trace 0.09:32.8 0.09:34.2
#>                highest below 100: 34.16064 at 0.09s, largest rise 33.61451 to 33.64181 at 0.09s
#>   read 26      0.09..0.10s: 3 calls, longest silence 0.00s (0.10..0.10s), trace 0.10:34.6 0.10:35.5
#>                highest below 100: 35.45771 at 0.10s, largest rise 35.03445 to 35.45771 at 0.10s
#>   read 27      0.10..0.10s: 3 calls, longest silence 0.00s (0.10..0.10s), trace 0.10:35.9 0.10:36.7
#>                highest below 100: 36.72747 at 0.10s, largest rise 35.88096 to 36.30421 at 0.10s
#>   read 28      0.10..0.10s: 3 calls, longest silence 0.00s (0.10..0.10s), trace 0.10:37.2 0.10:38.0
#>                highest below 100: 37.99723 at 0.10s, largest rise 37.15072 to 37.57397 at 0.10s
#>   read 29      0.10..0.11s: 3 calls, longest silence 0.00s (0.11..0.11s), trace 0.11:38.4 0.11:39.3
#>                highest below 100: 39.26699 at 0.11s, largest rise 38.42048 to 38.84373 at 0.11s
#>   read 30      0.11..0.11s: 3 calls, longest silence 0.00s (0.11..0.11s), trace 0.11:39.7 0.11:40.5
#>                highest below 100: 40.53675 at 0.11s, largest rise 40.11349 to 40.53675 at 0.11s
#>   read 31      0.11..0.12s: 130 calls, longest silence 0.00s (0.11..0.11s), trace 0.11:41.0 0.12:42.0
#>                highest below 100: 41.99765 at 0.12s, largest rise 40.96 to 41.38325 at 0.11s
#>   read 32      0.12..0.12s: 3 calls, longest silence 0.00s (0.12..0.12s), trace 0.12:42.4 0.12:43.3
#>                highest below 100: 43.29472 at 0.12s, largest rise 42.87147 to 43.29472 at 0.12s
#>   read 33      0.12..0.12s: 3 calls, longest silence 0.00s (0.12..0.12s), trace 0.12:43.7 0.12:44.6
#>                highest below 100: 44.56448 at 0.12s, largest rise 43.71797 to 44.14123 at 0.12s
#>   read 34      0.12..0.13s: 3 calls, longest silence 0.00s (0.12..0.13s), trace 0.12:45.0 0.13:45.8
#>                highest below 100: 45.83424 at 0.13s, largest rise 45.41099 to 45.83424 at 0.13s
#>   read 35      0.13..0.13s: 3 calls, longest silence 0.00s (0.13..0.13s), trace 0.13:46.3 0.13:47.1
#>                highest below 100: 47.104 at 0.13s, largest rise 46.25749 to 46.68075 at 0.13s
#>   read 36      0.13..0.13s: 135 calls, longest silence 0.00s (0.13..0.13s), trace 0.13:47.5 0.13:48.5
#>                highest below 100: 48.46933 at 0.13s, largest rise 47.52725 to 47.95051 at 0.13s
#>   read 37      0.13..0.14s: 3 calls, longest silence 0.00s (0.14..0.14s), trace 0.14:48.9 0.14:49.8
#>                highest below 100: 49.78005 at 0.14s, largest rise 48.93355 to 49.3568 at 0.14s
#>   read 38      0.14..0.14s: 4 calls, longest silence 0.00s (0.14..0.14s), trace 0.14:50.2 0.14:51.5
#>                highest below 100: 51.47307 at 0.14s, largest rise 50.20331 to 50.62656 at 0.14s
#>   read 39      0.14..0.15s: 328 calls, longest silence 0.00s (0.14..0.14s), trace 0.14:51.5 0.15:52.8
#>                highest below 100: 52.82475 at 0.15s, largest rise 52.34688 to 52.37419 at 0.15s
#>   read 40      0.15..0.15s: 122 calls, longest silence 0.00s (0.15..0.15s), trace 0.15:53.3 0.15:54.2
#>                highest below 100: 54.16277 at 0.15s, largest rise 53.27531 to 53.69856 at 0.15s
#>   read 41      0.15..0.15s: 3 calls, longest silence 0.00s (0.15..0.15s), trace 0.15:54.6 0.15:55.5
#>                highest below 100: 55.45984 at 0.15s, largest rise 54.61333 to 55.03659 at 0.15s
#>   read 42      0.15..0.16s: 135 calls, longest silence 0.00s (0.15..0.15s), trace 0.15:55.9 0.16:56.8
#>                highest below 100: 56.82517 at 0.16s, largest rise 55.88309 to 56.30635 at 0.16s
#>   read 43      0.16..0.16s: 3 calls, longest silence 0.00s (0.16..0.16s), trace 0.16:57.3 0.16:58.1
#>                highest below 100: 58.12224 at 0.16s, largest rise 57.27573 to 57.69899 at 0.16s
#>   read 44      0.16..0.16s: 3 calls, longest silence 0.00s (0.16..0.16s), trace 0.16:58.5 0.16:59.4
#>                highest below 100: 59.392 at 0.16s, largest rise 58.54549 to 58.96875 at 0.16s
#>   read 45      0.16..0.17s: 3 calls, longest silence 0.00s (0.16..0.17s), trace 0.17:59.8 0.17:60.7
#>                highest below 100: 60.66176 at 0.17s, largest rise 60.23851 to 60.66176 at 0.17s
#>   read 46      0.17..0.17s: 3 calls, longest silence 0.00s (0.17..0.17s), trace 0.17:61.1 0.17:61.9
#>                highest below 100: 61.93152 at 0.17s, largest rise 61.50827 to 61.93152 at 0.17s
#>   read 47      0.17..0.17s: 3 calls, longest silence 0.00s (0.17..0.17s), trace 0.17:62.4 0.17:63.2
#>                highest below 100: 63.20128 at 0.17s, largest rise 62.35477 to 62.77803 at 0.17s
#>   read 48      0.17..0.18s: 3 calls, longest silence 0.00s (0.17..0.17s), trace 0.17:63.6 0.18:64.5
#>                highest below 100: 64.47104 at 0.18s, largest rise 64.04779 to 64.47104 at 0.18s
#>   read 49      0.18..0.18s: 238 calls, longest silence 0.00s (0.18..0.18s), trace 0.18:64.9 0.18:66.2
#>                highest below 100: 66.16405 at 0.18s, largest rise 64.89429 to 65.31755 at 0.18s
#>   read 50      0.18..0.18s: 3 calls, longest silence 0.00s (0.18..0.18s), trace 0.18:66.6 0.18:100.0
#>                highest below 100: 66.66667 at 0.18s, largest rise 66.61461 to 66.66667 at 0.18s
#>   1 further reads with no calls, 0.00s in all
#> 
#> max_streaming_buffer_size = 10MiB 
#> 
#> ## buffer_10MiB | arrow | threads=4 | rows=5,000,000 | wall=0.15s | calls=3075 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s (0.00..0.00s), trace 0.00:100.0
#>   read 1       0.00..0.02s: 2982 calls, longest silence 0.00s (0.02..0.02s), trace 0.00:0.0 0.02:10.1
#>                highest below 100: 10.06251 at 0.02s, largest rise 0.9966933 to 1.037653 at 0.01s
#>   read 5       0.02..0.03s: 7 calls, longest silence 0.00s (0.02..0.02s), trace 0.02:10.8 0.03:14.5
#>                highest below 100: 14.47253 at 0.03s, largest rise 10.75883 to 11.45515 at 0.02s
#>   read 8       0.03..0.04s: 7 calls, longest silence 0.00s (0.03..0.03s), trace 0.03:15.1 0.04:18.9
#>                highest below 100: 18.85525 at 0.04s, largest rise 16.50688 to 17.2032 at 0.03s
#>   read 11      0.04..0.05s: 7 calls, longest silence 0.00s (0.04..0.04s), trace 0.04:19.5 0.05:23.2
#>                highest below 100: 23.23797 at 0.05s, largest rise 21.58592 to 22.26859 at 0.05s
#>   read 15      0.05..0.06s: 7 calls, longest silence 0.00s (0.05..0.05s), trace 0.05:23.9 0.06:27.6
#>                highest below 100: 27.62069 at 0.06s, largest rise 24.58965 to 25.28597 at 0.05s
#>   read 18      0.06..0.07s: 7 calls, longest silence 0.00s (0.06..0.06s), trace 0.06:28.3 0.07:32.0
#>                highest below 100: 32.00341 at 0.07s, largest rise 30.33771 to 31.03403 at 0.06s
#>   read 21      0.07..0.08s: 7 calls, longest silence 0.00s (0.07..0.07s), trace 0.07:32.7 0.08:36.4
#>                highest below 100: 36.38613 at 0.08s, largest rise 34.05141 to 34.73408 at 0.07s
#>   read 25      0.08..0.09s: 7 calls, longest silence 0.00s (0.08..0.08s), trace 0.08:37.1 0.08:40.8
#>                highest below 100: 40.76885 at 0.08s, largest rise 37.73781 to 38.43413 at 0.08s
#>   read 28      0.09..0.10s: 7 calls, longest silence 0.00s (0.09..0.09s), trace 0.09:41.4 0.09:45.2
#>                highest below 100: 45.15157 at 0.09s, largest rise 43.48587 to 44.18219 at 0.09s
#>   read 31      0.10..0.10s: 7 calls, longest silence 0.00s (0.10..0.10s), trace 0.10:45.8 0.10:49.5
#>                highest below 100: 49.53429 at 0.10s, largest rise 46.51691 to 47.19957 at 0.10s
#>   read 34      0.11..0.11s: 7 calls, longest silence 0.00s (0.11..0.11s), trace 0.11:50.2 0.11:53.9
#>                highest below 100: 53.91701 at 0.11s, largest rise 50.88597 to 51.58229 at 0.11s
#>   read 38      0.12..0.12s: 7 calls, longest silence 0.00s (0.12..0.12s), trace 0.12:54.6 0.12:58.3
#>                highest below 100: 58.29973 at 0.12s, largest rise 56.63403 to 57.33035 at 0.12s
#>   read 41      0.13..0.13s: 7 calls, longest silence 0.00s (0.13..0.13s), trace 0.13:59.0 0.13:62.7
#>                highest below 100: 62.68245 at 0.13s, largest rise 58.9824 to 59.66507 at 0.13s
#>   read 44      0.13..0.14s: 8 calls, longest silence 0.00s (0.13..0.14s), trace 0.14:63.4 0.14:100.0
#>                highest below 100: 66.66667 at 0.14s, largest rise 64.7168 to 65.41312 at 0.14s
#>   37 further reads with no calls, 0.03s in all
#> 
#> max_streaming_buffer_size = 1GiB 
#> 
#> ## buffer_1GiB | arrow | threads=4 | rows=5,000,000 | wall=0.15s | calls=21005 (of them =100: 2)
#>   open         0.00..0.00s: 1 calls, longest silence 0.00s (0.00..0.00s), trace 0.00:100.0
#>   read 1       0.00..0.12s: 21004 calls, longest silence 0.00s (0.05..0.05s), trace 0.00:0.1 0.12:100.0
#>                highest below 100: 66.66667 at 0.12s, largest rise 27.18379 to 28.99968 at 0.05s
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
