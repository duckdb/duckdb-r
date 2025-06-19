test_that("configuration key value pairs work as expected", {
  # but setting a legal option is fine
  drv <- duckdb(config = list("default_order" = "DESC"))

  # the option actually does something
  con <- dbConnect(drv)
  dbExecute(con, "create table a (i integer)")
  dbExecute(con, "insert into a values (44), (42)")
  res <- dbGetQuery(con, "select i from a order by i")
  dbDisconnect(con)
  expect_equal(res$i, c(44, 42))
  duckdb_shutdown(drv)
})
