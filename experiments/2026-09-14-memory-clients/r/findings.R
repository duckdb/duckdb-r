# The findings the memory leaves rest on, one per process, several metric lines out.
# Usage: Rscript findings.R <image-label> <finding>
args <- commandArgs(TRUE)
image <- args[1]
finding <- args[2]
rss <- function() {
  x <- readLines("/proc/self/status")
  as.numeric(strsplit(x[grep("VmRSS", x)], "\\s+")[[1]][2]) / 1024
}
hwm <- function() {
  x <- readLines("/proc/self/status")
  as.numeric(strsplit(x[grep("VmHWM", x)], "\\s+")[[1]][2]) / 1024
}
out <- function(metric, value) {
  cat(sprintf("%s,%s,%s,%s\n", image, finding, metric, format(value)))
}
suppressMessages(library(DBI))
ledger <- function(con) {
  dbGetQuery(
    con,
    "SELECT tag, round(memory_usage_bytes/1e6) AS mb, round(temporary_storage_bytes/1e6) AS spilled_mb FROM duckdb_memory() WHERE memory_usage_bytes > 0 OR temporary_storage_bytes > 0"
  )
}
big <- "SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range(50000000) t(i)" # 800 MB
if (finding == "version") {
  out("duckdb", as.character(packageVersion("duckdb")))
  out("R", R.version.string)
  con <- dbConnect(duckdb::duckdb())
  out(
    "memory_limit_default",
    dbGetQuery(con, "SELECT current_setting('memory_limit') AS x")$x
  )
  out(
    "mem_available_kb",
    strsplit(
      grep("MemAvailable", readLines("/proc/meminfo"), value = TRUE),
      "\\s+"
    )[[1]][2]
  )
  dbDisconnect(con, shutdown = TRUE)
} else if (finding == "eager") {
  con <- dbConnect(duckdb::duckdb())
  dbWriteTable(con, "t", data.frame(x = 1:100000))
  rs <- dbSendQuery(con, "SELECT * FROM t")
  out("resultset_rows_before_fetch", nrow(rs@env$resultset))
  out("fetch_n5_rows", nrow(dbFetch(rs, n = 5)))
  dbClearResult(rs)
  dbDisconnect(con, shutdown = TRUE)
} else if (finding == "double_copy") {
  con <- dbConnect(duckdb::duckdb())
  base <- hwm()
  df <- dbGetQuery(con, big)
  out("data_mb", 800)
  out("peak_over_base_mb", round(hwm() - base))
  out("rows", nrow(df))
  dbDisconnect(con, shutdown = TRUE)
} else if (finding == "ledger") {
  con <- dbConnect(duckdb::duckdb())
  dbExecute(
    con,
    "CREATE TABLE t AS SELECT i::DOUBLE a, i::DOUBLE b FROM range(5000000) t(i)"
  )
  rs <- dbSendQuery(con, "SELECT * FROM t", arrow = TRUE)
  l <- ledger(con)
  out(
    "tags_while_result_held",
    paste(sprintf("%s=%dMB", l$tag, l$mb), collapse = ";")
  )
  dbClearResult(rs)
  dbDisconnect(con, shutdown = TRUE)
} else if (finding == "altrep") {
  df <- data.frame(x = as.numeric(1:5e6), y = as.numeric(1:5e6))
  df$x <- df$x + 0
  df$y <- df$y + 0 # materialized, 76 MB
  con <- dbConnect(duckdb::duckdb())
  base <- rss()
  o <- duckdb:::rel_to_altrep(duckdb:::rel_filter(
    duckdb:::rel_from_df(con, df),
    list(duckdb:::expr_constant(TRUE))
  ))
  out("materialized_after_rel_to_altrep", duckdb:::df_is_materialized(o))
  out("rss_after_rel_to_altrep_mb", round(rss() - base))
  s <- sum(o$x) + sum(o$y)
  out("materialized_after_touch", duckdb:::df_is_materialized(o))
  out("rss_after_touch_mb", round(rss() - base))
  plain <- as.data.frame(lapply(o, function(col) col[seq_along(col)]))
  out("rss_after_copy_out_mb", round(rss() - base))
  rm(o)
  invisible(gc())
  out("rss_after_drop_altrep_mb", round(rss() - base))
  dbDisconnect(con, shutdown = TRUE)
} else if (finding == "adbc") {
  suppressMessages({
    library(adbcdrivermanager)
    library(nanoarrow)
  })
  db <- adbc_database_init(duckdb::duckdb_adbc())
  acon <- adbc_connection_init(db)
  stmt <- adbc_statement_init(acon)
  adbc_statement_set_sql_query(
    stmt,
    "SELECT i::DOUBLE a, i::DOUBLE b FROM range(30000000) t(i)"
  ) # 480 MB
  s <- nanoarrow_allocate_array_stream()
  adbc_statement_execute_query(stmt, s)
  a <- s$get_next()
  out("first_batch_rows", a$length)
  before <- rss()
  invisible(execute_adbc(acon, "SELECT 1"))
  out("rss_delta_after_second_statement_mb", round(rss() - before))
  n <- a$length
  repeat {
    a <- s$get_next()
    if (is.null(a)) {
      break
    }
    n <- n + a$length
  }
  out("rows_still_readable", n)
  s$release()
  adbc_statement_release(stmt)
  adbc_connection_release(acon)
  adbc_database_release(db)
} else if (finding %in% c("drain_plain", "drain_release", "drain_gc")) {
  con <- dbConnect(duckdb::duckdb())
  dbExecute(con, "SET memory_limit = '200MB'")
  rs <- dbSendQueryArrow(con, big)
  open <- hwm()
  rows <- 0
  repeat {
    ch <- dbFetchArrowChunk(rs, chunk_size = 100000)
    if (ch$length == 0) {
      break
    }
    rows <- rows + ch$length
    if (finding == "drain_release") {
      nanoarrow::nanoarrow_pointer_release(ch)
    }
    if (finding == "drain_gc" && rows %% 5e6 == 0) gc()
  }
  out("rows", rows)
  out("peak_at_open_mb", round(open))
  out("peak_after_drain_mb", round(hwm()))
  dbClearResult(rs)
  dbDisconnect(con, shutdown = TRUE)
} else if (
  finding %in%
    c("write_memory", "write_file", "write_txn_memory", "write_txn_file")
) {
  df <- data.frame(a = runif(30e6), b = runif(30e6)) # 480 MB
  dbdir <- if (grepl("file", finding)) {
    tempfile(fileext = ".duckdb")
  } else {
    ":memory:"
  }
  con <- dbConnect(duckdb::duckdb(), dbdir = dbdir)
  dbExecute(con, "SET memory_limit = '200MB'")
  base <- hwm()
  if (grepl("txn", finding)) {
    dbBegin(con)
  }
  res <- tryCatch(
    {
      dbWriteTable(con, "t", df)
      "ok"
    },
    error = function(e) substr(conditionMessage(e), 1, 60)
  )
  out("write", res)
  l <- ledger(con)
  out(
    "ledger_before_commit",
    paste(
      sprintf("%s=%dMB/spilled%dMB", l$tag, l$mb, l$spilled_mb),
      collapse = ";"
    )
  )
  if (grepl("txn", finding)) {
    out(
      "commit",
      tryCatch(
        {
          dbCommit(con)
          "ok"
        },
        error = function(e) substr(conditionMessage(e), 1, 60)
      )
    )
  }
  out("peak_over_base_mb", round(hwm() - base))
  if (grepl("file", finding)) {
    out("file_mb", round(file.size(dbdir) / 2^20))
  }
  dbDisconnect(con, shutdown = TRUE)
} else if (finding == "config_trap") {
  lim <- function(con) {
    v <- dbGetQuery(con, "SELECT current_setting('memory_limit') AS x")$x
    dbDisconnect(con, shutdown = TRUE)
    v
  }
  f <- tempfile(fileext = ".duckdb")
  out(
    "duckdb_config",
    lim(dbConnect(duckdb::duckdb(config = list(memory_limit = "200MB"))))
  )
  out(
    "dbConnect_config_memory",
    lim(dbConnect(duckdb::duckdb(), config = list(memory_limit = "200MB")))
  )
  out(
    "dbConnect_dbdir_config",
    lim(dbConnect(
      duckdb::duckdb(),
      dbdir = f,
      config = list(memory_limit = "200MB")
    ))
  )
  out(
    "dbConnect_config_on_dbdir_driver",
    lim(dbConnect(
      duckdb::duckdb(dbdir = f),
      config = list(memory_limit = "200MB")
    ))
  )
} else if (finding == "record_batch_cycles") {
  suppressMessages(library(arrow))
  con <- dbConnect(duckdb::duckdb())
  base <- rss()
  peaks <- c()
  for (i in 1:8) {
    rs <- dbSendQuery(
      con,
      "SELECT i::DOUBLE a, i::DOUBLE b FROM range(10000000) t(i)",
      arrow = TRUE
    )
    rd <- duckdb::duckdb_fetch_record_batch(rs)
    while (!is.null(b <- rd$read_next_batch())) {
      NULL
    }
    dbClearResult(rs)
    rm(rd, rs, b)
    invisible(gc())
    peaks <- c(peaks, round(rss() - base))
  }
  out("rss_over_base_after_each_cycle_mb", paste(peaks, collapse = ";"))
  dbDisconnect(con, shutdown = TRUE)
} else if (finding == "sorted_stream_limited") {
  con <- dbConnect(duckdb::duckdb())
  dbExecute(con, "SET memory_limit = '200MB'")
  rs <- dbSendQueryArrow(
    con,
    "SELECT i::DOUBLE AS a, ((i * 7919) % 1000003)::DOUBLE AS b FROM range(50000000) t(i) ORDER BY b"
  )
  out("peak_at_open_mb", round(hwm()))
  rows <- 0
  repeat {
    ch <- dbFetchArrowChunk(rs, chunk_size = 1e6)
    if (ch$length == 0) {
      break
    }
    rows <- rows + ch$length
    nanoarrow::nanoarrow_pointer_release(ch)
  }
  out("rows", rows)
  out("peak_after_drain_mb", round(hwm()))
  dbClearResult(rs)
  dbDisconnect(con, shutdown = TRUE)
} else {
  stop("unknown finding ", finding)
}
