## usethis namespace: start
#' @useDynLib duckdb, .registration = TRUE
## usethis namespace: end
#' @name duckdb-package
#' @keywords internal
"_PACKAGE"
NULL

# Internal error function for C++ layer
rapi_error_base <- function(context, message) {
  stop(paste0(context, ": ", message), call. = FALSE)
}

# Default error function (will be conditionally replaced in .onLoad)
rapi_error <- function(context, message) {
  if (requireNamespace("rlang", quietly = TRUE)) {
    rlang::abort(paste0(context, ": ", message))
  } else {
    rapi_error_base(context, message)
  }
}
