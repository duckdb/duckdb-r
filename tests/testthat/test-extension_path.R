skip_on_cran()
skip_on_os(c("windows"))

test_that("duckdb extensions are in a R specific directory", {
  con <- DBI::dbConnect(duckdb(config=list('allow_unsigned_extensions'='true')))
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  expect_error(dbExecute(con, "LOAD 'bogus'"), regexp = ".*R/duckdb/extensions/.*/bogus.duckdb_extension.*\" not found.")
})
