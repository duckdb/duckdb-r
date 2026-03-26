#' @rdname duckdb_result-class
#' @inheritParams DBI::dbGetRowsAffected
#' @usage NULL
dbGetRowsAffected__duckdb_result <- function(res, ...) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }
  # Return NA only when params are required but not yet bound
  if (is.null(res@env$resultset) && res@stmt_lst$n_param > 0 && is.null(res@env$pending_params)) {
    return(NA_integer_)
  }
  return(res@env$rows_affected)
}

#' @rdname duckdb_result-class
#' @export
setMethod("dbGetRowsAffected", "duckdb_result", dbGetRowsAffected__duckdb_result)
