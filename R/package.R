get_package_name <- function() {
  utils::packageName()
}

get_package_env <- function() {
  asNamespace(get_package_name())
}

# `system_file_path()` (called with no `...`) is the mockable seam for the
# package's installed library directory; tests stub it instead of resolving the
# real install path.
system_file_path <- function(...) {
  file.path(system.file(package = get_package_name()), ...)
}

# Base fallback for `rlang::check_dots_empty0()`; in `.onLoad()` this is swapped
# for rlang's version when rlang is available (same strategy as `is_interactive`
# and `rapi_error`). Named to match the function it shadows.
check_dots_empty0 <- function(...) {
  if (...length() > 0L) {
    stop("`...` must be empty.", call. = FALSE)
  }
  invisible()
}

# Base fallback for `rlang::inform()`, swapped for rlang's version in `.onLoad()`
# when rlang is available (same strategy as `check_dots_empty0()`). Emits the
# message vector as a single base message; the `class` and other rlang-only
# arguments are accepted and ignored.
inform <- function(message = NULL, ..., class = NULL) {
  base::message(paste(message, collapse = "\n"))
  invisible()
}

get_package_spec <- function() {
  getNamespaceInfo(get_package_name(), "spec")
}

get_package_version <- function() {
  get_package_spec()[["version"]]
}
