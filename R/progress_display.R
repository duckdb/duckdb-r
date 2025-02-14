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
  if (is.null(f)) return()
  if (isTRUE(f) || isFALSE(f)) return()
  if (is.function(f)) {
    if (length(formals(f)) > 0) return()
    stop("`progress_display` has no argument, expecting at least one.")
  }
  stop("`progress_display` is not function, expecting either a boolean or function.")
}

set_progress_display <- function(progress_display) {
  check_progress_display(progress_display)
  options("duckdb.progress_display" = {
    if (isTRUE(progress_display)) {
      duckdb_progress_display
    } else if (is.function(progress_display)) {
      progress_display
    } else {
      NULL
    }
  })
}

get_progress_display <- function(f) {
  getOption("duckdb.progress_display", default = duckdb_progress_display)
}
