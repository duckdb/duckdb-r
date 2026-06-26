default_user_directory <- function() {
  tools::R_user_dir("duckdb", "data")
}

# Per-session base directory for DuckDB state that should not persist across
# sessions by default. It lives under `tempdir()`, so out of the box nothing is
# written outside the R session's temporary directory, as the CRAN Repository
# Policy requires. It is stable within a session, so repeated connections share
# one extension cache. We deliberately do *not* set DuckDB's `home_directory`:
# that would also redirect `~` in user SQL (e.g. `COPY ... TO '~/out.csv'`), so
# we point each location at this base explicitly instead. See `?duckdb_storage`.
default_state_directory <- function() {
  file.path(tempdir(), "duckdb")
}

# Default location for the extension cache: a per-session tempdir sub-directory.
default_extension_directory <- function() {
  file.path(default_state_directory(), "extensions")
}

# Resolution order for the extension cache:
#   1. `options(duckdb.extension_directory =)`
#   2. `Sys.getenv("DUCKDB_EXTENSION_DIRECTORY")`
#   3. `default_extension_directory()` (a per-session tempdir, CRAN-safe)
resolve_extension_directory <- function() {
  opt <- getOption("duckdb.extension_directory")
  if (is.character(opt) && length(opt) == 1L && nzchar(opt)) {
    return(path.expand(opt))
  }
  env <- Sys.getenv("DUCKDB_EXTENSION_DIRECTORY", unset = "")
  if (nzchar(env)) {
    return(path.expand(env))
  }
  default_extension_directory()
}

# Secrets default to the per-session state directory too. DuckDB binds the
# secret path at startup from the process `$HOME`, so `secret_directory` must be
# set explicitly to keep secrets inside `tempdir()` by default.
default_secret_directory <- function() {
  file.path(default_state_directory(), "stored_secrets")
}

# Location used by the DuckDB CLI and the Python client. Sharing this
# directory across DuckDB clients is opt-in for R because CRAN policy
# forbids writing outside `R_user_dir()` without user consent.
common_secret_directory <- function() {
  path.expand("~/.duckdb/stored_secrets")
}

# Resolution order for the configured secrets directory:
#   1. `options(duckdb.secret_directory =)`
#   2. `Sys.getenv("DUCKDB_SECRET_DIRECTORY")`
#   3. `default_secret_directory()` (CRAN-safe fallback)
resolve_secret_directory <- function() {
  opt <- getOption("duckdb.secret_directory")
  if (!is.null(opt)) {
    if (is.character(opt) && length(opt) == 1L && nzchar(opt)) {
      return(path.expand(opt))
    }
    message('`getOption("duckdb.secret_directory")` is not a non-empty string.')
    options(duckdb.secret_directory = NULL)
  }
  env <- Sys.getenv("DUCKDB_SECRET_DIRECTORY", unset = "")
  if (nzchar(env)) {
    return(path.expand(env))
  }
  default_secret_directory()
}

#' Consolidate DuckDB secrets into the configured secret directory
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' Consolidates DuckDB stored secrets from up to three source directories into
#' the directory currently configured as the target for this R session.
#'
#' @details
#' The target directory is the one DuckDB would write to on the next
#' connection, determined by:
#'
#' \enumerate{
#'   \item `getOption("duckdb.secret_directory")`,
#'   \item the `DUCKDB_SECRET_DIRECTORY` environment variable,
#'   \item the R-specific default returned by [tools::R_user_dir()].
#' }
#'
#' Two source directories are considered automatically:
#'
#' \itemize{
#'   \item the location shared with the DuckDB CLI and Python client
#'     (`~/.duckdb/stored_secrets`), and
#'   \item the R-specific default location under [tools::R_user_dir()].
#' }
#'
#' Whichever of these equals the target is skipped. An additional source
#' directory may be supplied via `from`. Source files are moved into the
#' target (copied and then removed).
#'
#' To consistently share secrets with the DuckDB CLI and Python client,
#' set the `duckdb.secret_directory` R option, typically in `~/.Rprofile`:
#'
#' \preformatted{options(duckdb.secret_directory = "~/.duckdb/stored_secrets")}
#'
#' Alternatively, set the `DUCKDB_SECRET_DIRECTORY` environment variable in
#' `~/.Renviron` (e.g.\ via `usethis::edit_r_environ()`). Either way, then
#' call `duckdb_consolidate_secrets()` to move existing secrets into the
#' chosen location.
#'
#' The package emits a startup message when secret files exist in both
#' the R-default and common locations and neither `duckdb.secret_directory`
#' nor `DUCKDB_SECRET_DIRECTORY` is set. Pointing either at any location
#' both configures the resolver and silences the message.
#'
#' @param from Optional path to an additional source directory to merge in,
#'   or `NULL` (the default) for none.
#' @param overwrite If `FALSE` (the default), the function aborts when any
#'   source file would overwrite an existing secret of the same name at the
#'   target. Set to `TRUE` to allow overwriting.
#' @param ask If `TRUE` (the default in interactive sessions), confirm the
#'   plan before executing it.
#'
#' @return The target directory, invisibly.
#' @export
duckdb_consolidate_secrets <- function(
  from = NULL,
  overwrite = FALSE,
  ask = interactive()
) {
  stopifnot(
    is.logical(overwrite),
    length(overwrite) == 1L,
    !is.na(overwrite)
  )
  stopifnot(is.logical(ask), length(ask) == 1L, !is.na(ask))
  if (!is.null(from)) {
    stopifnot(is.character(from), length(from) == 1L, !is.na(from))
  }

  target <- resolve_secret_directory()
  target_canonical <- normalizePath(target, mustWork = FALSE)

  candidate_sources <- c(
    common_secret_directory(),
    default_secret_directory(),
    if (!is.null(from)) path.expand(from)
  )
  source_dirs <- vapply(
    candidate_sources,
    function(p) normalizePath(p, mustWork = FALSE),
    character(1)
  )
  source_dirs <- unique(source_dirs)
  source_dirs <- source_dirs[source_dirs != target_canonical]
  source_dirs <- source_dirs[vapply(source_dirs, dir.exists, logical(1))]

  if (length(source_dirs) == 0L) {
    message("No source secrets to consolidate. Target: ", target)
    return(invisible(target))
  }

  plan <- list()
  seen_dst <- character(0)
  for (src in source_dirs) {
    files <- list.files(src, full.names = FALSE, all.files = FALSE)
    for (f in files) {
      src_path <- file.path(src, f)
      if (!file.exists(src_path) || dir.exists(src_path)) {
        next
      }
      dst_path <- file.path(target, f)
      will_overwrite <- file.exists(dst_path) || dst_path %in% seen_dst
      seen_dst <- c(seen_dst, dst_path)
      plan[[length(plan) + 1L]] <- list(
        src = src_path,
        dst = dst_path,
        overwrite = will_overwrite
      )
    }
  }

  if (length(plan) == 0L) {
    message("No secret files to consolidate. Target: ", target)
    return(invisible(target))
  }

  message("Consolidating secrets into: ", target)
  for (entry in plan) {
    if (isTRUE(entry$overwrite)) {
      message("  ! overwrite ", entry$dst, " <- ", entry$src)
    } else {
      message("  + copy      ", entry$dst, " <- ", entry$src)
    }
  }

  has_overwrites <- any(vapply(
    plan,
    function(e) isTRUE(e$overwrite),
    logical(1)
  ))
  if (has_overwrites && !overwrite) {
    stop(
      "Some target secrets would be overwritten (see entries marked `!` above). ",
      "Re-run with `overwrite = TRUE` to proceed.",
      call. = FALSE
    )
  }

  if (ask) {
    answer <- prompt_proceed("Proceed? [y/N] ")
    if (!nzchar(answer) || !tolower(substr(answer, 1L, 1L)) %in% "y") {
      message("Aborted; no files were moved.")
      return(invisible(target))
    }
  }

  if (!dir.exists(target)) {
    dir.create(target, recursive = TRUE)
  }

  for (entry in plan) {
    ok <- file.copy(
      entry$src,
      entry$dst,
      overwrite = TRUE,
      copy.date = TRUE
    )
    if (!isTRUE(ok)) {
      stop("Failed to copy: ", entry$src, call. = FALSE)
    }
    if (!file.remove(entry$src)) {
      warning("Copied but could not remove: ", entry$src, call. = FALSE)
    }
  }

  message("Consolidated ", length(plan), " secret file(s) into ", target, ".")
  invisible(target)
}

# True if the user has explicitly pointed at a secret directory via the
# R option or env var (regardless of which path they picked).
secret_directory_is_configured <- function() {
  opt <- getOption("duckdb.secret_directory")
  if (!is.null(opt) && is.character(opt) && length(opt) == 1L && nzchar(opt)) {
    return(TRUE)
  }
  nzchar(Sys.getenv("DUCKDB_SECRET_DIRECTORY", unset = ""))
}

# Show a package startup hint when both the R-default and the common
# secret stores contain files and the user has not yet picked one.
# Pointing `DUCKDB_SECRET_DIRECTORY` (or `options(duckdb.secret_directory)`)
# at either location both configures the resolver and silences this
# message.
maybe_secret_directory_message <- function() {
  if (secret_directory_is_configured()) {
    return(invisible())
  }
  r_dir <- default_secret_directory()
  common_dir <- common_secret_directory()
  if (!has_secret_files(r_dir) || !has_secret_files(common_dir)) {
    return(invisible())
  }
  packageStartupMessage(
    "duckdb: stored secrets exist in two locations:\n",
    "  - ",
    r_dir,
    " (R default)\n",
    "  - ",
    common_dir,
    " (shared with DuckDB CLI / Python)\n",
    "Pick one and set it via the `duckdb.secret_directory` option, e.g.:\n",
    "  options(duckdb.secret_directory = \"~/.duckdb/stored_secrets\")   # shared with CLI/Python\n",
    "  options(duckdb.secret_directory = \"",
    r_dir,
    "\")   # keep R-only\n",
    "For a persistent setting, add the line to `~/.Rprofile`",
    "(e.g., via `usethis::edit_r_profile()`), or set the\n",
    "`DUCKDB_SECRET_DIRECTORY` env var in `~/.Renviron` (e.g. via\n",
    "`usethis::edit_r_environ()`), and restart R. Then call\n",
    "`duckdb_consolidate_secrets()` to move existing secrets\n",
    "into the chosen location. Configuring the directory also\n",
    "silences this message."
  )
  invisible()
}

has_secret_files <- function(path) {
  dir.exists(path) &&
    length(list.files(path, all.files = FALSE)) > 0L
}

# Indirection over `readline()` so tests can mock the prompt.
prompt_proceed <- function(prompt) {
  readline(prompt)
}

# Homegrown, rlang-style message throttling: emit a given message at most once
# per `seconds` within an R session. State lives in this package-local env, so
# the throttle is per-session (like rlang's `.frequency = "regularly"`), not
# persisted to disk.
message_throttle <- new.env(parent = emptyenv())

inform_once_every <- function(id, seconds, message) {
  now <- Sys.time()
  last <- message_throttle[[id]]
  if (!is.null(last) && as.double(now - last, units = "secs") < seconds) {
    return(invisible(FALSE))
  }
  message_throttle[[id]] <- now
  if (requireNamespace("rlang", quietly = TRUE)) {
    rlang::inform(message, class = paste0("duckdb_", id))
  } else {
    base::message(paste(message, collapse = "\n"))
  }
  invisible(TRUE)
}

# TRUE if `path` lies inside the session's temporary directory.
path_within_tempdir <- function(path) {
  np <- normalizePath(path, winslash = "/", mustWork = FALSE)
  tp <- normalizePath(tempdir(), winslash = "/", mustWork = FALSE)
  startsWith(np, tp)
}

# Eight hours, in seconds.
EPHEMERAL_STATE_MESSAGE_INTERVAL <- 8 * 60 * 60

# When a connection is established and the extension cache resolves to a
# temporary location, let the user know -- at most once every 8 hours per
# session -- that downloaded extensions will not persist, and how to opt into a
# permanent location. Emitted in unattended (non-interactive) runs too, so the
# notice shows up in logs.
maybe_ephemeral_state_message <- function(extension_directory) {
  if (
    is.null(extension_directory) || !path_within_tempdir(extension_directory)
  ) {
    return(invisible())
  }
  inform_once_every(
    "ephemeral_state",
    EPHEMERAL_STATE_MESSAGE_INTERVAL,
    c(
      "duckdb is keeping downloaded extensions in a temporary directory:",
      i = extension_directory,
      paste0(
        "This is removed when the R session ends, so extensions are ",
        "re-downloaded each session."
      ),
      i = paste0(
        "To keep them, point `options(duckdb.extension_directory =)` or the ",
        "`DUCKDB_EXTENSION_DIRECTORY` environment variable at a permanent path."
      )
    )
  )
}

cleanup_user_directory <- function() {
  user_directory <- default_user_directory()
  if (!dir.exists(user_directory)) {
    return()
  }
  # Extensions are no longer kept under R_user_dir; drop any leftovers from
  # earlier versions while preserving stored_secrets which still lives here.
  user_files <- setdiff(list.files(user_directory), "stored_secrets")
  if (length(user_files) > 0) {
    message(
      "Deleting files in duckdb user directory: ",
      paste(user_files, collapse = ", ")
    )
    unlink(file.path(user_directory, user_files), recursive = TRUE)
  }
}
