#' @rdname duckdb_result-class
#' @inheritParams DBI::dbGetStatement
#' @usage NULL
dbGetStatement__duckdb_result <- function(res, ...) {
  check_result_open(res)
  return(res@stmt_lst$str)
}

#' @rdname duckdb_result-class
#' @export
setMethod("dbGetStatement", "duckdb_result", dbGetStatement__duckdb_result)
