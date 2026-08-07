#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbGetRowsAffected
#' @usage NULL
dbGetRowsAffected__duckdb_result_arrow <- function(res, ...) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }
  NA_integer_
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("dbGetRowsAffected", "duckdb_result_arrow", dbGetRowsAffected__duckdb_result_arrow)
