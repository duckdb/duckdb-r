# Which results survive a second statement on the same connection, which
# everyday calls end a streaming result and how that shows, and whether a
# second DBI connection to the same instance interleaves where one connection
# cannot. Driven by run.sh; see README.md.
suppressMessages(library(duckdb))
suppressMessages(library(nanoarrow))

drv <- duckdb(home = file.path(tempdir(), "duckdb-home"))
con <- dbConnect(drv)
invisible(dbExecute(con, "CREATE TABLE t AS SELECT i FROM range(100000) r(i)"))
invisible(dbExecute(con, "CREATE TABLE sink (i BIGINT)"))

# The verdict is whether the first result can still be read after the
# interference, and what it says otherwise.
verdict <- function(label, expr) {
  out <- tryCatch(
    {
      value <- force(expr)
      if (is.character(value)) value else "survives"
    },
    error = function(e) paste0("fails: ", conditionMessage(e))
  )
  cat(sprintf("  %-46s %s\n", label, out))
  invisible(NULL)
}

cat("== A materialized result, with another statement between send and fetch\n")
r1 <- dbSendQuery(con, "SELECT * FROM t")
verdict("dbGetQuery() in between", {
  dbGetQuery(con, "SELECT count(*) FROM t")
  stopifnot(nrow(dbFetch(r1, 10)) == 10)
})
verdict("dbExecute(INSERT) in between", {
  dbExecute(con, "INSERT INTO sink VALUES (1)")
  stopifnot(nrow(dbFetch(r1, 10)) == 10)
})
verdict("a second dbSendQuery(), fetched alternately", {
  r2 <- dbSendQuery(con, "SELECT * FROM t WHERE i > 50000")
  stopifnot(
    nrow(dbFetch(r1, 10)) == 10,
    nrow(dbFetch(r2, 10)) == 10,
    nrow(dbFetch(r1, 10)) == 10
  )
  dbClearResult(r2)
})
dbClearResult(r1)

cat("== A streaming result (dbSendQueryArrow()), one interference per case\n")
# The stream holds 100,000 rows, and one batch of 1,000 is taken before the
# interference to prove it was live; what the next batch holds is the verdict.
open_stream <- function(con) {
  res <- dbSendQueryArrow(con, "SELECT * FROM t")
  stopifnot(dbFetchArrowChunk(res, chunk_size = 1000)$length == 1000)
  res
}
next_batch <- function(res) {
  batch <- dbFetchArrowChunk(res, chunk_size = 1000)
  if (batch$length == 1000) {
    "survives"
  } else {
    sprintf(
      "reads as drained: %d rows, dbHasCompleted() %s, no error",
      batch$length,
      dbHasCompleted(res)
    )
  }
}
cases <- list(
  "nothing in between" = function() NULL,
  "dbQuoteIdentifier(), which runs no statement" = function() {
    dbQuoteIdentifier(con, "x")
  },
  "dbExistsTable()" = function() dbExistsTable(con, "t"),
  "dbListTables()" = function() dbListTables(con),
  "dbListFields()" = function() dbListFields(con, "t"),
  "dbGetQuery(\"SELECT 1\")" = function() dbGetQuery(con, "SELECT 1"),
  "dbExecute(INSERT into another table)" = function() {
    dbExecute(con, "INSERT INTO sink VALUES (1)")
  },
  "duckdb_register()" = function() {
    duckdb_register(con, "df", data.frame(x = 1), overwrite = TRUE)
  },
  "dbAppendTable() (a view, then an INSERT)" = function() {
    dbAppendTable(con, "sink", data.frame(i = 1))
  },
  "dbBegin(); dbRollback()" = function() {
    dbBegin(con)
    dbRollback(con)
  },
  "a second dbSendQueryArrow()" = function() {
    dbClearResult(dbSendQueryArrow(con, "SELECT 1"))
  },
  "a dbSendQuery(), materialized" = function() {
    dbClearResult(dbSendQuery(con, "SELECT 1"))
  }
)
for (label in names(cases)) {
  res <- open_stream(con)
  verdict(label, {
    cases[[label]]()
    next_batch(res)
  })
  dbClearResult(res)
}

cat(
  "== The DBI chunked loop: read a stream, append each batch through a connection\n"
)
etl <- function(con_read, con_write) {
  invisible(dbExecute(con_write, "DELETE FROM sink"))
  res <- dbSendQueryArrow(con_read, "SELECT * FROM t")
  on.exit(dbClearResult(res))
  n <- 0
  repeat {
    batch <- dbFetchArrowChunk(res, chunk_size = 10000)
    if (batch$length == 0) {
      break
    }
    dbAppendTable(con_write, "sink", as.data.frame(batch))
    n <- n + batch$length
  }
  sprintf(
    "%s: %d of 100000 rows appended",
    if (n == 100000) "survives" else "stops early",
    n
  )
}
con2 <- dbConnect(drv)
verdict("the same connection reads and writes", etl(con, con))
verdict("a second connection writes", etl(con, con2))

cat("== Two streams on two connections to one instance\n")
r1 <- dbSendQueryArrow(con, "SELECT * FROM t")
r2 <- dbSendQueryArrow(con2, "SELECT * FROM t WHERE i > 50000")
verdict("batches from r1, r2, r1, r2", {
  for (res in list(r1, r2, r1, r2)) {
    stopifnot(dbFetchArrowChunk(res, chunk_size = 1000)$length == 1000)
  }
})
dbClearResult(r1)
dbClearResult(r2)
dbDisconnect(con2)
dbDisconnect(con)
