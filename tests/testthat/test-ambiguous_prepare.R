test_that("Test ambiguous prepare statements", {
  con <- local_con()

  res <- dbGetQuery(con, "select ?", 42)
  expect_identical(res[[1]], 42)

  res <- dbGetQuery(con, "select ?", "hello world")
  expect_identical(res[[1]], "hello world")
})
