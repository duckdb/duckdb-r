#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbGetInfo
#' @param dbObj An object inheriting from class [duckdb_connection-class].
#' @usage NULL
dbGetInfo__duckdb_connection <- function(dbObj, ...) {
  # Use hard-coded version instead of querying database to avoid establishing connection
  version <- get_duckdb_version()

  list(
    dbname = dbObj@driver@dbdir,
    db.version = version,
    username = NA,
    host = NA,
    port = NA
  )
}

#' @rdname duckdb_connection-class
#' @export
setMethod("dbGetInfo", "duckdb_connection", dbGetInfo__duckdb_connection)
