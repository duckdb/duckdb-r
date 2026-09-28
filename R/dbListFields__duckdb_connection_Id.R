#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbListFields
#' @usage NULL
dbListFields__duckdb_connection_Id <- function(conn, name, ...) {
  # DBI's method for `Id` fetches the columns into R, which fails on a table
  # holding a type R cannot hold; the character method reads DESCRIBE,
  # and quotes an `Id` itself (handbook/usage/types/README.md).
  dbListFields__duckdb_connection_character(conn, name, ...)
}

#' @rdname duckdb_connection-class
#' @export
setMethod(
  "dbListFields",
  c("duckdb_connection", "Id"),
  dbListFields__duckdb_connection_Id
)
