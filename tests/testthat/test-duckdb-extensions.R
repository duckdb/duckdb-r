test_that("Install DuckDB extension", {
  skip_on_dev_version()
  skip_on_cran_except_r_universe()

  expect_no_error(sql_exec("INSTALL icu"))
})
