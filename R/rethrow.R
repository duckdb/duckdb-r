# Re-raise an error coming out of the C++ glue against the caller's frame,
# so that the message names `dbGetQuery()` rather than the internal `rapi_*()` that noticed the problem (#522).
#
# A `duckdb_error` is rebuilt rather than flattened to its text:
# the class and the fields `rapi_error()` filled from DuckDB's `ErrorData` ride across,
# so a caller can branch on `err$error_type` instead of parsing `conditionMessage()` (#2711).
# Which fields those are is `duckdb_error_field_values()`'s to say --
# a new one added there makes this call fail rather than silently drop it.
#
# The original condition is deliberately not attached as `parent`.
# Its message is this message, and rlang would print the whole thing a second time under "Caused by error in `rapi_prepare()`" --
# naming the internal frame the rethrow exists to hide.
rethrow_error_from_rapi <- function(e, call) {
  # https://github.com/duckdb/duckdb-r/issues/519
  # After moving all error messages to JSON, we can parse them and return rich error information to R.

  e <- rapi_error_raise_pending(e)

  msg <- conditionMessage(e)
  tryCatch(
    # Called for side effect, rlang::abort() eventually calls nchar()
    nchar(msg),
    error = function(e) {
      msg <<- iconv(msg, from = "UTF-8", to = "UTF-8", sub = "?")
    }
  )

  # Anything else reaching here -- an error raised by an R callback the engine invoked, say --
  # is not ours to classify, and keeps the plain rethrow.
  if (!inherits(e, "duckdb_error")) {
    rlang::abort(msg, call = call)
  }

  fields <- duckdb_error_field_values(
    e$context,
    e$error_type,
    e$raw_message,
    e$extra_info
  )
  rlang::abort(msg, class = "duckdb_error", call = call, !!!fields)
}

# Raise the error the glue left pending for `e`, from R,
# with its class and fields; a stale one is left alone.
# handbook/architecture/glue/conventions/README.md
rapi_error_raise_pending <- function(e) {
  pending <- rapi_error_pending_take()
  if (is.null(pending) || !rapi_error_pending_matches(pending, e)) {
    return(e)
  }

  tryCatch(
    rapi_error(
      pending$context,
      pending$message,
      pending$error_type,
      pending$raw_message,
      pending$extra_info
    ),
    error = identity
  )
}

# Whether `pending` is the error `e` was raised for.
# `END_CPP11` hands R at most 8191 bytes of the exception's text,
# so a prefix decides;
# 1000 bytes tell two errors apart at a bounded cost.
rapi_error_pending_matches <- function(pending, e) {
  msg <- conditionMessage(e)
  if (!is.character(msg) || length(msg) != 1L) {
    return(FALSE)
  }
  got <- charToRaw(msg)
  want <- charToRaw(pending$what)
  n <- min(length(got), length(want), 1000L)
  n > 0L && identical(got[seq_len(n)], want[seq_len(n)])
}

# Read `the$rapi_error_pending`, which the glue writes, and clear it,
# so that a pending error is raised at most once.
rapi_error_pending_take <- function() {
  pending <- the$rapi_error_pending
  rapi_error_pending_reset()
  pending
}

# Called first in `.onLoad()`, which forces `the`:
# the glue reads it without evaluating anything.
rapi_error_pending_reset <- function() {
  the$rapi_error_pending <- NULL
}

# The wrapper `rethrow_restore()` installs without rlang:
# `tryCatch()` in place of `try_fetch()`, still raising the pending error.
rethrow_base <- function(fun) {
  force(fun)
  function(...) {
    tryCatch(fun(...), error = rethrow_error_from_rapi_base)
  }
}

rethrow_error_from_rapi_base <- function(e) {
  stop(rapi_error_raise_pending(e))
}
