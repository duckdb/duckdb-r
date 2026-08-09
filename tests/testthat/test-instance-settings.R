# Settings that bind when a database instance is created, and what happens when
# a later call asks for different ones. See handbook/usage/connections/README.md.

test_that("reusing an instance is silent when nothing collides", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  # Same settings again, and `bigint`, which `dbConnect()` does pick up.
  expect_no_warning(duckdb(path))
  expect_no_warning(duckdb(path, bigint = "integer64"))
  expect_no_warning(dbDisconnect(dbConnect(drv)))
})

test_that("a `read_only` that the instance cannot honor is reported", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  expect_warning(ro <- duckdb(path, read_only = TRUE), "read_only")
  # The setting is dropped, not applied: the instance is still the writable one.
  expect_identical(ro@database_ref, drv@database_ref)
})

test_that("a `config` entry that the instance cannot honor is reported", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path, config = list(default_order = "DESC"))
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  # Repeating what the instance already has is not a collision.
  expect_no_warning(duckdb(path, config = list(default_order = "DESC")))
  expect_warning(
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

  expect_warning(duckdb(path, shared_home = FALSE), "shared_home")
})

test_that("a `dbdir` that overrides a file driver's own is reported", {
  dir <- withr::local_tempdir()
  own <- file.path(dir, "own.duckdb")
  other <- file.path(dir, "other.duckdb")

  drv <- duckdb(own)
  withr::defer(duckdb_shutdown(drv))

  expect_warning(con <- dbConnect(drv, other), "overrides the database file")
  withr::defer(dbDisconnect(con))

  # The warning is about a real substitution: the connection is on `other`.
  expect_equal(dbGetInfo(con)$dbname, path_normalize(other))
})

test_that("the in-memory driver idiom stays silent", {
  # `dbConnect(duckdb(), "my.db")` is documented and everywhere; the driver's
  # own database is a throwaway in-memory one, so nothing is displaced.
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  expect_no_warning(con <- dbConnect(duckdb(), path))
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
