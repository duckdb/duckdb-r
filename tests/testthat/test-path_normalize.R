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

test_that("spellings of one database collapse to one key", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "db.duckdb")
  expected <- path_normalize(path)

  expect_equal(
    path_normalize(file.path(dir, "..", basename(dir), "db.duckdb")),
    expected
  )
  expect_equal(path_normalize(paste0(dir, "//db.duckdb")), expected)

  withr::local_dir(dir)
  expect_equal(path_normalize("db.duckdb"), expected)
})

test_that("a symlinked database resolves to its target", {
  dir <- withr::local_tempdir()
  target <- file.path(dir, "real.duckdb")
  file.create(target)
  link <- file.path(dir, "link.duckdb")
  skip_if_not(
    suppressWarnings(file.symlink(target, link)),
    "symlinks unavailable"
  )

  expect_equal(path_normalize(link), path_normalize(target))
})

test_that("a path that cannot be resolved is returned rather than refused (#455)", {
  # Resolving a path can fail for reasons that say nothing about whether the
  # database is usable -- on a network drive, for a directory the user may
  # traverse but not list. A path that resolves no further is absolute and
  # usable, which is all the driver cache needs.
  path <- file.path(withr::local_tempdir(), "no-such-directory", "db.duckdb")

  expect_no_error(out <- path_normalize(path))
  expect_true(nzchar(out))
  expect_false(file.exists(path))
})
