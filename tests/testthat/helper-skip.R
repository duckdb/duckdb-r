# https://github.com/r-lib/testthat/issues/2236
skip_on_dev_version <- function() {
  version <- asNamespace(testing_package())[[".__NAMESPACE__."]][["spec"]][[
    "version"
  ]] |>
    package_version() |>
    unclass() |>
    getElement(1L)

  if (length(version) < 3 || tail(version, 1L) < 9000) {
    invisible()
  } else {
    skip("Skip on development versions.")
  }
}

# Skip on CRAN, but run on R-universe
skip_on_cran_except_r_universe <- function() {
  if (!nzchar(Sys.getenv("MY_UNIVERSE"))) {
    skip_on_cran()
  }
}
