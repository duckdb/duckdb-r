#' @description
#' `dbDisconnect()` closes a DuckDB database connection.
#' The associated DuckDB database instance is shut down automatically,
#' it is no longer necessary to set `shutdown = TRUE` or to call `duckdb_shutdown()`.
#' Results still open on the connection are closed with it, with a warning:
#' clear them with [dbClearResult()] first.
#'
#' @param conn A `duckdb_connection` object
#' @param shutdown Unused.
#' The database instance is shut down automatically.
#' @rdname duckdb
#' @usage NULL
dbDisconnect__duckdb_connection <- function(conn, ..., shutdown = TRUE) {
  if (!dbIsValid(conn)) {
    warning("Connection already closed.", call. = FALSE)
    return(invisible(FALSE))
  }
  # Closing the connection closes the results still open on it, so that no
  # result keeps the instance alive past its connection
  # (handbook/architecture/glue/objects/README.md).
  # DBI asks for them to be cleared first, and for a warning otherwise.
  open_results <- rethrow_rapi_disconnect(conn@conn_ref)
  if (open_results > 0) {
    warning(
      sprintf(
        ngettext(
          open_results,
          "%d result was still open on this connection and has been closed with it.",
          "%d results were still open on this connection and have been closed with it."
        ),
        open_results
      ),
      "\nClear results with `dbClearResult()` before disconnecting.",
      call. = FALSE
    )
  }
  rs_on_connection_closed(conn)
  invisible(TRUE)
}

#' @rdname duckdb
#' @export
setMethod("dbDisconnect", "duckdb_connection", dbDisconnect__duckdb_connection)
