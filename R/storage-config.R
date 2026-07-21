# Documentation and implementation for the user-facing function that reports
# where the duckdb R package stores extensions and secrets. The storage policy
# itself is described in `?duckdb_storage`.

#' Report where DuckDB stores extensions and secrets
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' `duckdb_storage_status()` reports the directory the duckdb R package would
#' currently use for downloaded extensions and for persisted secrets, and which
#' tier of the resolution policy chose it. It has no side effects: it never
#' prompts and never creates a directory, so an as-yet-uncreated `~/.duckdb` is
#' reported as the per-session temporary default.
#'
#' The location is chosen -- and can be changed -- as documented in
#' [duckdb_storage]: the `home` argument of [duckdb()], the `duckdb.home` option,
#' the `DUCKDB_R_HOME` environment variable, or an existing `~/.duckdb`.
#'
#' @return A data frame (class `"duckdb_storage_status"`) with one row per kind
#'   of state and columns `kind`, `source`, and `directory`; its print method
#'   renders a readable summary when the result is auto-printed.
#'
#' @seealso [duckdb_storage] for the storage policy this reports on, and
#'   [duckdb()] for the `home` argument.
#' @export
#' @examples
#' duckdb_storage_status()
duckdb_storage_status <- function() {
  home <- describe_storage_home()
  status <- data.frame(
    kind = c("extensions", "stored_secrets"),
    source = c(home$source, home$source),
    directory = c(
      home_subdir(home$root, "extensions"),
      home_subdir(home$root, "stored_secrets")
    ),
    stringsAsFactors = FALSE
  )
  class(status) <- c("duckdb_storage_status", "data.frame")
  # Returned visibly: the print method below renders the readable summary when
  # the result is auto-printed, while assignment stays quiet as usual.
  status
}

#' @export
print.duckdb_storage_status <- function(x, ...) {
  cat("DuckDB storage locations:\n")
  kind <- format(x$kind, width = max(nchar(x$kind)))
  source <- format(
    paste0("[", x$source, "]"),
    width = max(nchar(x$source)) + 2L
  )
  cat(paste0("  ", kind, "  ", source, "  ", x$directory), sep = "\n")
  invisible(x)
}
