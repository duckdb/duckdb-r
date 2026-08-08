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

# "icu absent" is a build property, not a config one: a build that links
# icu statically (the fast path against a release libduckdb, like the CLI)
# has the TimeZone setting no matter what the extension directory holds,
# so absence-behavior tests cannot run there.
skip_if_builtin_icu <- function(con) {
  icu <- dbGetQuery(
    con,
    "SELECT loaded, install_mode FROM duckdb_extensions() WHERE extension_name = 'icu'"
  )
  if (nrow(icu) > 0 && (isTRUE(icu$loaded[[1]]) || identical(icu$install_mode[[1]], "STATICALLY_LINKED"))) {
    skip("icu is built into this binary")
  }
}

# The icu extension is not statically linked into the package,
# so tests that need it must download it first.
# That requires a released DuckDB version, a platform with published
# extension binaries, and a build that allows extensions at all --
# and is out of the question on CRAN.
# Same conditions as in tests/testthat/test-duckdb-extensions.R.
skip_if_no_icu <- function() {
  skip_on_dev_version()
  skip_on_cran_except_r_universe()
  skip_if_not(extensions_supported(), "DuckDB extensions disabled on this build (duckdb/duckdb-r#1107)")
  skip_if_not(extensions_published(), "No extension binaries published for this platform")
}
