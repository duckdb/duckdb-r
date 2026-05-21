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

cleanup_user_directory <- function() {
  user_directory <- default_user_directory()
  if (!dir.exists(user_directory)) {
    return()
  }
  # Extensions are no longer kept under R_user_dir; drop any leftovers from
  # earlier versions while preserving stored_secrets which still lives here.
  user_files <- setdiff(list.files(user_directory), "stored_secrets")
  if (length(user_files) > 0) {
    message("Deleting files in duckdb user directory: ", paste(user_files, collapse = ", "))
    unlink(file.path(user_directory, user_files), recursive = TRUE)
  }
}
