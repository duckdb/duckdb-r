default_user_directory <- function() {
  tools::R_user_dir("duckdb", "data")
}

# Extension binaries are stored inside the duckdb package's installed
# library directory:
#
#   <system.file(package = "duckdb")>/extensions/v<version>/<duckdb_platform>/<ext>.duckdb_extension
#
# Co-locating the cache with the package install guarantees that downloaded
# extensions are paired with the exact toolchain that built duckdb itself,
# regardless of C++ standard library, compiler version, or other ABI-relevant
# settings. When the package is reinstalled (upgrade, downgrade, fresh
# install on a new R), the install directory is replaced and the cache is
# wiped together with the old binaries, so the next download picks up
# extensions matching the new build.
#
# Example layouts for the spatial extension:
#
#   Linux,   user library :
#     ~/R/x86_64-pc-linux-gnu-library/4.5/duckdb/extensions/v1.5.3/linux_amd64/spatial.duckdb_extension
#   macOS,   user library :
#     ~/Library/R/arm64/4.5/library/duckdb/extensions/v1.5.3/osx_arm64/spatial.duckdb_extension
#   Windows, user library :
#     %LOCALAPPDATA%\R\win-library\4.5\duckdb\extensions\v1.5.3\windows_amd64_mingw\spatial.duckdb_extension
default_extension_directory <- function() {
  system_file_path("extensions")
}

default_secret_directory <- function() {
  file.path(default_user_directory(), "stored_secrets")
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
  if (!is.null(opt) && is.character(opt) && length(opt) == 1L && nzchar(opt)) {
    return(path.expand(opt))
  }
  env <- Sys.getenv("DUCKDB_SECRET_DIRECTORY", unset = "")
  if (nzchar(env)) {
    return(path.expand(env))
  }
  default_secret_directory()
}

#' Consolidate DuckDB secrets into the configured secret directory
#'
#' Consolidates DuckDB stored secrets from up to three source directories into
#' the directory currently configured as the target for this R session.
#'
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
    "For a persistent setting, add the line to `~/.Rprofile`, or set the\n",
    "`DUCKDB_SECRET_DIRECTORY` env var in `~/.Renviron` (e.g. via\n",
    "`usethis::edit_r_environ()`). Then call `duckdb_consolidate_secrets()`\n",
    "to move existing secrets into the chosen location. Configuring the\n",
    "directory also silences this message."
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
