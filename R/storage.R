# This file documents the *desired* state of how the duckdb R package chooses
# the file-system locations it (and the bundled DuckDB engine) writes to. It is
# design documentation in lieu of a plan: it describes the intended end state,
# parts of which may not yet be implemented. See `?duckdb_storage`.

#' DuckDB file-system usage: storage locations and how they are resolved
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' DuckDB writes several distinct kinds of data to the file system. This page
#' catalogs every such location and documents the unified policy the duckdb R
#' package uses to choose them, so that **by default nothing is written outside
#' the R session's temporary directory**, as required by the
#' [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html),
#' which states that packages should not write in the user's home filespace,
#' "nor anywhere else on the file system apart from the R session's temporary
#' directory".
#'
#' This topic describes the intended end state. It is documentation in lieu of a
#' design plan; some of the behavior below may not yet be implemented, and the
#' option, environment-variable, and marker names are provisional.
#'
#' @details
#' # Kinds of on-disk state
#'
#' Extensions and secrets are the two locations the package manages today; the
#' remaining kinds are subject to the same CRAN constraint and should be brought
#' under the same policy.
#'
#' \describe{
#'   \item{Extension binaries}{Downloaded `*.duckdb_extension` files (e.g.
#'     `spatial`, `httpfs`, `h3`). DuckDB setting: `extension_directory`. A
#'     re-usable cache: a given binary is valid only for the exact DuckDB
#'     version and platform/ABI that downloaded it.}
#'   \item{Secrets}{Persisted credentials under `stored_secrets`. DuckDB
#'     setting: `secret_directory`. Managed via [duckdb_consolidate_secrets()].}
#'   \item{Temporary / spill files}{Out-of-core intermediates for sorts, hash
#'     joins, aggregations, and the buffer manager. DuckDB settings:
#'     `temp_directory`, `max_temp_directory_size`. For an in-memory
#'     (`:memory:`) database DuckDB's own default spills to `.tmp` in the
#'     current working directory -- a CRAN-policy violation -- so the package
#'     must override it.}
#'   \item{Home directory}{The base DuckDB uses to expand a leading `~` and to
#'     derive several default sub-locations. DuckDB setting: `home_directory`.
#'     The umbrella setting behind the more specific ones above.}
#'   \item{Logs and profiling output}{Written only when explicitly enabled, but
#'     to disk when they are. DuckDB settings: `log_query_path`,
#'     `http_logging_output`, and profiling output.}
#'   \item{Database file, WAL, and checkpoints}{Chosen by the user through the
#'     `dbdir` argument of [duckdb()], so primarily the user's responsibility.
#'     The package is still responsible for ephemeral databases: a `:memory:`
#'     connection or an `ATTACH` of a temporary database should default into
#'     [tempdir()] and be cleaned up on disconnect.}
#' }
#'
#' # Resolution policy
#'
#' Each managed location is resolved through the same ordered chain. The first
#' source that yields a value wins:
#'
#' \enumerate{
#'   \item an explicit value passed to [duckdb()] via `config` (e.g.
#'     `config = list(temp_directory = "...")`);
#'   \item the corresponding R option, e.g. `getOption("duckdb.temp_directory")`;
#'   \item the corresponding environment variable, e.g.
#'     `Sys.getenv("DUCKDB_TEMP_DIRECTORY")`;
#'   \item a persistent location selected by a **marker file** (see below);
#'   \item the CRAN-safe default: a per-session sub-directory of [tempdir()].
#' }
#'
#' # Marker files
#'
#' Persisting data across sessions means writing outside [tempdir()], which the
#' CRAN Policy permits only with the user's consent. A marker file records that
#' consent on disk, once, so it need not be re-granted on every connection and
#' does not require editing `.Rprofile` or `.Renviron`.
#'
#' A marker is an empty sentinel file placed in a candidate persistent *store
#' root*. The general-purpose roots are the locations DuckDB clients otherwise
#' share:
#'
#' \itemize{
#'   \item the DuckDB default home (`~/.duckdb`) -- the location also used by
#'     the DuckDB CLI and Python client, so a marker here opts into a store
#'     shared across all DuckDB clients on the machine;
#'   \item a [tools::R_user_dir()] location -- the R-specific store, private to
#'     this package and surviving package upgrades.
#' }
#'
#' Extension binaries are the exception. In addition to the roots above they may
#' be cached in the duckdb package's own installed library directory
#' ([base::system.file()] location), which is wiped and re-created on every
#' re-install so the binaries are always paired with the current build's ABI.
#' That directory holds **only** extensions; it never stores secrets or any
#' other state. Wherever extensions instead persist across upgrades (the home
#' or [tools::R_user_dir()] roots), per-version, per-platform sub-paths keep a
#' stale binary from being loaded into a newer, ABI-incompatible build.
#'
#' Rules:
#'
#' \itemize{
#'   \item An option or environment variable overrides any marker.
#'   \item A marker in **more than one** root is ambiguous: the package emits a
#'     startup message naming the candidates and falls back to the [tempdir()]
#'     default until the ambiguity is resolved.
#'   \item The package **never ships a marker** and **never creates one as a
#'     side effect**. A marker is created only by an explicit user action (a
#'     dedicated helper), which is what makes the default CRAN-safe.
#'   \item A marked location that is not writable (for example the package
#'     library remounted read-only during `R CMD check`) falls back to the
#'     [tempdir()] default rather than failing.
#' }
#'
#' A marker selects the *location*. It is deliberately distinct from the
#' presence of a cached binary: an extension found under `v<version>/<platform>/`
#' governs only *validity* (whether a re-download is needed), never the choice
#' of location. This separation prevents a stale leftover binary from silently
#' resurrecting a store root and reintroducing an ABI mismatch.
#'
#' # CRAN compliance
#'
#' The policy rests on a single invariant: with no `config` value, no option, no
#' environment variable, and no marker, every managed location resolves under
#' [tempdir()]. A freshly built package ships no marker, and the check sandbox's
#' [tools::R_user_dir()] is clean, so on the CRAN check farm every location
#' resolves to the session temporary directory with no action required from
#' duckdb or from any reverse dependency. The writability fallback above is a
#' second line of defense for the read-only library remount used during checks.
#'
#' The package's own examples and tests additionally avoid exercising the C++
#' engine on CRAN; see the CRAN guard in `tests/testthat.R`.
#'
#' # Per-location reference
#'
#' | Kind        | DuckDB setting        | Option                        | Environment variable          | Default                         |
#' |-------------|-----------------------|-------------------------------|-------------------------------|---------------------------------|
#' | Extensions  | `extension_directory` | `duckdb.extension_directory`  | `DUCKDB_EXTENSION_DIRECTORY`  | `tempdir()` sub-directory       |
#' | Secrets     | `secret_directory`    | `duckdb.secret_directory`     | `DUCKDB_SECRET_DIRECTORY`     | [tools::R_user_dir()] (existing)|
#' | Temp/spill  | `temp_directory`      | `duckdb.temp_directory`       | `DUCKDB_TEMP_DIRECTORY`       | `tempdir()` sub-directory       |
#' | Home        | `home_directory`      | `duckdb.home_directory`       | `DUCKDB_HOME_DIRECTORY`       | `tempdir()` sub-directory       |
#' | Logs        | `log_query_path`      | `duckdb.log_directory`        | `DUCKDB_LOG_DIRECTORY`        | disabled                        |
#'
#' Secrets keep their existing [tools::R_user_dir()] default for backward
#' compatibility and are opt-in to the shared location; the marker mechanism is
#' the forward-looking, uniform way to opt any of these into persistence.
#'
#' @seealso [duckdb()] for the `config` argument, and
#'   [duckdb_consolidate_secrets()] for the secrets store.
#' @name duckdb_storage
#' @keywords internal
NULL
