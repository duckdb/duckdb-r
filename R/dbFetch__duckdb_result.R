#' @rdname duckdb_result-class
#' @inheritParams DBI::dbFetch
#' @importFrom utils head
#' @usage NULL
dbFetch__duckdb_result <- function(res, n = -1, ...) {
  if (!res@env$open) {
    stop("result set was closed")
  }

  if (res@arrow) {
    if (n != -1) {
      stop("Cannot dbFetch() an Arrow result unless n = -1")
    }
    return(as.data.frame(duckdb_fetch_arrow(res)))
  }

  # Streaming results (dbSendQuery(stream = TRUE)) pull chunks on demand and
  # never populate res@env$resultset. Multi-row binds materialize row-by-row
  # results (a prepared statement supports only one live stream), so they take
  # the default path below; the same result streams again after a subsequent
  # single-row dbBind().
  if (
    isTRUE(res@env$stream) &&
      is.null(res@env$resultset) &&
      (is.null(res@env$pending_params) || length(res@env$pending_params[[1]]) == 1)
  ) {
    if (
      res@stmt_lst$n_param > 0 &&
        is.null(res@env$pending_params) &&
        is.null(res@env$stream_result)
    ) {
      stop("Need to call `dbBind()` before `dbFetch()`")
    }
    return(duckdb_stream_fetch(res, check_fetch_n(n)))
  }

  # Handle deferred execution
  if (is.null(res@env$resultset)) {
    if (!is.null(res@env$pending_params)) {
      # Deferred bind+execute (parameterized query)
      duckdb_execute_pending_bind(res)
    } else if (res@stmt_lst$n_param == 0) {
      # Deferred execute (no params)
      duckdb_execute(res)
    } else {
      stop("Need to call `dbBind()` before `dbFetch()`")
    }
  }
  if (res@stmt_lst$type == "EXPLAIN") {
    df <- res@env$resultset
    attr(df, "query") <- res@stmt_lst$str
    class(df) <- c("duckdb_explain", class(df))
    return(df)
  }
  n <- check_fetch_n(n)
  if (res@stmt_lst$type != "SELECT" && res@stmt_lst$type != "RELATION" && res@stmt_lst$return_type != "QUERY_RESULT") {
    warning("Should not call dbFetch() on results that do not come from SELECT, got ", res@stmt_lst$type)
    return(data.frame())
  }

  if (res@env$rows_fetched < 0) {
    res@env$rows_fetched <- 0
  }

  n_remaining <- nrow(res@env$resultset) - res@env$rows_fetched

  if (n == -1) {
    n <- n_remaining
  } else {
    n <- min(n, n_remaining)
  }

  if (res@env$rows_fetched == 0 && n == n_remaining) {
    # Shortcut for performance
    df <- res@env$resultset
  } else if (n > 0) {
    df <- res@env$resultset[seq.int(res@env$rows_fetched + 1, res@env$rows_fetched + n), , drop = FALSE]
    attr(df, "row.names") <- c(NA_integer_, as.integer(-n))
  } else {
    df <- res@env$resultset[integer(), , drop = FALSE]
  }

  res@env$rows_fetched <- res@env$rows_fetched + n

  df
}

check_fetch_n <- function(n) {
  if (length(n) != 1) {
    stop("need exactly one value in n")
  }
  if (is.infinite(n) || is.na(n)) {
    n <- -1
  }
  if (n < -1) {
    stop("cannot fetch negative n other than -1")
  }
  if (!is_wholenumber(n)) {
    stop("n needs to be not a whole number")
  }
  n
}

#' @rdname duckdb_result-class
#' @export
setMethod("dbFetch", "duckdb_result", dbFetch__duckdb_result)
