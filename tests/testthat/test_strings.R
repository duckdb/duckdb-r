test_that("Invalid unicode produces an error", {
  con <- dbConnect(duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE))

  my_df <- structure(list(no_municipio_esc = "Est\xe2ncia", no_municipio_prova = "Est\xe2ncia"), row.names = 16L, class = "data.frame")
  expect_error(dbWriteTable( con , 'my_table' , my_df ), "Cannot process strings that are not valid", ignore.case = TRUE)
})
