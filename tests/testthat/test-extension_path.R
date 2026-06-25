skip_on_cran()
skip_on_os(c("windows"))

test_that("duckdb extensions are stored under a per-session temporary directory", {
  con <- local_con(config = list('allow_unsigned_extensions' = 'true'))
  expected_dir <- default_extension_directory()
  err <- expect_error(dbExecute(con, "LOAD 'bogus'"))
  expect_true(grepl(expected_dir, conditionMessage(err), fixed = TRUE))
  expect_true(grepl(
    "bogus.duckdb_extension",
    conditionMessage(err),
    fixed = TRUE
  ))
  expect_true(grepl("not found", conditionMessage(err), fixed = TRUE))
})

test_that("the extension directory defaults to a temporary location", {
  expect_true(path_within_tempdir(resolve_extension_directory()))
})
