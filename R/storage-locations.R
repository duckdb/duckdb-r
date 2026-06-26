# Implementation of the storage-location policy documented in `?duckdb_storage`.
# Roots and marker files; the resolvers and user-facing functions build on these.

# The R session's temporary directory (mockable seam).
session_temp_dir <- function() {
  tempdir()
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

# The directory a (root, kind) pair maps to, e.g. `<root>/extensions`. `root`
# must be a known root name (`storage_root_base()` errors otherwise); `kind` is
# the sub-directory, matching DuckDB's own names ("extensions",
# "stored_secrets").
storage_dir <- function(root, kind) {
  if (!kind %in% c("extensions", "stored_secrets")) {
    stop("Unknown storage kind: ", kind, call. = FALSE)
  }
  file.path(storage_root_base(root), kind)
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
KEEP_MARKER_TEXT <- paste0(
  "Marker written by the duckdb R package: while this file is present, ",
  "downloaded extensions or stored secrets are kept in this directory. ",
  "Delete this file to opt out; deleting the directory itself removes the ",
  "stored data."
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
  if (!dir.exists(dir)) {
    created <- dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    if (!created) {
      return(FALSE)
    }
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
  inform(message, class = paste0("duckdb_", id))
  invisible(TRUE)
}

inform_duplicate_marker <- function(kind, roots) {
  dirs <- vapply(roots, function(r) storage_dir(r, kind), character(1))
  names(dirs) <- rep("*", length(dirs))
  inform_once_every(
    paste0("duplicate_marker_", kind),
    STORAGE_MESSAGE_INTERVAL,
    c(
      sprintf(
        "duckdb: %s storage is marked in more than one location:",
        gsub("_", " ", kind)
      ),
      dirs,
      i = "Falling back to a temporary directory until only one remains."
    )
  )
}

# --- Resolution ---------------------------------------------------------------

# An explicit override for a storage kind ("extensions", "stored_secrets",
# "temp") and the tier it came from, via the option (source "option") or
# environment variable (source "env") for its DuckDB setting, or NULL if neither.
directory_override_with_source <- function(kind) {
  # The kind token ("extensions" / "stored_secrets") matches DuckDB's
  # sub-directory names; the option/env var use DuckDB's *setting* names
  # ("extension" / "secret"), which we map to here.
  setting <- override_setting(kind)
  opt <- getOption(paste0("duckdb.", setting, "_directory"))
  if (is.character(opt) && length(opt) == 1L && nzchar(opt)) {
    return(list(directory = path.expand(opt), source = "option"))
  }
  if (!is.null(opt)) {
    # Set but unusable: warn once per session and fall through to the env var.
    id <- paste0("bad_option_", setting)
    if (is.null(storage_message_state[[id]])) {
      storage_message_state[[id]] <- TRUE
      warning(
        sprintf(
          "Ignoring `options(duckdb.%s_directory=)`: not a non-empty string.",
          setting
        ),
        call. = FALSE
      )
    }
  }
  env <- Sys.getenv(
    paste0("DUCKDB_", toupper(setting), "_DIRECTORY"),
    unset = ""
  )
  if (nzchar(env)) {
    return(list(directory = path.expand(env), source = "env"))
  }
  NULL
}

# Map a storage kind to the DuckDB config-setting name behind its option / env
# var (`duckdb.<setting>_directory` / `DUCKDB_<SETTING>_DIRECTORY`).
override_setting <- function(kind) {
  switch(
    kind,
    extensions = "extension",
    stored_secrets = "secret",
    temp = "temp",
    stop("Unknown storage kind: ", kind, call. = FALSE)
  )
}

# Just the override path (or NULL), for the resolvers.
directory_override <- function(kind) {
  o <- directory_override_with_source(kind)
  if (is.null(o)) NULL else o$directory
}

# Resolve the extension cache directory (see ?duckdb_storage):
# override -> marker (user/shared) -> "library" write-probe -> session tempdir.
resolve_extension_directory <- function() {
  override <- directory_override("extensions")
  if (!is.null(override)) {
    return(override)
  }
  marked <- marked_storage_dir("extensions")
  if (!is.null(marked)) {
    return(marked)
  }
  library_dir <- storage_dir("library", "extensions")
  if (has_keep_marker(library_dir)) {
    return(library_dir)
  }
  # Writing the marker doubles as the writability probe. When it succeeds the
  # marker did not exist before, so this is the first time the library cache is
  # initialized -- say so once (it then persists across sessions).
  if (write_keep_marker(library_dir)) {
    inform_library_cache_init(library_dir)
    return(library_dir)
  }
  storage_dir("session", "extensions")
}

# Resolve the secrets directory (see ?duckdb_storage):
# override -> marker (user/shared) -> session tempdir. There is no "library"
# root for secrets, and the default is a per-session temporary directory.
resolve_secret_directory <- function() {
  override <- directory_override("stored_secrets")
  if (!is.null(override)) {
    return(override)
  }
  marked <- marked_storage_dir("stored_secrets")
  if (!is.null(marked)) {
    return(marked)
  }
  storage_dir("session", "stored_secrets")
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

# --- Inspecting and changing the persistent location -------------------------

# Read-only counterpart to the resolvers, used by duckdb_storage_status(): the
# resolved directory and the tier that selected it. Unlike the connect-time
# resolver it does not write-probe the library, so it has no side effects and
# reports only what is already persisted.
describe_storage <- function(kind) {
  override <- directory_override_with_source(kind)
  if (!is.null(override)) {
    return(override)
  }
  marked <- marked_storage_dir(kind)
  if (!is.null(marked)) {
    return(list(directory = marked, source = "marker"))
  }
  if (kind == "extensions") {
    library_dir <- storage_dir("library", kind)
    if (has_keep_marker(library_dir)) {
      return(list(directory = library_dir, source = "library"))
    }
  }
  list(directory = storage_dir("session", kind), source = "session")
}

# Roots whose marker is cleared before a new one is written, so a kind is never
# marked in more than one place. Extensions add "library" (the auto-probe root).
marker_roots <- function(kind) {
  if (kind == "extensions") {
    c("user", "shared", "library")
  } else {
    c("user", "shared")
  }
}

# Point a kind's persistent location at `location`: clear any existing markers,
# write the new one (unless `location` is "session", the opt-out), and migrate
# the cached files. Returns the resolved directory invisibly.
set_storage_marker <- function(kind, location, migrate, conflict) {
  # `location` is already validated against the kind's roots by the exported
  # wrapper (via arg_match()).
  conflict <- match.arg(conflict, c("error", "ours", "theirs"))
  stopifnot(is.logical(migrate), length(migrate) == 1L, !is.na(migrate))

  # Capture the current source(s) before clearing markers (see migration_sources
  # for why this can be more than one directory).
  from <- migration_sources(kind)

  for (root in marker_roots(kind)) {
    remove_keep_marker(storage_dir(root, kind))
  }

  if (identical(location, "session")) {
    # Opt-out: revert to the per-session default. Cached files are left where
    # they are rather than moved into a directory that is wiped on exit.
    return(invisible(storage_dir("session", kind)))
  }

  to <- storage_dir(location, kind)
  if (!write_keep_marker(to)) {
    stop("Cannot write the storage marker to ", to, ".", call. = FALSE)
  }
  if (isTRUE(migrate)) {
    for (src in from) {
      migrate_storage(src, to, conflict)
    }
  }
  invisible(to)
}

# The directory or directories holding a kind's currently-cached files, used as
# the migration source(s). Mirrors the resolver's precedence (override -> marker
# -> default) but, in the marker tier, returns *every* marked root: if a kind is
# (abnormally) marked in more than one root, relocating should sweep them all in
# rather than orphan the data left in the roots whose markers we clear.
migration_sources <- function(kind) {
  override <- directory_override_with_source(kind)
  if (!is.null(override)) {
    return(override$directory)
  }
  marked <- Filter(
    function(r) has_keep_marker(storage_dir(r, kind)),
    marker_roots(kind)
  )
  if (length(marked) > 0L) {
    return(vapply(marked, function(r) storage_dir(r, kind), character(1)))
  }
  describe_storage(kind)$directory
}

# Move the cached files from `from` to `to` (recursively, preserving DuckDB's
# `v<version>/<platform>/` layout) without the keep-marker. `conflict` decides
# name collisions at the destination: "error" aborts listing them, "ours"
# overwrites, "theirs" keeps the destination and drops the colliding sources.
migrate_storage <- function(from, to, conflict) {
  if (!dir.exists(from)) {
    return(invisible())
  }
  if (
    identical(
      normalizePath(from, mustWork = FALSE),
      normalizePath(to, mustWork = FALSE)
    )
  ) {
    return(invisible())
  }
  rel <- list.files(from, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  rel <- rel[basename(rel) != KEEP_MARKER_NAME]
  if (length(rel) == 0L) {
    return(invisible())
  }
  collide <- rel[file.exists(file.path(to, rel))]
  if (length(collide) > 0L && identical(conflict, "error")) {
    stop(
      "Migration would overwrite files at ",
      to,
      ":\n",
      paste0("  ", collide, collapse = "\n"),
      '\nRe-run with conflict = "ours" or "theirs".',
      call. = FALSE
    )
  }
  # "theirs" keeps the destination, so its colliding sources are not copied.
  to_copy <- if (identical(conflict, "theirs")) setdiff(rel, collide) else rel
  for (r in to_copy) {
    dst <- file.path(to, r)
    dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
    if (
      !file.copy(file.path(from, r), dst, overwrite = TRUE, copy.date = TRUE)
    ) {
      stop("Failed to migrate ", file.path(from, r), ".", call. = FALSE)
    }
  }
  # Every source is removed: copied ones moved, "theirs" collisions dropped.
  unlink(file.path(from, rel))
  remaining <- rel[file.exists(file.path(from, rel))]
  if (length(remaining) > 0L) {
    warning(
      "Migrated, but could not remove the originals under ",
      from,
      "; they now exist in both locations:\n",
      paste0("  ", remaining, collapse = "\n"),
      call. = FALSE
    )
  }
  invisible()
}

# Announce the first time the package library is used as the extension cache.
# Only reached when the keep-marker was just written (it persists afterwards),
# so this fires once per install rather than once per session.
inform_library_cache_init <- function(dir) {
  msg <- c(
    "duckdb: caching downloaded extensions in the package library:",
    i = dir,
    i = paste0(
      "This is removed when the package is re-installed; see `?duckdb_storage` ",
      "to choose a different location."
    )
  )
  inform(msg, class = "duckdb_library_cache_init")
  invisible()
}

# --- Ephemeral-storage message ------------------------------------------------

# TRUE if `path` lies inside the session's temporary directory. Compares whole
# path segments (so `/tmp/Rtmp1` is not treated as a prefix of `/tmp/Rtmp12`).
path_within_tempdir <- function(path) {
  if (length(path) != 1L || is.na(path) || !nzchar(path)) {
    return(FALSE)
  }
  np <- normalizePath(path, winslash = "/", mustWork = FALSE)
  tp <- normalizePath(session_temp_dir(), winslash = "/", mustWork = FALSE)
  np == tp || startsWith(np, paste0(tp, "/"))
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
