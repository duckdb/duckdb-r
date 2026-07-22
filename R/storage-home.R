# Implementation of the storage-location policy documented in `?duckdb_storage`.
# Extensions and stored secrets live under a single "home" directory that is
# resolved afresh on every `duckdb()` call; the resolvers and the user-facing
# status function build on the helpers below.

# --- Home root ----------------------------------------------------------------

# The R session's temporary directory (mockable seam).
session_temp_dir <- function() {
  tempdir()
}

# The per-session home, under tempdir(). Wiped when the R session ends.
session_home <- function() {
  file.path(session_temp_dir(), "duckdb")
}

# The sub-directory of a home root that holds a given kind of state. The names
# ("extensions", "stored_secrets") match DuckDB's own layout, so a home shared
# with the DuckDB CLI and Python client lines up.
home_subdir <- function(root, kind) {
  file.path(root, kind)
}

# TRUE for a usable scalar path string.
is_nonempty_string <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
}

# --- Resolution ---------------------------------------------------------------

# Resolve the home directory this connection uses for extensions and secrets,
# and the tier that chose it. First match wins:
#
#   1. the `home` argument to duckdb()          -> source "argument"
#   2. the `duckdb.home` option                 -> source "option"
#   3. the `DUCKDB_R_HOME` environment variable -> source "env"
#   4. `~/.duckdb`, if it already exists         -> source "shared"
#   5. otherwise: in an interactive session, offer to create `~/.duckdb` once
#      (source "created" if accepted); a declined prompt or a non-interactive
#      session falls back to a per-session tempdir (source "session").
#
# Only branch 5 in an interactive session has side effects (a prompt and, on
# consent, creating the directory). The read-only counterpart used by
# `duckdb_storage_status()` is `describe_storage_home()`.
resolve_storage_home <- function(home = NULL, shared_home = NULL) {
  # `shared_home` is a tri-state explicit override (duckdb() has already checked
  # it is not combined with `home`):
  #   * NULL  -- resolve automatically (the tiers below).
  #   * TRUE  -- opt in to ~/.duckdb, creating it if needed, with no prompt.
  #   * FALSE -- force a per-session tempdir, even if ~/.duckdb already exists
  #              (and ignoring the option/environment variable).
  if (isTRUE(shared_home)) {
    shared <- duckdb_shared_home()
    dir.create(shared, recursive = TRUE, showWarnings = FALSE)
    return(list(root = shared, source = "shared"))
  }
  if (isFALSE(shared_home)) {
    return(list(root = session_home(), source = "session"))
  }

  fixed <- fixed_storage_home(home)
  if (!is.null(fixed)) {
    return(fixed)
  }

  shared <- duckdb_shared_home()
  if (dir.exists(shared)) {
    return(list(root = shared, source = "shared"))
  }

  if (is_interactive() && !home_prompt_declined()) {
    # consent_to_create_home() returns askYesNo()'s TRUE/FALSE/NA; treat
    # anything but an explicit TRUE (including a cancelled prompt) as a decline.
    if (isTRUE(consent_to_create_home(shared))) {
      dir.create(shared, recursive = TRUE, showWarnings = FALSE)
      if (dir.exists(shared)) {
        return(list(root = shared, source = "created"))
      } else {
        warning(
          "duckdb: failed to create ", shared, "; falling back to a temporary directory.",
          call. = FALSE
        )
      }
    }

    # Remember a decline (or a failed creation) so we do not prompt again this
    # session; fall through to the per-session default.
    mark_home_prompt_declined()
  }

  list(root = session_home(), source = "session")
}

# The tiers of `resolve_storage_home()` that are pure lookups with no side
# effects: the explicit argument, the option, and the environment variable.
# Returns NULL when none is set. Shared by the resolver and the read-only
# `describe_storage_home()`.
fixed_storage_home <- function(home = NULL) {
  if (!is.null(home)) {
    check_home_arg(home)
    return(list(root = path.expand(home), source = "argument"))
  }
  opt <- getOption("duckdb.home")
  if (is_nonempty_string(opt)) {
    return(list(root = path.expand(opt), source = "option"))
  } else if (!is.null(opt)) {
    warning("`duckdb.home` option must be a single non-empty string (a directory path), or NULL.", call. = FALSE)
    options(duckdb.home = NULL)
  }
  env <- Sys.getenv("DUCKDB_R_HOME", unset = "")
  if (nzchar(env)) {
    return(list(root = path.expand(env), source = "env"))
  }
  NULL
}

# Read-only counterpart to `resolve_storage_home()`, used by
# `duckdb_storage_status()`: never prompts and never creates a directory.
# A missing `~/.duckdb` is therefore reported as the per-session default.
describe_storage_home <- function() {
  fixed <- fixed_storage_home()
  if (!is.null(fixed)) {
    return(fixed)
  }
  shared <- duckdb_shared_home()
  if (dir.exists(shared)) {
    return(list(root = shared, source = "shared"))
  }
  list(root = session_home(), source = "session")
}

check_home_arg <- function(home) {
  if (!is_nonempty_string(home)) {
    stop(
      "`home` must be a single non-empty string (a directory path), or NULL.",
      call. = FALSE
    )
  }
}

# --- Interactive consent ------------------------------------------------------

# Ask, in an interactive session, whether `~/.duckdb` may be created. Returns
# askYesNo()'s TRUE / FALSE / NA (NA when the prompt is cancelled); the caller
# treats anything but TRUE as a decline. Mockable seam: tests bind this directly
# rather than driving the console.
consent_to_create_home <- function(path) {
  utils::askYesNo(
    paste0("duckdb: create ", path, "?\n"),
    default = TRUE
  )
}

home_prompt_declined <- function() {
  isTRUE(storage_message_state[["home_prompt_declined"]])
}

mark_home_prompt_declined <- function() {
  storage_message_state[["home_prompt_declined"]] <- TRUE
}

# --- Temp / spill directory ---------------------------------------------------

# An explicit temp/spill-directory override via the `duckdb.temp_directory`
# option or the `DUCKDB_R_TEMP_DIRECTORY` environment variable, or NULL if neither
# is set. Unlike the extension/secret home this stays a separate knob: spill
# files can be large and are unrelated to the extension cache.
temp_directory_override <- function() {
  opt <- getOption("duckdb.temp_directory")
  if (is_nonempty_string(opt)) {
    return(list(directory = path.expand(opt), source = "option"))
  }
  env <- Sys.getenv("DUCKDB_R_TEMP_DIRECTORY", unset = "")
  if (nzchar(env)) {
    return(list(directory = path.expand(env), source = "env"))
  }
  NULL
}

# Resolve the temp/spill directory. For in-memory databases DuckDB would spill
# to a `.tmp` directory in the working directory, so point it at a per-session
# tempdir instead; for on-disk databases keep DuckDB's `<db>.tmp` default
# (`directory` is NULL so the setting is left unset). Overridable.
resolve_temp_directory <- function(dbdir) {
  override <- temp_directory_override()
  if (!is.null(override)) {
    return(override)
  }
  if (is_memory_dbdir(dbdir)) {
    return(list(
      directory = file.path(session_home(), "temp"),
      source = "session"
    ))
  }
  list(directory = NULL, source = "default")
}

is_memory_dbdir <- function(dbdir) {
  is.null(dbdir) ||
    !nzchar(dbdir) ||
    identical(dbdir, ":memory:") ||
    startsWith(dbdir, ":memory:")
}

# --- Throttled messages -------------------------------------------------------

# Eight hours, in seconds.
STORAGE_MESSAGE_INTERVAL <- 8 * 60 * 60

# Current time in seconds (mockable seam so throttle tests can inject time).
now_seconds <- function() {
  as.numeric(Sys.time())
}

# Session-local throttle state (also holds the "prompt declined" flag).
storage_message_state <- new.env(parent = emptyenv())

# Emit `message` (an rlang-style character vector, names "i"/"!"/"*" for
# bullets) at most once per `seconds` per session.
inform_once_every <- function(id, seconds, message) {
  now <- now_seconds()
  last <- storage_message_state[[id]]
  if (is.numeric(last) && (now - last) < seconds) {
    return(invisible(FALSE))
  }
  storage_message_state[[id]] <- now
  inform(message, class = paste0("duckdb_", id))
  invisible(TRUE)
}

# Called on connect in a non-interactive session, when the location was chosen
# by the package itself (a per-session tempdir, or an existing ~/.duckdb) rather
# than requested explicitly. Reports where extensions and secrets are going --
# at most once every 8 hours per session -- and how to change or silence it.
# `resolved` is the list(root, source) from resolve_storage_home().
maybe_storage_location_message <- function(resolved) {
  if (is.null(resolved) || is.null(resolved$root)) {
    return(invisible())
  }
  if (identical(resolved$source, "shared")) {
    message <- c(
      "duckdb is storing downloaded extensions and secrets under ~/.duckdb:",
      "i" = resolved$root,
      "This persists across sessions and is shared with the DuckDB CLI and other clients.",
      "i" = "Run duckdb(shared_home = FALSE) to use a temporary directory instead.",
      "i" = "See ?duckdb_storage for details and alternatives."
    )
  } else {
    message <- c(
      "duckdb is keeping downloaded extensions and secrets",
      "in a temporary directory:",
      "i" = resolved$root,
      "This is removed when the R session ends.",
      "*" = "Extensions are re-downloaded each session.",
      "*" = "Secrets are lost.",
      "i" = "Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users)",
      "i" = "Run duckdb(shared_home = FALSE) to silence this message",
      "i" = "See ?duckdb_storage for details and alternatives."
    )
  }
  inform_once_every("storage_location", STORAGE_MESSAGE_INTERVAL, message)
}
