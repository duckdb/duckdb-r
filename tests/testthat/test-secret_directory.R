# Secrets share the resolved home root with extensions (see ?duckdb_storage).

test_that("the secret store follows the home option", {
  withr::local_envvar(DUCKDB_R_HOME = NA)
  withr::local_options(duckdb.home = "/opt/home")
  expect_equal(
    home_subdir(resolve_storage_home()$root, "stored_secrets"),
    "/opt/home/stored_secrets"
  )
})

test_that("the secret store follows the DUCKDB_R_HOME environment variable", {
  withr::local_options(duckdb.home = NULL)
  withr::local_envvar(DUCKDB_R_HOME = "/env/home")
  expect_equal(
    home_subdir(resolve_storage_home()$root, "stored_secrets"),
    "/env/home/stored_secrets"
  )
})

test_that("the secret store defaults under the session tempdir", {
  withr::local_envvar(DUCKDB_R_HOME = NA)
  withr::local_options(duckdb.home = NULL, rlang_interactive = FALSE)
  local_mocked_bindings(
    duckdb_shared_home = function() file.path(tempdir(), "no-such-home-sec"),
    session_temp_dir = function() "/tmp/sess"
  )
  expect_equal(
    home_subdir(resolve_storage_home()$root, "stored_secrets"),
    "/tmp/sess/duckdb/stored_secrets"
  )
})
