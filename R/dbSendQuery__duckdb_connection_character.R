# Explained in handbook/usage/statements/README.md.

#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbSendQuery
#' @inheritParams DBI::dbBind
#' @param arrow Whether the query should be returned as an Arrow Table
#' @section Multiple statements:
#' A `statement` can hold several SQL statements separated by semicolons,
#' in [dbSendQuery()], [dbSendQueryArrow()],
#' and the helpers built on them, such as [dbExecute()] and [dbGetQuery()].
#' They run in order, and each is prepared only after those before it have run,
#' so it sees their effects:
#' a `PRAGMA` that generates SQL, such as `create_fts_index`,
#' finds a table created earlier in the same string.
#' Every statement but the last runs when the query is sent,
#' `params` bind to the last statement only,
#' and only the last statement's result is returned.
#'
#' The whole string is parsed before anything runs,
#' so a syntax error in any statement means that none of them run.
#' Any other error stops at the statement that raised it,
#' and the statements before it keep their effect,
#' because the string does not run in a transaction of its own.
#' For all or nothing, run the call inside [dbWithTransaction()],
#' or call [dbBegin()] before it and [dbRollback()] if it fails.
#' To know which statements have run when one fails,
#' send one statement per call.
#' @usage NULL
dbSendQuery__duckdb_connection_character <- function(
  conn,
  statement,
  params = NULL,
  ...,
  arrow = FALSE
) {
  if (conn@debug) {
    message("Q ", statement)
  }

  env <- find_caller()

  statement <- enc2utf8(statement)
  stmt_lst <- rethrow_rapi_prepare(conn@conn_ref, statement, env)

  res <- duckdb_result(
    connection = conn,
    stmt_lst = stmt_lst,
    arrow = arrow
  )
  if (length(params) > 0) {
    dbBind(res, params)
  }
  return(res)
}

#' @rdname duckdb_connection-class
#' @export
setMethod(
  "dbSendQuery",
  c("duckdb_connection", "character"),
  dbSendQuery__duckdb_connection_character
)

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
