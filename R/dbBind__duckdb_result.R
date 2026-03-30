#' @rdname duckdb_result-class
#' @inheritParams DBI::dbBind
#' @usage NULL
dbBind__duckdb_result <- function(res, params, ...) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }

  params <- as.list(params)
  if (!is.null(names(params))) {
    stop("`params` must not be named")
  }

  # Validate parameter count (mirrors rapi_bind C++ validation)
  n_param <- res@stmt_lst$n_param
  if (n_param == 0) {
    stop("`dbBind()` called but query takes no parameters")
  }
  if (length(params) != n_param) {
    stop("Bind parameters need to be a list of length ", n_param)
  }

  res@env$rows_fetched <- 0
  res@env$resultset <- NULL

  params <- encode_values(params)

  is_data_query <- res@stmt_lst$type %in% c("SELECT", "EXPLAIN", "RELATION") ||
    res@stmt_lst$return_type == "QUERY_RESULT"

  if (is_data_query && !res@arrow) {
    # Defer execution to dbFetch() for data-returning queries
    res@env$pending_params <- params
  } else {
    out <- rethrow_rapi_bind(
      res@stmt_lst$ref,
      params,
      duckdb_convert_opts_impl(res@connection@convert_opts, arrow = res@arrow)
    )
    if (length(out) == 1) {
      out <- out[[1]]
    } else if (length(out) == 0) {
      out <- data.frame()
    } else {
      out <- do.call(rbind, out)
    }
    duckdb_post_execute(res, out)
  }
  invisible(res)
}

#' @rdname duckdb_result-class
#' @export
setMethod("dbBind", "duckdb_result", dbBind__duckdb_result)
