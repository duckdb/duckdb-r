#' @rdname duckdb_result-class
#' @inheritParams DBI::dbBind
#' @details
#' `dbBind()` does not execute the statement:
#' execution happens at the first use of the result,
#' in `dbFetch()` or `dbGetRowsAffected()`.
#' Consequently, binding parameters and then clearing the result
#' without using it does not execute the statement.
#' The flows in the DBI specification always use the result
#' after binding.
#' @usage NULL
dbBind__duckdb_result <- function(res, params, ...) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }

  params <- as.list(params)
  if (!is.null(names(params))) {
    stop("`params` must not be named")
  }

  # Validate parameter count (mirrors rapi_bind C++ validation), so that
  # structural errors still surface at bind time
  n_param <- res@stmt_lst$n_param
  if (n_param == 0) {
    stop("`dbBind()` called but query takes no parameters", call. = FALSE)
  }
  if (length(params) != n_param) {
    stop("Bind parameters need to be a list of length ", n_param, call. = FALSE)
  }

  res@env$rows_fetched <- 0
  res@env$resultset <- NULL
  res@env$pending_params <- NULL

  params <- encode_values(params)

  if (!res@arrow) {
    # Defer execution to the first use of the result: dbFetch() or
    # dbGetRowsAffected(). Known limitation, per the DBI spec flows:
    # dbBind() + dbClearResult() without using the result does not execute
    # the statement. An explicit dbSendStatement() method
    # (duckdb/duckdb-r#2565) and the plan in duckdb/duckdb-r#2583 will
    # take care of that: warn on dbSendStatement() + dbBind() +
    # dbClearResult(), or eagerly start the work in background threads.
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
