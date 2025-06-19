test_that("configuration key value pairs work as expected", {
  # setting a configuration option to an unrecognized value
  expect_error(duckdb(config = list("default_order" = "asdf")))
})
