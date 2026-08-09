# The dbplyr backend refuses an argument DuckDB cannot express, rather than
# translating it into SQL that quietly means something else. dbplyr has
# `check_unsupported_arg()` for exactly that, but does not export it, and
# reaching into `dbplyr:::` would tie this package to a private API that any
# dbplyr release may move or rename.
#
# This is a base-only variant. The wording follows dbplyr's, so a message from
# this backend reads like the one the same argument produces on any other, but
# it is raised with `stop()` rather than `cli::cli_abort()` -- the cli
# formatting is all this package would gain from the dependency.

# `x` is accepted when it is missing, when it is `NULL` and `allow_null` is
# `TRUE`, or when it is identical to `allowed`; everything else is an error.
# `arg` names the argument in the message and defaults to the expression the
# caller passed, which is the caller's own argument name at every call site
# here.
check_unsupported_arg <- function(x,
                                  allowed = NULL,
                                  allow_null = FALSE,
                                  arg = deparse(substitute(x))) {
  if (missing(x)) {
    return(invisible())
  }
  if (allow_null && is.null(x)) {
    return(invisible())
  }
  if (identical(x, allowed)) {
    return(invisible())
  }

  if (is.null(allowed)) {
    # No value is supported, so there is nothing to point the caller at.
    msg <- paste0("Argument `", arg, "` isn't supported on database backends.")
  } else {
    detail <- if (allow_null) {
      paste0("It must be ", fmt_arg_value(allowed), " or `NULL` instead.")
    } else {
      paste0("It must be ", fmt_arg_value(allowed), " instead.")
    }
    msg <- paste0(
      "`", arg, " = ", fmt_arg_value(x), "` isn't supported on database backends.\n",
      detail
    )
  }

  stop(msg, call. = FALSE)
}

# Renders a value the way it would be written in R -- strings quoted, numbers
# bare -- on a single line, however long `deparse()` decides to wrap it.
fmt_arg_value <- function(x) {
  paste(deparse(x), collapse = " ")
}
