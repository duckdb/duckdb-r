test_that("configuration key value pairs work as expected", {
  # but we should throw an error on non-existent options
  expect_error(duckdb(config = list(a = "a")))
})
