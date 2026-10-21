#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbIsValid
#' @usage NULL
dbIsValid__duckdb_result_arrow <- function(dbObj, ...) {
  dbObj@env$open
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("dbIsValid", "duckdb_result_arrow", dbIsValid__duckdb_result_arrow)
