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

# ---- Recording ---------------------------------------------------------------

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

# ---- Setup -------------------------------------------------------------------

con <- dbConnect(duckdb(shared_home = FALSE))
info <- dbGetQuery(
  con,
  "SELECT version() AS v, current_setting('max_streaming_buffer_size') AS buf"
)
cat("# Progress display callback trace\n\n")
cat("date:      ", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), "\n")
cat("duckdb:    ", format(packageVersion("duckdb")), "\n")
cat("engine:    ", info$v, "\n")
cat("R:         ", R.version.string, "\n")
cat("nanoarrow: ", format(packageVersion("nanoarrow")), "\n")
cat(
  "OS:        ",
  paste(Sys.info()[c("sysname", "release", "machine")], collapse = " "),
  "\n"
)
cpu <- grep("^model name", readLines("/proc/cpuinfo"), value = TRUE)
cat("CPU:       ", sub(".*: ", "", cpu[1]), "x", length(cpu), "\n")
cat("default max_streaming_buffer_size:", info$buf, "\n")
cat("times are seconds since the R call that issued the query\n")

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

# ---- a. Large local queries --------------------------------------------------

local_queries <- c(
  scan_filter = "SELECT i, x FROM t WHERE hash(i::VARCHAR || 'salt') % 100 = 0",
  group_by = "SELECT k, sum(x) AS s, count(*) AS n FROM t GROUP BY k",
  order_by = "SELECT i, x FROM t WHERE i % 4 = 0 ORDER BY x",
  join = "SELECT t.k, x, y FROM t JOIN u ON t.k = u.k WHERE x < 0.01"
)

cat("\n# a. Large local queries\n")
# The optimizer's row estimate for the filtered scan, which weighs its share.
cat(
  grep(
    "Filters|rows",
    dbGetQuery(con, paste("EXPLAIN", local_queries[["scan_filter"]]))[[2]],
    value = TRUE
  ),
  sep = "\n"
)
for (name in names(local_queries)) {
  cat("\n", name, ": ", local_queries[[name]], "\n", sep = "")
  for (threads in c(1L, 4L)) {
    for (api in c("get", "arrow", "send")) {
      run(con, name, api, local_queries[[name]], threads)
    }
  }
}

# The filtered scan's count alone, to compare its speed at one and four
# threads with the scan that returns its rows.
scan_count <- sub(
  "SELECT i, x",
  "SELECT count(*)",
  local_queries[["scan_filter"]]
)
cat("\nscan_filter_count: ", scan_count, "\n", sep = "")
for (threads in c(1L, 4L)) {
  run(con, "scan_filter_count", "get", scan_count, threads)
}

# ---- b. A remote part and a local part ---------------------------------------

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
# Every query fetches the file again rather than from the engine's cache.
invisible(dbExecute(con, "SET enable_external_file_cache = false"))
cat(sprintf(
  "\n# b. Remote and local\n\nremote file: %s, %s bytes, 4,000,000 rows in row groups of 100,000, served at %s bytes/s\n",
  url,
  format(file.size(parquet), big.mark = ","),
  format(rate, big.mark = ",")
))

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

# ---- c. The streaming buffer -------------------------------------------------

# The first 10,000,000 rows of t, the table finish.R streams.
invisible(dbExecute(
  con,
  "CREATE TABLE s AS SELECT i, x FROM t WHERE i < 10000000"
))
cat(
  "\n# c. max_streaming_buffer_size, a stream of a cheap 5,000,000-row scan read in chunks of 100,000 rows\n"
)
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
invisible(dbExecute(con, "RESET max_streaming_buffer_size"))

system(sprintf("pkill -f 'throttle_server.py .* %d'", port))
write.csv(do.call(rbind, all_calls), calls_csv, row.names = FALSE)
cat("every call written to", basename(calls_csv), "\n")
dbDisconnect(con)
