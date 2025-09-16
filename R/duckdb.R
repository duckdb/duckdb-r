# Internal error function for C++ layer
rapi_error <- function(context, message, error_type = NULL, raw_message = NULL, extra_info = NULL) {
  if (is.null(error_type) && is.null(raw_message) && is.null(extra_info)) {
    extra_text <- ""
  } else {
    extra_text <- paste0(
      " (",
      if (!is.null(error_type)) paste0("error_type: ", error_type, "; ") else "",
      if (!is.null(raw_message)) paste0("raw_message: ", raw_message, "; ") else "",
      if (!is.null(extra_info)) paste0(paste0(names(extra_info), ": ", extra_info, collapse = "; ")) else "",
      ")"
    )
  }

  stop(paste0(context, ": ", message, extra_text), call. = FALSE)
}

# rlang error function (will be conditionally replaced in .onLoad)
rapi_error_rlang <- function(context, message, error_type = NULL, raw_message = NULL, extra_info = NULL) {
  # Avoid initializing NULL fields
  fields <- list()
  fields$context <- context
  fields$error_type <- error_type
  fields$raw_message <- raw_message
  fields$extra_info <- extra_info

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
  if (length(extra_info) > 0) {
    info_text <- paste0(names(extra_info), ": ", extra_info)
    names(info_text) <- rep_len("i", length(info_text))
    error_parts <- c(error_parts, info_text)
  }

  rlang::abort(error_parts, class = "duckdb_error", !!!fields)
}
