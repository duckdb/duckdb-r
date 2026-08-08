#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbSendQuery
#' @inheritParams DBI::dbBind
#' @param arrow Whether the query should be returned as an Arrow Table.
#'   `r lifecycle::badge("superseded")`: this path is slated for retirement;
#'   switch to the DBI generics, which stream via Arrow natively.
#'   The replacement is a drop-in change of the call:
#'   `dbSendQuery(con, sql, arrow = TRUE)` becomes
#'   [DBI::dbSendQueryArrow()]`(con, sql)`,
#'   fetch with [DBI::dbFetchArrow()] (everything, as a
#'   \pkg{nanoarrow} array stream) or [DBI::dbFetchArrowChunk()]
#'   (one batch at a time), and convert via
#'   [as.data.frame()] or `arrow::as_arrow_table()` as needed.
#'   For one-shot queries, `dbGetQuery(con, sql, arrow = TRUE)` becomes
#'   [DBI::dbGetQueryArrow()]`(con, sql)`.
#' @param stream Whether to fetch the result in chunks instead of
#'   materializing it on the first [dbFetch()] call.
#'   With `stream = TRUE`, `dbFetch(n = ...)` pulls only the requested rows
#'   from a streaming query result, so larger-than-memory results can be
#'   processed piece by piece.
#'   A streaming result holds a live cursor on the connection:
#'   running any other query on the same connection invalidates it,
#'   and fetching from an invalidated stream throws an error.
#'   `dbHasCompleted()` returns `TRUE` only after a `dbFetch()` call has
#'   drained the stream.
#'   The default `NULL` uses the connection-level default set via
#'   `dbConnect(stream = ...)`, which in turn defaults to `FALSE`.
#'   Applies to SELECT-shaped queries; other statements, including `EXPLAIN`,
#'   are unaffected.
#'   Not supported together with `arrow = TRUE`:
#'   use [DBI::dbSendQueryArrow()] for streaming via Arrow.
#' @usage NULL
dbSendQuery__duckdb_connection_character <- function(conn, statement, params = NULL, ..., arrow = FALSE, stream = NULL) {
  if (conn@debug) {
    message("Q ", statement)
  }

  if (is.null(stream)) {
    stream <- isTRUE(conn@stream)
  }
  if (isTRUE(stream) && isTRUE(arrow)) {
    stop(
      "`stream = TRUE` cannot be combined with `arrow = TRUE` ",
      "(including a `dbConnect(stream = TRUE)` default). ",
      "The legacy `arrow = TRUE` path is slated for retirement: ",
      "use `dbSendQueryArrow()` with `dbFetchArrow()` to stream via Arrow."
    )
  }

  env <- find_caller()

  statement <- enc2utf8(statement)
  stmt_lst <- rethrow_rapi_prepare(conn@conn_ref, statement, env)

  res <- duckdb_result(
    connection = conn,
    stmt_lst = stmt_lst,
    arrow = arrow,
    stream = stream
  )
  if (length(params) > 0) {
    dbBind(res, params)
  }
  return(res)
}

#' @rdname duckdb_connection-class
#' @export
setMethod("dbSendQuery", c("duckdb_connection", "character"), dbSendQuery__duckdb_connection_character)

find_caller <- function() {
  i <- 3L
  env <- parent.frame(i)

  while (!identical(env, emptyenv())) {
    env_name <- environmentName(parent.env(env))
    if (!(env_name %in% c(get_package_name(), "DBI"))) {
      return(env)
    }
    i <- i + 1L
    env <- parent.frame(i)
  }

  env
}
