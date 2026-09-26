# Covers `helper-skip.R`'s one condition that is a function of a string rather
# than of the build: which vendored versions count as a release. The other skip
# conditions ask about the running engine, the flavor, or the environment, and
# a test can only assert what the run it is in happens to be.

test_that("a release version is told from a snapshot between releases", {
  expect_true(is_release_version("1.5.5"))
  expect_true(is_release_version("0.0.0"))

  # A component of two digits or more. `0.10.0` shipped; a patch release gets
  # there the same way, and a single-digit pattern read both as snapshots and
  # skipped tests that should have run.
  expect_true(is_release_version("0.10.2"))
  expect_true(is_release_version("1.5.10"))
  expect_true(is_release_version("10.0.0"))

  # A snapshot between releases, which is what the skip is for.
  expect_false(is_release_version("1.5.4-dev157"))

  # Not three bare components at all.
  expect_false(is_release_version("1.5"))
  expect_false(is_release_version("1.5.5.9013"))
  expect_false(is_release_version("v1.5.5"))
  expect_false(is_release_version(""))
})
