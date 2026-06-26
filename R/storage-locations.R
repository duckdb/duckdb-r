# Implementation of the storage-location policy documented in `?duckdb_storage`.
# Roots and marker files; the resolvers and user-facing functions build on these.

# The R session's temporary directory (mockable seam).
session_temp_dir <- function() {
  tempdir()
}

# Per-kind sub-directory name under a storage root.
storage_kind_subdir <- function(kind) {
  switch(
    kind,
    extensions = "extensions",
    secrets = "stored_secrets",
    stop("Unknown storage kind: ", kind, call. = FALSE)
  )
}

# Base directory for a named root. `"library"` is only meaningful for
# extensions (it is wiped on re-install, pairing binaries with the build ABI).
storage_root_base <- function(root) {
  switch(
    root,
    session = file.path(session_temp_dir(), "duckdb"),
    user = default_user_directory(),
    shared = duckdb_shared_home(),
    library = system_file_path(),
    stop("Unknown storage root: ", root, call. = FALSE)
  )
}

# The directory a (root, kind) pair maps to, e.g. `<root>/extensions`. An
# explicit path (anything that is not a known root name) is used verbatim.
storage_dir <- function(root, kind) {
  known <- c("session", "user", "shared", "library")
  if (!root %in% known) {
    return(path.expand(root))
  }
  file.path(storage_root_base(root), storage_kind_subdir(kind))
}

# Persistent roots a marker may opt into, in priority order. (`session` is the
# tempdir default/opt-out; `library` is auto-probed, not marker-selected.)
persistent_roots <- function() {
  c("user", "shared")
}

# --- Marker files -------------------------------------------------------------

# Name and contents of the per-kind "keep" marker. Contents are informational
# only: the package checks for the file's presence, never reads it back.
KEEP_MARKER_NAME <- ".duckdb-r-keep"
KEEP_MARKER_TEXT <- paste(
  "This directory is used by the duckdb R package to store downloaded",
  "extensions or secrets. It is safe to delete."
)

# TRUE if the keep-marker is present in `dir`.
has_keep_marker <- function(dir) {
  file.exists(file.path(dir, KEEP_MARKER_NAME))
}

# Write the keep-marker into `dir` (creating `dir` if needed) and leave it in
# place. The write doubles as a writability probe: returns TRUE if the marker
# now exists. A real write rather than file.access(), which is unreliable on
# Windows.
write_keep_marker <- function(dir) {
  if (
    !dir.exists(dir) &&
      !dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  ) {
    return(FALSE)
  }
  marker <- file.path(dir, KEEP_MARKER_NAME)
  ok <- tryCatch(
    {
      writeLines(KEEP_MARKER_TEXT, marker)
      TRUE
    },
    error = function(e) FALSE
  )
  isTRUE(ok) && file.exists(marker)
}

# Remove the keep-marker from `dir` if present.
remove_keep_marker <- function(dir) {
  marker <- file.path(dir, KEEP_MARKER_NAME)
  if (file.exists(marker)) {
    unlink(marker)
  }
  invisible()
}

# Scan the persistent roots for a kind's keep-marker. Returns the directory of
# the single marked root, or NULL if none is marked. If more than one root is
# marked the choice is ambiguous: emit a one-time message and return NULL so the
# caller falls back to the default.
marked_storage_dir <- function(kind) {
  marked <- Filter(
    function(root) has_keep_marker(storage_dir(root, kind)),
    persistent_roots()
  )
  if (length(marked) == 0L) {
    return(NULL)
  }
  if (length(marked) > 1L) {
    inform_duplicate_marker(kind, marked)
    return(NULL)
  }
  storage_dir(marked[[1L]], kind)
}

# --- Throttled messages -------------------------------------------------------

# Eight hours, in seconds.
STORAGE_MESSAGE_INTERVAL <- 8 * 60 * 60

# Current time in seconds (mockable seam so throttle tests can inject time).
now_seconds <- function() {
  as.numeric(Sys.time())
}

# Session-local throttle state.
storage_message_state <- new.env(parent = emptyenv())

# Emit `message` (an rlang-style character vector, names "i"/"!"/"*" for
# bullets) at most once per `seconds` per session.
inform_once_every <- function(id, seconds, message) {
  now <- now_seconds()
  last <- storage_message_state[[id]]
  if (!is.null(last) && (now - last) < seconds) {
    return(invisible(FALSE))
  }
  storage_message_state[[id]] <- now
  if (requireNamespace("rlang", quietly = TRUE)) {
    rlang::inform(message, class = paste0("duckdb_", id))
  } else {
    base::message(paste(message, collapse = "\n"))
  }
  invisible(TRUE)
}

inform_duplicate_marker <- function(kind, roots) {
  dirs <- vapply(roots, function(r) storage_dir(r, kind), character(1))
  names(dirs) <- rep("*", length(dirs))
  inform_once_every(
    paste0("duplicate_marker_", kind),
    STORAGE_MESSAGE_INTERVAL,
    c(
      sprintf("duckdb: %s storage is marked in more than one location:", kind),
      dirs,
      i = "Falling back to a temporary directory until only one remains."
    )
  )
}

# --- Resolution ---------------------------------------------------------------

# An explicit override for a location kind ("extension", "secret", "temp"), via
# `options(duckdb.<kind>_directory)` or `DUCKDB_<KIND>_DIRECTORY`, or NULL.
directory_override <- function(kind) {
  opt <- getOption(paste0("duckdb.", kind, "_directory"))
  if (is.character(opt) && length(opt) == 1L && nzchar(opt)) {
    return(path.expand(opt))
  }
  env <- Sys.getenv(paste0("DUCKDB_", toupper(kind), "_DIRECTORY"), unset = "")
  if (nzchar(env)) {
    return(path.expand(env))
  }
  NULL
}

# Resolve the extension cache directory (see ?duckdb_storage):
# override -> marker (user/shared) -> "library" write-probe -> session tempdir.
resolve_extension_directory <- function() {
  override <- directory_override("extension")
  if (!is.null(override)) {
    return(override)
  }
  marked <- marked_storage_dir("extensions")
  if (!is.null(marked)) {
    return(marked)
  }
  library_dir <- storage_dir("library", "extensions")
  if (has_keep_marker(library_dir) || write_keep_marker(library_dir)) {
    return(library_dir)
  }
  storage_dir("session", "extensions")
}

# Resolve the temp/spill directory. For in-memory databases DuckDB would spill
# to a `.tmp` directory in the working directory, so point it at a per-session
# tempdir instead; for on-disk databases keep DuckDB's `<db>.tmp` default
# (return NULL so the setting is left unset). Overridable.
resolve_temp_directory <- function(dbdir) {
  override <- directory_override("temp")
  if (!is.null(override)) {
    return(override)
  }
  if (is_memory_dbdir(dbdir)) {
    return(file.path(session_temp_dir(), "duckdb", "temp"))
  }
  NULL
}

is_memory_dbdir <- function(dbdir) {
  is.null(dbdir) ||
    !nzchar(dbdir) ||
    identical(dbdir, ":memory:") ||
    startsWith(dbdir, ":memory:")
}

# --- Ephemeral-storage message ------------------------------------------------

# TRUE if `path` lies inside the session's temporary directory.
path_within_tempdir <- function(path) {
  np <- normalizePath(path, winslash = "/", mustWork = FALSE)
  tp <- normalizePath(session_temp_dir(), winslash = "/", mustWork = FALSE)
  startsWith(np, tp)
}

# On connect, when the extension cache resolves to a temporary location, let the
# user know -- at most once every 8 hours per session, in unattended runs too --
# that downloaded extensions will not persist, and how to opt into a permanent
# location.
maybe_ephemeral_state_message <- function(extension_directory) {
  if (
    is.null(extension_directory) || !path_within_tempdir(extension_directory)
  ) {
    return(invisible())
  }
  inform_once_every(
    "ephemeral_state",
    STORAGE_MESSAGE_INTERVAL,
    c(
      "duckdb is keeping downloaded extensions in a temporary directory:",
      i = extension_directory,
      paste0(
        "This is removed when the R session ends, so extensions are ",
        "re-downloaded each session."
      ),
      i = paste0(
        "To keep them, point `options(duckdb.extension_directory =)` or the ",
        "`DUCKDB_EXTENSION_DIRECTORY` environment variable at a permanent path."
      )
    )
  )
}
