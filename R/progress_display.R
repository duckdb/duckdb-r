# Handbook: handbook/usage/interactive/README.md

duckdb_progress_display <- function(x) {
  if (x >= 100) {
    # Completion bypasses the throttle, so no painted line outlives its query.
    if (isTRUE(the$progress_painted)) {
      cat("\r                     \r")
    }
    the$progress_last_time <- NULL
    the$progress_painted <- NULL
    return()
  }

  time <- progress_now()
  if (is.null(the$progress_last_time)) {
    the$progress_last_time <- time
  }

  min_seconds <- 0.5
  if (time - the$progress_last_time < min_seconds) {
    return()
  }

  cat(sprintf("\rDuckDB progress: %3d%%", trunc(x)))
  the$progress_last_time <- time
  the$progress_painted <- TRUE
}

# The clock the display reads, in seconds, apart so that a test can set it.
progress_now <- function() {
  as.numeric(Sys.time())
}

get_progress_display <- function() {
  f <- getOption("duckdb.progress_display", default = is_interactive())

  if (is.null(f)) {
    f
  } else if (isTRUE(f)) {
    duckdb_progress_display
  } else if (is.logical(f)) {
    NULL
  } else if (is.function(f)) {
    if (length(formals(f)) > 0) {
      f
    } else {
      message(
        '`getOption("duckdb.progress_display")` is a function that has no argument, expecting at least one argument.'
      )
      options(duckdb.progress_display = NULL)
      NULL
    }
  } else {
    message(
      '`getOption("duckdb.progress_display")` is not a function, expecting either a boolean or function.'
    )
    options(duckdb.progress_display = NULL)
    NULL
  }
}
