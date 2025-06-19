

test_that("Conversion of sub-dates prior Posix origin is correct", {
  con <- dbConnect(duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE))

  df <- data.frame(
    d = as.Date(c(-1.1, -0.1, 0, 0.1, 1.1), origin = "1970-01-01")
  )

  duckdb_register(con, "df", df)

  res <- sql("from df", con)

  expect_identical(
    as.character(df$d),
    as.character(res$d)
  )
})

