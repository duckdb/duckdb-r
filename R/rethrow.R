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
