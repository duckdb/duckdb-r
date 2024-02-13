skip_on_cran()
skip_on_os(c("windows"))
local_edition(3)

test_that("duckdb extensions are in a R specific directory", {
  con <- DBI::dbConnect(duckdb(config=list('allow_unsigned_extensions'='true')))
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  expect_error(dbExecute(con, "LOAD 'httpfs'"),regexp = ".*R/duckdb/extensions/.*/httpfs.duckdb_extension\" not found.")
})