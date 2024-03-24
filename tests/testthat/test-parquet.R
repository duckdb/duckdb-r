test_that("parquet reader works on the notorious userdata1 file", {
  con <- dbConnect(duckdb())
  res <- dbGetQuery(con, "SELECT * FROM parquet_scan('data/userdata1.parquet')")
  dbDisconnect(con, shutdown = TRUE)
  expect_true(TRUE)
})

test_that("parquet reader works with the binary as string flag", {
  con <- dbConnect(duckdb())
  res <- dbGetQuery(con, "SELECT typeof(#1) FROM parquet_scan('data/binary_string.parquet',binary_as_string=true) limit 1")
  expect_true(res[1] == "VARCHAR")
  dbDisconnect(con, shutdown = TRUE)
})

test_that("duckdb_write_parquet() works as expected", {
  con <- dbConnect(duckdb())

  tf <- tempfile()

  # write to parquet
  iris_rel <- rel_from_df(con, iris)
  rel_to_parquet(iris_rel, tf)

  res_rel <- rel_from_table_function(con, 'read_parquet', list(tf))
  res_df <- rel_to_altrep(res_rel)
  res_df$Species <- as.factor(res_df$Species)
  expect_true(identical(res_df, iris))


  # nulls
  iris_na <- iris
  iris_na[[2]][42] <- NA

  iris_na_rel <- duckdb:::rel_from_df(con, iris_na)
  duckdb:::rel_to_parquet(iris_na_rel, tf)

  res_rel <- duckdb:::rel_from_table_function(con, 'read_parquet', list(tf))
  res_df <- duckdb:::rel_to_altrep(res_rel)
  res_df$Species <- as.factor(res_df$Species)
  expect_true(identical(res_df, iris_na))
})

test_that("duckdb rel_to_parquet() throws error with no file name", {
  con <- dbConnect(duckdb())

  # write to parquet
  iris_rel <- rel_from_df(con, iris)
  expect_error(rel_to_parquet(iris_rel, ""))
})

