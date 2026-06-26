# Documentation for how the duckdb R package chooses the file-system locations
# it (and the bundled DuckDB engine) writes to. See `?duckdb_storage`.
#
# CRAN rationale (kept out of the user-facing docs deliberately):
#
# The CRAN Repository Policy says a package should not write in the user's home
# filespace, "nor anywhere else on the file system apart from the R session's
# temporary directory". The defaults below keep every writable location under
# tempdir() so that, with no config/option/env/marker, nothing is written
# outside the session temporary directory and reverse dependencies pass checks
# with no action:
#   * Extensions default to the package library only when it is writable. On the
#     CRAN check farm the library is remounted read-only, the marker-write probe
#     fails, and the cache falls back to tempdir(); no persistent write is ever
#     attempted where it would fail.
#   * Secrets and the in-memory temp/spill directory are pointed at tempdir()
#     explicitly, overriding DuckDB's own defaults ($HOME/.duckdb and a `.tmp`
#     directory in the working directory, respectively).
# The package's tests and runnable examples also avoid the bundled C++ engine on
# CRAN; see the CRAN guard in tests/testthat.R.
#
# Why each location is set explicitly rather than via `home_directory`: setting
# `home_directory` would be incomplete (it relocates the extension cache but not
# secrets, whose path the secret manager binds at startup from $HOME, nor spill
# files) and too broad (it is also the base for `~` expansion in user SQL, so it
# would silently redirect paths like `COPY ... TO '~/out.csv'`). We therefore
# leave `home_directory` alone and set `extension_directory`, `secret_directory`,
# and `temp_directory` -- all database-global settings, applied via `duckdb()` --
# directly.

#' DuckDB file-system usage: storage locations and how they are resolved
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' DuckDB writes several distinct kinds of data to the file system. This page
#' catalogs every such location and documents the unified policy the duckdb R
#' package uses to choose them, so that by default nothing is written outside
#' the R session's temporary directory.
#'
#' The functions that configure these locations are documented in
#' [duckdb_storage_config()].
#'
#' # Kinds of on-disk state
#'
#' \describe{
#'   \item{Home directory}{The base DuckDB uses to expand a leading `~` and to
#'     derive default sub-locations such as the extension cache. DuckDB setting:
#'     `home_directory`. The package does not set this: doing so would also
#'     redirect `~` in user SQL (e.g. `COPY ... TO '~/out.csv'`). Each location
#'     below is pointed at a temporary directory directly instead.}
#'   \item{Extension binaries}{Downloaded `*.duckdb_extension` files (e.g.
#'     `spatial`, `httpfs`, `h3`). DuckDB setting: `extension_directory`. A
#'     re-usable cache: a given binary is valid only for the exact DuckDB
#'     version and platform/ABI that downloaded it. By default the cache is the
#'     `"library"` root (alongside the installed package) when it is writable,
#'     falling back to a [tempdir()] sub-directory when it is not. See the
#'     marker section for how this is detected.}
#'   \item{Stored secrets}{Persisted credentials under `stored_secrets`. DuckDB
#'     setting: `secret_directory`. Set explicitly to a [tempdir()] location by
#'     default. Configured and migrated with [duckdb_storage_config()].}
#'   \item{Temporary / spill files}{Out-of-core intermediates for sorts, hash
#'     joins, and similar operations. DuckDB settings: `temp_directory`,
#'     `max_temp_directory_size`. For an in-memory (`:memory:`) database DuckDB's
#'     own default spills to `.tmp` in the current working directory, so the
#'     package overrides it with a [tempdir()] sub-directory by default.}
#'   \item{Logs and profiling output}{Written only when a path is explicitly
#'     configured (DuckDB settings `log_query_path`, `http_logging_output`,
#'     profiling output). They default to *off*, so there is no location to
#'     default and nothing is written without the user asking. If the user turns
#'     logging on they choose where it goes.}
#'   \item{Database file, WAL, and checkpoints}{Chosen by the user through the
#'     `dbdir` argument of [duckdb()]. The package does not manage these: an
#'     on-disk database and its sidecar files live where `dbdir` points, and an
#'     in-memory (`:memory:`) database has none.}
#' }
#'
#' # Resolution policy
#'
#' Each managed location is resolved through the same ordered chain. The first
#' source that yields a value wins:
#'
#' 1. an explicit value passed to [duckdb()] via `config` (e.g.
#'    `config = list(temp_directory = "...")`);
#' 1. the corresponding R option, e.g. `getOption("duckdb.temp_directory")`;
#' 1. the corresponding environment variable, e.g.
#'    `Sys.getenv("DUCKDB_TEMP_DIRECTORY")`;
#' 1. a persistent location selected by a marker file (see below);
#' 1. the default: a per-session sub-directory of [tempdir()].
#'
#' The extension cache inserts one extra step before the [tempdir()] fallback:
#' if no marker has selected a root, the `"library"` root is probed at connect
#' time by writing its marker -- the write doubles as the writability test, and
#' the marker is left in place to record the choice. If the write fails (the
#' library is read-only) the cache falls back to [tempdir()]. So the effective
#' default is "library when writable, else tempdir", with no persistent write
#' ever attempted where it would fail.
#'
#' # Marker files
#'
#' Persisting data across sessions means writing outside [tempdir()]; a marker
#' file records the user's consent to do so, once, so it need not be re-granted
#' on every connection and does not require editing `.Rprofile` or `.Renviron`.
#'
#' Two functions write and relocate these markers -- one per kind of state, so
#' the two can be configured independently -- and a third reports the current
#' state. They are documented in full on [duckdb_storage_config()]:
#'
#' ```r
#' duckdb_extension_storage(location, ..., migrate = TRUE, conflict = "error")
#' duckdb_secret_storage(location, ..., migrate = TRUE, conflict = "error")
#' duckdb_storage_status()
#' ```
#'
#' A `*_storage()` call writes the marker at `location` (creating, relocating,
#' or -- with `"session"` -- removing it); `duckdb_storage_status()` reports
#' where each kind currently resolves and how it was chosen. There is no `ask`
#' argument: calling a `*_storage()` function *is* the consent.
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
#'     package ([base::system.file()]). It pairs binaries with the build's ABI
#'     but is wiped on every re-install. This is the automatic default for
#'     extensions when the library is writable (see the resolution policy
#'     above): rather than require an explicit opt-in, the package probes it at
#'     connect time and uses it unless the write fails. Not offered for stored
#'     secrets, which always default to `"session"`.}
#' }
#'
#' ## The marker file
#'
#' The marker's name and contents make clear it belongs to the R package, so a
#' user inspecting the directory can tell at a glance what created it. This
#' matters most in the `"shared"` root (`~/.duckdb`), which is also used by the
#' DuckDB CLI and Python client:
#'
#' ```
#' <root>/extensions/.duckdb-r-keep        # opts in the extension cache
#' <root>/stored_secrets/.duckdb-r-keep    # opts in stored secrets
#' ```
#'
#' It is not empty: the package writes a single line of human-readable text
#' describing what the file is and that it is safe to delete. Only the file's
#' presence is significant -- the contents are never read back or validated, so
#' editing it has no effect.
#'
#' Markers are per-kind and live inside each kind's sub-directory, so one root
#' can persist extensions but not stored secrets, or vice versa. For extensions in a
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
#' drops the colliding sources. Secret migration is folded into
#' `duckdb_secret_storage()`.
#'
#' ## Rules
#'
#' * An option or environment variable overrides any marker.
#' * A kind's marker present in more than one root is ambiguous: the package
#'   emits a startup message naming the candidates and falls back to the
#'   [tempdir()] default until the ambiguity is resolved.
#' * The package never ships a marker. The only writes are by
#'   `duckdb_extension_storage()` / `duckdb_secret_storage()`, and the
#'   connect-time probe of the `"library"` root for extensions (which writes the
#'   marker only when the directory is writable).
#' * A marked location that is not writable falls back to the [tempdir()]
#'   default rather than failing.
#'
#' A marker selects the *location*. It is deliberately distinct from the
#' presence of a cached binary: an extension found under `v<version>/<platform>/`
#' governs only *validity* (whether a re-download is needed), never the choice
#' of location. This separation prevents a stale leftover binary from silently
#' resurrecting a store root and reintroducing an ABI mismatch.
#'
#' # Per-location reference
#'
#' | Kind        | DuckDB setting        | Option / environment variable                              | Default                          |
#' |-------------|-----------------------|------------------------------------------------------------|----------------------------------|
#' | Home        | `home_directory`      | --                                                         | left untouched (not set)            |
#' | Extensions  | `extension_directory` | `duckdb.extension_directory` / `DUCKDB_EXTENSION_DIRECTORY` | library if writable, else `tempdir()`|
#' | Stored secrets | `secret_directory` | `duckdb.secret_directory` / `DUCKDB_SECRET_DIRECTORY`       | `tempdir()` sub-directory (set)     |
#' | Temp/spill  | `temp_directory`      | `duckdb.temp_directory` / `DUCKDB_TEMP_DIRECTORY`          | `tempdir()` sub-directory (set)     |
#' | Logs        | `log_query_path`      | `duckdb.log_directory` / `DUCKDB_LOG_DIRECTORY`            | disabled (off)                      |
#'
#' "set" means `duckdb()` sets the value explicitly in the database config. The
#' home directory is left untouched so that `~` in user SQL keeps its usual
#' meaning.
#'
#' # Startup message
#'
#' When a connection is established and the resolved extension cache lies inside
#' [tempdir()], the package emits an informational message -- at most once every
#' eight hours per session, including in unattended (non-interactive) runs. It
#' explains that downloaded extensions will not persist across sessions and how
#' to opt into a permanent location via `options(duckdb.extension_directory =)`
#' or `DUCKDB_EXTENSION_DIRECTORY`.
#'
#' @seealso [duckdb_storage_config()] for the functions that configure these
#'   locations, and [duckdb()] for the `config` argument.
#' @name duckdb_storage
#' @keywords internal
NULL
