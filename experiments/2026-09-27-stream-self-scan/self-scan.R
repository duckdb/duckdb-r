## Scanning a streaming result on its own connection: which routes wait
## instead of answering, whether an interrupt ends the wait, whether the build
## before #2775 waits too, and what works instead. Every case runs in a fresh
## R session, killed when it has not answered within ten seconds.
## PRE_2775_LIB names the library that holds the build before #2775.
library(callr)

# Runs `f` in a fresh session with the duckdb build at `lib` first,
# and says what came back: the value, the error, or nothing in time.
case <- function(f, args = list(), lib = .libPaths()[[1]], timeout = 10) {
  tryCatch(
    r(f, args = args, libpath = c(lib, .libPaths()), timeout = timeout),
    callr_timeout_error = function(e) {
      sprintf("no answer within %d seconds, killed", timeout)
    },
    callr_status_error = function(e) conditionMessage(e$parent)
  )
}

# A stream from dbGetQueryArrow(), handed to arrow as a reader, registered on
# the connection it came from, and scanned there.
scan_own <- function(rows = 3e6, threads = NULL, read_first = FALSE) {
  library(DBI)
  con <- dbConnect(duckdb::duckdb())
  if (!is.null(threads)) {
    dbExecute(con, paste("SET threads =", threads))
  }
  sql <- sprintf("SELECT i FROM range(%d) t(i)", rows)
  reader <- arrow::as_record_batch_reader(dbGetQueryArrow(con, sql))
  if (read_first) {
    reader$read_next_batch()
  }
  duckdb::duckdb_register_arrow(con, "s", reader)
  dbGetQuery(con, "SELECT count(*) AS n FROM s")$n
}

# Only the cases load duckdb and arrow, so the session info below lacks them.
case(function() {
  pkgs <- c("duckdb", "DBI", "arrow", "nanoarrow", "dbplyr", "dplyr")
  vapply(pkgs, function(p) as.character(packageVersion(p)), "")
})

## Every scan on the stream's own connection waits ---------------------------
case(scan_own)

# The size of the result does not matter, nor does the number of threads,
# nor whether a batch has been read already.
case(scan_own, list(rows = 10))
case(scan_own, list(threads = 1))
case(scan_own, list(read_first = TRUE))

# to_arrow_stream() handed back to its connection with arrow::to_duckdb().
case(function() {
  library(DBI)
  con <- dbConnect(duckdb::duckdb())
  dbWriteTable(con, "t", data.frame(i = seq_len(3e6)))
  reader <- duckdb::to_arrow_stream(dplyr::tbl(con, "t"))
  dplyr::pull(dplyr::count(arrow::to_duckdb(reader, con = con)))
})

# A table from to_duckdb() lives on the one connection arrow keeps,
# and so does the reader to_duckdb() registers without `con`.
case(function() {
  table <- arrow::to_duckdb(arrow::arrow_table(i = seq_len(3e6)))
  reader <- duckdb::to_arrow_stream(table)
  dplyr::pull(dplyr::count(arrow::to_duckdb(reader)))
})

## The build before #2775 waits too ------------------------------------------
pre_2775 <- Sys.getenv("PRE_2775_LIB")
case(function() as.character(packageVersion("duckdb")), lib = pre_2775)
case(scan_own, lib = pre_2775)

## An interrupt does not end the wait ----------------------------------------
# SIGINT, what Ctrl-C sends, twice, five seconds apart.
interrupted <- function(f) {
  p <- r_bg(f, libpath = .libPaths())
  on.exit(p$kill())
  Sys.sleep(3)
  alive <- logical()
  for (i in 1:2) {
    p$interrupt()
    Sys.sleep(5)
    alive[[i]] <- p$is_alive()
  }
  c(after_first = alive[[1]], after_second = alive[[2]])
}
interrupted(scan_own)

# The same interrupt stops an ordinary long query at once.
interrupted(function() {
  library(DBI)
  con <- dbConnect(duckdb::duckdb())
  dbGetQuery(con, "SELECT sum(i) FROM range(100000000000) t(i)")
})

## What works instead --------------------------------------------------------
# A second connection to the same database scans the stream.
case(function() {
  library(DBI)
  drv <- duckdb::duckdb()
  con <- dbConnect(drv)
  other <- dbConnect(drv)
  stream <- dbGetQueryArrow(other, "SELECT i FROM range(3000000) t(i)")
  duckdb::duckdb_register_arrow(con, "s", arrow::as_record_batch_reader(stream))
  dbGetQuery(con, "SELECT count(*) AS n FROM s")$n
})

# So does its own connection, once the stream is read to the end.
case(function() {
  library(DBI)
  con <- dbConnect(duckdb::duckdb())
  stream <- dbGetQueryArrow(con, "SELECT i FROM range(3000000) t(i)")
  duckdb::duckdb_register_arrow(con, "s", arrow::as_arrow_table(stream))
  dbGetQuery(con, "SELECT count(*) AS n FROM s")$n
})

# A materialized result is read to the end before the scan starts.
case(function() {
  library(DBI)
  con <- dbConnect(duckdb::duckdb())
  res <- dbSendQuery(con, "SELECT i FROM range(3000000) t(i)", arrow = TRUE)
  duckdb::duckdb_register_arrow(
    con,
    "s",
    duckdb::duckdb_fetch_record_batch(res)
  )
  dbGetQuery(con, "SELECT count(*) AS n FROM s")$n
})

## Routes that read the stream on R's thread fail instead --------------------
# DBI's dbWriteTableArrow() asks dbExistsTable() before it reads the schema,
# and creates nothing.
case(function() {
  library(DBI)
  con <- dbConnect(duckdb::duckdb())
  stream <- dbGetQueryArrow(con, "SELECT i FROM range(10) t(i)")
  error <- tryCatch(
    dbWriteTableArrow(con, "copy", stream),
    error = conditionMessage
  )
  list(error = error, created = dbExistsTable(con, "copy"))
})

# DBI's dbAppendTableArrow() appends batch by batch with dbAppendTable(),
# so the second read fails after the first batch has been appended.
append_own <- function(rows) {
  library(DBI)
  con <- dbConnect(duckdb::duckdb())
  dbExecute(con, "CREATE TABLE copy (i BIGINT)")
  sql <- sprintf("SELECT i FROM range(%d) t(i)", rows)
  stream <- dbGetQueryArrow(con, sql)
  out <- tryCatch(
    dbAppendTableArrow(con, "copy", stream),
    error = conditionMessage
  )
  list(out = out, rows = dbGetQuery(con, "SELECT count(*) AS n FROM copy")$n)
}
case(append_own, list(rows = 3e6))

# A stream of one batch has been read to the end before the first append.
case(append_own, list(rows = 10))

## Aside: a bare stream is not a scannable Arrow object ----------------------
# duckdb_register_arrow() refuses the nanoarrow stream itself on either
# connection, which is why the cases above wrap it in arrow's reader.
case(function() {
  library(DBI)
  drv <- duckdb::duckdb()
  con <- dbConnect(drv)
  other <- dbConnect(drv)
  stream <- dbGetQueryArrow(other, "SELECT i FROM range(10) t(i)")
  duckdb::duckdb_register_arrow(con, "s", stream)
  dbGetQuery(con, "SELECT count(*) AS n FROM s")$n
})
