# Borrowed from rlang
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

local_interactive <- function(value = TRUE, frame = rlang::caller_env()) {
  rlang::local_options(rlang_interactive = value, .frame = frame)
}
