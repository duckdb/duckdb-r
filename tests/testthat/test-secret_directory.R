# Secrets resolution (plan/PLAN-storage-locations.md, Phase 1).

test_that("resolve_secret_directory honors the option override", {
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = NA)
  withr::local_options(duckdb.secret_directory = "/opt/sec")
  expect_equal(
    resolve_secret_directory(),
    list(directory = "/opt/sec", source = "option")
  )
})

test_that("resolve_secret_directory honors the env-var override", {
  withr::local_options(duckdb.secret_directory = NULL)
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = "/env/sec")
  expect_equal(
    resolve_secret_directory(),
    list(directory = "/env/sec", source = "env")
  )
})

test_that("resolve_secret_directory defaults to a session tempdir, not R_user_dir", {
  user <- withr::local_tempdir()
  shared <- withr::local_tempdir()
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = NA)
  withr::local_options(duckdb.secret_directory = NULL)
  local_mocked_bindings(
    default_user_directory = function() user,
    duckdb_shared_home = function() shared,
    session_temp_dir = function() "/tmp/sess"
  )
  expect_equal(
    resolve_secret_directory(),
    list(directory = "/tmp/sess/duckdb/stored_secrets", source = "session")
  )
})

test_that("resolve_secret_directory uses a marked root over the default", {
  user <- withr::local_tempdir()
  shared <- withr::local_tempdir()
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = NA)
  withr::local_options(duckdb.secret_directory = NULL)
  local_mocked_bindings(
    default_user_directory = function() user,
    duckdb_shared_home = function() shared
  )
  write_keep_marker(storage_dir("shared", "stored_secrets"))
  resolved <- resolve_secret_directory()
  expect_equal(
    normalizePath(resolved$directory),
    normalizePath(file.path(shared, "stored_secrets"))
  )
  expect_equal(resolved$source, "marker")
})
