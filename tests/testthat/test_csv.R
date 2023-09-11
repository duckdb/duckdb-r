test_that("Csv reader produces same results as read.csv", {
  con <- dbConnect(duckdb())

  tf <- tempfile(fileext = ".csv")

  test <- data.frame(num=c(1, 2, "-"), char=c("yes", "no", "-"), logi=c(TRUE, FALSE, "-"))
    # default case
  write.csv(test, tf, row.names = FALSE)
  table_name <- "csv_table"
  duckdb_read_csv(con, table_name, tf)

  identical(
    dbReadTable(con, table_name),
    read.csv(tf, na.strings = "-")
  )

  dbDisconnect(con, shutdown = TRUE)
})
