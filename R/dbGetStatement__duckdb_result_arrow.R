#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbGetStatement
#' @usage NULL
dbGetStatement__duckdb_result_arrow <- function(res, ...) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }
  res@stmt_lst$str
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("dbGetStatement", "duckdb_result_arrow", dbGetStatement__duckdb_result_arrow)
