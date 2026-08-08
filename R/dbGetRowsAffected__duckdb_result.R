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
    duckdb_execute_pending_bind(res)
  }
  # Params required but not yet bound (and legacy arrow results)
  if (is.null(res@env$resultset)) {
    return(NA_integer_)
  }
  return(res@env$rows_affected)
}

#' @rdname duckdb_result-class
#' @export
setMethod("dbGetRowsAffected", "duckdb_result", dbGetRowsAffected__duckdb_result)
