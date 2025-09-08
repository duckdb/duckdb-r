test_that("dbFetch() can fetch RETURNING statements (#3875)", {
  con <- local_con()

  dbCreateTable(con, "x", list(a = "int"))

  expect_silent(out <- dbGetQuery(con, "INSERT INTO x VALUES (1) RETURNING (a)"))
  expect_equal(out, data.frame(a = 1L))
})
