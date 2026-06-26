get_package_name <- function() {
  utils::packageName()
}

get_package_env <- function() {
  asNamespace(get_package_name())
}

# The duckdb package's installed library directory. A thin, mockable seam so
# the storage-location logic can be tested without resolving the real install
# path.
package_install_dir <- function() {
  system.file(package = get_package_name())
}

system_file_path <- function(...) {
  file.path(package_install_dir(), ...)
}

# Cache rlang's availability (looked up once per session) so the various places
# that fall back to base R when rlang is absent share a single check.
rlang_cache <- new.env(parent = emptyenv())

has_rlang <- function() {
  if (is.null(rlang_cache$available)) {
    rlang_cache$available <- requireNamespace("rlang", quietly = TRUE)
  }
  rlang_cache$available
}

# Home-grown `check_dots_empty()`: forward to rlang when available, otherwise a
# base fallback that errors if any `...` were passed.
check_dots_empty <- function(...) {
  if (has_rlang()) {
    rlang::check_dots_empty0(...)
  } else if (...length() > 0L) {
    stop("`...` must be empty.", call. = FALSE)
  }
  invisible()
}

get_package_spec <- function() {
  getNamespaceInfo(get_package_name(), "spec")
}

get_package_version <- function() {
  get_package_spec()[["version"]]
}
