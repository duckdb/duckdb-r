#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbClearResult
#' @usage NULL
dbClearResult__duckdb_result_arrow <- function(res, ...) {
  if (res@env$open) {
    res@env$query_result <- NULL
    rethrow_rapi_release(res@stmt_lst$ref)
    res@env$open <- FALSE
  } else {
    warning("Result was cleared already")
  }
  invisible(TRUE)
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("dbClearResult", "duckdb_result_arrow", dbClearResult__duckdb_result_arrow)
