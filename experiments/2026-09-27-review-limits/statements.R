## Three limits of running statements: an INSTALL or LOAD that stops a whole
## string, a PRAGMA's expansion left half done while a stream is open, and a
## parameter that invalidates the database.
library(DBI)

first_line <- function(e) sub("\n.*", "", conditionMessage(e))

## allow_extensions = FALSE ----------------------------------------------------
con <- dbConnect(duckdb::duckdb(allow_extensions = FALSE, shared_home = FALSE))
tryCatch(
  dbExecute(con, "CREATE TABLE l1 (i INTEGER); LOAD parquet"),
  error = first_line
)
dbExistsTable(con, "l1")
# Any other failing statement leaves the ones before it in effect.
tryCatch(
  dbExecute(con, "CREATE TABLE l2 (i INTEGER); SELECT * FROM nope"),
  error = first_line
)
dbExistsTable(con, "l2")
dbDisconnect(con)

## A PRAGMA's expansion while a stream is open ---------------------------------
# An export of two tables, and the second table's CSV made unparseable.
dir <- tempfile("export")
src <- dbConnect(duckdb::duckdb(shared_home = FALSE))
dbExecute(src, "CREATE TABLE a AS SELECT 1 AS i")
dbExecute(src, "CREATE TABLE b AS SELECT 2 AS i")
dbExecute(src, sprintf("EXPORT DATABASE '%s'", dir))
dbDisconnect(src)
writeLines(c("i", "not a number"), file.path(dir, "b.csv"))
import <- sprintf("PRAGMA import_database('%s')", dir)

# Without a stream, the failure rolls the whole expansion back.
con <- dbConnect(duckdb::duckdb(shared_home = FALSE))
tryCatch(dbExecute(con, import), error = first_line)
dbGetQuery(con, "SELECT table_name FROM duckdb_tables()")
dbDisconnect(con)

# With a stream open on the connection, the statements before it stay.
con <- dbConnect(duckdb::duckdb(shared_home = FALSE))
res <- dbSendQueryArrow(con, "SELECT * FROM range(10000000)")
tryCatch(dbExecute(con, import), error = first_line)
dbGetQuery(
  con,
  "SELECT (SELECT count(*) FROM a) AS a_rows, (SELECT count(*) FROM b) AS b_rows"
)
tryCatch(dbRollback(con), error = first_line)
dbClearResult(res)
dbDisconnect(con)

## One character parameter inside typeof() and in a cast ------------------------
# Each case runs in a session of its own, because the error invalidates the
# database.
sql <- "SELECT typeof($1) AS type, $1::VARCHAR AS text"
in_session <- function(f) {
  callr::r(f, args = list(sql = sql), libpath = .libPaths())
}

in_session(function(sql) {
  first_line <- function(e) sub("\n.*", "", conditionMessage(e))
  con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE))
  list(
    query = tryCatch(
      DBI::dbGetQuery(con, sql, params = list("ok")),
      error = first_line
    ),
    next_statement = tryCatch(
      DBI::dbGetQuery(con, "SELECT 42"),
      error = first_line
    ),
    new_connection = tryCatch(DBI::dbConnect(con@driver), error = first_line)
  )
})

# Other classes, and a character value bound to two parameters, answer.
in_session(function(sql) {
  con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE))
  rbind(
    DBI::dbGetQuery(con, sql, params = list(1L)),
    DBI::dbGetQuery(con, sql, params = list(1.5)),
    DBI::dbGetQuery(con, sql, params = list(TRUE)),
    DBI::dbGetQuery(con, sql, params = list(as.Date("2026-09-27"))),
    DBI::dbGetQuery(
      con,
      "SELECT typeof(?) AS type, ?::VARCHAR AS text",
      params = list("ok", "ok")
    )
  )
})

# On a file, a new driver gets the same instance until duckdb_shutdown().
in_session(function(sql) {
  first_line <- function(e) sub("\n.*", "", conditionMessage(e))
  path <- tempfile(fileext = ".duckdb")
  drv <- duckdb::duckdb(path)
  con <- DBI::dbConnect(drv)
  DBI::dbWriteTable(con, "t", data.frame(x = 1:3))
  count <- function() {
    con <- DBI::dbConnect(duckdb::duckdb(path))
    DBI::dbGetQuery(con, "SELECT count(*) AS n FROM t")$n
  }
  list(
    query = tryCatch(
      DBI::dbGetQuery(con, sql, params = list("ok")),
      error = first_line
    ),
    new_driver = tryCatch(count(), error = first_line),
    after_shutdown = {
      duckdb::duckdb_shutdown(drv)
      count()
    }
  )
})
