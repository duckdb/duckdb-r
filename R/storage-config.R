# Documentation and implementation for the user-facing functions that configure
# where the duckdb R package stores extensions and secrets. The storage policy
# itself is described in `?duckdb_storage`. See `?duckdb_storage_config`.

#' Configure where DuckDB stores extensions and secrets
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' Choose where the duckdb R package keeps downloaded extensions and persisted
#' secrets, by writing a small marker file that records the choice:
#'
#' * `duckdb_extension_storage()` -- set or move the extension cache (default:
#'   the package library when writable, otherwise a per-session temporary
#'   directory).
#' * `duckdb_secret_storage()` -- set or move the secret store (default: a
#'   per-session temporary directory).
#' * `duckdb_storage_status()` -- report where each currently resolves.
#'
#' These functions move the cache and secret store to a location that survives
#' across sessions; the same locations can also be set without a marker by
#' overriding with options and environment variables. The full policy is
#' documented in [duckdb_storage].
#'
#' @details
#' `duckdb_extension_storage()` and `duckdb_secret_storage()` write (or remove)
#' the marker for that one kind of state, so the two can be configured
#' independently. `duckdb_storage_status()` reports where each kind currently
#' resolves and which tier of the resolution policy chose it. The new location
#' takes effect for connections opened afterwards; existing connections are
#' unaffected.
#'
#' There is no `ask` argument: calling a `*_storage()` function is itself the
#' consent to write outside the temporary directory.
#'
#' @param location The destination root (not a path); one of:
#'   * `"session"` -- the per-session temporary directory; also the opt-out
#'     (removes the marker).
#'   * `"user"` -- [tools::R_user_dir()].
#'   * `"shared"` -- `~/.duckdb`, shared with the DuckDB CLI and Python client.
#'   * `"library"` -- *(`duckdb_extension_storage()` only)* alongside the
#'     installed package.
#'
#'   To use an arbitrary directory, set the option or environment variable
#'   instead (see [duckdb_storage]).
#' @param ... These dots are for future extensions and must be empty.
#' @param migrate If `TRUE` (the default), move the already-cached files from the
#'   current location into the new one. Ignored when `location` is `"session"`:
#'   opting out never moves files into the per-session directory.
#' @param conflict How to resolve a name collision during migration: `"error"`
#'   (the default) aborts and lists the collisions without moving anything;
#'   `"ours"` lets the files being relocated overwrite the destination;
#'   `"theirs"` keeps the destination files and drops the colliding sources.
#'
#' @return The `*_storage()` functions are called for their side effect (writing
#'   or removing a marker, and optionally migrating files) and return the
#'   resolved directory invisibly. `duckdb_storage_status()` prints a readable
#'   summary and invisibly returns a data frame with one row per kind of state
#'   and columns `kind`, `source`, and `directory`. It reports only the
#'   persisted selection and does not run the connect-time `"library"`
#'   write-probe, so before the first connection of a session it may report
#'   `"session"` for extensions even though a writable library would be used on
#'   connect.
#'
#' @seealso [duckdb_storage] for the storage policy these functions implement.
#' @name duckdb_storage_config
NULL

#' @rdname duckdb_storage_config
#' @export
duckdb_extension_storage <- function(
  location,
  ...,
  migrate = TRUE,
  conflict = "error"
) {
  check_dots_empty0(...)
  set_storage_marker("extensions", location, migrate, conflict)
}

#' @rdname duckdb_storage_config
#' @export
duckdb_secret_storage <- function(
  location,
  ...,
  migrate = TRUE,
  conflict = "error"
) {
  check_dots_empty0(...)
  set_storage_marker("stored_secrets", location, migrate, conflict)
}

#' @rdname duckdb_storage_config
#' @export
duckdb_storage_status <- function() {
  extensions <- describe_storage("extensions")
  stored_secrets <- describe_storage("stored_secrets")
  status <- data.frame(
    kind = c("extensions", "stored_secrets"),
    source = c(extensions$source, stored_secrets$source),
    directory = c(extensions$directory, stored_secrets$directory),
    stringsAsFactors = FALSE
  )
  class(status) <- c("duckdb_storage_status", "data.frame")
  print(status)
  invisible(status)
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
