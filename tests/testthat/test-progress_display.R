test_that("progress display", {

  expect_message(check_progress_display(5), "expecting either a boolean or function")
  expect_message(check_progress_display(function(){}), "has no argument, expecting at least one")

  expect_null(check_progress_display(function(x){}))
  expect_null(check_progress_display(TRUE))
  expect_null(check_progress_display(FALSE))
  expect_null(check_progress_display(NULL))

})
