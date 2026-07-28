# How a database path becomes the key the driver cache is kept under.
# See handbook/usage/connections/README.md.

test_that("an in-memory database normalizes to itself", {
  expect_equal(path_normalize(""), ":memory:")
  expect_equal(path_normalize(":memory:"), ":memory:")
})

test_that("an existing database file normalizes to its resolved path", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")
  file.create(path)

  expect_same_path(path_normalize(path), normalizePath(path))
})

test_that("a database file yet to be created gets the key it will keep", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  before <- path_normalize(path)
  # Nothing is created to arrive at that answer.
  expect_false(file.exists(path))

  file.create(path)
  expect_equal(path_normalize(path), before)
})

test_that("a lower-case drive letter resolves on that drive, not in the working directory", {
  # The engine walks up to the drive and turns it into its root, and a bare
  # `c:` is the working directory on that drive rather than its root. Only a
  # Windows engine knows drive letters: elsewhere `c:` is a relative name.
  # patch/0043-Accept-a-lower-case-drive-letter-in-Windows-paths.patch
  skip_if_not(.Platform$OS.type == "windows", "drive letters are Windows-only")
  dir <- withr::local_tempdir()
  withr::local_dir(dir)
  drive <- substr(normalizePath(dir), 1, 1)
  missing <- basename(tempfile("no-such-directory-"))

  expect_equal(
    path_normalize(paste0(tolower(drive), ":/", missing, "/db.duckdb")),
    paste0(toupper(drive), ":\\", missing, "\\db.duckdb")
  )
})

test_that("a path that cannot be resolved is returned rather than refused (#455)", {
  # Resolving a path can fail for reasons that say nothing about whether the
  # database is usable (on a network drive, for a directory the user may
  # traverse but not list). A path that resolves no further is absolute and
  # usable, which is all the driver cache needs.
  path <- file.path(withr::local_tempdir(), "no-such-directory", "db.duckdb")

  expect_no_error(out <- path_normalize(path))
  expect_true(nzchar(out))
  expect_false(file.exists(path))
})

test_that("a relative path with no working directory fails as a `duckdb_error`", {
  # The one thing the engine throws on: a working directory removed from under
  # the session leaves a relative path nothing to resolve against.
  dir <- withr::local_tempdir()
  withr::local_dir(dir)
  unlink(dir, recursive = TRUE)
  # Windows refuses to remove a directory that is in use.
  skip_if(dir.exists(dir), "the working directory could not be removed")

  err <- expect_error(path_normalize("db.duckdb"), class = "duckdb_error")
  # Routed through the engine's error data, not its serialized form.
  expect_no_match(conditionMessage(err), "exception_type", fixed = TRUE)
})

test_that("a database in a directory that does not exist fails in `duckdb()`, naming the path", {
  # Normalizing no longer creates anything, so nothing fails there: the engine
  # refuses the open instead, and caches nothing.
  path <- file.path(withr::local_tempdir(), "no-such-directory", "db.duckdb")
  # Called from a function of its own, so that an error naming the caller of
  # `duckdb()` rather than `duckdb()` itself would show.
  open <- function() duckdb(dbdir = path)

  err <- expect_error(open(), "no-such-directory", fixed = TRUE)
  expect_identical(conditionCall(err)[[1]], quote(duckdb))
  # The engine's message as it reads, not its serialized form.
  expect_identical(err$error_type, "IO")
  expect_no_match(conditionMessage(err), "exception_type", fixed = TRUE)
  expect_null(driver_registry[[path_normalize(path)]])
})

test_that("a database in a directory that does not exist fails in `dbConnect()`, naming it", {
  # `dbConnect()` creates the instance for a `dbdir` of its own through `duckdb()`,
  # called under the name `dbConnect`, so the error names the user's call.
  path <- file.path(withr::local_tempdir(), "no-such-directory", "db.duckdb")
  open <- function() dbConnect(duckdb(), dbdir = path)

  err <- expect_error(open(), "no-such-directory", fixed = TRUE)
  expect_identical(conditionCall(err)[[1]], quote(dbConnect))
  expect_null(driver_registry[[path_normalize(path)]])
})
