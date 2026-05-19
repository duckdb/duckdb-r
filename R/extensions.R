default_user_directory <- function() {
  tools::R_user_dir("duckdb", "data")
}

default_extension_directory <- function() {
  base <- file.path(default_user_directory(), "extensions")
  runtime <- detect_cxx_runtime()
  if (nzchar(runtime)) {
    file.path(base, runtime)
  } else {
    base
  }
}

default_secret_directory <- function() {
  file.path(default_user_directory(), "stored_secrets")
}

# DuckDB-provided extension binaries are ABI-tied to a specific C++ standard
# library (libstdc++ or libc++). When several R installations on one machine
# link against different C++ runtimes, sharing a single extension cache
# causes the loader to pick up a binary built for the wrong ABI. Partition
# the cache by runtime so each ABI gets its own subdirectory.
.cxx_runtime_cache <- new.env(parent = emptyenv())

detect_cxx_runtime <- function() {
  if (exists("value", envir = .cxx_runtime_cache, inherits = FALSE)) {
    return(.cxx_runtime_cache$value)
  }
  value <- detect_cxx_runtime_uncached()
  .cxx_runtime_cache$value <- value
  value
}

detect_cxx_runtime_uncached <- function() {
  sysname <- Sys.info()[["sysname"]]
  if (sysname == "Windows") {
    # R on Windows uses Rtools (MinGW + libstdc++); the platform string
    # itself already carries an "_mingw" suffix, so no further partition.
    return("")
  }

  dll <- getLoadedDLLs()[["duckdb"]]
  if (is.null(dll)) {
    return("")
  }
  dll_path <- dll[["path"]]
  if (!nzchar(dll_path) || !file.exists(dll_path)) {
    return("")
  }

  out <- tryCatch(
    if (sysname == "Darwin") {
      system2("otool", c("-L", dll_path), stdout = TRUE, stderr = FALSE)
    } else {
      system2("ldd", dll_path, stdout = TRUE, stderr = FALSE)
    },
    error = function(e) character(),
    warning = function(w) character()
  )

  if (length(out) == 0L) {
    return("")
  }
  if (any(grepl("libc++", out, fixed = TRUE))) {
    return("libcxx")
  }
  if (any(grepl("libstdc++", out, fixed = TRUE))) {
    return("libstdcxx")
  }
  ""
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

  extensions_root <- file.path(user_directory, "extensions")
  if (!dir.exists(extensions_root)) {
    return()
  }

  current_extension_directory <- default_extension_directory()
  current_version <- paste0("v", get_package_version())

  # When the cache is partitioned by runtime, the only top-level entries we
  # own are the runtime subdirectories. Drop legacy "v<ver>" directories
  # from before the partitioning, but leave other runtimes' subdirectories
  # alone (they may belong to a different R installation on this machine).
  if (!identical(current_extension_directory, extensions_root)) {
    top_entries <- list.files(extensions_root)
    legacy <- top_entries[grepl("^v[0-9]", top_entries)]
    if (length(legacy) > 0) {
      message("Deleting files in duckdb extension directory: ", paste(legacy, collapse = ", "))
      unlink(file.path(extensions_root, legacy), recursive = TRUE)
    }
  }

  if (dir.exists(current_extension_directory)) {
    extension_files <- setdiff(list.files(current_extension_directory), current_version)
    if (length(extension_files) > 0) {
      message("Deleting files in duckdb extension directory: ", paste(extension_files, collapse = ", "))
      unlink(file.path(current_extension_directory, extension_files), recursive = TRUE)
    }
  }
}
