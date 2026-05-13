test_that("fractional seconds can be roundtripped", {
  skip_if_not(TEST_RE2)

  con <- local_con()

  df <- data.frame(a = as.POSIXct(
    1.234567 + (1:100) * 1e-6,
    origin = structure(0, class = c("POSIXct", "POSIXt")),
    tz = "UTC"
  ))
  dbWriteTable(con, "df", df)
  df_out <- dbReadTable(con, "df")
  expect_equal(df_out, df)
})

test_that("fractional seconds can be extracted from TIME columns", {
  con <- local_con()

  data <- dbGetQuery(con, "SELECT TIME '01:02:03.45' AS a, INTERVAL '01:02:03.45' AS b")
  expect_equal(
    data$a,
    structure(3723.45, class = "difftime", units = "secs")
  )
  expect_equal(
    data$b,
    structure(3723.45, class = "difftime", units = "secs")
  )
})
