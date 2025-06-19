test_that("configuration key value pairs work as expected", {
  # setting nothing or empty list should work
  drv <- duckdb()
  duckdb_shutdown(drv)

  drv <- duckdb(config = list())
  duckdb_shutdown(drv)

  # but we should throw an error on non-existent options
  expect_error(duckdb(config = list(a = "a")))
})
