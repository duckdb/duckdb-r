#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbAppendTable
#' @usage NULL
dbAppendTable__duckdb_connection <- function(conn, name, value, ..., row.names = NULL) {
  if (!is.null(row.names)) {
    stop("Can't pass `row.names` to `dbAppendTable()`")
  }

  target_names <- dbListFields(conn, name)

  if (!all(names(value) %in% target_names)) {
    stop("Column `", setdiff(names(value), target_names)[[1]], "` does not exist in target table.")
  }

  if (nrow(value)) {
    table_name <- dbQuoteIdentifier(conn, name)

    view_name <- sprintf("_duckdb_append_view_%s", duckdb_random_string())
    on.exit(duckdb_unregister(conn, view_name))
    duckdb_register(conn, view_name, value)

    target_types <- duckdb_target_column_types(conn, name)
    select_exprs <- duckdb_select_exprs_for_target(conn, names(value), target_types)

    sql <- paste0(
      "INSERT INTO ", table_name, "\n",
      "(", paste(dbQuoteIdentifier(conn, names(value)), collapse = ", "), ")\n",
      "SELECT ", paste(select_exprs, collapse = ", "), " FROM ", view_name
    )

    dbExecute(conn, sql)

    rs_on_connection_updated(conn, hint = paste0("Updated table'", table_name, "'"))
  }

  invisible(nrow(value))
}

# Build a named vector mapping target column names to DuckDB column type strings.
duckdb_target_column_types <- function(conn, name) {
  info <- dbGetQuery(
    conn,
    paste0("DESCRIBE ", dbQuoteIdentifier(conn, name))
  )
  setNames(info$column_type, info$column_name)
}

# Build SELECT column expressions, converting source representations into the
# target column types where DuckDB cannot implicitly cast (e.g. MAP).
duckdb_select_exprs_for_target <- function(conn, col_names, target_types) {
  vapply(col_names, function(col_name) {
    quoted <- dbQuoteIdentifier(conn, col_name)
    target_type <- target_types[[col_name]]
    if (!is.null(target_type) && duckdb_is_map_type(target_type)) {
      # `map_from_entries()` builds a MAP from a LIST(STRUCT(key, value))
      # representation, which matches how MAPs are read back into R.
      paste0("map_from_entries(", quoted, ") AS ", quoted)
    } else {
      as.character(quoted)
    }
  }, character(1), USE.NAMES = FALSE)
}

# Returns TRUE if `type` is a top-level DuckDB MAP type,
# e.g. "MAP(VARCHAR, INTEGER)". Returns FALSE for nested types
# such as "MAP(VARCHAR, INTEGER)[]" (array of MAP) or "STRUCT(m MAP(...))".
duckdb_is_map_type <- function(type) {
  grepl("^MAP\\(.*\\)$", type)
}

#' @rdname duckdb_connection-class
#' @export
setMethod("dbAppendTable", "duckdb_connection", dbAppendTable__duckdb_connection)
