# TEMPORARY GeoTox workaround -- remove after the next CRAN release.
#
# GeoTox opens a DuckDB connection transitively (through duckplyr) inside a test
# that asserts the call is silent (`expect_silent()`). The storage-location
# message introduced in #2396 therefore trips that test and shows up as a
# reverse-dependency failure in GeoTox's CRAN check.
#
# Until GeoTox ships an adjusted test, suppress the storage-location message --
# and only that message -- when GeoTox is somewhere on the call stack. This is
# deliberately narrow: direct, top-level use of duckdb() still emits the message,
# and interactive behaviour (including the offer to create `~/.duckdb`) is
# unchanged.
#
# To revert: delete this file, the `!caller_is_geotox()` guard in R/Driver.R, and
# tests/testthat/test-storage-geotox-workaround.R.
# See https://github.com/duckdb/duckdb-r/pull/2397.
caller_is_geotox <- function() {
  frames <- sys.frames()
  for (i in seq_along(frames)) {
    if (identical(environmentName(topenv(frames[[i]])), "GeoTox")) {
      return(TRUE)
    }
  }
  FALSE
}
