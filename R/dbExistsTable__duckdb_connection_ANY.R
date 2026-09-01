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
  # Quoted outside the probe, so a name that cannot be quoted is an error
  # rather than a table that does not exist.
  quoted <- dbQuoteIdentifier(conn, name)
  tryCatch(
    probe_table(conn, quoted),
    error = function(c) {
      # In a transaction that had already failed, nothing was looked up.
      if (identical(c$error_type, "TRANSACTION")) {
        stop(c)
      }
      FALSE
    }
  )
}

# Binds `SELECT * FROM` the quoted name, which raises for a name that does not
# resolve; inside a transaction, from DuckDB 2.0, with the transaction's policy
# relaxed so that a failure leaves it usable, and put back as it was
# (handbook/usage/statements/README.md).
probe_table <- function(conn, quoted) {
  # Once main vendors DuckDB 2.0, the version check goes
  # (https://github.com/duckdb/duckdb-r/issues/2895).
  if (
    numeric_version(sub("-.*", "", get_duckdb_version())) >= "2.0.0" &&
      rethrow_rapi_connection_in_transaction(conn@conn_ref)
  ) {
    previous <- rethrow_rapi_connection_set_invalidation_policy(
      conn@conn_ref,
      "SYNTACTIC_ERRORS_DO_NOT_INVALIDATE"
    )
    on.exit(rethrow_rapi_connection_set_invalidation_policy(
      conn@conn_ref,
      previous
    ))
  }
  # DESCRIBE fetches the column metadata as text, so a table whose
  # columns R cannot receive is found all the same
  # (handbook/usage/types/README.md).
  dbGetQuery(
    conn,
    sqlInterpolate(conn, "DESCRIBE SELECT * FROM ? WHERE FALSE", quoted)
  )
  TRUE
}

#' @rdname duckdb_connection-class
#' @export
setMethod(
  "dbExistsTable",
  c("duckdb_connection", "ANY"),
  dbExistsTable__duckdb_connection_ANY
)
