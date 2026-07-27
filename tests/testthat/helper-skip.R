# https://github.com/r-lib/testthat/issues/2236
skip_on_dev_version <- function() {
  version <- get_duckdb_version()
  if (!grepl("^[0-9]+[.][0-9]+[.][0-9]$", version)) {
    skip("Skip on development versions.")
  }
}

# Skip when running as one of the LTS builds.
#
# `scripts/lts.sh` renames the package to `duckdb.<version>` (e.g. `duckdb.1.3`)
# by applying `scripts/lts.patch`. Tests that depend on another package hard-coding
# the mainline `duckdb` name -- arrow's DuckDB integration, for instance -- cannot
# work there. The suffix is what tells the builds apart: the mainline name has no
# dot in it, every LTS name does.
skip_on_lts <- function() {
  if (grepl(".", get_package_name(), fixed = TRUE)) {
    skip("Skip on LTS builds.")
  }
}

# Skip on CRAN, but run on R-universe
skip_on_cran_except_r_universe <- function() {
  if (!nzchar(Sys.getenv("MY_UNIVERSE"))) {
    skip_on_cran()
  }
}
