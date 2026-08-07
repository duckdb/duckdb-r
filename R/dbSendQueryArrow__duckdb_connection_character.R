#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbSendQueryArrow
#' @inheritParams DBI::dbBind
#' @usage NULL
dbSendQueryArrow__duckdb_connection_character <- function(conn, statement, params = NULL, ...) {
  if (conn@debug) {
    message("Q ", statement)
  }

  env <- find_caller()

  statement <- enc2utf8(statement)
  stmt_lst <- rethrow_rapi_prepare(conn@conn_ref, statement, env)

  res <- duckdb_result_arrow(
    connection = conn,
    stmt_lst = stmt_lst
  )
  if (length(params) > 0) {
    dbBind(res, params)
  }
  res
}

#' @rdname duckdb_connection-class
#' @export
setMethod(
  "dbSendQueryArrow", c("duckdb_connection", "character"),
  dbSendQueryArrow__duckdb_connection_character
)
