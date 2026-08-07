#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbGetRowCount
#' @usage NULL
dbGetRowCount__duckdb_result_arrow <- function(res, ...) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }
  0
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("dbGetRowCount", "duckdb_result_arrow", dbGetRowCount__duckdb_result_arrow)
