# Behavior-neutral seams introduced for the storage-location policy
# (plan/PLAN-storage-locations.md). These tests pin the current behavior and
# confirm the seams are mockable without touching the real filesystem.

test_that("default_user_directory routes through the R_user_dir seam", {
  expect_equal(default_user_directory(), tools::R_user_dir("duckdb", "data"))
})

test_that("check_dots_empty rejects non-empty dots", {
  f <- function(x, ...) {
    check_dots_empty(...)
    x
  }
  expect_identical(f(1), 1)
  expect_error(f(1, 2))
})
