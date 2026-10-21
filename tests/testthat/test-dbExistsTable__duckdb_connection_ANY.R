test_that("a new table can be written inside a transaction (#2892)", {
  con <- local_con()

  dbBegin(con)
  dbWriteTable(con, "x", data.frame(a = 1))
  dbWriteTable(con, "x", data.frame(a = 2), append = TRUE)
  dbCommit(con)

  expect_identical(dbReadTable(con, "x"), data.frame(a = c(1, 2)))
})

test_that("asking for a missing table leaves the transaction usable", {
  con <- local_con()

  dbBegin(con)
  dbExecute(con, "CREATE TABLE created AS SELECT 1 AS a")
  expect_false(dbExistsTable(con, "nope"))
  expect_true(dbExistsTable(con, "created"))
  dbCommit(con)

  expect_true(dbExistsTable(con, "created"))
})

test_that("asking leaves the transaction's own policy as it found it", {
  con <- local_con()

  # Whether a misspelt table name aborts the transaction is the engine's
  # policy, DuckDB 1.x and 2.0 differ, and asking must not change it.
  aborts <- function(ask) {
    dbBegin(con)
    on.exit(dbRollback(con))
    if (ask) {
      dbExistsTable(con, "nope")
    }
    try(dbGetQuery(con, "SELECT * FROM nope"), silent = TRUE)
    inherits(try(dbGetQuery(con, "SELECT 1"), silent = TRUE), "try-error")
  }
  expect_identical(aborts(ask = TRUE), aborts(ask = FALSE))
})

test_that("an aborted transaction is an error, not a missing table", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1))

  dbBegin(con)
  on.exit(dbRollback(con))
  try(dbGetQuery(con, "SELECT 'x'::INTEGER"), silent = TRUE)

  expect_error(dbExistsTable(con, "t"), "aborted")
})

test_that("asking keeps a policy the transaction was given", {
  # DuckDB 1.x has no policy to give; once main vendors 2.0, the skip goes
  # (https://github.com/duckdb/duckdb-r/issues/2895).
  skip_if(numeric_version(sub("-.*", "", get_duckdb_version())) < "2.0.0")
  con <- local_con()

  dbBegin(con)
  on.exit(dbRollback(con))
  dbExecute(
    con,
    "SET current_transaction_invalidation_policy = 'SYNTACTIC_ERRORS_DO_NOT_INVALIDATE'"
  )
  expect_false(dbExistsTable(con, "nope"))

  # Under that policy, a misspelt table name leaves the transaction usable.
  expect_error(dbGetQuery(con, "SELECT * FROM nope"), "nope")
  expect_identical(dbGetQuery(con, "SELECT 1 AS a"), data.frame(a = 1L))
})

test_that("a locked configuration does not keep the policy from relaxing", {
  con <- local_con(drv = duckdb(config = list(lock_configuration = "true")))
  dbWriteTable(con, "t", data.frame(a = 1))

  dbBegin(con)
  on.exit(dbRollback(con))

  expect_true(dbExistsTable(con, "t"))
  expect_false(dbExistsTable(con, "nope"))
  expect_identical(dbReadTable(con, "t"), data.frame(a = 1))
})
