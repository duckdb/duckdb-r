test_that("dbSendQueryArrow() returns a duckdb_result_arrow", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER, b VARCHAR)")
  dbExecute(con, "INSERT INTO t VALUES (1, 'x'), (2, 'y')")

  res <- dbSendQueryArrow(con, "SELECT a, b FROM t")
  on.exit(dbClearResult(res), add = TRUE)

  expect_s4_class(res, "duckdb_result_arrow")
  expect_true(dbIsValid(res))
  expect_equal(dbGetStatement(res), "SELECT a, b FROM t")
})

test_that("dbColumnInfo() works before fetching", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER, b VARCHAR)")

  res <- dbSendQueryArrow(con, "SELECT a, b FROM t")
  on.exit(dbClearResult(res), add = TRUE)

  info <- dbColumnInfo(res)
  expect_equal(info$name, c("a", "b"))
  expect_equal(info$type, c("integer", "character"))
})

test_that("dbHasCompleted() reports not-yet-completed before any fetch", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER)")
  dbExecute(con, "INSERT INTO t VALUES (1)")

  res <- dbSendQueryArrow(con, "SELECT a FROM t")
  on.exit(dbClearResult(res), add = TRUE)

  expect_false(dbHasCompleted(res))
})

test_that("dbClearResult() invalidates and rejects further use", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER)")

  res <- dbSendQueryArrow(con, "SELECT a FROM t")
  expect_true(dbIsValid(res))

  dbClearResult(res)
  expect_false(dbIsValid(res))
  expect_error(dbColumnInfo(res), "cleared")
  expect_error(dbGetStatement(res), "cleared")
  expect_warning(dbClearResult(res), "cleared already")
})

test_that("dbSendQueryArrow() does not materialize a large streaming query", {
  con <- local_con()

  # Should return promptly without allocating the full 1e7 rows
  start <- Sys.time()
  res <- dbSendQueryArrow(con, "SELECT * FROM range(10000000)")
  elapsed <- as.numeric(Sys.time() - start, units = "secs")
  on.exit(dbClearResult(res), add = TRUE)

  expect_lt(elapsed, 1)
  expect_true(dbIsValid(res))
})
