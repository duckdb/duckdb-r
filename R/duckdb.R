## usethis namespace: start
#' @useDynLib duckdb, .registration = TRUE
## usethis namespace: end
#' @name duckdb-package
#' @keywords internal
"_PACKAGE"
NULL

# Internal error function for C++ layer
rapi_error <- function(message) {
  stop(message, call. = FALSE)
}
