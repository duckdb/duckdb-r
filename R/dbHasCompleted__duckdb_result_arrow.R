#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbHasCompleted
#' @usage NULL
dbHasCompleted__duckdb_result_arrow <- function(res, ...) {
  check_result_open(res)
  isTRUE(res@env$completed)
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod(
  "dbHasCompleted",
  "duckdb_result_arrow",
  dbHasCompleted__duckdb_result_arrow
)
