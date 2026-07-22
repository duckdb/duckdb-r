# TEMPORARY: tests for the GeoTox reverse-dependency workaround
# (R/storage-geotox-workaround.R). Remove together with the workaround.

# Build an environment that topenv() treats as the named namespace, without
# needing the package installed.
fake_namespace <- function(name) {
  ns <- new.env()
  info <- new.env()
  info$spec <- c(name = name, version = "0.0.0")
  assign(".__NAMESPACE__.", info, envir = ns)
  ns
}

test_that("caller_is_geotox detects GeoTox on the call stack, else FALSE", {
  # Nothing GeoTox-related on the stack.
  expect_false(caller_is_geotox())

  # A function living in (a stand-in for) the GeoTox namespace, calling down.
  from_geotox <- function() caller_is_geotox()
  environment(from_geotox) <- fake_namespace("GeoTox")
  expect_true(from_geotox())

  # A different package on the stack must not trigger it.
  from_other <- function() caller_is_geotox()
  environment(from_other) <- fake_namespace("someOtherPkg")
  expect_false(from_other())
})
