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
  # Outside the probe, so that a name that cannot be quoted is an error.
  quoted <- dbQuoteIdentifier(conn, name)
  # A probe that fails must leave an open transaction usable,
  # which from DuckDB 2.0 takes relaxing its policy while the probe runs
  # (handbook/usage/statements/README.md).
  if (can_relax_invalidation_policy(conn)) {
    dbExecute(
      conn,
      "SET current_transaction_invalidation_policy = 'SYNTACTIC_ERRORS_DO_NOT_INVALIDATE'"
    )
    on.exit(tryCatch(
      dbExecute(
        conn,
        "SET current_transaction_invalidation_policy = 'STANDARD_POLICY'"
      ),
      # A transaction the probe aborted takes its policy from the next BEGIN.
      error = function(e) NULL
    ))
  }
  tryCatch(
    {
      # DESCRIBE fetches the column metadata as text, so a table whose
      # columns R cannot receive is found all the same
      # (handbook/usage/types/README.md).
      dbGetQuery(
        conn,
        sqlInterpolate(conn, "DESCRIBE SELECT * FROM ? WHERE FALSE", quoted)
      )
      TRUE
    },
    error = function(c) {
      # In a transaction that had already failed, nothing was looked up.
      if (identical(c$error_type, "TRANSACTION")) {
        stop(c)
      }
      FALSE
    }
  )
}

# Whether the probe can relax the transaction's policy.
# The engine has the policy from DuckDB 2.0; once main vendors 2.0, the version
# check goes (https://github.com/duckdb/duckdb-r/issues/2895).
# A locked configuration refuses the change, and refusing aborts the
# transaction, asked every time because a connection can lock it at any point.
can_relax_invalidation_policy <- function(conn) {
  numeric_version(sub("-.*", "", get_duckdb_version())) >= "2.0.0" &&
    !dbGetQuery(
      conn,
      "SELECT current_setting('lock_configuration') AS locked"
    )$locked
}

#' @rdname duckdb_connection-class
#' @export
setMethod(
  "dbExistsTable",
  c("duckdb_connection", "ANY"),
  dbExistsTable__duckdb_connection_ANY
)
