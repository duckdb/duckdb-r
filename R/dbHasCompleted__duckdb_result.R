#' @rdname duckdb_result-class
#' @inheritParams DBI::dbHasCompleted
#' @usage NULL
dbHasCompleted__duckdb_result <- function(res, ...) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }

  # Streaming results never populate resultset: completed once a dbFetch()
  # call has drained the stream. A multi-row bind falls back to the
  # materialized path and is handled below.
  if (isTRUE(res@env$stream) && is.null(res@env$resultset)) {
    res@env$stream_eof
  } else if (is.null(res@env$resultset)) {
    FALSE
  } else if (res@stmt_lst$type == "SELECT") {
    res@env$rows_fetched == nrow(res@env$resultset)
  } else {
    TRUE
  }
}

#' @rdname duckdb_result-class
#' @export
setMethod("dbHasCompleted", "duckdb_result", dbHasCompleted__duckdb_result)
