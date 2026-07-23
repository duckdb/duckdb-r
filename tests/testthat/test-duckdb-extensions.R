test_that("Install DuckDB extension", {
  skip_on_dev_version()
  skip_on_cran_except_r_universe()
  # Disabled on a libc++ Linux build (loading a prebuilt extension crashes R --
  # duckdb/duckdb-r#1107); INSTALL is refused there by design.
  skip_if_not(extensions_supported(), "DuckDB extensions disabled on this build (duckdb/duckdb-r#1107)")

  expect_no_error(sql_exec("INSTALL icu"))
})
