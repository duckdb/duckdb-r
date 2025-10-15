#' Check for unsupported argument values
#'
#' The function checks whether a given argument is unsupported
#' It throws an error message if the argument is not among the allowed values.
#' Function is taken from dplyr.
#'
#' @param x The argument to check.
#' @param allowed A value or vector of values that are allowed for `x`. If `NULL`, no value is allowed.
#' @param allow_null Logical. If `TRUE`, allows `x` to be `NULL`.
#' @param backend Optional character string indicating the back-end.
#' @param arg The name of the argument being checked (automatically inferred via `rlang::caller_arg()`).
#' @param call The calling environment used for error reporting (automatically inferred via `rlang::caller_env()`).
#'
#' @noRd
check_unsupported_arg <- function (x, allowed = NULL, allow_null = FALSE, backend = NULL,
                                   arg = caller_arg(x), call = caller_env())
{
  if (rlang::is_missing(x)) {
    return()
  }
  if (allow_null && rlang::is_null(x)) {
    return()
  }
  if (identical(x, allowed)) {
    return()
  }
  if (rlang::is_null(allowed)) {
    msg <- "Argument {.arg {arg}} isn't supported"
  }
  else {
    msg <- "{.code {arg} = {.val {x}}} isn't supported"
  }
  if (is.null(backend)) {
    msg <- paste0(msg, " on database backends.")
  }
  else {
    msg <- paste0(msg, " in {backend} translation.")
  }
  if (!rlang::is_null(allowed)) {
    if (allow_null) {
      allow_msg <- "It must be {.val {allowed}} or {.code NULL} instead."
    }
    else {
      allow_msg <- "It must be {.val {allowed}} instead."
    }
    msg <- c(msg, i = allow_msg)
  }
  cli_abort(msg, call = call)
}

