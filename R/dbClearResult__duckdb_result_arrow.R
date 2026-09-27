#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbClearResult
#' @usage NULL
dbClearResult__duckdb_result_arrow <- function(res, ...) {
  if (res@env$open) {
    if (!is.null(res@env$query_result)) {
      rethrow_rapi_release_arrow_result(res@env$query_result)
    }
    res@env$query_result <- NULL
    # The unread results of a multi-row bind hold their rows outside R's heap,
    # which the garbage collector would free only whenever it next runs.
    for (query_result in res@env$pending_query_results) {
      rethrow_rapi_release_arrow_result(query_result)
    }
    res@env$pending_query_results <- NULL
    rethrow_rapi_release(res@stmt_lst$ref)
    res@env$open <- FALSE
  } else {
    warning("Result was cleared already")
  }
  invisible(TRUE)
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod(
  "dbClearResult",
  "duckdb_result_arrow",
  dbClearResult__duckdb_result_arrow
)
