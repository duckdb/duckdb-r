#' @rdname duckdb_result-class
#' @inheritParams DBI::dbIsValid
#' @usage NULL
dbIsValid__duckdb_result <- function(dbObj, ...) {
  # Cleared, or closed with its connection: see check_result_open() in Result.R.
  dbObj@env$open && dbIsValid(dbObj@connection)
}

#' @rdname duckdb_result-class
#' @export
setMethod("dbIsValid", "duckdb_result", dbIsValid__duckdb_result)
