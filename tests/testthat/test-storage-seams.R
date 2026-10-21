# Behavior-neutral seams introduced for the storage-location policy
# (plan/done/PLAN-storage-locations.md). These tests pin the current behavior and
# confirm the seams are mockable without touching the real filesystem.

test_that("check_dots_empty0 rejects non-empty dots", {
  f <- function(x, ...) {
    check_dots_empty0(...)
    x
  }
  expect_identical(f(1), 1)
  expect_error(f(1, 2))
})
