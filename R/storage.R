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
#' The home, extension, and secret defaults and the ephemeral-home startup
#' message are implemented. The marker mechanism described below is the planned
#' way to opt into persistence without configuration; until it lands, use the
#' options or environment variables. Some names remain provisional.
#'
#' @details
#' # Kinds of on-disk state
#'
#' \describe{
#'   \item{Home directory}{The base DuckDB uses to expand a leading `~` and to
#'     derive default sub-locations such as the extension cache. DuckDB setting:
#'     `home_directory`. The package **does not set this**: doing so would also
#'     redirect `~` in user SQL (e.g. `COPY ... TO '~/out.csv'`). Each location
#'     below is pointed at a temporary directory directly instead.}
#'   \item{Extension binaries}{Downloaded `*.duckdb_extension` files (e.g.
#'     `spatial`, `httpfs`, `h3`). DuckDB setting: `extension_directory`. A
#'     re-usable cache: a given binary is valid only for the exact DuckDB
#'     version and platform/ABI that downloaded it. Set explicitly to a
#'     [tempdir()] sub-directory by default.}
#'   \item{Secrets}{Persisted credentials under `stored_secrets`. DuckDB
#'     setting: `secret_directory`. Managed via [duckdb_consolidate_secrets()].
#'     Set explicitly to a [tempdir()] location by default.}
#'   \item{Temporary / spill files}{Out-of-core intermediates for sorts, hash
#'     joins, aggregations, and the buffer manager. DuckDB settings:
#'     `temp_directory`, `max_temp_directory_size`. For an in-memory
#'     (`:memory:`) database DuckDB's own default spills to `.tmp` in the
#'     current working directory -- a CRAN-policy violation -- so the package
#'     must override it.}
#'   \item{Logs and profiling output}{Written only when a path is explicitly
#'     configured (DuckDB settings `log_query_path`, `http_logging_output`,
#'     profiling output). They default to *off*, so there is no location to
#'     default and nothing written without the user asking -- which is why the
#'     package does not force them into [tempdir()]. If the user turns logging
#'     on they choose where it goes.}
#'   \item{Database file, WAL, and checkpoints}{Chosen by the user through the
#'     `dbdir` argument of [duckdb()], so primarily the user's responsibility.
#'     The package is still responsible for ephemeral databases: a `:memory:`
#'     connection or an `ATTACH` of a temporary database should default into
#'     [tempdir()] and be cleaned up on disconnect.}
#' }
#'
#' # Why each location is set explicitly, not via the home directory
#'
#' It is tempting to set `home_directory` to a [tempdir()] location and leave
#' every other location unset. Two problems rule that out. First, it is
#' incomplete: it would relocate the extension cache (DuckDB resolves that
#' lazily through the connection's opener-aware file system, which consults the
#' setting) but **not** secrets -- the secret manager fixes its path once at
#' database startup from the raw process `$HOME`, never seeing the
#' `home_directory` setting -- nor spill files. Second, it is too broad:
#' `home_directory` is also the base for `~` expansion in user SQL, so setting
#' it would silently redirect paths like `COPY ... TO '~/out.csv'`. The package
#' therefore leaves `home_directory` alone and sets `extension_directory` and
#' `secret_directory` (and, where relevant, `temp_directory`) explicitly.
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
#' Two functions write and relocate these markers -- one per kind of state, so
#' the two can be configured independently:
#'
#' \preformatted{
#' duckdb_extension_storage(location = NULL, migrate = TRUE, conflict = "error")
#' duckdb_secret_storage(location = NULL, migrate = TRUE, conflict = "error")
#' }
#'
#' Called with `location = NULL` (the default) each function reports where that
#' kind currently resolves and how it was chosen. Called with a `location` it
#' writes the marker there (creating, relocating, or -- with `"session"` --
#' removing it). There is no `ask` argument: calling the function *is* the
#' consent.
#'
#' ## The `location` argument
#'
#' `location` names a *root*, not a full path (an explicit path is also
#' accepted). The recognized roots are:
#'
#' \describe{
#'   \item{`"session"`}{`tempdir()` -- the default, and the opt-out: setting it
#'     removes the marker and reverts that kind to a per-session location.}
#'   \item{`"user"`}{[tools::R_user_dir()] -- R-specific, private to this
#'     package, surviving package upgrades.}
#'   \item{`"shared"`}{`~/.duckdb` -- shared with the DuckDB CLI and Python
#'     client.}
#'   \item{`"library"`}{*(extensions only)* alongside the installed duckdb
#'     package ([base::system.file()]). This was the default before extensions
#'     moved to `tempdir()`; it pairs binaries with the build's ABI but is wiped
#'     on every re-install, so the marker there must be re-created after an
#'     upgrade. Not offered for secrets.}
#' }
#'
#' The argument name and value vocabulary are still provisional. Alternatives
#' considered: name `where` or `root` instead of `location`; values
#' `"temporary"`/`"package"` instead of `"session"`/`"library"`.
#'
#' ## The marker file
#'
#' The marker is an empty sentinel whose name makes clear it belongs to the R
#' package -- important because the `"shared"` root (`~/.duckdb`) is also used
#' by the DuckDB CLI and Python client, which must not mistake it for their own:
#'
#' \preformatted{<root>/extensions/.duckdb-r-keep     # opts in the extension cache
#' <root>/stored_secrets/.duckdb-r-keep              # opts in secrets}
#'
#' Markers are per-kind and live inside each kind's sub-directory, so one root
#' can persist extensions but not secrets, or vice versa. For extensions in a
#' persistent root, DuckDB's `v<version>/<platform>/` sub-paths keep a stale
#' binary from being loaded into a newer, ABI-incompatible build.
#'
#' ## Migration
#'
#' `migrate = TRUE` moves the already-cached files from the current location to
#' the new root. `conflict` decides what happens when a file of the same name
#' exists at the destination: `"error"` (the default) aborts and lists the
#' collisions without moving anything; `"ours"` lets the files being relocated
#' win (overwriting the destination); `"theirs"` keeps the destination files and
#' drops the colliding sources. Secret migration is performed by
#' [duckdb_consolidate_secrets()].
#'
#' ## Rules
#'
#' \itemize{
#'   \item An option or environment variable overrides any marker.
#'   \item A kind's marker present in **more than one** root is ambiguous: the
#'     package emits a startup message naming the candidates and falls back to
#'     the [tempdir()] default until the ambiguity is resolved.
#'   \item The package **never ships a marker** and **never creates one as a
#'     side effect**; only `duckdb_extension_storage()` /
#'     `duckdb_secret_storage()` write one, which is what keeps the default
#'     CRAN-safe.
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
#' | Kind        | DuckDB setting        | Option                        | Environment variable          | Default                          |
#' |-------------|-----------------------|-------------------------------|-------------------------------|----------------------------------|
#' | Home        | `home_directory`      | --                            | --                            | left untouched (not set)         |
#' | Extensions  | `extension_directory` | `duckdb.extension_directory`  | `DUCKDB_EXTENSION_DIRECTORY`  | `tempdir()` sub-directory (set)  |
#' | Secrets     | `secret_directory`    | `duckdb.secret_directory`     | `DUCKDB_SECRET_DIRECTORY`     | `tempdir()` sub-directory (set)  |
#' | Temp/spill  | `temp_directory`      | `duckdb.temp_directory`       | `DUCKDB_TEMP_DIRECTORY`       | `tempdir()` sub-directory        |
#' | Logs        | `log_query_path`      | `duckdb.log_directory`        | `DUCKDB_LOG_DIRECTORY`        | disabled (off)                   |
#'
#' "set" means the package passes the value to [duckdb()] explicitly. The home
#' directory is left untouched so that `~` in user SQL keeps its usual meaning.
#'
#' # Startup message
#'
#' When a connection is established and the resolved extension cache lies inside
#' [tempdir()], the package emits an informational message -- at most once every
#' eight hours per session, and only in interactive sessions, so non-interactive
#' scripts and CRAN checks stay quiet. It explains that downloaded extensions
#' will not persist across sessions and how to opt into a permanent location via
#' `options(duckdb.extension_directory =)` or `DUCKDB_EXTENSION_DIRECTORY`.
#'
#' @seealso [duckdb()] for the `config` argument, and
#'   [duckdb_consolidate_secrets()] for the secrets store.
#' @name duckdb_storage
#' @keywords internal
NULL
