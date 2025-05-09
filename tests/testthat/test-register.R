test_that("duckdb_register() works", {
  con <- dbConnect(duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE))

  # most basic case
  duckdb_register(con, "my_df1", iris)
  res <- dbReadTable(con, "my_df1")
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris))
  duckdb_unregister(con, "my_df1")

  duckdb_register(con, "my_df2", mtcars)
  res <- dbReadTable(con, "my_df2")
  row.names(res) <- row.names(mtcars)
  expect_true(identical(res, mtcars))
  duckdb_unregister(con, "my_df2")

  duckdb_register(con, "my_df1", mtcars)
  res <- dbReadTable(con, "my_df1")
  row.names(res) <- row.names(mtcars)
  expect_true(identical(res, mtcars))

  # re-registering under same name is an error by default, see issue #967
  expect_error(duckdb_register(con, "my_df1", iris))
  # can force an overwrite
  duckdb_register(con, "my_df1", iris, overwrite = TRUE)
  res <- dbReadTable(con, "my_df1")
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris))

  duckdb_unregister(con, "my_df1")
  duckdb_unregister(con, "my_df2")
  duckdb_unregister(con, "xxx")

  # this needs to be empty now
  expect_true(length(attributes(con@conn_ref)) == 0)
})


test_that("various error cases for duckdb_register()", {
  skip_if_not(TEST_RE2)

  con <- dbConnect(duckdb())

  duckdb_register(con, "my_df1", iris)
  duckdb_unregister(con, "my_df1")
  expect_error(dbReadTable(con, "my_df1"))

  expect_error(duckdb_register(1, "my_df1", iris))
  expect_error(duckdb_register(con, "", iris))
  expect_error(duckdb_unregister(1, "my_df1"))
  expect_error(duckdb_unregister(con, ""))
  dbDisconnect(con, shutdown = TRUE)
  # this is fine
  duckdb_unregister(con, "my_df1")
})


test_that("uppercase data frames are queryable", {
  con <- dbConnect(duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE))

  duckdb_register(con, "My_Mtcars", mtcars)
  dbGetQuery(con, "SELECT * FROM \"My_Mtcars\"")

  res <- dbReadTable(con, "My_Mtcars")
  row.names(res) <- row.names(mtcars)
  expect_true(identical(res, mtcars))
  duckdb_unregister(con, "My_Mtcars")
})

test_that("experimental string handling works", {
  con <- dbConnect(duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE))
  df <- data.frame(a=c(NA, as.character(1:10000)))

  duckdb_register(con, "df", df, experimental=TRUE)

  expect_equal(df, dbGetQuery(con, "SELECT a::STRING a FROM df"))
  expect_equal(df, dbGetQuery(con, "SELECT a FROM df"))
})

test_that("can register list of NULL values", {
  skip_if_not_installed("tibble")

  con <- dbConnect(duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE))
  df <- tibble::tibble(a = 1:2, b = list(NULL))

  expect_silent(duckdb_register(con, "df1", df))
  expect_silent(duckdb_register(con, "df2", df[0, ]))

  expect_equal(dbGetQuery(con, "SELECT * FROM df1"), as.data.frame(df))
})
