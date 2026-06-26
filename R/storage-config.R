# Documentation for the user-facing functions that configure where the duckdb R
# package stores extensions and secrets. The storage policy itself is described
# in `?duckdb_storage`. See `?duckdb_storage_config`.

#' Configure where DuckDB stores extensions and secrets
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' Choose where the duckdb R package keeps downloaded extensions and persisted
#' secrets, by writing a small *marker file* that records the choice:
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
#' @usage
#' duckdb_extension_storage(location, migrate = TRUE, conflict = "error")
#' duckdb_secret_storage(location, migrate = TRUE, conflict = "error")
#' duckdb_storage_status()
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
#' @param location The destination root, or an explicit path. Recognized roots
#'   are `"session"` (the per-session temporary directory; also the opt-out --
#'   it removes the marker), `"user"` ([tools::R_user_dir()]), `"shared"`
#'   (`~/.duckdb`, shared with the DuckDB CLI and Python client), and -- for
#'   `duckdb_extension_storage()` only -- `"library"` (alongside the installed
#'   package). See [duckdb_storage] for what each root means.
#' @param migrate If `TRUE` (the default), move the already-cached files from the
#'   current location into the new one.
#' @param conflict How to resolve a name collision during migration: `"error"`
#'   (the default) aborts and lists the collisions without moving anything;
#'   `"ours"` lets the files being relocated overwrite the destination;
#'   `"theirs"` keeps the destination files and drops the colliding sources.
#'
#' @return The `*_storage()` functions are called for their side effect (writing
#'   or removing a marker, and optionally migrating files) and return the
#'   resolved directory invisibly. `duckdb_storage_status()` returns a data frame
#'   with one row per kind of state.
#'
#' @details
#' # Relationship to existing functions
#'
#' `duckdb_secret_storage()` supersedes [duckdb_consolidate_secrets()], which is
#' hard-deprecated: secret migration is now a `migrate` step of
#' `duckdb_secret_storage()`.
#'
#' @seealso [duckdb_storage] for the storage policy these functions implement.
#' @name duckdb_storage_config
#' @aliases duckdb_extension_storage duckdb_secret_storage duckdb_storage_status
#' @keywords internal
NULL
