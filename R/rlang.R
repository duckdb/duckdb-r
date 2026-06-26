# Base fallbacks for the handful of rlang functions the package uses. rlang is a
# soft dependency: each fallback below is swapped for the real rlang function in
# `.onLoad()` when rlang is available (see zzz.R), and named to match it.

# `rlang::is_interactive()`.
is_interactive <- function() {
  opt <- getOption("rlang_interactive")
  if (!is.null(opt)) {
    return(isTRUE(opt))
  }
  if (isTRUE(getOption("knitr.in.progress"))) {
    return(FALSE)
  }
  if (identical(Sys.getenv("TESTTHAT"), "true")) {
    return(FALSE)
  }
  interactive()
}

# `rlang::check_dots_empty0()`.
check_dots_empty0 <- function(...) {
  if (...length() > 0L) {
    stop("`...` must be empty.", call. = FALSE)
  }
  invisible()
}

# `rlang::inform()`. Emits the message vector as a single base message; the
# `class` and other rlang-only arguments are accepted and ignored.
inform <- function(message = NULL, ..., class = NULL) {
  base::message(paste(message, collapse = "\n"))
  invisible()
}

# `rlang::arg_match()`. With `values` unset the allowed values are taken from the
# calling function's formal default for `arg` (as `rlang::arg_match()` and
# `match.arg()` do), so an unmodified `arg` resolves to its first value.
arg_match <- function(arg, values = NULL, ...) {
  if (is.null(values)) {
    parent <- sys.parent()
    values <- eval(
      formals(sys.function(parent))[[as.character(substitute(arg))]],
      envir = sys.frame(parent)
    )
  }
  match.arg(arg, values)
}
