# `dbIsValid()` on a driver is a predicate: it reports whether the driver still
# holds a database instance, and opens nothing to find out.

test_that("a driver is valid for as long as it holds an instance", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  withr::defer(duckdb_shutdown(drv))
  expect_true(dbIsValid(drv))

  con <- dbConnect(drv)
  expect_true(dbIsValid(drv))

  # The last connection releases the instance, leaving the driver holding
  # nothing. See handbook/usage/connections/README.md.
  dbDisconnect(con)
  expect_false(dbIsValid(drv))
})

test_that("a driver that has been shut down is not valid", {
  drv <- duckdb()
  expect_true(dbIsValid(drv))

  duckdb_shutdown(drv)
  expect_false(dbIsValid(drv))
})

test_that("`dbIsValid()` does not reopen the database", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "db.duckdb")

  drv <- duckdb(path)
  con <- dbConnect(drv)
  dbDisconnect(con)
  unlink(path)

  # The implementation this replaces opened a connection to answer, which
  # reopened -- here, recreated -- the file the driver no longer held.
  expect_false(dbIsValid(drv))
  expect_false(file.exists(path))
})

test_that("`duckdb_shutdown()` is silent once the instance is gone", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  con <- dbConnect(drv)
  dbDisconnect(con)

  expect_silent(duckdb_shutdown(drv))
  expect_silent(duckdb_shutdown(drv))
})

test_that("`duckdb_shutdown()` leaves a newer driver for the same path cached", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  old <- duckdb(path)
  con <- dbConnect(old)
  dbDisconnect(con)

  # The instance `old` held is gone, so this call creates and caches a second
  # one. Shutting `old` down must not evict it: the next `duckdb()` call would
  # then open a third instance beside a live one, on the same file.
  new <- duckdb(path)
  withr::defer(duckdb_shutdown(new))

  duckdb_shutdown(old)
  expect_identical(duckdb(path)@database_ref, new@database_ref)
})
