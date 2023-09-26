library(duckdb)

test_that("Invalid unicode produces an error", {
  # this doesn't throw an error on old releases of R.
  skip_if(R.Version()$major <= 4 && R.Version()$minor <= 2.3)
  con <- DBI::dbConnect(duckdb::duckdb())

  my_df <- structure(list(no_municipio_esc = "Est\xe2ncia", no_municipio_prova = "Est\xe2ncia"), row.names = 16L, class = "data.frame")
  expect_error(dbWriteTable(con , 'my_table' , my_df ))

  # test that the connection still works.
  dbWriteTable(con, 'myTable', data.frame(a=c(1, 2, 3), b=c(4, 5, 6)))
  DBI::dbDisconnect(con, shutdown = TRUE)
})
