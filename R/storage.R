# Documentation for how the duckdb R package chooses the file-system locations
# it (and the bundled DuckDB engine) writes to. See `?duckdb_storage`.
#
# CRAN rationale (kept out of the user-facing docs deliberately):
#
# The CRAN Repository Policy says a package should not write in the user's home
# filespace, "nor anywhere else on the file system apart from the R session's
# temporary directory". The package therefore never *creates* anything in the
# home directory on its own: in a non-interactive session (all package checks)
# extensions and secrets go under tempdir() unless a `~/.duckdb` already exists
# or a location is set explicitly, so reverse dependencies pass checks with no
# action. `~/.duckdb` is only ever created after an explicit, interactive
# confirmation from the user. Nothing is written to the package/user library.
#
# Why the extension and secret locations are set explicitly (rather than via
# DuckDB's own `home_directory`): setting `home_directory` is both incomplete
# (it does not move the spill directory) and too broad (it is also the base for
# `~` expansion in user SQL, so it would silently redirect paths like
# `COPY ... TO '~/out.csv'`). We therefore leave `home_directory` alone and set
# `extension_directory`, `secret_directory`, and `temp_directory` -- all
# database-global settings, applied via `duckdb()` -- directly.
#
# The package's tests and runnable examples also avoid the bundled C++ engine on
# CRAN; see the CRAN guard in tests/testthat.R.

#' DuckDB file-system usage: storage locations and how they are resolved
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' DuckDB writes several distinct kinds of data to the file system.
#' This page catalogs every such location
#' and documents the policy the duckdb R package uses to choose them.
#' By default the package never creates anything in your home directory on its own:
#' downloaded extensions and stored secrets go under the R session's temporary directory
#' unless a `~/.duckdb` directory already exists
#' (or you point the package somewhere explicitly).
#'
#' [duckdb_storage_status()] reports where each location currently resolves.
#'
#' # Kinds of on-disk state
#'
#' \describe{
#'   \item{Home directory}{The base DuckDB uses to expand a leading `~` and to
#'     derive default sub-locations. DuckDB setting: `home_directory`. The
#'     package does not set this: doing so would also redirect `~` in user SQL
#'     (e.g. `COPY ... TO '~/out.csv'`). The extension and secret locations
#'     below are pointed at the resolved home root directly instead.}
#'   \item{Extension binaries}{Downloaded `*.duckdb_extension` files (e.g.
#'     `spatial`, `httpfs`, `h3`). DuckDB setting: `extension_directory`. A
#'     re-usable cache placed at `<home>/extensions`, where `<home>` is resolved
#'     as described below.}
#'   \item{Stored secrets}{Persisted credentials under `stored_secrets`. DuckDB
#'     setting: `secret_directory`. Placed at `<home>/stored_secrets`, the same
#'     `<home>`.}
#'   \item{Temporary / spill files}{Out-of-core intermediates for sorts, hash
#'     joins, and similar operations. DuckDB settings: `temp_directory`,
#'     `max_temp_directory_size`. For an in-memory (`:memory:`) database DuckDB's
#'     own default spills to `.tmp` in the current working directory, so the
#'     package overrides it with a [tempdir()] sub-directory by default. This is
#'     a separate setting from the extension/secret home (see below).}
#'   \item{Logs and profiling output}{Written only when a path is explicitly
#'     configured (DuckDB settings `log_query_path`, `http_logging_output`,
#'     profiling output). They default to *off*, so nothing is written without
#'     the user asking, and the user chooses where it goes.}
#'   \item{Database file, WAL, and checkpoints}{Chosen by the user through the
#'     `dbdir` argument of [duckdb()]. The package does not manage these.}
#' }
#'
#' # Resolving the home directory
#'
#' Extensions and secrets share one *home* root, resolved fresh on every call to
#' [duckdb()] that creates a new database driver object.
#' The first source that yields a value wins:
#'
#' 1. the `home` argument to [duckdb()];
#' 1. the `duckdb.home` R option, e.g.
#'    `options(duckdb.home = "/path/to/duckdb")`;
#' 1. the `DUCKDB_R_HOME` environment variable;
#' 1. `~/.duckdb`, if that directory already exists -- the location shared with
#'    the DuckDB CLI and other clients;
#' 1. In interactive sessions only, the package offers to create `~/.duckdb`
#'    once: answer "yes" to create and use it, "no" to fall through to the
#'    temporary directory below, or cancel the prompt to abort with an error.
#' 1. Otherwise a per-session sub-directory of [tempdir()].
#'
#' The extension cache is then `<home>/extensions` and the secret store is
#' `<home>/stored_secrets`.
#'
#' Because the decision is remade on every new driver object, creating
#' `~/.duckdb` (or setting the option/variable) takes effect immediately for
#' drivers created afterwards.
#' Existing drivers are unaffected.
#'
#' The `shared_home` argument of [duckdb()] overrides this resolution:
#' `shared_home = TRUE` uses (and creates) `~/.duckdb`, and `shared_home = FALSE`
#' forces a per-session [tempdir()] even if `~/.duckdb` already exists.
#'
#' # Per-location reference
#'
#' | Kind           | DuckDB setting        | How to set it                                                         | Default                          |
#' |----------------|-----------------------|-----------------------------------------------------------------------|----------------------------------|
#' | Home           | `home_directory`      | --                                                                    | left untouched (not set)         |
#' | Extensions     | `extension_directory` | `home` arg / `duckdb.home` / `DUCKDB_R_HOME` (as `<home>/extensions`) | `tempdir()` sub-directory (set)  |
#' | Stored secrets | `secret_directory`    | like extensions (`<home>/stored_secrets`)                             | `tempdir()` sub-directory (set)  |
#' | Temp/spill     | `temp_directory`      | `duckdb.temp_directory` / `DUCKDB_R_TEMP_DIRECTORY`                   | `tempdir()` sub-directory (set)  |
#' | Logs           | `log_query_path`      | DuckDB setting                                                        | disabled (off)                   |
#'
#' "set" means `duckdb()` sets the value explicitly in the database config.
#' The home directory is left untouched so that `~` in user SQL keeps its usual meaning.
#' An `extension_directory` / `secret_directory` / `temp_directory`
#' passed directly in the `config` list is always honored
#' and takes precedence over the resolution above.
#'
#' # Messages
#'
#' \describe{
#'   \item{Storage-location message}{When the package picked the location itself
#'     (a per-session [tempdir()], or an existing `~/.duckdb`), `duckdb()` emits
#'     an informational message describing where extensions and secrets are
#'     going and how to change it. It is throttled by session type: in an
#'     **interactive** session at most once every eight hours (a human can act
#'     on it); in a **non-interactive** session up to 100 times, after which it
#'     goes silent for good, so a long-running or automated process is not
#'     reminded forever. The message is suppressed entirely when you chose the
#'     location yourself -- the `home` or `shared_home` argument, the
#'     `duckdb.home` option, or the `DUCKDB_R_HOME` environment variable.
#'     Non-interactively it covers both the temporary directory and an existing
#'     `~/.duckdb`; interactively it is issued only when the user opts out of
#'     creating `~/.duckdb`.
#'     It is also suppressed once you have made any explicit `home` or
#'     `shared_home` choice earlier in the session: having set the location
#'     explicitly once, you have seen how, so later auto-resolved calls stay
#'     quiet.
#'   }
#' }
#'
#' ## Silencing the message
#'
#' Make the choice explicit and it is no longer announced.
#' Pass `shared_home` to [duckdb()] -- `TRUE` to keep extensions and secrets under `~/.duckdb`,
#' `FALSE` to accept a per-session temporary directory.
#' Alternatively, point `home` (or the `duckdb.home` option / `DUCKDB_R_HOME` variable)
#' at a location of your choice.
#' As a last resort, use [suppressMessages()]:
#'
#' ```r
#' # Explicit arguments:
#' con <- dbConnect(duckdb(shared_home = FALSE))
#' con <- dbConnect(duckdb(home = "/path/to/duckdb"))
#'
#' # As a fallback:
#' con <- suppressMessages(dbConnect(duckdb()))
#'
#' # With configuration:
#' Sys.setenv(DUCKDB_R_HOME = "/path/to/duckdb")
#' con <- dbConnect(duckdb())
#' options(duckdb.home = "/path/to/duckdb")
#' con <- dbConnect(duckdb())
#' ```
#'
#' # Use by other packages
#'
#' Packages that use duckdb inherit this policy:
#'
#' * duckdb never writes outside [tempdir()] on its own during checks.
#'   In a non-interactive session (which all `R CMD check` runs are)
#'   it uses `tempdir()` by default unless a `~/.duckdb` already exists,
#'   and it never *creates* `~/.duckdb` unless requested.
#'   So a package that merely opens a database needs no special handling.
#' * Downloading and installing an extension is the caller's responsibility.
#'   Ensure that all tests involving extensions are skipped if the download fails.
#'   For robust testing on CRAN and other platforms,
#'   ensure that the extensions your package uses can be downloaded and installed.
#'   Run the check in a subprocess to avoid crashing the main R process
#'   if the extension is incompatible with the platform.
#'   To force a throwaway cache in your own tests, connect with an explicit home:
#'
#' ```r
#' tempdir_for_tests <- withr::local_tempdir()
#' con <- DBI::dbConnect(duckdb::duckdb(home = tempdir_for_tests))
#' ```
#'
#' @seealso [duckdb()] for the `home` and `shared_home` arguments.
#' @name duckdb_storage
NULL
