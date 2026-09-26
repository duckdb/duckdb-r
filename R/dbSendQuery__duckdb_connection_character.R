#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbSendQuery
#' @inheritParams DBI::dbBind
#' @param arrow `r lifecycle::badge("deprecated")`
#'   Whether the query should be returned as an Arrow Table.
#'   Use [DBI::dbSendQueryArrow()] or [DBI::dbGetQueryArrow()] instead.
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

  if (isTRUE(arrow)) {
    deprecate_soft(
      paste(
        "`dbSendQuery(arrow = TRUE)` and `dbGetQuery(arrow = TRUE)` are deprecated",
        "and will be removed in a future release.",
        "Use `dbSendQueryArrow()` or `dbGetQueryArrow()` instead."
      ),
      env
    )
  }

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

# Warns like lifecycle::deprecate_soft():
# for a call from user code or a test, not for one from another package's code,
# whose users could not act on the warning.
# arrow::to_arrow() still sends its query with `arrow = TRUE`
# (handbook/usage/memory/reading/README.md).
deprecate_soft <- function(msg, caller_env) {
  caller <- environmentName(topenv(caller_env))
  tested <- Sys.getenv("TESTTHAT_PKG")
  if (
    caller %in%
      c("R_GlobalEnv", "testthat") ||
      (nzchar(tested) && caller == tested)
  ) {
    .Deprecated(msg = msg)
  }
}

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
