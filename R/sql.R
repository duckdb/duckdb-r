sql <- function(sql, conn = default_connection()) {
  stopifnot(dbIsValid(conn))
  dbGetQuery(conn, sql)
}

default_duckdb_connection <- new.env(parent=emptyenv())

default_connection <- function() {
  if(!exists("con", default_duckdb_connection)) {
    con <- DBI::dbConnect(duckdb::duckdb())

    default_duckdb_connection$con <- con

    reg.finalizer(default_duckdb_connection, onexit = TRUE, function(e) {
      DBI::dbDisconnect(e$con, shutdown = TRUE)
    })
  }
  default_duckdb_connection$con
}
