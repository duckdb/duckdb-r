#' @rdname duckdb_connection-class
#' @usage NULL
dbQuoteLiteral__duckdb_connection <- function(conn, x, ...) {
  # Switchpatching to avoid ambiguous S4 dispatch, so that our method
  # is used only if no alternatives are available.

  if (is(x, "SQL")) {
    return(x)
  }

  if (is.factor(x)) {
    return(dbQuoteString(conn, as.character(x)))
  }

  if (is.character(x)) {
    return(dbQuoteString(conn, x))
  }

  if (inherits(x, "POSIXt")) {
    if (length(x) == 0) {
      return(SQL(character()))
    }

    out <- dbQuoteString(
      conn,
      strftime(as.POSIXct(x), "%Y-%m-%d %H:%M:%S", tz = "UTC")
    )

    return(SQL(paste0(out, "::timestamp")))
  }

  if (inherits(x, "Date")) {
    if (length(x) == 0) {
      return(SQL(character()))
    }

    out <- callNextMethod()
    return(SQL(paste0(out, "::date")))
  }

  if (inherits(x, "difftime")) {
    if (length(x) == 0) {
      return(SQL(character()))
    }

    units(x) <- "secs"
    value <- round(as.numeric(x) * 1000000)
    value[!is.finite(x)] <- NA

    out <- paste0("to_microseconds(", formatC(value, format = "f", digits = 0), ")")
    out[is.na(value)] <- "NULL"
    return(SQL(out))
  }

  if (is.list(x)) {
    blob_data <- vapply(
      x,
      function(x) {
        if (is.null(x)) {
          "NULL"
        } else if (is.raw(x)) {
          paste0("'", paste0("\\x", format(x), collapse = ""), "'")
        } else {
          stop("Lists must contain raw vectors or NULL", call. = FALSE)
        }
      },
      character(1)
    )
    return(SQL(blob_data, names = names(x)))
  }

  x <- as.character(x)
  x[is.na(x)] <- "NULL"
  SQL(x, names = names(x))
}

#' @rdname duckdb_connection-class
#' @export
setMethod("dbQuoteLiteral", signature("duckdb_connection"), dbQuoteLiteral__duckdb_connection)
