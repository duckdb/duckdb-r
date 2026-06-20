# Used as the condition of `@examplesIf` for the runnable examples that exercise
# DuckDB's bundled C++ engine. These examples are too heavy for CRAN's check
# farm, so they are skipped there: an explicit `DUCKDB_R_RUN_TESTS` setting
# always wins, otherwise they run automatically on GitHub Actions (our own CI as
# well as r-universe) and stay off everywhere else (notably CRAN).
examples_enabled <- function() {
  value <- tolower(trimws(Sys.getenv("DUCKDB_R_RUN_TESTS", "")))
  if (value %in% c("true", "1", "yes", "on")) {
    return(TRUE)
  }
  if (value %in% c("false", "0", "no", "off")) {
    return(FALSE)
  }

  github_actions <- tolower(trimws(Sys.getenv("GITHUB_ACTIONS", ""))) == "true"
  my_universe <- nzchar(trimws(Sys.getenv("MY_UNIVERSE", "")))
  github_actions || my_universe
}
