default_user_directory <- function() {
  tools::R_user_dir("duckdb", "data")
}

# `default_user_directory()` above and `duckdb_shared_home()` below are thin
# wrappers over the environment so the storage-location logic stays testable
# without touching the real filesystem or HOME. See `?duckdb_storage` and
# plan/PLAN-storage-locations.md.

# The DuckDB default home (`~/.duckdb`), shared with the DuckDB CLI and Python
# client.
duckdb_shared_home <- function() {
  path.expand("~/.duckdb")
}

# Extension binaries are cached inside the duckdb package's installed library
# directory; co-locating with the install pairs them with the build's ABI.
default_extension_directory <- function() {
  system_file_path("extensions")
}

default_secret_directory <- function() {
  file.path(default_user_directory(), "stored_secrets")
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
