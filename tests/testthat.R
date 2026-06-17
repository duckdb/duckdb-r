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
# keep it off on CRAN but run it automatically on GitHub Actions (GITHUB_ACTIONS)
# and on r-universe (MY_UNIVERSE). An explicit DUCKDB_R_RUN_TESTS opts in
# (true-ish) or out (false-ish) and always wins; otherwise we fall back to those.
# This check is intentionally inlined here (rather than calling into the package)
# so the guard is obvious and self-contained.
run_tests <- tolower(trimws(Sys.getenv("DUCKDB_R_RUN_TESTS", "")))

if (run_tests %in% c("true", "1", "yes", "on")) {
  run <- TRUE
} else if (run_tests %in% c("false", "0", "no", "off")) {
  run <- FALSE
} else {
  run <- tolower(trimws(Sys.getenv("GITHUB_ACTIONS", ""))) == "true" ||
    nzchar(trimws(Sys.getenv("MY_UNIVERSE", "")))
}

if (run) {
  test_check("duckdb")
} else {
  message(
    "\n",
    strrep("=", 78),
    "\n",
    "Skipping the duckdb test suite.\n",
    "\n",
    "The duckdb tests exercise DuckDB's bundled C++ engine and are deliberately\n",
    "NOT run on CRAN. They run automatically on GitHub Actions (including\n",
    "r-universe). This keeps check time and resource usage on CRAN within\n",
    "acceptable limits and helps release duckdb in a predictable and controlled\n",
    "manner.\n",
    "\n",
    "This is intentional, not an oversight. duckdb has an extensive test suite\n",
    "that runs continuously in our own CI; see <https://github.com/duckdb/duckdb-r>.\n",
    "\n",
    "To run the test suite locally, set the environment variable before checking:\n",
    "  Sys.setenv(DUCKDB_R_RUN_TESTS = \"true\")    # from within R, or\n",
    "  DUCKDB_R_RUN_TESTS=true R CMD check ...      # from the shell\n",
    strrep("=", 78),
    "\n"
  )
}
