# The skip conditions this suite shares, each named for what it skips on.
#
# A test that cannot run everywhere is skipped on a property of what it is
# running against -- a development snapshot of the engine, a renamed flavor,
# CRAN, a build with icu linked in -- and the same property is asked about from
# several test files. The reasoning for each lives here, so a call site is one
# line that says which condition it is subject to and nothing more.
#
# A condition that a test could assert on instead is not one of these: where
# DuckDB publishes no extension binaries the suite asserts the download error
# rather than skipping, so the day the gap closes it is the assertion that
# fails (handbook/testing/suite/README.md).

# Skip where the vendored engine is a development snapshot rather than a
# release. `get_duckdb_version()` reports a bare three-component version only at
# a tag; anything else is a snapshot between releases, which has no published
# extension binaries and no released libduckdb to match.
# https://github.com/r-lib/testthat/issues/2236
skip_on_dev_version <- function() {
  if (!is_release_version(get_duckdb_version())) {
    skip("Skip on development versions.")
  }
}

# Is this version string a release, rather than a snapshot between releases?
#
# Three numbers and nothing else. Every component is `[0-9]+` rather than a
# single digit: DuckDB has already shipped a two-digit component (`0.10.0`), and
# a patch release reaches two digits the same way -- which a single-digit
# pattern reads as a snapshot, skipping tests that should have run on a release.
# Covered by `test-helper-skip.R`, because nothing else here can be: the
# condition this feeds is a property of the build.
is_release_version <- function(version) {
  grepl("^[0-9]+[.][0-9]+[.][0-9]+$", version)
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
  if (
    nrow(icu) > 0 &&
      (isTRUE(icu$loaded[[1]]) ||
        identical(icu$install_mode[[1]], "STATICALLY_LINKED"))
  ) {
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
  skip_if_not(
    extensions_supported(),
    "DuckDB extensions disabled on this build (duckdb/duckdb-r#1107)"
  )
  skip_if_not(
    extensions_published(),
    "No extension binaries published for this platform"
  )
}
