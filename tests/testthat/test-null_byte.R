test_that("test null bytes in strings", {
  con <- local_con()
  expect_error(dbGetQuery(con, "SELECT chr(0)"))
})
