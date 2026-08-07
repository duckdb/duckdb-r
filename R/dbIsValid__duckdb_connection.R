#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbIsValid
#' @usage NULL
dbIsValid__duckdb_connection <- function(dbObj, ...) {
  # Use fast C++ connection validity check instead of executing SELECT 1
  # This avoids deadlock issues when called from progress bar handlers
  # that already have ScopedInterruptHandler protection
  rethrow_rapi_connection_valid(dbObj@conn_ref)
}

#' @rdname duckdb_connection-class
#' @export
setMethod("dbIsValid", "duckdb_connection", dbIsValid__duckdb_connection)
