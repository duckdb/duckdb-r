duckdb_progress_env <- new.env(parent = emptyenv())

duckdb_progress_display <- function(x) {
  time <- Sys.time()
  if (is.null(duckdb_progress_env$last_time)) {
    duckdb_progress_env$last_time <- time
  }

  min_seconds <- 0.5
  if (time - duckdb_progress_env$last_time < min_seconds) {
    return()
  }

  if (x < 100) {
    cat(sprintf("\rDuckDB progress: %3d%%", trunc(x)))
  } else {
    cat("\r                     \r")
    duckdb_progress_env$last_time <- NULL
  }
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
      message('`getOption("duckdb.progress_display")` is a function that has no argument, expecting at least one argument.')
      options(duckdb.progress_display = NULL)
      NULL
    }
  } else {
    message('`getOption("duckdb.progress_display")` is not a function, expecting either a boolean or function.')
    options(duckdb.progress_display = NULL)
    NULL
  }
}
