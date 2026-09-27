#' @rdname duckdb_result-class
#' @inheritParams DBI::dbHasCompleted
#' @usage NULL
dbHasCompleted__duckdb_result <- function(res, ...) {
  check_result_open(res)

  if (is.null(res@env$resultset)) {
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
