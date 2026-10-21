# Whether a result outlives the connection it was sent on, what that keeps
# open, and what a second open of the same file then meets, in this process and
# in another. Driven by run.sh; see README.md.
suppressMessages(library(duckdb))

home <- file.path(tempdir(), "duckdb-home")
path <- tempfile(fileext = ".duckdb")

report <- function(label, expr) {
  out <- tryCatch(
    paste(format(expr), collapse = " "),
    error = function(e) paste0("error: ", conditionMessage(e))
  )
  cat(sprintf("  %-60s %s\n", label, out))
  invisible(NULL)
}

# Opens the file from another process, which is where the engine's file lock
# is decided: a POSIX record lock is held per process.
open_elsewhere <- function() {
  callr::r(
    function(path, home) {
      con <- DBI::dbConnect(duckdb::duckdb(path, home = home))
      DBI::dbDisconnect(con)
      "opened"
    },
    args = list(path = path, home = home)
  )
}

drv <- duckdb(path, home = home)
con <- dbConnect(drv)
res <- dbSendQuery(
  con,
  "SELECT count(*) AS n FROM duckdb_tables() WHERE table_name = ?",
  params = list("u")
)
dbDisconnect(con)
report("dbIsValid(con) after dbDisconnect()", dbIsValid(con))
report("dbIsValid(res) after dbDisconnect()", dbIsValid(res))
report("dbFetch(res)$n, the copy taken at send time", dbFetch(res)$n)
report("dbBind(res, 'u'); dbFetch(res)$n, re-executed", {
  dbBind(res, list("u"))
  dbFetch(res)$n
})
report(
  "dbIsValid(drv): does the driver still hold the instance",
  dbIsValid(drv)
)
report("open the file again from another process", open_elsewhere())
report("dbConnect(duckdb(path)) in this process, and CREATE TABLE u", {
  con2 <- dbConnect(duckdb(path, home = home))
  dbExecute(con2, "CREATE TABLE u (x INTEGER)")
  dbDisconnect(con2)
  "opened"
})
report("dbBind(res, 'u'); dbFetch(res)$n: does the result's instance see u", {
  dbBind(res, list("u"))
  dbFetch(res)$n
})
dbClearResult(res)
report("open the file from another process once the result is cleared", {
  open_elsewhere()
})
