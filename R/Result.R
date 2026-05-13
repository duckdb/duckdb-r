#' DuckDB Result Set
#'
#' Methods for accessing result sets for queries on DuckDB connections.
#' Implements [DBIResult-class].
#'
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

duckdb_result <- function(connection, stmt_lst, arrow) {
  env <- new.env(parent = emptyenv())
  env$rows_fetched <- 0
  env$open <- TRUE
  env$rows_affected <- 0

  res <- new("duckdb_result", connection = connection, stmt_lst = stmt_lst, env = env, arrow = arrow)

  if (stmt_lst$n_param == 0) {
    if (arrow) {
      query_result <- duckdb_execute(res)
      new_res <- new(
        "duckdb_result",
        connection = connection,
        stmt_lst = stmt_lst,
        env = env,
        arrow = arrow,
        query_result = query_result
      )
      return(new_res)
    } else {
      duckdb_execute(res)
    }
  }

  return(res)
}

duckdb_execute <- function(res) {
  out <- rethrow_rapi_execute(
    res@stmt_lst$ref,
    duckdb_convert_opts_impl(res@connection@convert_opts, arrow = res@arrow)
  )
  duckdb_post_execute(res, out)
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

  if (res@connection@tz_out_convert == "force") {
    out <- tz_force(out, res@connection@timezone_out)
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
