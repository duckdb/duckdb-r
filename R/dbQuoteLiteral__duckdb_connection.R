#' @rdname duckdb_connection-class
#' @usage NULL
dbQuoteLiteral__duckdb_connection <- function(conn, x, ...) {
  # Switchpatching to avoid ambiguous S4 dispatch, so that our method is used only if no alternatives are available.

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

    # A `TIMESTAMPTZ` literal without an offset is read in the session zone,
    # so spell the offset out; that much parses without the icu extension.
    if (identical(conn@convert_opts$posixct, "timestamptz")) {
      text <- timestamp_literal_text(x)
      # `paste0()` would spell an `NA` as the string "NA+00:00"
      present <- !is.na(text)
      text[present] <- paste0(text[present], "+00:00")

      return(SQL(paste0(dbQuoteString(conn, text), "::timestamptz")))
    }

    return(SQL(paste0(
      dbQuoteString(conn, timestamp_literal_text(x)),
      "::timestamp"
    )))
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

    out <- paste0(
      "to_microseconds(",
      formatC(value, format = "f", digits = 0),
      ")"
    )
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
          abort("Lists must contain raw vectors or NULL")
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
setMethod(
  "dbQuoteLiteral",
  signature("duckdb_connection"),
  dbQuoteLiteral__duckdb_connection
)

# The wall clock of a `POSIXct`, in UTC, to microsecond precision.
#
# `strftime()` stops at whole seconds, which silently drops what DuckDB
# stores: its timestamps are microseconds, and a literal that truncates makes
# a value that no longer compares equal to the one it came from. So the
# sub-second part is taken from the epoch value instead, rounded the way
# `dbQuoteLiteral()` already rounds a `difftime`, and appended only where
# there is one. `NA` stays `NA`, for `dbQuoteString()` to turn into `NULL`.
timestamp_literal_text <- function(x) {
  micros <- round(as.numeric(as.POSIXct(x)) * 1e6)
  secs <- micros %/% 1e6
  frac <- micros - secs * 1e6

  out <- strftime(.POSIXct(secs, tz = "UTC"), "%Y-%m-%d %H:%M:%S", tz = "UTC")
  fractional <- !is.na(frac) & frac != 0
  out[fractional] <- paste0(
    out[fractional],
    sub("0+$", "", sprintf(".%06.0f", frac[fractional]))
  )
  out
}
