# duckdb_storage_status() reports the resolved locations (read-only).

local_no_home_overrides <- function(.local_envir = parent.frame()) {
  withr::local_envvar(DUCKDB_R_HOME = NA, .local_envir = .local_envir)
  withr::local_options(duckdb.home = NULL, .local_envir = .local_envir)
}

test_that("duckdb_storage_status reports the per-session default", {
  local_no_home_overrides()
  local_mocked_bindings(
    session_temp_dir = function() "/tmp/sess",
    duckdb_shared_home = function() file.path(tempdir(), "no-such-shared-home")
  )
  st <- duckdb_storage_status()
  expect_s3_class(st, "data.frame")
  expect_named(st, c("kind", "source", "directory"))
  expect_equal(st$kind, c("extensions", "stored_secrets"))
  expect_equal(st$source, c("session", "session"))
  expect_equal(
    st$directory,
    c("/tmp/sess/duckdb/extensions", "/tmp/sess/duckdb/stored_secrets")
  )
})

test_that("duckdb_storage_status reports an option override", {
  local_no_home_overrides()
  withr::local_options(duckdb.home = "/opt/home")
  st <- duckdb_storage_status()
  expect_equal(st$source, c("option", "option"))
  expect_equal(
    st$directory,
    c("/opt/home/extensions", "/opt/home/stored_secrets")
  )
})

test_that("duckdb_storage_status reports an existing ~/.duckdb", {
  local_no_home_overrides()
  shared <- withr::local_tempdir()
  local_mocked_bindings(duckdb_shared_home = function() shared)
  st <- duckdb_storage_status()
  expect_equal(st$source, c("shared", "shared"))
  expect_equal(st$directory[[1]], file.path(shared, "extensions"))
})

test_that("duckdb_storage_status returns a visible frame with no side effects", {
  local_no_home_overrides()
  local_mocked_bindings(
    session_temp_dir = function() "/tmp/sess",
    duckdb_shared_home = function() file.path(tempdir(), "no-such-shared-home2")
  )
  result <- withVisible(duckdb_storage_status())
  expect_true(result$visible)
  expect_s3_class(result$value, "duckdb_storage_status")
})

test_that("duckdb_storage_status prints a readable summary", {
  local_no_home_overrides()
  local_mocked_bindings(
    session_temp_dir = function() "/tmp/sess",
    duckdb_shared_home = function() file.path(tempdir(), "snapshot-no-shared-home")
  )
  expect_snapshot(duckdb_storage_status())
})
