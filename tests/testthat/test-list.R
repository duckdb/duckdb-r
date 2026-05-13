test_that("one-level lists can be read", {
  con <- local_con()

  res <- dbGetQuery(con, "SELECT [] a")$a
  expect_equal(res, list(integer(0)))

  res <- dbGetQuery(con, "SELECT [42] a")$a
  expect_equal(res, list(42))

  res <- dbGetQuery(con, "SELECT [NULL] a")$a
  expect_true(is.na(res[[1]]))

  res <- dbGetQuery(con, "SELECT [42] a UNION ALL SELECT NULL")$a
  expect_true(is.null(res[[2]]))

  res <- dbGetQuery(con, "SELECT [42, 43] a")$a
  expect_equal(res, list(c(42, 43)))

  res <- dbGetQuery(con, "SELECT [42] a union all select [43]")$a
  expect_equal(res, list(42, 43))

  res <- dbGetQuery(con, "SELECT [42, 43, 44] a union all select [45, 46]")$a
  expect_equal(res, list(c(42, 43, 44), c(45, 46)))

  res <- dbGetQuery(con, "SELECT ['Hello', 'World'] a union all select ['There']")$a
  expect_equal(res, list(c("Hello", "World"), c("There")))
})

test_that("rel_filter() handles LIST logical type", {
  skip_if_not(getRversion() >= "4.3.0")
  skip_if_not_installed("tibble")

  con <- local_con()

  df1 <- tibble::tibble(a = list(1, c(1,2)))

  rel1 <- rel_from_df(con, df1)
  rel2 <- rel_filter(rel1, list(expr_constant(TRUE)))

  df2 <- rel_to_altrep(rel2)
  expect_equal(df1$a, df2$a)
})
