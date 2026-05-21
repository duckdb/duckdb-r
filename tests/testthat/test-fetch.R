test_that("dbFetch() can fetch RETURNING statements (#3875)", {
  con <- local_con()

  dbCreateTable(con, "x", list(a = "int"))

  expect_silent(out <- dbGetQuery(con, "INSERT INTO x VALUES (1) RETURNING (a)"))
  expect_equal(out, data.frame(a = 1L))
})

test_that("dbSendQuery defers execution until dbFetch", {
  con <- local_con()
  dbWriteTable(con, "mt", mtcars)

  rs <- dbSendQuery(con, "SELECT * FROM mt")
  expect_null(rs@env$resultset)
  expect_false(dbHasCompleted(rs))

  result <- dbFetch(rs, n = 10)
  expect_equal(nrow(result), 10)
  expect_false(dbHasCompleted(rs))

  result <- dbFetch(rs, n = -1)
  expect_equal(nrow(result), 22)
  expect_true(dbHasCompleted(rs))

  dbClearResult(rs)
})

test_that("dbBind defers execution until dbFetch", {
  con <- local_con()
  dbWriteTable(con, "mt", mtcars)

  rs <- dbSendQuery(con, "SELECT * FROM mt WHERE cyl = ?")
  expect_null(rs@env$resultset)

  dbBind(rs, list(6L))
  expect_null(rs@env$resultset)
  expect_false(dbHasCompleted(rs))

  result <- dbFetch(rs)
  expect_equal(nrow(result), 7)
  expect_true(dbHasCompleted(rs))

  # Re-bind with new params
  dbBind(rs, list(4L))
  expect_null(rs@env$resultset)
  expect_false(dbHasCompleted(rs))

  result <- dbFetch(rs)
  expect_equal(nrow(result), 11)
  expect_true(dbHasCompleted(rs))

  dbClearResult(rs)
})

test_that("dbGetRowsAffected returns 0 for deferred SELECT queries", {
  con <- local_con()
  dbWriteTable(con, "mt", mtcars)

  # No-param SELECT: deferred, not yet executed -> 0, not NA
  rs <- dbSendQuery(con, "SELECT * FROM mt")
  expect_identical(dbGetRowsAffected(rs), 0)
  dbFetch(rs)
  expect_identical(dbGetRowsAffected(rs), 0)
  dbClearResult(rs)

  # Parameterized SELECT before dbBind(): params required -> NA
  rs <- dbSendQuery(con, "SELECT * FROM mt WHERE cyl = ?")
  expect_identical(dbGetRowsAffected(rs), NA_integer_)

  # After dbBind() but before dbFetch(): execution is pending -> 0
  dbBind(rs, list(6L))
  expect_identical(dbGetRowsAffected(rs), 0)

  dbFetch(rs)
  expect_identical(dbGetRowsAffected(rs), 0)
  dbClearResult(rs)
})
