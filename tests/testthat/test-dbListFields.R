test_that("dbListFields() lists a table named by Id() as by its name", {
  con <- local_con()
  dbExecute(con, "CREATE SCHEMA s")
  dbExecute(con, "CREATE TABLE s.t (a INTEGER, b VARCHAR)")

  expect_equal(dbListFields(con, Id(schema = "s", table = "t")), c("a", "b"))
  expect_equal(
    dbListFields(con, Id(schema = "s", table = "t")),
    dbListFields(con, SQL("s.t"))
  )
})

test_that("dbListFields() lists a table named by Id() holding a type R cannot hold", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x BIT, y INTEGER)")

  expect_equal(dbListFields(con, Id(table = "t")), c("x", "y"))
  expect_equal(dbListFields(con, Id(schema = "main", table = "t")), c("x", "y"))
})

test_that("dbAppendTable() appends to a table named by Id() holding a type R cannot hold", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x BIT, y INTEGER)")

  expect_equal(dbAppendTable(con, Id(table = "t"), data.frame(y = 1:2)), 2L)

  res <- dbGetQuery(con, "SELECT x IS NULL AS n, y FROM t ORDER BY y")
  expect_equal(res, data.frame(n = c(TRUE, TRUE), y = 1:2))
})

test_that("dbListFields() fails on a missing table named by Id() as by its name", {
  con <- local_con()

  by_id <- expect_error(
    dbListFields(con, Id(table = "nope")),
    class = "duckdb_error"
  )
  by_name <- expect_error(dbListFields(con, "nope"), class = "duckdb_error")
  expect_identical(conditionMessage(by_id), conditionMessage(by_name))
})
