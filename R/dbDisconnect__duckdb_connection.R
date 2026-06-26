#' @description
#' `dbDisconnect()` closes a DuckDB database connection.
#' The associated DuckDB database instance is shut down automatically,
#' it is no longer necessary to set `shutdown = TRUE` or to call `duckdb_shutdown()`.
#'
#' @param conn A `duckdb_connection` object
#' @param shutdown Unused. The database instance is shut down automatically.
#' @rdname duckdb
#' @usage NULL
dbDisconnect__duckdb_connection <- function(conn, ..., shutdown = TRUE) {
  if (!dbIsValid(conn)) {
    warning("Connection already closed.", call. = FALSE)
    invisible(FALSE)
  }
  rethrow_rapi_disconnect(conn@conn_ref)
  rs_on_connection_closed(conn)
  invisible(TRUE)
}

#' @rdname duckdb
#' @export
setMethod("dbDisconnect", "duckdb_connection", dbDisconnect__duckdb_connection)
