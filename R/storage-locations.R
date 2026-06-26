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

# An explicit override for a location kind ("extension", "secret", "temp") and
# the tier it came from, via `options(duckdb.<kind>_directory)` (source
# "option") or `DUCKDB_<KIND>_DIRECTORY` (source "env"), or NULL if neither.
directory_override_with_source <- function(kind) {
  opt <- getOption(paste0("duckdb.", kind, "_directory"))
  if (is.character(opt) && length(opt) == 1L && nzchar(opt)) {
    return(list(directory = path.expand(opt), source = "option"))
  }
  if (!is.null(opt)) {
    # Set but unusable: warn once per session and fall through to the env var.
    id <- paste0("bad_option_", kind)
    if (is.null(storage_message_state[[id]])) {
      storage_message_state[[id]] <- TRUE
      warning(
        sprintf(
          "Ignoring `options(duckdb.%s_directory=)`: not a non-empty string.",
          kind
        ),
        call. = FALSE
      )
    }
  }
  env <- Sys.getenv(paste0("DUCKDB_", toupper(kind), "_DIRECTORY"), unset = "")
  if (nzchar(env)) {
    return(list(directory = path.expand(env), source = "env"))
  }
  NULL
}

# Just the override path (or NULL), for the resolvers.
directory_override <- function(kind) {
  o <- directory_override_with_source(kind)
  if (is.null(o)) NULL else o$directory
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
  override <- directory_override("secret")
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
  prefix <- if (kind == "extensions") "extension" else "secret"
  override <- directory_override_with_source(prefix)
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

# Validate a requested `location` for a kind. `location` must name a known root
# ("library" is extensions-only): a marker is only ever rediscovered in a fixed
# root, so an arbitrary path could not persist and is rejected -- arbitrary
# directories are configured through the option / environment variable instead.
validate_location <- function(kind, location) {
  stopifnot(is.character(location), length(location) == 1L, !is.na(location))
  roots <- c("session", "user", "shared", if (kind == "extensions") "library")
  if (location %in% roots) {
    return(invisible())
  }
  prefix <- if (kind == "extensions") "extension" else "secret"
  stop(
    "`location` must be one of ",
    paste0('"', roots, '"', collapse = ", "),
    ", not a path. To use an arbitrary directory, set ",
    sprintf("`options(duckdb.%s_directory = ...)`", prefix),
    " or the ",
    sprintf("`DUCKDB_%s_DIRECTORY`", toupper(prefix)),
    " environment variable.",
    call. = FALSE
  )
}

# Point a kind's persistent location at `location`: clear any existing markers,
# write the new one (unless `location` is "session", the opt-out), and migrate
# the cached files. Returns the resolved directory invisibly.
set_storage_marker <- function(kind, location, migrate, conflict) {
  validate_location(kind, location)
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
  prefix <- if (kind == "extensions") "extension" else "secret"
  override <- directory_override_with_source(prefix)
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
  if (requireNamespace("rlang", quietly = TRUE)) {
    rlang::inform(msg, class = "duckdb_library_cache_init")
  } else {
    base::message(paste(msg, collapse = "\n"))
  }
  invisible()
}

# --- Ephemeral-storage warning ------------------------------------------------

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

# Directories where, if anything lands, it lands *ephemerally*: locations under
# tempdir() that duckdb() resolved itself (not ones the user pointed at). Maps
# directory -> kind. Rather than nag at connect, we wait until disconnect or
# session exit and warn only if these actually hold downloaded extensions or
# persisted secrets -- i.e. only if the session really wrote something that
# will not survive.
ephemeral_dirs <- new.env(parent = emptyenv())

# Record `dir` as ephemeral if it is under tempdir(), and make sure the
# at-exit backstop is installed. Called by duckdb() for the locations it
# auto-resolves (not when an option / env var / config chose them).
note_ephemeral_dir <- function(kind, dir) {
  if (is.null(dir) || !path_within_tempdir(dir)) {
    return(invisible())
  }
  ephemeral_dirs[[dir]] <- kind
  ensure_ephemeral_exit_hook()
  invisible()
}

# Register, once per session, a finalizer that runs the ephemeral check when R
# exits. This is the backstop for scripts that never call dbDisconnect() --
# including the long-lived default connection behind sql_query()/sql_exec().
ensure_ephemeral_exit_hook <- function() {
  if (isTRUE(storage_message_state[["exit_hook"]])) {
    return(invisible())
  }
  storage_message_state[["exit_hook"]] <- TRUE
  reg.finalizer(
    ephemeral_dirs,
    function(e) maybe_warn_ephemeral(),
    onexit = TRUE
  )
  invisible()
}

# The file names DuckDB writes for each kind, used to tell "the session really
# wrote something here" from "the directory was merely created".
ephemeral_kind_pattern <- function(kind) {
  if (kind == "extensions") "\\.duckdb_extension$" else "\\.duckdb_secret$"
}

# If any recorded ephemeral directory now actually holds downloaded extensions
# or persisted secrets, warn -- once per session -- that they will not persist,
# and how to opt into a permanent location. Called on disconnect and at exit.
maybe_warn_ephemeral <- function() {
  if (isTRUE(storage_message_state[["ephemeral_warned"]])) {
    return(invisible(FALSE))
  }
  affected <- list()
  for (dir in ls(ephemeral_dirs)) {
    kind <- ephemeral_dirs[[dir]]
    hits <- list.files(
      dir,
      pattern = ephemeral_kind_pattern(kind),
      recursive = TRUE
    )
    if (length(hits) > 0L) {
      affected[[kind]] <- dir
    }
  }
  if (length(affected) == 0L) {
    return(invisible(FALSE))
  }
  storage_message_state[["ephemeral_warned"]] <- TRUE
  inform_ephemeral(affected)
  invisible(TRUE)
}

inform_ephemeral <- function(affected) {
  bullets <- vapply(
    names(affected),
    function(k) sprintf("%s: %s", gsub("_", " ", k), affected[[k]]),
    character(1)
  )
  names(bullets) <- rep("*", length(bullets))
  msg <- c(
    "duckdb: this session kept downloaded data in a temporary directory:",
    bullets,
    i = "It is removed when the R session ends, so it will not persist.",
    i = paste0(
      "To keep it, set `options(duckdb.extension_directory=)` / ",
      "`options(duckdb.secret_directory=)` (or the matching `DUCKDB_*_DIRECTORY` ",
      "environment variables), or call `duckdb_extension_storage()` / ",
      "`duckdb_secret_storage()`."
    )
  )
  if (requireNamespace("rlang", quietly = TRUE)) {
    rlang::inform(msg, class = "duckdb_ephemeral_storage")
  } else {
    base::message(paste(msg, collapse = "\n"))
  }
  invisible()
}
