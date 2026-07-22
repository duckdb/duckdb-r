skip_on_cran()
skip_on_os(c("windows"))

test_that("duckdb extensions are stored in the resolved extension directory", {
  con <- local_con(config = list('allow_unsigned_extensions' = 'true'))
  expected_dir <- home_subdir(resolve_storage_home()$root, "extensions")
  err <- expect_error(dbExecute(con, "LOAD 'bogus'"))
  expect_true(grepl(expected_dir, conditionMessage(err), fixed = TRUE))
  expect_true(grepl(
    "bogus.duckdb_extension",
    conditionMessage(err),
    fixed = TRUE
  ))
  expect_true(grepl("not found", conditionMessage(err), fixed = TRUE))
})
