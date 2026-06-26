# This file documents the *planned* user-facing functions for configuring where
# the duckdb R package stores extensions and secrets. It is design documentation
# in lieu of a plan; the functions are not implemented yet. The storage policy
# itself is described in `?duckdb_storage`. See `?duckdb_storage_config`.

#' Configure where DuckDB stores extensions and secrets
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' Choose where the duckdb R package keeps downloaded extensions and persisted
#' secrets, by writing a small *marker file* that records the choice:
#'
#' * `duckdb_extension_storage()` -- set or move the extension cache.
#' * `duckdb_secret_storage()` -- set or move the secret store.
#' * `duckdb_storage_status()` -- report where each currently resolves.
#'
#' By default both kinds live in a per-session temporary directory (extensions
#' use the package library when it is writable); these functions move them to a
#' location that survives across sessions. The same locations can also be set
#' without a marker by overriding with options and environment variables; the
#' full policy is documented in [duckdb_storage].
#'
#' These functions are planned and not yet implemented; this page describes
#' their intended behavior.
#'
#' @details
#' # Functions
#'
#' \preformatted{
#' duckdb_extension_storage(location, migrate = TRUE, conflict = "error")
#' duckdb_secret_storage(location, migrate = TRUE, conflict = "error")
#' duckdb_storage_status()
#' }
#'
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
#' # Arguments
#'
#' \describe{
#'   \item{`location`}{The destination root, or an explicit path. Recognized
#'     roots are `"session"` (the per-session temporary directory; also the
#'     opt-out -- it removes the marker), `"user"` ([tools::R_user_dir()]),
#'     `"shared"` (`~/.duckdb`, shared with the DuckDB CLI and Python client),
#'     and -- for `duckdb_extension_storage()` only -- `"library"` (alongside
#'     the installed package). See [duckdb_storage] for what each root means and
#'     for the still-provisional naming.}
#'   \item{`migrate`}{If `TRUE` (the default), move the already-cached files
#'     from the current location into the new one.}
#'   \item{`conflict`}{How to resolve a name collision during migration:
#'     `"error"` (the default) aborts and lists the collisions without moving
#'     anything; `"ours"` lets the files being relocated overwrite the
#'     destination; `"theirs"` keeps the destination files and drops the
#'     colliding sources.}
#' }
#'
#' # Value
#'
#' The `*_storage()` functions are called for their side effect (writing or
#' removing a marker, and optionally migrating files) and return the resolved
#' directory invisibly. `duckdb_storage_status()` returns a data frame with one
#' row per kind of state.
#'
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
