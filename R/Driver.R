DBDIR_MEMORY <- ":memory:"

check_flag <- function(x) {
  if (is.null(x) || length(x) != 1 || is.na(x) || !is.logical(x)) {
    stop("flags need to be scalar logicals")
  }
}

extptr_str <- function(e, n = 5) {
  x <- rethrow_rapi_ptr_to_str(e)
  substr(x, nchar(x) - n + 1, nchar(x))
}

drv_to_string <- function(drv) {
  if (!is(drv, "duckdb_driver")) {
    stop("pass a duckdb_driver object")
  }
  sprintf(
    "<duckdb_driver dbdir='%s' read_only=%s bigint=%s>",
    drv@dbdir,
    drv@read_only,
    drv@convert_opts$bigint
  )
}

driver_registry <- new.env(parent = emptyenv())

#' @description
#' `duckdb()` creates or reuses a database instance.
#'
#' @param home Root directory for DuckDB's downloaded extensions and stored secrets.
#'   `NULL` (the default) resolves the location as described in [duckdb_storage]:
#'   an existing `~/.duckdb`, else a per-session temporary directory
#'   (with an offer to create `~/.duckdb` in interactive sessions).
#'   Pass a path to use it as the root explicitly, creating it if needed.
#'   Cannot be combined with `shared_home`.
#' @param shared_home Opt in or out of the shared `~/.duckdb` location,
#'   overriding the automatic resolution.
#'   One of:
#'   * `NULL` (the default) -- resolve automatically (see [duckdb_storage]).
#'     This is the safe default.
#'   * `TRUE` -- store extensions and secrets under `~/.duckdb`, **creating that
#'     directory if it does not exist**.
#'     This is a good setting for permanent deployments (Posit Connect, Shiny, APIs).
#'     Do not use on CRAN or on other infrastructure where you don't own `~/.duckdb`.
#'
#'     The setting is a durable, machine-level side effect that is *not* scoped to the current session:
#'     the directory persists after R exits, is reused by every future R session
#'     (and by the DuckDB CLI, Python and other clients that share `~/.duckdb`),
#'     and any secrets written there outlive this process.
#'     Applying this setting repeatedly is a fast no-op.
#'   * `FALSE` -- use a per-session temporary directory even if `~/.duckdb`
#'     already exists. Nothing persists beyond the session.
#'
#'   Cannot be combined with `home`.
#' @param environment_scan Set to `TRUE` to treat
#'   data frames from the calling environment as tables.
#'   If a database table with the same name exists, it takes precedence.
#'   The default of this setting may change in a future version.
#'
#' @return `duckdb()` returns an object of class [duckdb_driver-class].
#'
#' @import methods DBI
#' @export
duckdb <- function(
  dbdir = DBDIR_MEMORY,
  read_only = FALSE,
  bigint = "numeric",
  config = list(),
  ...,
  home = NULL,
  shared_home = NULL,
  environment_scan = FALSE
) {
  check_flag(read_only)
  if (...length() > 0) {
    stop("... must be empty")
  }
  if (
    !is.null(shared_home) &&
      !(is.logical(shared_home) && length(shared_home) == 1L && !is.na(shared_home))
  ) {
    stop("`shared_home` must be TRUE, FALSE, or NULL.", call. = FALSE)
  }
  if (!is.null(home) && !is.null(shared_home)) {
    stop("Pass either `home` or `shared_home`, not both.", call. = FALSE)
  }

  convert_opts <- duckdb_convert_opts(bigint = bigint)

  dbdir <- path_normalize(dbdir)
  if (dbdir != DBDIR_MEMORY) {
    drv <- driver_registry[[dbdir]]
    # We reuse an existing driver object if the database is still alive.
    # If not, we fall back to creating a new driver object with a new database.
    if (!is.null(drv) && rethrow_rapi_lock(drv@database_ref)) {
      # We don't care about different read_only or config settings here.
      # The bigint setting can be actually picked up by dbConnect(), we update it here.
      drv@convert_opts <- convert_opts
      drv@bigint <- convert_opts$bigint
      return(drv)
    }
  }

  # Choose CRAN-safe locations for the engine's writable state unless the user
  # set them explicitly. Extensions and secrets share a "home" directory
  # resolved fresh on every call (an existing ~/.duckdb, else a temporary
  # directory; see `?duckdb_storage`); the temp/spill directory is redirected
  # for in-memory databases.
  need_extension <- !("extension_directory" %in% names(config))
  need_secret <- !("secret_directory" %in% names(config))
  if (need_extension || need_secret) {
    resolved_home <- resolve_storage_home(home, shared_home)
    if (need_extension) {
      config["extension_directory"] <- home_subdir(
        resolved_home$root,
        "extensions"
      )
    }
    if (need_secret) {
      config["secret_directory"] <- home_subdir(
        resolved_home$root,
        "stored_secrets"
      )
    }
    # In a non-interactive session, report where storage resolved (once),
    # unless the caller chose the location explicitly with `home` or
    # `shared_home`. Only the package's own choices are announced (a per-session
    # tempdir, or an existing ~/.duckdb); an option/environment override or an
    # interactive prompt is already the user's decision.
    if (
      !is_interactive() &&
        is.null(home) &&
        is.null(shared_home) &&
        resolved_home$source %in% c("session", "shared")
    ) {
      maybe_storage_location_message(resolved_home)
    }
  }
  if (!("temp_directory" %in% names(config))) {
    temp_directory <- resolve_temp_directory(dbdir)$directory
    if (!is.null(temp_directory)) {
      config["temp_directory"] <- temp_directory
    }
  }

  # Always create new database for in-memory,
  # allows isolation and mixing different configs
  drv <- new(
    "duckdb_driver",
    config = config,
    database_ref = rethrow_rapi_startup(
      dbdir,
      read_only,
      config,
      environment_scan
    ),
    dbdir = dbdir,
    read_only = read_only,
    convert_opts = convert_opts,
    bigint = convert_opts$bigint
  )

  if (dbdir != DBDIR_MEMORY) {
    driver_registry[[dbdir]] <- drv
  }

  reg.finalizer(drv@database_ref, onexit = TRUE, rapi_shutdown)

  drv
}

#' @description
#' `duckdb_shutdown()` shuts down a database instance.
#'
#' @return `dbDisconnect()` and `duckdb_shutdown()` are called for their
#'   side effect.
#' @rdname duckdb
#' @export
duckdb_shutdown <- function(drv) {
  if (!is(drv, "duckdb_driver")) {
    stop("pass a duckdb_driver object")
  }
  if (!dbIsValid(drv)) {
    warning("invalid driver object, already closed?")
    invisible(FALSE)
  }
  rethrow_rapi_shutdown(drv@database_ref)

  if (drv@dbdir != DBDIR_MEMORY) {
    rm(list = drv@dbdir, envir = driver_registry)
  }

  invisible(TRUE)
}

#' @description
#' Return an [adbcdrivermanager::adbc_driver()] for use with Arrow Database
#' Connectivity via the adbcdrivermanager package.
#'
#' @return An object of class "adbc_driver"
#' @rdname duckdb
#' @export
#' @examplesIf simulate_duckdb()$env$examples_enabled() && requireNamespace("adbcdrivermanager", quietly = TRUE)
#' library(adbcdrivermanager)
#' with_adbc(db <- adbc_database_init(duckdb_adbc()), {
#'   as.data.frame(read_adbc(db, "SELECT 1 as one;"))
#' })
duckdb_adbc <- function() {
  init_func <- structure(
    rethrow_rapi_adbc_init_func(),
    class = "adbc_driver_init_func"
  )
  adbcdrivermanager::adbc_driver(init_func, subclass = "duckdb_driver_adbc")
}

# Registered in zzz.R
adbc_database_init.duckdb_driver_adbc <- function(driver, ...) {
  adbcdrivermanager::adbc_database_init_default(
    driver,
    list(...),
    subclass = "duckdb_database_adbc"
  )
}

adbc_connection_init.duckdb_database_adbc <- function(database, ...) {
  adbcdrivermanager::adbc_connection_init_default(
    database,
    list(...),
    subclass = "duckdb_connection_adbc"
  )
}

adbc_statement_init.duckdb_connection_adbc <- function(connection, ...) {
  adbcdrivermanager::adbc_statement_init_default(
    connection,
    list(...),
    subclass = "duckdb_statement_adbc"
  )
}

is_installed <- function(pkg) {
  as.logical(requireNamespace(pkg, quietly = TRUE)) == TRUE
}

check_tz <- function(timezone) {
  if (!is.null(timezone) && timezone == "") {
    return("")
  }

  if (is.null(timezone) || !timezone %in% OlsonNames()) {
    warning(
      "Invalid time zone '",
      timezone,
      "', ",
      "falling back to UTC.\n",
      "Set the `timezone_out` argument to a valid time zone.\n",
      call. = FALSE
    )
    return("UTC")
  }

  timezone
}

path_normalize <- function(path) {
  if (path == "" || path == DBDIR_MEMORY) {
    return(DBDIR_MEMORY)
  }

  out <- normalizePath(path, mustWork = FALSE)

  # Stable results are only guaranteed if the file exists
  if (!file.exists(out)) {
    on.exit(unlink(out))
    writeLines(character(), out)
    out <- normalizePath(out, mustWork = TRUE)
  }
  out
}
