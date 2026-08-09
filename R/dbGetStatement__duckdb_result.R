#' @rdname duckdb_result-class
#' @inheritParams DBI::dbGetStatement
#' @usage NULL
dbGetStatement__duckdb_result <- function(res, ...) {
  if (!res@env$open) {
    abort("result has already been cleared")
  }
  return(res@stmt_lst$str)
}

#' @rdname duckdb_result-class
#' @export
setMethod("dbGetStatement", "duckdb_result", dbGetStatement__duckdb_result)
