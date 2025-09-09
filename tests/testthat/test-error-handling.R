test_that("rapi_error functions accept additional parameters", {
  # Test that our updated function signatures work with default parameters
  expect_error(rapi_error("test_context", "test message"), "test_context: test message")
  
  # Test with additional parameters (should not cause different errors about function signature)
  expect_error(rapi_error("test_context", "test message", "PARSER"), "test_context: test message")
  expect_error(rapi_error("test_context", "test message", "PARSER", "raw message"), "test_context: test message") 
  expect_error(rapi_error("test_context", "test message", "PARSER", "raw message", list(key = "value")), "test_context: test message")
})