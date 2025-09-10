test_that("rapi_error functions accept additional parameters", {
  skip_if(getRversion() < "4.2", "Error message formatting differs in R 4.1")
  local_edition(3)
  rlang::local_options(cli.num_colors = 1)

  # Test that our updated function signatures work with default parameters
  expect_snapshot(error = TRUE, {
    rapi_error("test_context", "test message")
  })

  # Test with additional parameters (should not cause different errors about function signature)
  expect_snapshot(error = TRUE, {
    rapi_error("test_context", "test message", "PARSER")
  })
  expect_snapshot(error = TRUE, {
    rapi_error("test_context", "test message", "PARSER", "raw message")
  })
  expect_snapshot(error = TRUE, {
    rapi_error("test_context", "test message", "PARSER", "raw message", list(key = "value"))
  })
})
