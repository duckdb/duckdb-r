# The cross-client scenarios, R side: one scenario per process, one CSV line out.
# Usage: Rscript clients.R <image-label> <scenario>
args <- commandArgs(TRUE); image <- args[1]; scenario <- args[2]
peak_mb <- function() { x <- readLines("/proc/self/status"); as.numeric(strsplit(x[grep("VmHWM", x)], "\\s+")[[1]][2]) / 1024 }
suppressMessages(library(DBI))
q <- "SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range(50000000) t(i)"
q_sorted <- "SELECT i::DOUBLE AS a, ((i * 7919) % 1000003)::DOUBLE AS b FROM range(50000000) t(i) ORDER BY b"
con <- dbConnect(duckdb::duckdb())
t0 <- Sys.time(); rows <- 0
if (scenario == "materialize") {
  df <- dbGetQuery(con, q); rows <- nrow(df)
} else if (scenario == "chunked_native") {
  rs <- dbSendQuery(con, q)
  repeat { d <- dbFetch(rs, n = 1e6); if (nrow(d) == 0) break; rows <- rows + nrow(d) }
  dbClearResult(rs)
} else if (scenario %in% c("stream_discard", "stream_plain", "stream_sorted_limited")) {
  if (scenario == "stream_sorted_limited") dbExecute(con, "SET memory_limit = '200MB'")
  rs <- dbSendQueryArrow(con, if (scenario == "stream_sorted_limited") q_sorted else q)
  repeat {
    ch <- dbFetchArrowChunk(rs, chunk_size = 1e6); if (ch$length == 0) break; rows <- rows + ch$length
    if (scenario != "stream_plain") nanoarrow::nanoarrow_pointer_release(ch)
  }
  dbClearResult(rs)
} else if (scenario == "stream_convert") {
  # batch-wise conversion to data frames, the shape a chunked consumer runs
  rs <- dbSendQueryArrow(con, q)
  repeat { ch <- dbFetchArrowChunk(rs, chunk_size = 1e6); if (ch$length == 0) break; d <- as.data.frame(ch); rows <- rows + nrow(d); nanoarrow::nanoarrow_pointer_release(ch) }
  dbClearResult(rs)
} else if (scenario == "arrow_legacy") {
  rs <- dbSendQuery(con, q, arrow = TRUE); tb <- duckdb::duckdb_fetch_arrow(rs); rows <- tb$num_rows; dbClearResult(rs)
} else if (scenario %in% c("adbc_stream", "adbc_sorted_limited")) {
  suppressMessages({library(adbcdrivermanager); library(nanoarrow)})
  db <- adbc_database_init(duckdb::duckdb_adbc()); acon <- adbc_connection_init(db)
  if (scenario == "adbc_sorted_limited") invisible(execute_adbc(acon, "SET memory_limit = '200MB'"))
  stmt <- adbc_statement_init(acon); adbc_statement_set_sql_query(stmt, if (scenario == "adbc_sorted_limited") q_sorted else q)
  s <- nanoarrow_allocate_array_stream(); adbc_statement_execute_query(stmt, s)
  repeat { a <- s$get_next(); if (is.null(a)) break; rows <- rows + a$length; nanoarrow_pointer_release(a) }
  s$release(); adbc_statement_release(stmt); adbc_connection_release(acon); adbc_database_release(db)
} else stop("unknown scenario ", scenario)
cat(sprintf("r,%s,%s,%d,%d,%.1f\n", image, scenario, rows, round(peak_mb()), as.numeric(Sys.time() - t0, units = "secs")))
dbDisconnect(con, shutdown = TRUE)
