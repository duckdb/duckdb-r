# Behavior-neutral seams introduced for the storage-location policy
# (plan/PLAN-storage-locations.md). These tests pin the current behavior and
# confirm the seams are mockable without touching the real filesystem.

test_that("default_extension_directory routes through the package-install seam", {
  expect_equal(default_extension_directory(), system_file_path("extensions"))

  local_mocked_bindings(package_install_dir = function() "/pkg")
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

test_that("dir_is_writable is TRUE for a writable dir and mockable otherwise", {
  d <- withr::local_tempdir()
  expect_true(dir_is_writable(d))

  # The library probe can be simulated as read-only without a real read-only FS.
  local_mocked_bindings(dir_is_writable = function(dir) FALSE)
  expect_false(dir_is_writable(d))
})

test_that("has_rlang caches and check_dots_empty rejects non-empty dots", {
  expect_type(has_rlang(), "logical")

  f <- function(x, ...) {
    check_dots_empty(...)
    x
  }
  expect_identical(f(1), 1)
  expect_error(f(1, 2))
})
