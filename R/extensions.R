default_user_directory <- function() {
  tools::R_user_dir("duckdb", "data")
}

default_extension_directory <- function() {
  file.path(default_user_directory(), "extensions")
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
