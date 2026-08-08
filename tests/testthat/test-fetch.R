test_that("dbFetch() can fetch RETURNING statements (#3875)", {
  con <- local_con()

  dbCreateTable(con, "x", list(a = "int"))

  expect_silent(out <- dbGetQuery(con, "INSERT INTO x VALUES (1) RETURNING (a)"))
  expect_equal(out, data.frame(a = 1L))
})

test_that("dbExecute() executes data-returning statements eagerly", {
  con <- local_con()

  # Parameter-less statements run at dbSendQuery() time, so dbExecute(),
  # which never fetches, must not lose their side effects
  dbExecute(con, "CREATE TABLE x (a INT)")
  expect_equal(dbExecute(con, "INSERT INTO x VALUES (1) RETURNING (a)"), 1)
  expect_equal(dbGetQuery(con, "SELECT count(*) AS n FROM x")$n, 1)

  dbExecute(con, "CREATE SEQUENCE s")
  dbExecute(con, "SELECT nextval('s')")
  expect_equal(dbGetQuery(con, "SELECT currval('s') AS v")$v, 1)
})

test_that("dbBind() + dbClearResult() without use does not execute", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE x (a INT)")

  # Documented limitation, per the DBI spec flows: execution happens at the
  # first use of the result, and a result that is never used never executes.
  # duckdb/duckdb-r#2565 and duckdb/duckdb-r#2583 will improve this.
  rs <- dbSendQuery(con, "INSERT INTO x VALUES (?)")
  dbBind(rs, list(1L))
  dbClearResult(rs)
  expect_equal(dbGetQuery(con, "SELECT count(*) AS n FROM x")$n, 0)
})

test_that("dbGetRowsAffected() executes a bound pending statement", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE x (a INT)")

  rs <- dbSendQuery(con, "INSERT INTO x VALUES (?) RETURNING (a)")
  dbBind(rs, list(1L))
  expect_equal(dbGetRowsAffected(rs), 1)
  dbClearResult(rs)
  expect_equal(dbGetQuery(con, "SELECT count(*) AS n FROM x")$n, 1)

  # dbExecute() with params goes through the same path
  expect_equal(dbExecute(con, "INSERT INTO x VALUES (?) RETURNING (a)", params = list(1L)), 1)
  expect_equal(dbGetQuery(con, "SELECT count(*) AS n FROM x")$n, 2)
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

test_that("dbGetRowsAffected returns 0 for SELECT queries", {
  con <- local_con()
  dbWriteTable(con, "mt", mtcars)

  # No-param SELECT: executed eagerly -> 0, not NA
  rs <- dbSendQuery(con, "SELECT * FROM mt")
  expect_identical(dbGetRowsAffected(rs), 0)
  dbFetch(rs)
  expect_identical(dbGetRowsAffected(rs), 0)
  dbClearResult(rs)

  # Parameterized SELECT before dbBind(): params required -> NA
  rs <- dbSendQuery(con, "SELECT * FROM mt WHERE cyl = ?")
  expect_identical(dbGetRowsAffected(rs), NA_integer_)

  # dbBind() defers execution; dbGetRowsAffected() runs the statement -> 0
  dbBind(rs, list(6L))
  expect_identical(dbGetRowsAffected(rs), 0)

  dbFetch(rs)
  expect_identical(dbGetRowsAffected(rs), 0)
  dbClearResult(rs)
})
