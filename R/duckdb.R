## usethis namespace: start
#' @useDynLib duckdb, .registration = TRUE
## usethis namespace: end
#' @name duckdb-package
#' @keywords internal
"_PACKAGE"
NULL

# Internal error function for C++ layer
rapi_error <- function(context, message, error_type = NULL, raw_message = NULL, extra_info = NULL) {
  stop(paste0(context, ": ", message), call. = FALSE)
}

# rlang error function (will be conditionally replaced in .onLoad)
rapi_error_rlang <- function(context, message, error_type = NULL, raw_message = NULL, extra_info = NULL) {
  # Create error message with context
  error_parts <- c(message, i = paste0("Context: ", context))
  
  # Add error type if available
  if (!is.null(error_type)) {
    error_parts <- c(error_parts, i = paste0("Error type: ", error_type))
  }
  
  # Add raw message if different from processed message
  if (!is.null(raw_message) && raw_message != message) {
    error_parts <- c(error_parts, i = paste0("Raw message: ", raw_message))
  }
  
  # Add extra info if available
  if (!is.null(extra_info) && length(extra_info) > 0) {
    info_text <- paste(names(extra_info), extra_info, sep = ": ", collapse = ", ")
    error_parts <- c(error_parts, i = paste0("Extra info: ", info_text))
  }
  
  rlang::abort(error_parts)
}
