test_that("as.numeric treats values as doubles", {
  skip_if_not_installed("dplyr")

  con <- local_con()
  df <- data.frame(value = 1.23456789123)
  duckdb_register(con, "df", df)
  # NB: If this results in value AS NUMERIC, the result will be fixed to 3dp, i.e. 1.235
  res <- dplyr::tbl(con, "df") |> dplyr::mutate(x = as.numeric(value)) |> dplyr::pull(x)
  expect_equal(res, df[1, "value"])
})

