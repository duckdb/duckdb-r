# The structured fields a `duckdb_error` carries, documented in `?duckdb_error`.
# Both `rapi_error()` implementations below fill them from DuckDB's `ErrorData`.
# A field DuckDB did not supply is dropped rather than stored as `NULL`, so that
# `names()` on the condition says what is available.
duckdb_error_field_values <- function(
  context,
  error_type,
  raw_message,
  extra_info
) {
  fields <- list(
    context = context,
    error_type = error_type,
    raw_message = raw_message,
    extra_info = extra_info
  )
  fields[!vapply(fields, is.null, logical(1))]
}

# What `rethrow_error_from_rapi()` carries across the rethrow. Read off the
# builder above rather than spelled out a second time, so a field added there
# reaches the caller instead of being silently dropped on the way.
duckdb_error_fields <- names(formals(duckdb_error_field_values))

# Internal error function for C++ layer, base half of the pair below. Reachable
# under this name so that the no-rlang path can be tested with rlang installed;
# `rapi_error()` is what the glue calls, and `.onLoad()` points it at whichever
# half applies.
rapi_error_base <- function(
  context,
  message,
  error_type = NULL,
  raw_message = NULL,
  extra_info = NULL
) {
  # The extension INSTALL/LOAD guard throws with context "load_extension" and an
  # empty message; the text is centralized in R (extensions_disabled_error()).
  if (identical(context, "load_extension") && !any(nzchar(message))) {
    message <- paste(extensions_disabled_error(), collapse = " ")
  }

  # The exception type is short, bounded, and worth a reader's attention; the
  # rest of what the engine attached rides on the condition instead
  # (`?duckdb_error`), because `extra_info` can hold a resolved stack trace or a
  # list of candidate names that no error message wants inlined.
  if (is.null(error_type)) {
    extra_text <- ""
  } else {
    extra_text <- paste0(" (error_type: ", error_type, ")")
  }

  # A classed condition rather than `stop(<string>)`: without rlang the message
  # has no bullets, but the caller still gets `duckdb_error` and the fields.
  # `call = NULL` is what `call. = FALSE` does -- the message stands on its own.
  cond <- c(
    list(message = paste0(context, ": ", message, extra_text), call = NULL),
    duckdb_error_field_values(context, error_type, raw_message, extra_info)
  )
  class(cond) <- c("duckdb_error", "error", "condition")
  stop(cond)
}

# rlang error function (will be conditionally replaced in .onLoad)
rapi_error_rlang <- function(
  context,
  message,
  error_type = NULL,
  raw_message = NULL,
  extra_info = NULL
) {
  # The extension INSTALL/LOAD guard throws with context "load_extension" and an
  # empty message; the text is centralized in R (extensions_disabled_error()).
  if (identical(context, "load_extension") && !any(nzchar(message))) {
    message <- extensions_disabled_error()
  }

  fields <- duckdb_error_field_values(
    context,
    error_type,
    raw_message,
    extra_info
  )

  # Create error message with context
  error_parts <- c(message, i = paste0("Context: ", context))

  # Add error type if available
  if (!is.null(error_type)) {
    error_parts <- c(error_parts, i = paste0("Error type: ", error_type))
  }

  rlang::abort(error_parts, class = "duckdb_error", !!!fields)
}

# What the C++ glue looks up. `.onLoad()` swaps in `rapi_error_rlang()` where
# rlang is installed; without it the base half above stands.
rapi_error <- rapi_error_base
