default_user_directory <- function() {
  tools::R_user_dir("duckdb", "data")
}

# `default_user_directory()` above and `duckdb_shared_home()` below are thin
# wrappers over the environment so the storage-location logic stays testable
# without touching the real filesystem or HOME. See `?duckdb_storage` and
# plan/PLAN-storage-locations.md.

# The DuckDB default home (`<home>/.duckdb`), shared with the DuckDB CLI and
# Python client. The `<home>` base must match the engine's own notion of the
# home directory or markers/secrets written here would not be seen by the CLI.
duckdb_shared_home <- function() {
  file.path(duckdb_home_directory(), ".duckdb")
}

# Replicate the default home directory the bundled DuckDB engine derives in
# FileSystem::GetHomeDirectory() (src/duckdb/src/common/file_system.cpp):
# the USERPROFILE environment variable on Windows, HOME elsewhere.
#
# This deliberately avoids R's `path.expand("~")`, which on Windows resolves to
# the user's Documents folder (e.g. `C:/Users/<user>/Documents`), not the
# profile root (`C:/Users/<user>`) that DuckDB, its CLI, and the Python client
# treat as `~`. Using `path.expand()` there would point the "shared" root at a
# directory the rest of the DuckDB ecosystem never looks in.
duckdb_home_directory <- function() {
  var <- if (is_windows()) "USERPROFILE" else "HOME"
  home <- Sys.getenv(var, unset = "")
  if (!nzchar(home)) {
    # The environment variable DuckDB consults is unset (rare); fall back to
    # R's own idea of the home directory rather than producing a rootless path.
    home <- path.expand("~")
  }
  home
}

# Platform seam, mockable in tests. Mirrors DuckDB's compile-time
# `DUCKDB_WINDOWS` switch.
is_windows <- function() {
  .Platform$OS.type == "windows"
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
