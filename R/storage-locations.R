# Resolution of the file-system locations the duckdb R package writes to.
# See `?duckdb_storage`.

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
