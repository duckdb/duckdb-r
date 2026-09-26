#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbGetStatement
#' @usage NULL
dbGetStatement__duckdb_result_arrow <- function(res, ...) {
  check_result_open(res)
  res@stmt_lst$str
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod(
  "dbGetStatement",
  "duckdb_result_arrow",
  dbGetStatement__duckdb_result_arrow
)
