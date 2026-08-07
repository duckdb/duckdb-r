# https://github.com/r-lib/testthat/issues/2236
skip_on_dev_version <- function() {
  version <- get_duckdb_version()
  if (!grepl("^[0-9]+[.][0-9]+[.][0-9]$", version)) {
    skip("Skip on development versions.")
  }
}

# Skip on every flavor but the mainline one.
#
# `scripts/flavor.sh` renames the package to a flavor -- `duckdb.1.4`,
# `duckdb.1.4.dev`, `duckdb.dev`, ... -- by applying `scripts/flavor.patch`; see
# BRANCHES.md. Tests that depend on another package hard-coding the mainline
# `duckdb` name -- arrow's DuckDB integration, for instance -- cannot work under
# any of them. The suffix is what tells the flavors apart: the mainline name has
# no dot in it, every renamed one does.
skip_on_flavor <- function() {
  if (grepl(".", get_package_name(), fixed = TRUE)) {
    skip("Skip on renamed flavors.")
  }
}

# Skip on CRAN, but run on R-universe
skip_on_cran_except_r_universe <- function() {
  if (!nzchar(Sys.getenv("MY_UNIVERSE"))) {
    skip_on_cran()
  }
}
