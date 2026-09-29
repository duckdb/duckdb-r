#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbListFields
#' @usage NULL
dbListFields__duckdb_connection_character <- function(conn, name, ...) {
  # DESCRIBE fetches the column metadata as text, so a table whose columns
  # R cannot receive still lists them (handbook/usage/types/README.md).
  dbGetQuery(
    conn,
    sqlInterpolate(
      conn,
      "DESCRIBE SELECT * FROM ? WHERE FALSE",
      dbQuoteIdentifier(conn, name)
    )
  )$column_name
}

#' @rdname duckdb_connection-class
#' @export
setMethod(
  "dbListFields",
  c("duckdb_connection", "character"),
  dbListFields__duckdb_connection_character
)
