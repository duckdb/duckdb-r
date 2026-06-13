#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbBind
#' @usage NULL
dbBind__duckdb_result_arrow <- function(res, params, ...) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }
  res@env$completed <- FALSE
  res@env$arrow_schema <- NULL
  res@env$query_result <- NULL
  res@env$pending_query_results <- NULL

  params <- as.list(params)
  if (!is.null(names(params))) {
    stop("`params` must not be named")
  }

  params <- encode_values(params)

  out <- rethrow_rapi_bind(
    res@stmt_lst$ref,
    params,
    duckdb_convert_opts_impl(res@connection@convert_opts, arrow = TRUE)
  )
  if (length(out) == 0L) {
    # Zero-length bind: no executions; result is immediately drained.
    res@env$completed <- TRUE
  } else {
    res@env$query_result <- out[[1L]]
    if (length(out) > 1L) {
      res@env$pending_query_results <- out[-1L]
    }
  }
  invisible(res)
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("dbBind", "duckdb_result_arrow", dbBind__duckdb_result_arrow)

#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbBindArrow
#' @usage NULL
dbBindArrow__duckdb_result_arrow <- function(res, params, ...) {
  require_nanoarrow("dbBindArrow()")
  param_list <- as.list(as.data.frame(nanoarrow::as_nanoarrow_array_stream(params)))
  if (length(param_list) > 0 && all(names(param_list) == "")) {
    names(param_list) <- NULL
  }
  dbBind(res, param_list, ...)
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("dbBindArrow", "duckdb_result_arrow", dbBindArrow__duckdb_result_arrow)
