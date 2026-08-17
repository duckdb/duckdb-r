# Settings that bind when a database instance is created, and what happens when
# a later call asks for different ones. See handbook/usage/connections/README.md.

test_that("reusing an instance is silent when nothing collides", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  # Same settings again, and `bigint`, which `dbConnect()` does pick up.
  expect_no_error(duckdb(path))
  expect_no_error(duckdb(path, bigint = "integer64"))
  expect_no_error(dbDisconnect(dbConnect(drv)))
})

test_that("a `read_only` that the instance cannot honor is reported", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  # The engine's cache raises this, less specifically than the R-side check
  # it replaced -- it names neither the setting nor the way out. Tracked in
  # plan/PLAN-instance-cache.md.
  expect_error(duckdb(path, read_only = TRUE), "different configuration")
  # Refused, not applied: the writable instance is untouched and still usable.
  expect_no_error(dbExecute(con, "CREATE TABLE untouched AS SELECT 1"))
})

test_that("a `config` entry that the instance cannot honor is reported", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path, config = list(default_order = "DESC"))
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  # Repeating what the instance already has is not a collision.
  expect_no_error(duckdb(path, config = list(default_order = "DESC")))
  expect_error(
    duckdb(path, config = list(default_order = "ASC")),
    "different configuration"
  )
})

test_that("storage arguments are reported when the instance already exists", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  expect_error(duckdb(path, shared_home = FALSE), "different configuration")
})

test_that("a `dbdir` that overrides a file driver's own is reported", {
  dir <- withr::local_tempdir()
  own <- file.path(dir, "own.duckdb")
  other <- file.path(dir, "other.duckdb")

  drv <- duckdb(own)
  withr::defer(duckdb_shutdown(drv))

  expect_error(dbConnect(drv, other), "can't override")

  # Refused outright: no connection, and the driver still holds its own.
  expect_equal(drv@dbdir, normalizePath(own))
})

test_that("the in-memory driver idiom stays silent", {
  # `dbConnect(duckdb(), "my.db")` is documented and everywhere; the driver's
  # own database is a throwaway in-memory one, so nothing is displaced.
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  expect_no_error(con <- dbConnect(duckdb(), path))
  withr::defer(dbDisconnect(con, shutdown = TRUE))
})

test_that("a `dbdir` an extension answers is left alone", {
  # `md:` names a replacement open, not a file. The engine makes that
  # distinction itself, in `GetDBAbsolutePath()`, so the test is what a caller
  # sees: the path reaches the engine as spelled, and nothing local is created.
  #
  # Extensions off and storage kept out of `~/.duckdb`: with them on, the
  # engine installs the MotherDuck extension on demand -- 19 MB over the
  # network, into the user's shared home -- before failing.
  withr::local_dir(withr::local_tempdir())

  err <- expect_error(
    duckdb("md:mydb", allow_extensions = FALSE, shared_home = FALSE)
  )
  # The refusal names the extension, which is only reachable if the prefix
  # survived: a mangled path is a local file name and opens without error.
  expect_match(conditionMessage(err), "md", fixed = TRUE)
  expect_equal(list.files(all.files = TRUE, no.. = TRUE), character())
})
