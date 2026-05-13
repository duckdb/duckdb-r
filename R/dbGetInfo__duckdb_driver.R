#' @rdname duckdb_driver-class
#' @inheritParams DBI::dbGetInfo
#' @param dbObj An object inheriting from class [duckdb_driver-class].
#' @usage NULL
dbGetInfo__duckdb_driver <- function(dbObj, ...) {
  # Use hard-coded version instead of querying database to avoid establishing connection
  version <- get_duckdb_version()

  list(
    driver.version = version,
    client.version = version,
    dbname = dbObj@dbdir
  )
}

#' @rdname duckdb_driver-class
#' @export
setMethod("dbGetInfo", "duckdb_driver", dbGetInfo__duckdb_driver)
