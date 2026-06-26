# Behavior-neutral seams introduced for the storage-location policy
# (plan/PLAN-storage-locations.md). These tests pin the current behavior and
# confirm the seams are mockable without touching the real filesystem.

test_that("default_extension_directory routes through the system_file_path seam", {
  expect_equal(default_extension_directory(), system_file_path("extensions"))

  local_mocked_bindings(system_file_path = function(...) file.path("/pkg", ...))
  expect_equal(default_extension_directory(), file.path("/pkg", "extensions"))
})

test_that("default_secret_directory routes through the R_user_dir seam", {
  local_mocked_bindings(default_user_directory = function() "/userdir")
  expect_equal(
    default_secret_directory(),
    file.path("/userdir", "stored_secrets")
  )
})

test_that("common_secret_directory routes through the shared-home seam", {
  local_mocked_bindings(duckdb_shared_home = function() "/home/.duckdb")
  expect_equal(
    common_secret_directory(),
    file.path("/home/.duckdb", "stored_secrets")
  )
})

test_that("check_dots_empty0 rejects non-empty dots", {
  f <- function(x, ...) {
    check_dots_empty0(...)
    x
  }
  expect_identical(f(1), 1)
  expect_error(f(1, 2))
})
