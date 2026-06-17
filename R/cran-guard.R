# CRAN guard
#
# DuckDB ships its own large C++ engine. Running the test suite or the runnable
# examples exercises that engine, which is too heavy (in time and resource use)
# for CRAN's check farm. We therefore gate everything that touches the C++ code
# so that nothing heavy runs on CRAN, while it always runs on GitHub Actions
# (our own CI as well as r-universe, both powered by GitHub Actions).
#
# The behaviour is controlled by two environment variables:
#
# * `DUCKDB_R_RUN_TESTS` is an explicit opt-in (or opt-out) that always wins.
#   Set it to a true-ish value to run the tests and examples locally, or to a
#   false-ish value to force them off (used by the engine-poisoning CI entry).
# * Otherwise we fall back to `GITHUB_ACTIONS`, which GitHub Actions sets to
#   "true". This keeps the heavy code off on CRAN (where neither variable is
#   set) but on for every GitHub Actions run, including r-universe.
#
# This is intentional, not an oversight. The same logic is consulted, without
# relying on this file, directly in `tests/testthat.R`.

# Name of the environment variable that opts in to (or out of) running code
# that touches DuckDB's C++ engine.
DUCKDB_R_RUN_TESTS_ENVVAR <- "DUCKDB_R_RUN_TESTS"

# TRUE if code that touches DuckDB's C++ engine should run. An explicit
# DUCKDB_R_RUN_TESTS setting always wins; otherwise we run on GitHub Actions.
duckdb_run_tests_enabled <- function() {
  value <- tolower(trimws(Sys.getenv(DUCKDB_R_RUN_TESTS_ENVVAR, "")))
  if (value %in% c("true", "1", "yes", "on")) {
    return(TRUE)
  }
  if (value %in% c("false", "0", "no", "off")) {
    return(FALSE)
  }

  # No explicit opt-in/out: run automatically on GitHub Actions (this also
  # covers r-universe), stay off everywhere else (notably CRAN).
  tolower(trimws(Sys.getenv("GITHUB_ACTIONS", ""))) == "true"
}

# Used as the condition of `@examplesIf` for every runnable example that touches
# DuckDB's C++ engine. When the example is skipped it emits a verbose, actionable
# message so that it is obvious *why* nothing ran and how to opt in.
examples_enabled <- function() {
  if (duckdb_run_tests_enabled()) {
    return(TRUE)
  }

  message(
    "Skipping duckdb examples that exercise the bundled C++ engine.\n",
    "This is intentional: these examples are not run on CRAN to keep check ",
    "time and resource usage within CRAN's limits. They run automatically on ",
    "GitHub Actions (including r-universe).\n",
    "duckdb has an extensive test suite that runs continuously in our own CI; ",
    "see <https://github.com/duckdb/duckdb-r>.\n",
    "To run these examples, set ",
    DUCKDB_R_RUN_TESTS_ENVVAR,
    "=true, e.g. ",
    "Sys.setenv(",
    DUCKDB_R_RUN_TESTS_ENVVAR,
    " = \"true\")."
  )
  FALSE
}
