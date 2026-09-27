#' @rdname duckdb_result-class
#' @inheritParams DBI::dbGetRowCount
#' @usage NULL
dbGetRowCount__duckdb_result <- function(res, ...) {
  check_result_open(res)
  return(res@env$rows_fetched)
}

#' @rdname duckdb_result-class
#' @export
setMethod("dbGetRowCount", "duckdb_result", dbGetRowCount__duckdb_result)
