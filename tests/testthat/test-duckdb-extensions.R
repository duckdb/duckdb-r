test_that("Install DuckDB extension", {
  skip_on_dev_version()
  skip_on_cran_except_r_universe()
  # Disabled on a libc++ Linux build (loading a prebuilt extension crashes R --
  # duckdb/duckdb-r#1107); INSTALL is refused there by design.
  skip_if_not(extensions_supported(), "DuckDB extensions disabled on this build (duckdb/duckdb-r#1107)")
  # Nothing to install where DuckDB publishes no binaries for this platform;
  # the test below is what covers those.
  skip_if_no_extension_binaries()

  expect_no_error(sql_exec("INSTALL icu"))
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
