test_that("configuration key value pairs work as expected", {
  # setting a configuration option to a non-string is an error
  expect_error(duckdb(config = list("default_order" = 42)))
})
