rethrow_error_from_rapi <- function(e, call) {
  # https://github.com/duckdb/duckdb-r/issues/519
  # After moving all error messages to JSON, we can parse them
  # and return rich error information to R.
  # For now, we just rethrow the error message as is, this gets us
  # the caller.

  msg <- conditionMessage(e)
  tryCatch(
    # Called for side effect, rlang::abort() eventually calls nchar()
    nchar(msg),
    error = function(e) {
      msg <<- iconv(msg, from = "UTF-8", to = "UTF-8", sub = "?")
    }
  )

  rlang::abort(msg, call = call)
}
