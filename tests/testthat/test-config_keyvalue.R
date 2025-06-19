test_that("configuration key value pairs work as expected", {
  expect_error(duckdb(config = list("default_order" = c("a", "b"))))
})
