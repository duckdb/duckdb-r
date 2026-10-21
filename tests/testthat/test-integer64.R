# this tests both retrieval and scans
test_that("we can roundtrip an integer64 via driver", {
  skip_if_not_installed("bit64")
  con <- local_con(bigint = "integer64")
  df <- data.frame(
    a = bit64::as.integer64(42),
    b = bit64::as.integer64(-42),
    c = bit64::as.integer64(NA)
  )

  duckdb_register(con, "df", df)

  res <- dbReadTable(con, "df")
  expect_identical(df, res)
})

test_that("we can roundtrip an integer64 via dbConnect", {
  skip_if_not_installed("bit64")
  con <- local_con(bigint = "integer64")
  df <- data.frame(
    a = bit64::as.integer64(42),
    b = bit64::as.integer64(-42),
    c = bit64::as.integer64(NA)
  )

  duckdb_register(con, "df", df)

  res <- dbReadTable(con, "df")
  expect_identical(df, res)
})

test_that("an integer64 column registers as BIGINT whatever `bigint` says", {
  skip_if_not_installed("bit64")
  con <- local_con()
  df <- data.frame(a = bit64::as.integer64(c("9007199254740993", NA)))

  duckdb_register(con, "df", df)

  res <- dbGetQuery(con, "SELECT typeof(a) AS t, a::VARCHAR AS v FROM df")
  expect_equal(res$t, c("BIGINT", "BIGINT"))
  expect_equal(res$v, c("9007199254740993", NA))
})

test_that("an integer64 parameter binds as BIGINT", {
  skip_if_not_installed("bit64")
  con <- local_con()

  res <- dbGetQuery(
    con,
    "SELECT ?::VARCHAR AS v",
    params = list(bit64::as.integer64(c("9007199254740993", NA)))
  )

  expect_equal(res$v, c("9007199254740993", NA))
})
