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

cleanup_user_directory <- function() {
  user_directory <- default_user_directory()
  if (!dir.exists(user_directory)) {
    return()
  }
  # Extensions are no longer kept under R_user_dir; drop any leftovers from
  # earlier versions while preserving stored_secrets which may still live here.
  user_files <- setdiff(list.files(user_directory), "stored_secrets")
  if (length(user_files) > 0) {
    message(
      "Deleting files in duckdb user directory: ",
      paste(user_files, collapse = ", ")
    )
    unlink(file.path(user_directory, user_files), recursive = TRUE)
  }
}
