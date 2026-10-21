# Settings that bind when a database instance is created, and what happens when
# a later call asks for different ones. See handbook/usage/connections/README.md.

test_that("reusing an instance is silent when nothing collides", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  # Same settings again.
  expect_no_error(duckdb(path))
  expect_no_error(dbDisconnect(dbConnect(drv)))
})

test_that("a differing `bigint` is not a collision", {
  # `bigint` is a connection setting that `dbConnect()` picks up, not one the
  # instance binds -- so asking for another one is not a collision. Its own case
  # because `bigint = "integer64"` needs bit64, and the rest of the file does
  # not (handbook/operations/ci/matrix/README.md).
  skip_if_not_installed("bit64")

  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  expect_no_error(duckdb(path, bigint = "integer64"))
})

test_that("a `read_only` that the instance cannot honor is reported", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  expect_error(duckdb(path, read_only = TRUE), "read_only")
  # Refused, not applied: the writable instance is untouched and still reachable.
  expect_identical(duckdb(path)@database_ref, drv@database_ref)
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
    "config$default_order",
    fixed = TRUE
  )
})

test_that("storage arguments are reported when the instance already exists", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  expect_error(duckdb(path, shared_home = FALSE), "shared_home")
})

test_that("a `dbdir` that overrides a file driver's own is reported", {
  dir <- withr::local_tempdir()
  own <- file.path(dir, "own.duckdb")
  other <- file.path(dir, "other.duckdb")

  drv <- duckdb(own)
  withr::defer(duckdb_shutdown(drv))

  expect_error(dbConnect(drv, other), "can't override")

  # Refused outright: no connection, and the driver still holds its own.
  expect_equal(drv@dbdir, path_normalize(own))
})

test_that("the in-memory driver idiom stays silent", {
  # `dbConnect(duckdb(), "my.db")` is documented and everywhere; the driver's
  # own database is a throwaway in-memory one, so nothing is displaced.
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  expect_no_error(con <- dbConnect(duckdb(), path))
  withr::defer(dbDisconnect(con, shutdown = TRUE))
})

test_that("a `dbdir` an extension answers is left alone", {
  # `md:` is MotherDuck's entry point; normalizing it would hand the engine a
  # local file name instead. No connection is opened -- the extension is not
  # installed here -- only the path handling is under test.
  expect_equal(path_normalize("md:mydb"), "md:mydb")
  expect_equal(path_normalize("ducklake:metadata.db"), "ducklake:metadata.db")

  # A URL scheme is not an extension prefix, and neither is a Windows drive.
  expect_false(has_extension_prefix("s3://bucket/db.duckdb"))
  expect_false(has_extension_prefix("C:/db.duckdb"))
  expect_false(has_extension_prefix("/tmp/db.duckdb"))
  expect_true(has_extension_prefix("md:"))

  # Nothing is created for a prefixed `dbdir`.
  withr::local_dir(withr::local_tempdir())
  path_normalize("md:mydb")
  expect_equal(list.files(all.files = TRUE, no.. = TRUE), character())
})
