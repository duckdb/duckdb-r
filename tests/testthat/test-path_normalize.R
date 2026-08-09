# Make every `normalizePath(mustWork = TRUE)` call this package makes fail, the
# way one fails on a network drive whose directories the user cannot read, and
# leave every other caller — `loadNamespace()` among them — untouched.
local_unresolvable_paths <- function(frame = parent.frame()) {
  base_ns <- asNamespace("base")
  orig <- normalizePath
  pkg <- topenv(environment(path_normalize))

  shim <- function(path, winslash = "\\", mustWork = NA) {
    if (isTRUE(mustWork) && identical(topenv(parent.frame()), pkg)) {
      stop("path[1]: Access is denied")
    }
    orig(path, winslash = winslash, mustWork = mustWork)
  }

  withr::defer(
    {
      assign("normalizePath", orig, envir = base_ns)
      lockBinding("normalizePath", base_ns)
    },
    envir = frame
  )
  unlockBinding("normalizePath", base_ns)
  assign("normalizePath", shim, envir = base_ns)
}

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

test_that("a path that cannot be resolved still normalizes (#455)", {
  local_unresolvable_paths()

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
  expect_match(conditionMessage(err), "Cannot create database file", fixed = TRUE)
  expect_match(conditionMessage(err), path, fixed = TRUE)
})
