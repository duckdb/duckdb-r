# https://github.com/r-lib/testthat/issues/2236
skip_on_dev_version <- function() {
  version <- get_duckdb_version()
  if (!grepl("^[0-9]+[.][0-9]+[.][0-9]$", version)) {
    skip("Skip on development versions.")
  }
}

# Skip on CRAN, but run on R-universe
skip_on_cran_except_r_universe <- function() {
  if (!nzchar(Sys.getenv("MY_UNIVERSE"))) {
    skip_on_cran()
  }
}
