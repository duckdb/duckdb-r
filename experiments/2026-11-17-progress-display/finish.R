# Prints every progress callback, one line each, so that finish.sh can put a
# breakpoint's marker on RProgressBarDisplay::Finish() between them: the
# callback sees the 100 of Finish() and the 100 of a full Update() alike.
#
# Handbook: handbook/usage/interactive/README.md

suppressPackageStartupMessages(library(duckdb))
con <- dbConnect(duckdb(shared_home = FALSE))
# One thread and a seed, so that random() gives the same table every run.
invisible(dbExecute(con, "SET threads = 1"))
invisible(dbExecute(con, "SELECT setseed(0.42)"))
invisible(dbExecute(
  con,
  "CREATE TABLE t AS
   SELECT i, hash(i) % 2500000 AS k, random() AS x FROM range(10000000) r(i)"
))
invisible(dbExecute(con, "SET threads = 4"))
where <- ""
say <- function(x) {
  cat(x, "\n")
  flush(stdout())
}
options(duckdb.progress_display = function(x) {
  cat(sprintf("callback %s %.4f\n", where, x))
  flush(stdout())
})

materialized <- function(name, sql) {
  say(paste("=== scenario", name))
  where <<- "call"
  invisible(dbGetQuery(con, sql))
}

streamed <- function(name, sql, buffer) {
  say(paste("=== scenario", name))
  where <<- "set_buffer"
  invisible(dbExecute(
    con,
    sprintf("SET max_streaming_buffer_size = '%s'", buffer)
  ))
  where <<- "open"
  s <- dbGetQueryArrow(con, sql, chunk_size = 100000)
  k <- 0
  repeat {
    k <- k + 1
    where <<- paste0("read_", k)
    b <- s$get_next()
    if (is.null(b)) break
  }
  s$release()
  say(paste("=== reads", k))
}

materialized("dbGetQuery", "SELECT count(*) FROM t WHERE x < 0.5")
materialized(
  "dbGetQuery_three_statements",
  "SELECT 1; SELECT count(*) FROM t WHERE x < 0.5; SELECT 2"
)
scan <- "SELECT i, x FROM t WHERE i % 2 = 0"
streamed("stream_scan_976KiB", scan, "976KiB")
streamed("stream_scan_10MiB", scan, "10MiB")
streamed("stream_scan_1GiB", scan, "1GiB")
streamed(
  "stream_group_by_10MiB",
  "SELECT k, sum(x) AS s, count(*) AS n FROM t GROUP BY k",
  "10MiB"
)
streamed(
  "stream_order_by_10MiB",
  "SELECT i, x FROM t WHERE i % 4 = 0 ORDER BY x",
  "10MiB"
)

# The same on one thread, where R's thread runs every task.
say("=== scenario set_threads")
where <- "set_threads"
invisible(dbExecute(con, "SET threads = 1"))
materialized("dbGetQuery_threads_1", "SELECT count(*) FROM t WHERE x < 0.5")
streamed("stream_scan_976KiB_threads_1", scan, "976KiB")
streamed(
  "stream_group_by_10MiB_threads_1",
  "SELECT k, sum(x) AS s, count(*) AS n FROM t GROUP BY k",
  "10MiB"
)
say("=== done")
