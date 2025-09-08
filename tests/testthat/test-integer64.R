# this tests both retrieval and scans
test_that("we can roundtrip an integer64 via driver", {
  skip_if_not_installed("bit64")
  con <- local_con(bigint = "integer64")
  df <- data.frame(a = bit64::as.integer64(42), b = bit64::as.integer64(-42), c = bit64::as.integer64(NA))

  duckdb_register(con, "df", df)

  res <- dbReadTable(con, "df")
  expect_identical(df, res)
})

test_that("we can roundtrip an integer64 via dbConnect", {
  skip_if_not_installed("bit64")
  con <- local_con(bigint = "integer64")
  df <- data.frame(a = bit64::as.integer64(42), b = bit64::as.integer64(-42), c = bit64::as.integer64(NA))

  duckdb_register(con, "df", df)

  res <- dbReadTable(con, "df")
  expect_identical(df, res)
})
