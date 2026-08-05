test_that("Install DuckDB extension", {
  skip_on_dev_version()
  skip_on_cran_except_r_universe()
  # Disabled on a libc++ Linux build (loading a prebuilt extension crashes R --
  # duckdb/duckdb-r#1107); INSTALL is refused there by design.
  skip_if_not(extensions_supported(), "DuckDB extensions disabled on this build (duckdb/duckdb-r#1107)")
  # Nothing to install where DuckDB publishes no binaries for this platform;
  # the test below is what covers those.
  skip_if_no_extension_binaries()

  if (extensions_published()) {
    expect_no_error(sql_exec("INSTALL icu"))
  } else {
    # A canary, not a skip (duckdb/duckdb-r#2425):
    # the extension repository has no directory for this platform,
    # so the download must come back an HTTP error.
    # The day DuckDB starts publishing for this platform,
    # this expectation is what fails,
    # and the platform moves to the branch above
    # by deleting its exception in extensions_published().
    expect_error(sql_exec("INSTALL icu"), "Failed to download extension")
  }
})

test_that("duckdb_platform() reports the repository's path segment", {
  # `<os>_<arch>` with an optional toolchain suffix, exactly as the extension
  # repository is addressed; asserted by shape, since the value differs per
  # platform and the point is that it is the engine's own string.
  expect_match(duckdb_platform(), "^[a-z0-9]+_[a-z0-9]+(_[a-z0-9]+)?$")
})

test_that("extensions_published() knows which platforms are covered", {
  # The gap as of 2026-08: DuckDB builds arm64 Windows extensions, but only as
  # `windows_arm64` (MSVC); the `_mingw` flavor R's toolchain needs exists for
  # x86_64 alone. Expected to change -- when it does, the canary above and this
  # assertion are what say so.
  expect_false(extensions_published("windows_arm64_mingw"))

  expect_true(extensions_published("windows_amd64_mingw"))
  expect_true(extensions_published("linux_amd64"))
  expect_true(extensions_published("osx_arm64"))
})

# The canary for what `skip_if_no_extension_binaries()` skips. Asserting the 404
# rather than passing over it means that the day DuckDB starts publishing for
# the platform, this fails and the skip above can go (duckdb/duckdb-r#2425).
test_that("Installing an extension fails where DuckDB publishes none", {
  skip_on_dev_version()
  skip_on_cran_except_r_universe()
  platform <- duckdb_extension_platform()
  skip_if_not(
    platform %in% platforms_without_extensions,
    paste0("DuckDB publishes extensions for ", platform, ".")
  )

  err <- expect_error(sql_exec("INSTALL icu"))
  expect_match(conditionMessage(err), "HTTP 404", fixed = TRUE)
  expect_match(conditionMessage(err), platform, fixed = TRUE)
})
