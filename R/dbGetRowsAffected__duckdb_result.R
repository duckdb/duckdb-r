#' @rdname duckdb_result-class
#' @inheritParams DBI::dbGetRowsAffected
#' @usage NULL
dbGetRowsAffected__duckdb_result <- function(res, ...) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }
  # dbExecute() never fetches: per the DBI spec, a statement whose parameters
  # are bound but whose execution is still pending runs now, so its side
  # effects and row counts are not lost.
  if (!is.null(res@env$pending_params)) {
    duckdb_execute_pending(res)
  }
  # Return NA only when params are required but not yet bound
  if (is.null(res@env$resultset) && is.null(res@env$stream_result) && res@stmt_lst$n_param > 0) {
    return(NA_integer_)
  }
  return(res@env$rows_affected)
}

#' @rdname duckdb_result-class
#' @export
setMethod("dbGetRowsAffected", "duckdb_result", dbGetRowsAffected__duckdb_result)
