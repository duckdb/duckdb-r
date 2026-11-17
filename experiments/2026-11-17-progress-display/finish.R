# Prints every progress callback, one line each, so that finish.sh can put a
# breakpoint's marker on RProgressBarDisplay::Finish() between them: the
# callback sees the 100 of Finish() and the 100 of a full Update() alike.
#
# Handbook: handbook/usage/interactive/README.md

suppressPackageStartupMessages(library(duckdb))
con <- dbConnect(duckdb(shared_home = FALSE))
invisible(dbExecute(
  con,
  "CREATE TABLE t AS SELECT i, random() AS x FROM range(10000000) r(i)"
))
invisible(dbExecute(con, "SET threads = 4"))
invisible(dbExecute(con, "SET max_streaming_buffer_size = '976KiB'"))
where <- ""
options(duckdb.progress_display = function(x) {
  cat(sprintf("callback %s %.4f\n", where, x))
  flush(stdout())
})
say <- function(x) {
  cat(x, "\n")
  flush(stdout())
}

say("=== dbGetQuery()")
where <- "dbGetQuery"
invisible(dbGetQuery(con, "SELECT count(*) FROM t WHERE x < 0.5"))

say("=== dbGetQueryArrow(), then $get_next() until NULL")
where <- "open"
s <- dbGetQueryArrow(
  con,
  "SELECT i, x FROM t WHERE i % 2 = 0",
  chunk_size = 100000
)
k <- 0
repeat {
  k <- k + 1
  where <- paste("read", k)
  b <- s$get_next()
  if (is.null(b)) break
}
say("=== done")
