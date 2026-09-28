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

  # Under `time = "hms"` an hms quotes as the TIME it writes,
  # and under `interval = "Period"` a Period as the INTERVAL it writes, part for part
  # (handbook/usage/types/README.md).
  if (inherits(x, "hms") && identical(conn@convert_opts$time, "hms")) {
    return(SQL(time_literal_text(x)))
  }

  if (
    inherits(x, "Period") && identical(conn@convert_opts$interval, "Period")
  ) {
    return(SQL(period_literal_text(x)))
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

# A `TIME` literal for each value of an hms, rounded to the microsecond as the write routes round it,
# and refused outside 00:00:00 to 24:00:00, which `TIME` does not hold.
time_literal_text <- function(x, call = parent.frame()) {
  micros <- round(as.numeric(x) * 1e6)
  bad <- !is.na(x) & (is.na(micros) | micros < 0 | micros > 86400e6)
  if (any(bad)) {
    abort(
      paste0(
        "`x` must hold times of day from 00:00:00 to 24:00:00 to quote as `TIME`, not ",
        format(as.numeric(x)[which(bad)[[1]]], digits = 15),
        " seconds."
      ),
      call = call
    )
  }

  secs <- micros %/% 1e6
  frac <- micros - secs * 1e6
  out <- sprintf(
    "%02.0f:%02.0f:%02.0f",
    secs %/% 3600,
    secs %/% 60 %% 60,
    secs %% 60
  )
  fractional <- !is.na(frac) & frac != 0
  out[fractional] <- paste0(
    out[fractional],
    sub("0+$", "", sprintf(".%06.0f", frac[fractional]))
  )
  out <- paste0("'", out, "'::TIME")
  out[is.na(micros)] <- "NULL"
  out
}

# An exact `INTERVAL` expression for each value of a Period, part for part,
# with NA in any part as NULL, as the write routes treat it.
period_literal_text <- function(x, call = parent.frame()) {
  months <- x@year * 12 + x@month
  days <- x@day
  micros <- round((x@hour * 3600 + x@minute * 60 + x@.Data) * 1e6)
  missing <- is.na(months) | is.na(days) | is.na(micros)

  whole <- function(v, limit) is.finite(v) & v == trunc(v) & abs(v) <= limit
  bad <- !missing &
    !(whole(months, 2^31) & whole(days, 2^31) & whole(micros, 2^63))
  if (any(bad)) {
    abort(
      paste0(
        "`x` must hold periods that fit an `INTERVAL` to quote as one, not ",
        format(x[which(bad)[[1]]]),
        "."
      ),
      call = call
    )
  }

  number <- function(v) formatC(v, format = "f", digits = 0)
  out <- paste0(
    "(to_months(",
    number(months),
    ") + to_days(",
    number(days),
    ") + to_microseconds(",
    number(micros),
    "))"
  )
  out[missing] <- "NULL"
  out
}

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
