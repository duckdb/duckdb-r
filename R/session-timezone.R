# Aligning the engine's session time zone with the one this package reads a
# naive wall clock in.
# Explained in handbook/usage/timestamps/README.md.

# A `TIMESTAMP` has no zone, so both sides have to agree on one, and they
# read it from different places: this package reads the wall clock as UTC,
# while the engine renders one in its session `TimeZone`, which icu defaults
# to the machine's. Where the machine is not on UTC the two disagree, and a
# `POSIXct` written into a `TIMESTAMP` column comes back as a different
# instant. Setting the session to UTC at connect removes the disagreement,
# and leaves `SET TimeZone` free to override it afterwards.
#
# The setting lives in icu. Asking for it when icu is absent attempts an
# autoload, so this reaches for it only where it is installed already --
# `duckdb_extensions()` answers that without loading anything. Where icu
# cannot be had, the engine reports `UTC` for want of the setting, which is
# the zone this would have set.
duckdb_align_session_timezone <- function(conn) {
  if (!isTRUE(conn@driver@allow_extensions)) {
    return(invisible(FALSE))
  }

  icu <- dbGetQuery(
    conn,
    "SELECT loaded, installed
       FROM duckdb_extensions() WHERE extension_name = 'icu'"
  )
  if (nrow(icu) == 0) {
    return(invisible(FALSE))
  }

  if (!isTRUE(icu$loaded[[1]])) {
    if (!isTRUE(icu$installed[[1]])) {
      return(invisible(FALSE))
    }
    # Installed means on disk: `LOAD` reads it, and never downloads
    if (!duckdb_try_silently(conn, "LOAD icu")) {
      return(invisible(FALSE))
    }
  }

  invisible(duckdb_try_silently(conn, "SET TimeZone = 'UTC'"))
}

# A statement whose failure is an answer rather than an error: a platform
# where icu will not load, a build that refuses the setting.
duckdb_try_silently <- function(conn, sql) {
  tryCatch(
    {
      dbExecute(conn, sql)
      TRUE
    },
    error = function(e) FALSE
  )
}
