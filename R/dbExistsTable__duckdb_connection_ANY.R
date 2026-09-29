#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbExistsTable
#' @usage NULL
dbExistsTable__duckdb_connection_ANY <- function(conn, name, ...) {
  if (!dbIsValid(conn)) {
    abort("Invalid connection")
  }
  if (length(name) != 1) {
    abort("Can only have a single name argument")
  }
  exists <- FALSE
  tryCatch(
    {
      # DESCRIBE fetches the column metadata as text, so a table whose
      # columns R cannot receive is found all the same
      # (handbook/usage/types/README.md).
      dbGetQuery(
        conn,
        sqlInterpolate(
          conn,
          "DESCRIBE SELECT * FROM ? WHERE FALSE",
          dbQuoteIdentifier(conn, name)
        )
      )
      exists <- TRUE
    },
    error = function(c) {}
  )
  exists
}

#' @rdname duckdb_connection-class
#' @export
setMethod(
  "dbExistsTable",
  c("duckdb_connection", "ANY"),
  dbExistsTable__duckdb_connection_ANY
)
