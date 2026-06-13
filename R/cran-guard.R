# CRAN guard
#
# DuckDB ships its own large C++ engine. Running the test suite or the runnable
# examples exercises that engine, which is too heavy (in time and resource use)
# for CRAN's check farm. We therefore gate everything that touches the C++ code
# behind the `DUCKDB_R_RUN_TESTS` environment variable: it is unset on CRAN (so
# nothing heavy runs) and set in our own continuous integration, where the full
# suite runs on every change (<https://github.com/duckdb/duckdb-r>).
#
# This is intentional, not an oversight. The same variable is consulted, without
# relying on this file, directly in `tests/testthat.R`.

# Name of the environment variable that opts in to running DuckDB's C++ code.
DUCKDB_R_RUN_TESTS_ENVVAR <- "DUCKDB_R_RUN_TESTS"

# TRUE if the user has opted in to running code that touches DuckDB's C++ engine.
duckdb_run_tests_enabled <- function() {
  value <- tolower(trimws(Sys.getenv(DUCKDB_R_RUN_TESTS_ENVVAR, "")))
  value %in% c("true", "1", "yes", "on")
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
    "time and resource usage within CRAN's limits.\n",
    "duckdb has an extensive test suite that runs continuously in our own CI; ",
    "see <https://github.com/duckdb/duckdb-r>.\n",
    "To run these examples, set ", DUCKDB_R_RUN_TESTS_ENVVAR, "=true, e.g. ",
    "Sys.setenv(", DUCKDB_R_RUN_TESTS_ENVVAR, " = \"true\")."
  )
  FALSE
}
