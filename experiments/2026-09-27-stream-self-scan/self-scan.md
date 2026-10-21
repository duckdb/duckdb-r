``` r
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
#>       duckdb          DBI        arrow    nanoarrow       dbplyr        dplyr 
#> "1.5.5.9028"      "1.3.0"     "25.0.1"      "0.9.0"      "2.6.0"      "1.2.1"

## Every scan on the stream's own connection waits ---------------------------
case(scan_own)
#> [1] "no answer within 10 seconds, killed"

# The size of the result does not matter, nor does the number of threads,
# nor whether a batch has been read already.
case(scan_own, list(rows = 10))
#> [1] "no answer within 10 seconds, killed"
case(scan_own, list(threads = 1))
#> [1] "no answer within 10 seconds, killed"
case(scan_own, list(read_first = TRUE))
#> [1] "no answer within 10 seconds, killed"

# to_arrow_stream() handed back to its connection with arrow::to_duckdb().
case(function() {
  library(DBI)
  con <- dbConnect(duckdb::duckdb())
  dbWriteTable(con, "t", data.frame(i = seq_len(3e6)))
  reader <- duckdb::to_arrow_stream(dplyr::tbl(con, "t"))
  dplyr::pull(dplyr::count(arrow::to_duckdb(reader, con = con)))
})
#> [1] "no answer within 10 seconds, killed"

# A table from to_duckdb() lives on the one connection arrow keeps,
# and so does the reader to_duckdb() registers without `con`.
case(function() {
  table <- arrow::to_duckdb(arrow::arrow_table(i = seq_len(3e6)))
  reader <- duckdb::to_arrow_stream(table)
  dplyr::pull(dplyr::count(arrow::to_duckdb(reader)))
})
#> [1] "no answer within 10 seconds, killed"

## The build before #2775 waits too ------------------------------------------
pre_2775 <- Sys.getenv("PRE_2775_LIB")
case(function() as.character(packageVersion("duckdb")), lib = pre_2775)
#> [1] "1.5.5.9026"
case(scan_own, lib = pre_2775)
#> [1] "no answer within 10 seconds, killed"

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
#>  after_first after_second 
#>         TRUE         TRUE

# The same interrupt stops an ordinary long query at once.
interrupted(function() {
  library(DBI)
  con <- dbConnect(duckdb::duckdb())
  dbGetQuery(con, "SELECT sum(i) FROM range(100000000000) t(i)")
})
#>  after_first after_second 
#>        FALSE        FALSE

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
#> [1] 3e+06

# So does its own connection, once the stream is read to the end.
case(function() {
  library(DBI)
  con <- dbConnect(duckdb::duckdb())
  stream <- dbGetQueryArrow(con, "SELECT i FROM range(3000000) t(i)")
  duckdb::duckdb_register_arrow(con, "s", arrow::as_arrow_table(stream))
  dbGetQuery(con, "SELECT count(*) AS n FROM s")$n
})
#> [1] 3e+06

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
#> [1] 3e+06

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
#> $error
#> [1] "array_stream->get_schema(): [22] Invalid Input Error: The query result was invalidated by another statement on its connection before it was read to the end. Read it to the end first, or run the other statement on a separate connection."
#> 
#> $created
#> [1] FALSE

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
#> $out
#> [1] "array_stream->get_next(): [22] Invalid Input Error: The query result was invalidated by another statement on its connection before it was read to the end. Read it to the end first, or run the other statement on a separate connection."
#> 
#> $rows
#> [1] 1e+06

# A stream of one batch has been read to the end before the first append.
case(append_own, list(rows = 10))
#> $out
#> [1] 10
#> 
#> $rows
#> [1] 10

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
#> [1] "Invalid Error: std::exception\nℹ Context: rapi_prepare\nℹ Error type: INVALID"
```

<sup>Created on 2026-09-27 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

<details style="margin-bottom:10px;">

<summary>

Session info
</summary>

``` r
sessioninfo::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────
#>  setting  value
#>  version  R version 4.5.3 (2026-03-11)
#>  os       Ubuntu 24.04.4 LTS
#>  system   x86_64, linux-gnu
#>  ui       X11
#>  language (EN)
#>  collate  C.UTF-8
#>  ctype    C.UTF-8
#>  tz       Etc/UTC
#>  date     2026-09-27
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version date (UTC) lib source
#>  callr       * 3.8.0   2026-06-05 [2] RSPM
#>  cli           3.6.6   2026-04-09 [2] RSPM
#>  digest        0.6.39  2025-11-19 [2] RSPM
#>  evaluate      1.0.5   2025-08-27 [2] RSPM
#>  fastmap       1.2.0   2024-05-15 [2] RSPM
#>  fs            2.1.0   2026-04-18 [2] RSPM
#>  glue          1.8.1   2026-04-17 [2] RSPM
#>  htmltools     0.5.9   2025-12-04 [2] RSPM
#>  knitr         1.52    2026-09-06 [2] RSPM
#>  lifecycle     1.0.5   2026-01-08 [2] RSPM
#>  otel          0.2.0   2025-08-29 [2] RSPM
#>  processx      3.9.0   2026-04-22 [2] RSPM
#>  ps            1.9.3   2026-04-20 [2] RSPM
#>  R6            2.6.1   2025-02-15 [2] RSPM
#>  reprex        2.1.1   2024-07-06 [2] RSPM
#>  rlang         1.3.0   2026-07-05 [2] RSPM
#>  rmarkdown     2.32    2026-09-01 [2] RSPM
#>  sessioninfo   1.2.4   2026-06-04 [2] RSPM
#>  withr         3.0.3   2026-06-19 [2] RSPM
#>  xfun          0.61    2026-09-16 [2] RSPM
#>  yaml          2.3.12  2025-12-10 [2] RSPM
#> 
#>  [1] <fast-path build library>
#>  [2] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [3] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

</details>
