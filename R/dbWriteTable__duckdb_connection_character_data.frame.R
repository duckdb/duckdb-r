#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbWriteTable
#' @param conn A [duckdb_connection-class] object as returned by [DBI::dbConnect()]
#' @param row.names Whether the row.names of the data.frame should be preserved
#' @param overwrite If a table with the given name already exists, should it be overwritten?
#' @param append If a table with the given name already exists, just try to append the passed data to it
#' @param field.types Override the auto-generated SQL types
#' @param temporary Should the created table be temporary?
#' @usage NULL
dbWriteTable__duckdb_connection_character_data.frame <- function(conn,
                                                                 name,
                                                                 value,
                                                                 ...,
                                                                 row.names = FALSE,
                                                                 overwrite = FALSE,
                                                                 append = FALSE,
                                                                 field.types = NULL,
                                                                 temporary = FALSE) {
  check_flag(overwrite)
  check_flag(append)
  check_flag(temporary)

  # TODO: start a transaction if one is not already running

  if (overwrite && append) {
    stop("Setting both overwrite and append makes no sense")
  }

  if (!is.null(field.types)) {
    if (!(is.character(field.types) && !is.null(names(field.types)) && !anyDuplicated(names(field.types)))) {
      stop("`field.types` must be a named character vector with unique names, or NULL")
    }
  }
  if (append && !is.null(field.types)) {
    stop("Cannot specify `field.types` with `append = TRUE`")
  }

  value <- as.data.frame(value)
  if (!is.data.frame(value)) {
    stop("need a data frame as parameter")
  }

  # use Kirill's magic, convert rownames to additional column
  value <- sqlRownamesToColumn(value, row.names)

  if (dbExistsTable(conn, name)) {
    if (overwrite) {
      dbRemoveTable(conn, name)
    }
    if (!overwrite && !append) {
      stop(
        "Table ",
        name,
        " already exists. Set `overwrite = TRUE` if you want to remove the existing table. ",
        "Set `append = TRUE` if you would like to add the new data to the existing table."
      )
    }
  }
  table_name <- dbQuoteIdentifier(conn, name)

  if (!dbExistsTable(conn, name)) {
    view_name <- sprintf("_duckdb_write_view_%s", duckdb_random_string())
    on.exit(duckdb_unregister(conn, view_name))
    duckdb_register(conn, view_name, value)

    temp_str <- ""
    if (temporary) temp_str <- "TEMPORARY"

    col_names <- dbGetQuery(conn, SQL(sprintf(
      "DESCRIBE %s", view_name
    )))$column_name

    # Auto-fill MAP column types from `dbDataType()`, so that
    # `vctrs::list_of`-tagged columns produced by
    # `dbConnect(map = "list_of")` round-trip back into MAP columns.
    field.types <- duckdb_augment_field_types_for_map(conn, value, field.types)

    cols <- character()
    col_idx <- 1
    for (name in col_names) {
      if (name %in% names(field.types)) {
        if (duckdb_is_map_type(field.types[[name]])) {
          # `map_from_entries()` builds a MAP from a LIST(STRUCT(key, value))
          # representation, which matches how MAPs are read back into R.
          cols <- c(cols, sprintf("map_from_entries(#%d)::%s %s", col_idx, field.types[name], dbQuoteIdentifier(conn, name)))
        } else {
          cols <- c(cols, sprintf("#%d::%s %s", col_idx, field.types[name], dbQuoteIdentifier(conn, name)))
        }
      } else {
        cols <- c(cols, sprintf("#%d", col_idx))
      }
      col_idx <- col_idx + 1
    }
    dbExecute(conn, SQL(sprintf("CREATE %s TABLE %s AS SELECT %s FROM %s", temp_str, table_name, paste(cols, collapse = ","), view_name)))
    rs_on_connection_updated(conn, hint = paste0("Create table'", table_name, "'"))
  } else {
    dbAppendTable(conn, name, value)
  }
  invisible(TRUE)
}

# Adds MAP types inferred from `dbDataType()` to `field.types`, but only for
# columns the user has not already provided a type for. Other types are left
# to the existing `CREATE TABLE AS SELECT` flow, which avoids unnecessary
# casts and matches DuckDB's own type inference.
duckdb_augment_field_types_for_map <- function(conn, value, field.types) {
  for (col_name in names(value)) {
    if (col_name %in% names(field.types)) {
      next
    }
    inferred <- dbDataType(conn, value[[col_name]])
    if (duckdb_is_map_type(inferred)) {
      field.types[[col_name]] <- inferred
    }
  }
  field.types
}

#' @rdname duckdb_connection-class
#' @export
setMethod("dbWriteTable", c("duckdb_connection", "character", "data.frame"), dbWriteTable__duckdb_connection_character_data.frame)
