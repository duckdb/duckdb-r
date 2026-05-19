default_user_directory <- function() {
  tools::R_user_dir("duckdb", "data")
}

# Extension binaries are downloaded to:
#
#   <user_dir>/extensions/<runtime>/v<version>/<duckdb_platform>/<ext>.duckdb_extension
#
# The <runtime> segment partitions the cache by C++ standard library so that
# co-existing R installations on one machine never load each other's
# ABI-incompatible binaries. Example layouts for the spatial extension:
#
#   Linux,   GCC / libstdc++ :
#     ~/.local/share/R/duckdb/extensions/libstdcxx/v1.5.3/linux_amd64/spatial.duckdb_extension
#   Linux,   Clang / libc++  :
#     ~/.local/share/R/duckdb/extensions/libcxx/v1.5.3/linux_amd64/spatial.duckdb_extension
#   macOS,   Clang / libc++  :
#     ~/Library/Application Support/org.R-project.R/R/duckdb/extensions/libcxx/v1.5.3/osx_arm64/spatial.duckdb_extension
#   Windows, Rtools / MinGW  :
#     %LOCALAPPDATA%\R\data\R\duckdb\extensions\libstdcxx\v1.5.3\windows_amd64_mingw\spatial.duckdb_extension
#
# When runtime detection fails (or the package is loaded without going
# through ./configure), the <runtime> segment is omitted and the legacy
# unpartitioned path is used.
default_extension_directory <- function() {
  base <- file.path(default_user_directory(), "extensions")
  runtime <- the$cxx_runtime
  if (is.null(runtime) || !nzchar(runtime)) {
    base
  } else {
    file.path(base, runtime)
  }
}

default_secret_directory <- function() {
  file.path(default_user_directory(), "stored_secrets")
}

cleanup_user_directory <- function() {
  user_directory <- default_user_directory()
  if (!dir.exists(user_directory)) {
    return()
  }
  user_files <- setdiff(list.files(user_directory), c("extensions", "stored_secrets"))
  if (length(user_files) > 0) {
    message("Deleting files in duckdb user directory: ", paste(user_files, collapse = ", "))
    unlink(file.path(user_directory, user_files), recursive = TRUE)
  }

  extension_directory <- default_extension_directory()
  if (!dir.exists(extension_directory)) {
    return()
  }
  extension_files <- setdiff(list.files(extension_directory), paste0("v", get_package_version()))
  if (length(extension_files) > 0) {
    message("Deleting files in duckdb extension directory: ", paste(extension_files, collapse = ", "))
    unlink(file.path(extension_directory, extension_files), recursive = TRUE)
  }
}
