#' DuckDB Result Set
#'
#' Methods for accessing result sets for queries on DuckDB connections.
#' Implements [DBIResult-class].
#'
#' @slot connection the [duckdb_connection-class] the query was executed on.
#' @slot stmt_lst internal list describing the prepared statement (names,
#'   types, ...).
#' @slot env environment holding the result's mutable fetch state.
#' @slot arrow whether the result is fetched via Arrow.
#' @slot query_result external pointer to the underlying materialized query
#'   result.
#' @aliases duckdb_result
#' @keywords internal
#' @export
setClass("duckdb_result",
  contains = "DBIResult",
  slots = list(
    connection = "duckdb_connection",
    stmt_lst = "list",
    env = "environment",
    arrow = "logical",
    query_result = "externalptr"
  )
)

#' DuckDB Arrow Result Set
#'
#' Streaming Arrow result for queries on DuckDB connections.
#' Implements [DBIResultArrow-class][DBI::DBIResultArrow-class].
#'
#' @slot connection the [duckdb_connection-class] the query was executed on.
#' @slot stmt_lst internal list describing the prepared statement.
#' @slot env environment holding the result's mutable fetch state.
#' @aliases duckdb_result_arrow
#' @keywords internal
#' @export
setClass("duckdb_result_arrow",
  contains = "DBIResultArrow",
  slots = list(
    connection = "duckdb_connection",
    stmt_lst = "list",
    env = "environment"
  )
)

duckdb_result_arrow <- function(connection, stmt_lst) {
  env <- new.env(parent = emptyenv())
  env$open <- TRUE
  env$completed <- FALSE
  env$query_result <- NULL

  res <- new(
    "duckdb_result_arrow",
    connection = connection,
    stmt_lst = stmt_lst,
    env = env
  )

  if (stmt_lst$n_param == 0) {
    env$query_result <- duckdb_execute_arrow(res)
  }

  res
}

duckdb_execute_arrow <- function(res) {
  rethrow_rapi_execute(
    res@stmt_lst$ref,
    duckdb_convert_opts_impl(res@connection@convert_opts, arrow = TRUE, streaming = TRUE)
  )
}

duckdb_result <- function(connection, stmt_lst, arrow, stream = FALSE) {
  env <- new.env(parent = emptyenv())
  env$rows_fetched <- 0
  env$open <- TRUE
  env$rows_affected <- 0
  env$stream <- isTRUE(stream) && !arrow && is_stream_query(stmt_lst)
  env$stream_result <- NULL
  env$stream_eof <- FALSE

  res <- new("duckdb_result", connection = connection, stmt_lst = stmt_lst, env = env, arrow = arrow)

  if (stmt_lst$n_param > 0) {
    return(res)
  }

  if (arrow) {
    query_result <- duckdb_execute(res)
    return(new(
      "duckdb_result",
      connection = connection,
      stmt_lst = stmt_lst,
      env = env,
      arrow = arrow,
      query_result = query_result
    ))
  }

  # Parameter-less statements execute eagerly, so side effects (INSERT ...
  # RETURNING, SELECT nextval(), CALL ...) happen at dbSendQuery() time and
  # dbExecute(), which never fetches, works. Only parameterized statements
  # defer execution to dbBind()/first use. Under stream = TRUE, SELECT-shaped
  # statements open a streaming result instead of materializing, so the
  # deferred-allocation benefit is preserved where it matters.
  if (env$stream) {
    duckdb_stream_open(res)
  } else {
    duckdb_execute(res)
  }

  res
}

is_stream_query <- function(stmt_lst) {
  # EXPLAIN results are tiny and wrapped in a bespoke class: keep them
  # materialized. Everything that is not SELECT-shaped executes eagerly and
  # computes rows_affected from the materialized result.
  stmt_lst$type %in% c("SELECT", "RELATION")
}


duckdb_execute <- function(res) {
  out <- rethrow_rapi_execute(
    res@stmt_lst$ref,
    duckdb_convert_opts_impl(res@connection@convert_opts, arrow = res@arrow)
  )
  duckdb_post_execute(res, out)
}

duckdb_execute_pending_bind <- function(res) {
  out <- rethrow_rapi_bind(
    res@stmt_lst$ref,
    res@env$pending_params,
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
  res@env$pending_params <- NULL
}

# Execute a streaming result (dbSendQuery(stream = TRUE)) on first dbFetch():
# the query result stays in C++ as an externalptr, and dbFetch() pulls chunks
# from it via rapi_stream_fetch(). res@env$resultset is never populated.
duckdb_stream_open <- function(res) {
  convert_opts <- duckdb_convert_opts_impl(
    res@connection@convert_opts,
    arrow = FALSE,
    streaming = TRUE
  )
  if (is.null(res@env$pending_params)) {
    res@env$stream_result <- rethrow_rapi_execute(res@stmt_lst$ref, convert_opts)
  } else {
    out <- rethrow_rapi_bind(res@stmt_lst$ref, res@env$pending_params, convert_opts)
    res@env$stream_result <- out[[1]]
    res@env$pending_params <- NULL
  }
}

duckdb_stream_fetch <- function(res, n) {
  if (is.null(res@env$stream_result)) {
    duckdb_stream_open(res)
  }

  out <- rethrow_rapi_stream_fetch(
    res@env$stream_result,
    n,
    duckdb_convert_opts_impl(res@connection@convert_opts, arrow = FALSE, streaming = TRUE)
  )

  df <- out$df
  if (out$eof) {
    res@env$stream_eof <- TRUE
  }

  if (res@connection@convert_opts$tz_out_convert == "force") {
    df <- tz_force(df, res@connection@convert_opts$timezone_out)
  }

  res@env$rows_fetched <- res@env$rows_fetched + nrow(df)
  df
}

# Execute a statement whose parameters are bound but whose execution is still
# pending: streaming results open their stream, everything else materializes
# through the regular bind path.
duckdb_execute_pending <- function(res) {
  if (isTRUE(res@env$stream) && length(res@env$pending_params[[1]]) == 1) {
    duckdb_stream_open(res)
  } else {
    duckdb_execute_pending_bind(res)
  }
}

# Close a live stream (if any) so the connection is free for the next query.
# Safe to call on results that never streamed.
duckdb_stream_close <- function(res) {
  if (!is.null(res@env$stream_result)) {
    rethrow_rapi_stream_close(res@env$stream_result)
    res@env$stream_result <- NULL
  }
  res@env$stream_eof <- FALSE
}

duckdb_post_execute <- function(res, out) {
  if (res@arrow) {
    return(out)
  }

  stopifnot(is.data.frame(out))

  rows_affected <- 0
  if (!(res@stmt_lst$type %in% c("SELECT", "EXPLAIN", "CALL"))) {
    rows_affected <- sum(as.numeric(out[[1]]))
  }
  res@env$rows_affected <- rows_affected

  if (res@connection@convert_opts$tz_out_convert == "force") {
    out <- tz_force(out, res@connection@convert_opts$timezone_out)
  }

  res@env$resultset <- out

  out
}

# as per is.integer documentation
is_wholenumber <- function(x, tol = .Machine$double.eps^0.5) abs(x - round(x)) < tol

#' @rdname duckdb_result-class
#' @param res Query result to be converted to an Arrow Table
#' @param chunk_size The chunk size
#' @export
duckdb_fetch_arrow <- function(res, chunk_size = 1000000) {
  if (chunk_size <= 0) {
    stop("Chunk Size must be higher than 0")
  }
  rethrow_rapi_execute_arrow(res@query_result, chunk_size)
}

#' @rdname duckdb_result-class
#' @param res Query result to be converted to a Record Batch Reader
#' @param chunk_size The chunk size
#' @export
duckdb_fetch_record_batch <- function(res, chunk_size = 1000000) {
  if (chunk_size <= 0) {
    stop("Chunk Size must be higher than 0")
  }
  rethrow_rapi_record_batch(res@query_result, chunk_size)
}

tz_force <- function(x, timezone) {
  if (timezone == "UTC") {
    return(x)
  }

  is_datetime <- which(vapply(x, inherits, "POSIXt", FUN.VALUE = logical(1)))

  if (length(is_datetime) > 0) {
    x[is_datetime] <- lapply(x[is_datetime], tz_force_one, timezone)
  }
  x
}

tz_force_one <- function(x, timezone) {
  # Reset back to UTC
  attr(x, "tzone") <- "UTC"
  # convert to character in ISO format, stripping the timezone
  ct <- format(x, format = "%Y-%m-%d %H:%M:%OS", usetz = FALSE)
  # recreate the POSIXct with specified timezone
  # this is the slow part, and it remains slow even if the input is a POSIXlt
  as.POSIXct(ct, format = "%Y-%m-%d %H:%M:%OS", tz = timezone)
}
