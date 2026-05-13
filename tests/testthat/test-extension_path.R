skip_on_cran()
skip_on_os(c("windows"))

test_that("duckdb extensions are in a R specific directory", {
  con <- local_con(config = list('allow_unsigned_extensions' = 'true'))
  expect_error(dbExecute(con, "LOAD 'bogus'"), regexp = ".*R/duckdb/extensions/.*/bogus.duckdb_extension.*\" not found.")
})
