test_that("rapi_error functions accept additional parameters", {
  local_edition(3)

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
