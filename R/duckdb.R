## usethis namespace: start
#' @useDynLib duckdb, .registration = TRUE
## usethis namespace: end
#' @name duckdb-package
#' @keywords internal
"_PACKAGE"
NULL

# Internal error function for C++ layer
rapi_error <- function(context, message) {
  stop(paste0(context, ": ", message), call. = FALSE)
}

# rlang error function (will be conditionally replaced in .onLoad)
rapi_error_rlang <- function(context, message) {
  rlang::abort(c(message, i = paste0("Context: ", context)))
}
