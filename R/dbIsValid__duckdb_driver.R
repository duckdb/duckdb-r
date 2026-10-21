#' @rdname duckdb_driver-class
#' @inheritParams DBI::dbIsValid
#' @usage NULL
dbIsValid__duckdb_driver <- function(dbObj, ...) {
  # A predicate, not a probe: the connection this used to open would reopen a
  # database the driver no longer holds, and `duckdb_shutdown()` asks first.
  rethrow_rapi_database_valid(dbObj@database_ref)
}

#' @rdname duckdb_driver-class
#' @export
setMethod("dbIsValid", "duckdb_driver", dbIsValid__duckdb_driver)
