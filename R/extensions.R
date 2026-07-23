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

# Platform seam, mockable in tests. Distinguishes Linux from other unix (e.g.
# macOS): the libc++ extension incompatibility below is Linux-specific.
is_linux <- function() {
  Sys.info()[["sysname"]] == "Linux"
}

# The C++ standard library this build of duckdb was compiled against ("libc++",
# "libstdc++", or "<an unknown C++ library>"), read from a compile-time macro
# (see `rapi_cxx_stdlib()` in src/utils.cpp). Wrapped for mockability.
compiled_cxx_stdlib <- function() {
  rapi_cxx_stdlib()
}

# TRUE when this build can safely load DuckDB's prebuilt extensions. Those are
# libstdc++ builds on Linux; loading one into a package built with a different
# C++ standard library (libc++, or one we cannot identify) is ABI-incompatible
# and crashes R (duckdb/duckdb-r#1107). So a Linux build is supported only when
# positively compiled against libstdc++; every non-Linux build is supported
# (macOS is libc++, but its prebuilt extensions match). This is the detector
# behind the auto path of resolve_allow_extensions(): on an unsupported build
# extensions default to disabled -- the engine glue errors on INSTALL/LOAD, and
# automatic extension install/load is turned off at connect. Conservative for
# the (Linux-unreachable in practice) unidentified stdlib; duckdb(allow_extensions
# = TRUE) lets a user force-enable to test.
extensions_supported <- function() {
  !is_linux() || identical(compiled_cxx_stdlib(), "libstdc++")
}

# Decide, for a single duckdb() call, whether this driver may load DuckDB
# extensions. Returns list(allow, source, announce). First match wins:
#
#   1. the `allow_extensions` argument (if non-NULL)   -> source "argument"
#   2. the `duckdb.allow_extensions` option            -> source "option"
#   3. a `DUCKDB_R_ALLOW_EXTENSIONS` env var as.logical() reads as TRUE/FALSE
#                                                        -> source "env"
#   4. otherwise: auto -- allow when this is a supported build (see
#      extensions_supported())                          -> source "auto"
#
# `announce` is TRUE only on the auto path when the build is affected (so
# extensions came out disabled). An explicit argument or option, or an env var
# as.logical() reads as TRUE (enable) or FALSE (disable), silences the advisory
# message; an unset, empty, or unparseable env var is NA -- undecided -- and
# falls through to the auto path. The option must be a scalar logical, else it
# warns and resets to NULL, mirroring `duckdb.home`.
resolve_allow_extensions <- function(allow_extensions) {
  if (!is.null(allow_extensions)) {
    check_flag(allow_extensions)
    return(list(allow = allow_extensions, source = "argument", announce = FALSE))
  }
  opt <- getOption("duckdb.allow_extensions")
  if (!is.null(opt)) {
    if (is.logical(opt) && length(opt) == 1L && !is.na(opt)) {
      return(list(allow = opt, source = "option", announce = FALSE))
    }
    warning("`duckdb.allow_extensions` option must be TRUE, FALSE, or NULL.", call. = FALSE)
    options(duckdb.allow_extensions = NULL)
  }
  env_allow <- as.logical(Sys.getenv("DUCKDB_R_ALLOW_EXTENSIONS", unset = ""))
  if (!is.na(env_allow)) {
    return(list(allow = env_allow, source = "env", announce = FALSE))
  }
  allow <- extensions_supported()
  list(allow = allow, source = "auto", announce = !allow)
}

# The advisory lines shown when extensions are disabled automatically on an
# affected build (Linux, not libstdc++). rlang-style character vector, names
# "*"/"i" for bullets, like the storage-location message.
extensions_disabled_message <- function() {
  c(
    paste0("duckdb was built with ", compiled_cxx_stdlib(), " (not libstdc++) on Linux, so DuckDB extensions are disabled:"),
    "*" = "Loading a prebuilt (libstdc++) extension could crash R (https://github.com/duckdb/duckdb-r/issues/1107).",
    "*" = "INSTALL/LOAD of an extension will error, and automatic extension loading is off.",
    "i" = "Pass duckdb(allow_extensions = FALSE) to accept this and silence this message.",
    "i" = "Pass duckdb(allow_extensions = TRUE) to attempt loading anyway (may crash R).",
    "i" = "See ?duckdb for details."
  )
}

# Message for the INSTALL/LOAD guard (CheckExtensionLoadAllowed() in
# src/statement.cpp). The C++ guard throws with context "load_extension" and an
# empty message; rapi_error()/rapi_error_rlang() fill it in from here, so the
# guard's text lives only in R -- never duplicated in the C++ glue. Kept neutral
# about the cause (unlike the duckdb() advisory, which names the stdlib): the
# guard fires both on the auto-disable path (an affected non-libstdc++ Linux
# build) and whenever the driver was created with duckdb(allow_extensions = FALSE),
# which can happen on any platform.
extensions_disabled_error <- function() {
  c(
    "DuckDB extension loading (INSTALL / LOAD) is disabled for this driver.",
    "i" = paste0(
      "Recreate the driver with duckdb(allow_extensions = TRUE) to enable it ",
      "(this may crash R on a Linux build not compiled with libstdc++; ",
      "see https://github.com/duckdb/duckdb-r/issues/1107)."
    ),
    "i" = "See ?duckdb for details."
  )
}

# Emit the extensions-disabled advisory, throttled like the storage-location
# message: interactively at most once every 8 hours, non-interactively a bounded
# number of times before going silent. Called from duckdb() only on the auto
# path when extensions came out disabled.
maybe_extensions_message <- function() {
  message <- extensions_disabled_message()
  if (is_interactive()) {
    inform_once_every("extensions", STORAGE_MESSAGE_INTERVAL, message)
  } else {
    inform_up_to("extensions", STORAGE_MESSAGE_MAX, message)
  }
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
