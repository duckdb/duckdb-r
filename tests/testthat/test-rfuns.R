test_that("can load rfuns extension and run functions", {
  drv <- duckdb()
  con <- dbConnect(drv)

  expect_error(dbGetQuery(con, 'SELECT "r_base::=="(1, 2)'))

  rapi_load_rfuns(drv@database_ref)

  expect_equal(dbGetQuery(con, 'SELECT "r_base::=="(1, 2)')[[1]], FALSE)

  dbDisconnect(con)
})
