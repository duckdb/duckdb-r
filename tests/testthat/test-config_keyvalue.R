test_that("configuration key value pairs work as expected", {
  # setting nothing or empty list should work
  drv <- duckdb()
  duckdb_shutdown(drv)
})
