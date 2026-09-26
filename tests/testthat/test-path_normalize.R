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

test_that("a database file yet to be created normalizes like an existing one", {
  path <- file.path(withr::local_tempdir(), "db.duckdb")
  file.create(path)
  expected <- normalizePath(path)
  unlink(path)

  expect_same_path(path_normalize(path), expected)
  # The placeholder is gone again, so the engine creates the database itself.
  expect_false(file.exists(path))
})

test_that("a path that cannot be resolved is returned rather than refused (#455)", {
  # Resolving a path can fail for reasons that say nothing about whether the
  # database is usable. On Windows it walks every directory above the file and
  # needs to list each one, which a network share routinely refuses while still
  # letting the caller through. Nothing on a POSIX runner reproduces that --
  # resolving needs only search permission, which opening the file needs too --
  # so the failure is injected: every `normalizePath(mustWork = TRUE)` call made
  # from this package fails, and every other caller is left alone.
  pkg <- topenv(environment(path_normalize))
  base_ns <- asNamespace("base")
  orig <- normalizePath

  shim <- function(path, winslash = "\\", mustWork = NA) {
    if (isTRUE(mustWork) && identical(topenv(parent.frame()), pkg)) {
      abort("path[1]: Access is denied")
    }
    orig(path, winslash = winslash, mustWork = mustWork)
  }

  withr::defer({
    assign("normalizePath", orig, envir = base_ns)
    lockBinding("normalizePath", base_ns)
  })
  unlockBinding("normalizePath", base_ns)
  assign("normalizePath", shim, envir = base_ns)

  path <- file.path(withr::local_tempdir(), "db.duckdb")
  file.create(path)
  expected <- normalizePath(path)
  unlink(path)

  expect_same_path(path_normalize(path), expected)
  expect_false(file.exists(path))
})

test_that("a path that cannot be created fails, naming the path", {
  path <- file.path(withr::local_tempdir(), "no-such-directory", "db.duckdb")

  err <- expect_error(path_normalize(path))
  expect_match(
    conditionMessage(err),
    "Can't create the database file",
    fixed = TRUE
  )
  expect_match(conditionMessage(err), path, fixed = TRUE)
})
