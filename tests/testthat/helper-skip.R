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
# release. `get_duckdb_version()` reports `X.Y.Z-devN` for a snapshot between
# releases, which has no published extension binaries and no released libduckdb
# to match; a tag and an upstream alpha build (`X.Y.Z-alphaN`) have both.
# https://github.com/r-lib/testthat/issues/2236
skip_on_dev_version <- function() {
  if (!is_release_version(get_duckdb_version())) {
    skip("Skip on development versions.")
  }
}

# Is this version string a release, rather than a snapshot between releases?
#
# Three numbers, optionally with a suffix that is not `-dev`: the engine draws
# the line in the same place (`VersioningUtils::IsReleaseVersion()`), and looks
# up extensions under the version for a release and under the commit for
# anything else. An alpha stamp is how a series build reaches the extensions
# upstream publishes (.claude/skills/series-alpha/SKILL.md).
# Every component is `[0-9]+` rather than a single digit: DuckDB has already
# shipped a two-digit component (`0.10.0`), and a patch release reaches two
# digits the same way -- which a single-digit pattern reads as a snapshot,
# skipping tests that should have run on a release.
# Covered by `test-helper-skip.R`, because nothing else here can be: the
# condition this feeds is a property of the build.
is_release_version <- function(version) {
  grepl(
    "^[0-9]+[.][0-9]+[.][0-9]+(-(?!dev)[a-z]+[0-9]*)?$",
    version,
    perl = TRUE
  )
}

# Skip while the vendored engine predates `version`, the engine that brings back
# what the test asks for.
#
# The gate a series puts on a test `main` has where its engine is older than the
# one the test was written against, at a rewind, instead of deleting or
# rewriting the test: it names where the test runs again, so the suite re-arms
# itself there without a restore that a replay could lose
# (handbook/operations/vendoring/series-loop/README.md). One line, inside the
# `test_that()` body, so `scripts/series-tests.sh` can read the version off it.
skip_if_engine_before <- function(version, why) {
  engine <- get_duckdb_version()
  if (engine_before(engine, version)) {
    skip(paste0("Engine ", engine, " predates ", version, ": ", why))
  }
}

# Does `engine` predate `version`?
#
# A development snapshot `X.Y.Z-devN` orders by its three numbers and then by its
# counter, which counts upstream commits, and precedes the release `X.Y.Z`. A
# release never predates anything: a rewind only reaches a snapshot, and `main`
# vendors a release. Nor does a string that is not a version, so a gate that
# cannot be read lets its test run rather than hiding it.
# `scripts/series-tests.sh` reads gates the same way.
engine_before <- function(engine, version) {
  parse <- function(x) {
    m <- regmatches(
      x,
      regexec("^([0-9]+[.][0-9]+[.][0-9]+)(-dev([0-9]+))?$", x)
    )[[1]]
    if (length(m) == 0) {
      return(NULL)
    }
    list(
      base = package_version(m[[2]]),
      dev = if (nzchar(m[[4]])) as.numeric(m[[4]]) else Inf
    )
  }
  e <- parse(engine)
  v <- parse(version)
  if (is.null(e) || is.null(v) || is.infinite(e$dev)) {
    return(FALSE)
  }
  if (e$base != v$base) {
    return(e$base < v$base)
  }
  e$dev < v$dev
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

# The fast path links upstream's release libduckdb instead of the vendored
# engine. It carries none of the engine patches in patch/, and on Linux it is
# built by a different compiler than the glue, so some tests cannot run there.
# A release libduckdb is the build that links icu statically, which the
# vendored engine never does (see skip_if_builtin_icu()).
skip_if_prebuilt_engine <- function(con, why) {
  icu <- dbGetQuery(
    con,
    "SELECT install_mode FROM duckdb_extensions() WHERE extension_name = 'icu'"
  )
  if (
    nrow(icu) > 0 &&
      identical(icu$install_mode[[1]], "STATICALLY_LINKED")
  ) {
    skip(paste0("prebuilt libduckdb: ", why))
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

# Whether to run the tests that reach DuckDB's re2: those that call
# `skip_if_not(TEST_RE2)`, and the `TEST_RE2` block of `test-DBItest.R`.
#
# On in every run but the R-hub workflow, whose CRAN check flavours re2 once
# tripped (https://github.com/duckdb/duckdb-r/issues/121).
# `DUCKDB_R_TEST_RE2` overrides that, read like `DUCKDB_R_RUN_TESTS`.
# Why it defaults to on is handbook/testing/suite/README.md's;
# covered by `test-helper-skip.R`.
test_re2_enabled <- function() {
  value <- tolower(trimws(Sys.getenv("DUCKDB_R_TEST_RE2", "")))
  if (value %in% c("true", "1", "yes", "on")) {
    return(TRUE)
  }
  if (value %in% c("false", "0", "no", "off")) {
    return(FALSE)
  }
  Sys.getenv("GITHUB_WORKFLOW") != "R-hub"
}

# A value rather than a call, because duckplyr generates `test-rel_api.R`
# with `skip_if_not(TEST_RE2)` in it.
TEST_RE2 <- test_re2_enabled()
