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

# Rounds to the nearest whole number, half away from zero, as C's `round()` does in the write routes,
# where R's `round()` rounds half to even: a literal of a tie then holds what a write of it writes.
# The whole part comes off exactly, so the comparison with one half is exact too;
# `NA`, `NaN` and the infinities stay as they are.
round_half_away <- function(x) {
  whole <- trunc(x)
  whole + sign(x) * (is.finite(x) & abs(x - whole) >= 0.5)
}

# A `TIME` literal for each value of an hms, rounded to the microsecond as the write routes round it,
# and refused outside 00:00:00 to 24:00:00, which `TIME` does not hold, `NaN` and the infinities included;
# only `NA` is `NULL`, as for the write routes.
time_literal_text <- function(x, call = parent.frame()) {
  if (length(x) == 0) {
    return(character())
  }
  micros <- round_half_away(as.numeric(x) * 1e6)
  missing <- is.na(x) & !is.nan(x)
  bad <- !missing & (!is.finite(micros) | micros < 0 | micros > 86400e6)
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
  out[missing] <- "NULL"
  out
}

# An exact `INTERVAL` expression for each value of a Period, part for part,
# with NA in any part as NULL, as the write routes treat it.
# The hours and minutes stay apart from the seconds, so that no part passes through a double of microseconds.
period_literal_text <- function(x, call = parent.frame()) {
  if (length(x) == 0) {
    return(character())
  }
  # The seconds split as a write splits them (src/types.cpp):
  # whole seconds, and the fraction left over rounded to the microsecond, half away from zero, of the same sign
  seconds <- trunc(x@.Data)
  fraction <- round_half_away((x@.Data - seconds) * 1e6)
  carry <- trunc(fraction / 1e6)
  parts <- list(
    months = x@year * 12 + x@month,
    days = x@day,
    hours = x@hour,
    minutes = x@minute,
    seconds = seconds + carry,
    fraction = fraction - carry * 1e6
  )
  missing <- Reduce(
    `|`,
    lapply(list(x@.Data, x@year, x@month, x@day, x@hour, x@minute), is.na)
  )

  # Whole and within the signed 32 or 64 bits the part is held in, as a write checks (src/types.cpp).
  # A double compares hours and minutes closely enough,
  # since the next one past the bound is millions of microseconds past it.
  # The seconds are compared whole and in microseconds apart, which is exact:
  # 64 bits of microseconds hold 9223372036854 seconds and 775808 microseconds below zero, and 775807 above.
  # A sum of parts past 64 bits is DuckDB's to refuse, which it does with an overflow error.
  whole <- function(v, bits, scale = 1) {
    is.finite(v) &
      v == trunc(v) &
      v * scale >= -2^(bits - 1) &
      v * scale < 2^(bits - 1)
  }
  max_seconds <- 9223372036854
  seconds_fit <- is.finite(parts$seconds) &
    (abs(parts$seconds) < max_seconds |
      (parts$seconds == max_seconds & parts$fraction <= 775807) |
      (parts$seconds == -max_seconds & parts$fraction >= -775808))
  bad <- !missing &
    !(whole(parts$months, 32) &
      whole(parts$days, 32) &
      whole(parts$hours, 64, 3600e6) &
      whole(parts$minutes, 64, 60e6) &
      seconds_fit)
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
  # Spelled digit by digit, since a double past 2^53 does not hold every count of microseconds
  microseconds <- ifelse(
    parts$seconds == 0,
    number(parts$fraction),
    paste0(
      number(parts$seconds),
      formatC(
        abs(parts$fraction),
        width = 6,
        flag = "0",
        format = "f",
        digits = 0
      )
    )
  )
  out <- paste0(
    "(to_months(",
    number(parts$months),
    ") + to_days(",
    number(parts$days),
    ") + to_hours(",
    number(parts$hours),
    ") + to_minutes(",
    number(parts$minutes),
    ") + to_microseconds(",
    microseconds,
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
