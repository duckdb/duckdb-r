skip_on_cran()
skip_on_os(c("windows"))

test_that("duckdb extensions are stored under the per-session temporary home", {
  con <- local_con(config = list('allow_unsigned_extensions' = 'true'))
  expected_dir <- default_duckdb_home()
  err <- expect_error(dbExecute(con, "LOAD 'bogus'"))
  expect_true(grepl(expected_dir, conditionMessage(err), fixed = TRUE))
  expect_true(grepl(
    "bogus.duckdb_extension",
    conditionMessage(err),
    fixed = TRUE
  ))
  expect_true(grepl("not found", conditionMessage(err), fixed = TRUE))
})

test_that("home directory defaults to a temporary location", {
  expect_true(path_within_tempdir(resolve_home_directory()))
})
