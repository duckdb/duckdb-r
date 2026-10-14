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
  frame <- environment()
  tryCatch(
    probe_table(conn, quoted),
    error = function(c) {
      # In a transaction that had already failed, nothing was looked up.
      if (identical(c$error_type, "TRANSACTION")) {
        stop(c)
      }
      if (
        identical(c$error_type, "INVALID_INPUT") &&
          grepl(
            "configuration has been locked",
            conditionMessage(c),
            fixed = TRUE
          )
      ) {
        abort(
          c(
            "Can't look up a table inside a transaction while the configuration is locked.",
            i = "From DuckDB 2.0, a failed lookup aborts the transaction unless the transaction's policy is relaxed, which `lock_configuration` refuses.",
            i = "The transaction is aborted. Look up tables before `dbBegin()`, or connect without `lock_configuration`."
          ),
          parent = c,
          call = frame
        )
      }
      FALSE
    }
  )
}

# Binds `SELECT * FROM` the quoted name, which raises for a name that does not
# resolve; inside a transaction, from DuckDB 2.0, with the transaction's policy
# relaxed so that a failure leaves it usable
# (handbook/usage/statements/README.md).
probe_table <- function(conn, quoted) {
  if (can_relax_invalidation_policy(conn)) {
    dbExecute(
      conn,
      "SET current_transaction_invalidation_policy = 'SYNTACTIC_ERRORS_DO_NOT_INVALIDATE'"
    )
    on.exit(dbExecute(
      conn,
      "SET current_transaction_invalidation_policy = 'STANDARD_POLICY'"
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

# Inside a transaction, where a failure would abort it, and with DuckDB 2.0,
# which has the policy; once main vendors 2.0, the version check goes
# (https://github.com/duckdb/duckdb-r/issues/2895).
can_relax_invalidation_policy <- function(conn) {
  numeric_version(sub("-.*", "", get_duckdb_version())) >= "2.0.0" &&
    rethrow_rapi_connection_in_transaction(conn@conn_ref)
}

#' @rdname duckdb_connection-class
#' @export
setMethod(
  "dbExistsTable",
  c("duckdb_connection", "ANY"),
  dbExistsTable__duckdb_connection_ANY
)
