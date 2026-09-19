test_that("path normalization stays non-strict after creating a missing file", {
  normalize_must_work <- logical()
  normalize_path <- function(path, mustWork) {
    normalize_must_work <<- c(normalize_must_work, mustWork)
    path
  }

  path <- tempfile(fileext = ".duckdb")
  expect_identical(path_normalize(path, normalize_path), path)
  expect_identical(normalize_must_work, c(FALSE, FALSE))
  expect_false(file.exists(path))
})
