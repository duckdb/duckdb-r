test_that("progress display", {
  # Restore at end
  rlang::local_options(duckdb.progress_display = NULL)

  if (!is_interactive()) {
    options(duckdb.progress_display = NULL)
    expect_null(get_progress_display())
  }

  options(duckdb.progress_display = 5)
  expect_message(expect_null(get_progress_display()), "expecting either a boolean or function")

  options(duckdb.progress_display = function() {})
  expect_message(expect_null(get_progress_display()), "has no argument, expecting at least one")

  local_interactive()

  options(duckdb.progress_display = function(x) {})
  expect_type(get_progress_display(), "closure")

  options(duckdb.progress_display = TRUE)
  expect_identical(get_progress_display(), duckdb_progress_display)

  options(duckdb.progress_display = FALSE)
  expect_null(get_progress_display())

  # Default in interactive setting
  options(duckdb.progress_display = NULL)
  expect_identical(get_progress_display(), duckdb_progress_display)
})
