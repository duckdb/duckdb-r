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

test_that("two spellings of one database share an instance", {
  # Not a reuse optimization: the engine does not refuse a second read-write
  # instance on a file this process already holds, and two of them diverge
  # silently. The registry is what prevents that, and it can only do so if the
  # key unifies the spellings. See handbook/usage/connections/README.md.
  dir <- withr::local_tempdir()
  path <- file.path(dir, "db.duckdb")

  drv1 <- duckdb(path)
  # `defer()` unwinds last-in-first-out, so every connection is closed before
  # the instance they belong to is shut down.
  withr::defer(duckdb_shutdown(drv1))
  con1 <- dbConnect(drv1)
  withr::defer(dbDisconnect(con1))
  dbWriteTable(con1, "x", data.frame(a = 1L))

  drv2 <- duckdb(file.path(dir, "..", basename(dir), "db.duckdb"))
  expect_identical(drv2@database_ref, drv1@database_ref)

  con2 <- dbConnect(drv2)
  withr::defer(dbDisconnect(con2))
  # A second instance would not see a write made through the first.
  expect_equal(dbReadTable(con2, "x"), data.frame(a = 1L))
})

test_that("a read-only request reuses the read-write instance it finds", {
  # Documented in `?duckdb`: `read_only` binds when the instance is created.
  # Pinned because dropping the registry in favour of the engine's cache would
  # change it -- the engine raises on a configuration mismatch instead
  # (duckdb/duckdb-r#2560).
  path <- file.path(withr::local_tempdir(), "db.duckdb")

  drv <- duckdb(path)
  withr::defer(duckdb_shutdown(drv))
  con <- dbConnect(drv)
  withr::defer(dbDisconnect(con))

  ro <- duckdb(path, read_only = TRUE)
  expect_identical(ro@database_ref, drv@database_ref)

  con_ro <- dbConnect(ro)
  withr::defer(dbDisconnect(con_ro))
  dbWriteTable(con, "x", data.frame(a = 1L))
  # Same instance, so a write through `con` is visible here.
  expect_equal(dbReadTable(con_ro, "x"), data.frame(a = 1L))
})
