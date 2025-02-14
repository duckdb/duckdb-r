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
    cat(sprintf("\rDuckDB progress: %3d%%", x))
  } else {
    cat("\r                     \r")
    duckdb_progress_env$last_time <- NULL
  }
}

check_progress_display <- function(f) {
  if (is.null(f)) {
    f
  } else if (isTRUE(f)) {
    duckdb_progress_display
  } else if (is.logical(f)) {
    NULL
  } else if (is.function(f)) {
    if (length(formals(f)) >= 0) {
      f
    } else {
      message('`getOption("duckdb.progress_display")` has no argument, expecting at least one.')
      NULL
    }
  } else {
    message('`getOption("duckdb.progress_display")` is not a function, expecting either a boolean or function.')
    NULL
  }
}

get_progress_display <- function() {
  if (!is_interactive()) {
    return(NULL)
  }
  progress_display <- getOption("duckdb.progress_display", default = duckdb_progress_display)
  check_progress_display(progress_display)
}
