test_that("fractional seconds can be roundtripped", {
  skip_if_not(TEST_RE2)

  con <- dbConnect(duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE))

  df <- data.frame(a = as.POSIXct(
    1.234567 + (1:100) * 1e-6,
    origin = structure(0, class = c("POSIXct", "POSIXt")),
    tz = "UTC"
  ))
  dbWriteTable(con, "df", df)
  df_out <- dbReadTable(con, "df")
  expect_equal(df_out, df)
})
