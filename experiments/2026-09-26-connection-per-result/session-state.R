# What a second connection to the same instance sees of the first one's session
# state, and what a statement on one connection does to a stream open on the
# other. Driven by run.sh; see README.md.
suppressMessages(library(duckdb))
suppressMessages(library(nanoarrow))

home <- file.path(tempdir(), "duckdb-home")
path <- tempfile(fileext = ".duckdb")
drv <- duckdb(path, home = home)
con1 <- dbConnect(drv) # the DBI connection
con2 <- dbConnect(drv) # what a private context behind a result would be
invisible(dbExecute(con1, "CREATE TABLE t AS SELECT i FROM range(100000) r(i)"))

sees <- function(label, expr) {
  out <- tryCatch(
    paste("reads:", paste(format(expr), collapse = " ")),
    error = function(e) {
      paste0("fails: ", strsplit(conditionMessage(e), "\n")[[1]][[1]])
    }
  )
  cat(sprintf("  %-46s %s\n", label, out))
  invisible(NULL)
}

cat("== Set on the first connection, read from the second\n")
invisible(dbExecute(con1, "CREATE TEMP TABLE tt AS SELECT 42 AS x"))
sees("CREATE TEMP TABLE tt", dbGetQuery(con2, "SELECT x FROM tt")$x)
duckdb_register(con1, "df", data.frame(x = 43))
sees("duckdb_register(\"df\")", dbGetQuery(con2, "SELECT x FROM df")$x)
invisible(dbExecute(con1, "PREPARE p AS SELECT 44 AS x"))
sees("PREPARE p", dbGetQuery(con2, "EXECUTE p")$x)
invisible(dbExecute(con1, "SET TimeZone = 'Asia/Tokyo'"))
sees(
  "SET TimeZone, a session setting",
  dbGetQuery(con2, "SELECT current_setting('TimeZone') AS tz")$tz
)
invisible(dbExecute(con1, "SET threads = 2"))
sees(
  "SET threads, a global setting",
  dbGetQuery(con2, "SELECT current_setting('threads') AS n")$n
)
invisible(dbExecute(con1, "ATTACH ':memory:' AS other"))
sees(
  "ATTACH other, an instance-wide change",
  dbGetQuery(
    con2,
    "SELECT database_name FROM duckdb_databases() WHERE database_name = 'other'"
  )$database_name
)
dbname <- dbGetQuery(con2, "SELECT current_database() AS db")$db
invisible(dbExecute(con1, "USE other"))
sees(
  "USE other, the session's default database",
  dbGetQuery(con2, "SELECT current_database() AS db")$db
)
invisible(dbExecute(con1, paste("USE", dbQuoteIdentifier(con1, dbname))))
dbBegin(con1)
invisible(dbExecute(con1, "INSERT INTO t VALUES (-1)"))
sees(
  "an INSERT inside an open transaction",
  dbGetQuery(con2, "SELECT count(*) AS n FROM t WHERE i = -1")$n
)
dbCommit(con1)
sees(
  "the same INSERT once committed",
  dbGetQuery(con2, "SELECT count(*) AS n FROM t WHERE i = -1")$n
)

cat("== A stream open on the second connection, statements on the first\n")
res <- dbSendQueryArrow(con2, "SELECT * FROM t")
invisible(dbFetchArrowChunk(res, chunk_size = 1000))
step <- function(label, statement) {
  ran <- tryCatch(
    {
      dbExecute(con1, statement)
      "ran"
    },
    error = function(e) {
      paste0("refused: ", strsplit(conditionMessage(e), "\n")[[1]][[1]])
    }
  )
  stream <- tryCatch(
    {
      batch <- dbFetchArrowChunk(res, chunk_size = 1000)
      sprintf("stream yields %d more rows", batch$length)
    },
    error = function(e) paste0("stream fails: ", conditionMessage(e))
  )
  cat(sprintf("  %-46s %s; %s\n", label, ran, stream))
}
step("INSERT INTO t", "INSERT INTO t VALUES (-2)")
step("CHECKPOINT", "CHECKPOINT")
step("DROP TABLE t", "DROP TABLE t")
dbClearResult(res)
dbDisconnect(con2)
dbDisconnect(con1)

# The same sequence again, ending in FORCE CHECKPOINT, which aborts the other
# transactions it finds. The stream's transaction is parked until a consumer
# fetches, and the consumer is the thread issuing the checkpoint, so this case
# runs in another process under a budget, and a kill is a result too.
cat("== The same sequence, then FORCE CHECKPOINT on the first connection\n")
forced <- tryCatch(
  callr::r(
    function(home) {
      drv <- duckdb::duckdb(tempfile(fileext = ".duckdb"), home = home)
      con1 <- DBI::dbConnect(drv)
      con2 <- DBI::dbConnect(drv)
      DBI::dbExecute(con1, "CREATE TABLE t AS SELECT i FROM range(100000) r(i)")
      res <- DBI::dbSendQueryArrow(con2, "SELECT * FROM t")
      DBI::dbFetchArrowChunk(res, chunk_size = 1000)
      DBI::dbExecute(con1, "INSERT INTO t VALUES (-2)")
      DBI::dbExecute(con1, "CHECKPOINT")
      DBI::dbExecute(con1, "DROP TABLE t")
      DBI::dbExecute(con1, "FORCE CHECKPOINT")
      "ran"
    },
    args = list(home = home),
    timeout = 20
  ),
  error = function(e) {
    if (inherits(e, "callr_timeout_error")) {
      "did not return within 20 s, killed"
    } else {
      paste0("refused: ", strsplit(conditionMessage(e), "\n")[[1]][[1]])
    }
  }
)
cat(sprintf("  %-46s %s\n", "FORCE CHECKPOINT", forced))
