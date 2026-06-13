# This file is part of the standard setup for testthat.
# It is recommended that you do not modify it.
#
# Where should you do additional test configuration?
# Learn more about the roles of various files in:
# * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
# * https://testthat.r-lib.org/articles/special-files.html

library(testthat)
library(duckdb)

# CRAN guard
#
# The duckdb test suite exercises DuckDB's bundled C++ engine, which is too heavy
# for CRAN's check farm, and checks were very fragile in the past. We therefore
# only run it when the DUCKDB_R_RUN_TESTS environment variable opts in.
# This check is intentionally inlined here (rather than calling into the package)
# so the guard is obvious and self-contained.
run_tests <- tolower(trimws(Sys.getenv("DUCKDB_R_RUN_TESTS", "")))

if (run_tests %in% c("true", "1", "yes", "on")) {
  test_check("duckdb")
} else {
  message(
    "\n",
    strrep("=", 78), "\n",
    "Skipping the duckdb test suite.\n",
    "\n",
    "The duckdb tests exercise DuckDB's bundled C++ engine and are deliberately\n",
    "NOT run unless the DUCKDB_R_RUN_TESTS environment variable is set. This keeps\n",
    "check time and resource usage on CRAN within acceptable limits and helps\n",
    "release duckdb in a predictable and controlled manner.\n",
    "\n",
    "This is intentional, not an oversight. duckdb has an extensive test suite\n",
    "that runs continuously in our own CI; see <https://github.com/duckdb/duckdb-r>.\n",
    "\n",
    "To run the test suite locally, set the environment variable before checking:\n",
    "  Sys.setenv(DUCKDB_R_RUN_TESTS = \"true\")    # from within R, or\n",
    "  DUCKDB_R_RUN_TESTS=true R CMD check ...      # from the shell\n",
    strrep("=", 78), "\n"
  )
}
