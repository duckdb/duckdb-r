#' @rdname duckdb_driver-class
#' @inheritParams DBI::dbGetInfo
#' @param dbObj An object inheriting from class [duckdb_driver-class].
#' @usage NULL
dbGetInfo__duckdb_driver <- function(dbObj, ...) {
  info <- dbGetInfo__duckdb_connection(default_connection())
  list(
    driver.version = info$db.version,
    client.version = info$db.version,
    dbname = dbObj@dbdir
  )
}

#' @rdname duckdb_driver-class
#' @export
setMethod("dbGetInfo", "duckdb_driver", dbGetInfo__duckdb_driver)
