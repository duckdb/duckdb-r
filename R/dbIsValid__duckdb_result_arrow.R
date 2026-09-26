#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbIsValid
#' @usage NULL
dbIsValid__duckdb_result_arrow <- function(dbObj, ...) {
  # Cleared, or closed with its connection: see check_result_open() in Result.R.
  dbObj@env$open && dbIsValid(dbObj@connection)
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("dbIsValid", "duckdb_result_arrow", dbIsValid__duckdb_result_arrow)
