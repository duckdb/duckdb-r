# Covers the conditions in `helper-skip.R` that are a function of their input
# rather than of the build: which vendored versions count as a release, and
# which environments run the tests behind `TEST_RE2`. The other skip conditions
# ask about the running engine or the flavor, and a test can only assert what
# the run it is in happens to be.

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

  # An upstream alpha build is a release to the engine, which looks up its
  # extensions under the version.
  expect_true(is_release_version("2.0.0-alpha46057"))

  # Not three bare components at all.
  expect_false(is_release_version("1.5"))
  expect_false(is_release_version("1.5.5.9013"))
  expect_false(is_release_version("v1.5.5"))
  expect_false(is_release_version(""))
})

test_that("an engine gate holds until the version it names, and never on a release", {
  # Along one line of snapshots, by the counter and then by the three numbers.
  expect_true(engine_before("1.5.0-dev5296", "1.5.0-dev7500"))
  expect_false(engine_before("1.5.0-dev7500", "1.5.0-dev7500"))
  expect_true(engine_before("1.5.0-dev7500", "1.6.0-dev2046"))
  expect_false(engine_before("2.0.0-dev83856", "1.6.0-dev2046"))
  expect_true(engine_before("1.6.0-dev99", "1.6.0"))

  # A release, an upstream alpha build among them, is never gated.
  expect_false(engine_before("1.5.6", "2.0.0-dev1"))
  expect_false(engine_before("2.0.0-alpha46057", "2.0.0-dev90000"))

  # A gate that cannot be read lets its test run.
  expect_false(engine_before("1.5.0-dev5296", "soon"))
})

test_that("the tests behind `TEST_RE2` run everywhere but in the R-hub workflow", {
  withr::local_envvar(DUCKDB_R_TEST_RE2 = NA, GITHUB_WORKFLOW = NA)
  expect_true(test_re2_enabled())

  withr::local_envvar(GITHUB_WORKFLOW = "rcc")
  expect_true(test_re2_enabled())

  withr::local_envvar(GITHUB_WORKFLOW = "R-hub")
  expect_false(test_re2_enabled())

  # The variable wins both ways.
  withr::local_envvar(DUCKDB_R_TEST_RE2 = "true")
  expect_true(test_re2_enabled())
  withr::local_envvar(DUCKDB_R_TEST_RE2 = "off", GITHUB_WORKFLOW = "rcc")
  expect_false(test_re2_enabled())
})

test_that("the rcc workflow runs the tests behind `TEST_RE2`", {
  # A skip that no run lifts lets its tests rot (handbook/testing/suite/README.md).
  skip_if_not(identical(Sys.getenv("GITHUB_WORKFLOW"), "rcc"), "not rcc")
  expect_true(TEST_RE2)
})
