local_edition(3)

test_that("arrays of INTEGER can be read", {
  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (a INTEGER, b INTEGER[3])")
  dbExecute(con, "INSERT INTO tbl VALUES (10, [1, 5, 9])")
  dbExecute(con, "INSERT INTO tbl VALUES (11, [2, 6, 10])")
  dbExecute(con, "INSERT INTO tbl VALUES (12, [3, 7, 11])")
  dbExecute(con, "INSERT INTO tbl VALUES (13, [4, 8, 12])")

  df <- dbGetQuery(con, "FROM tbl")

  a <- c(10, 11, 12, 13)
  b <- matrix(1:12, nrow = 4, ncol = 3)

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of INTEGER with NULL can be read", {
  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (a INTEGER, b INTEGER[3])")
  dbExecute(con, "INSERT INTO tbl VALUES (10, [1, 5, 9])")
  dbExecute(con, "INSERT INTO tbl VALUES (11, [NULL, 6, 10])")
  dbExecute(con, "INSERT INTO tbl VALUES (12, [3, 7, NULL])")
  dbExecute(con, "INSERT INTO tbl VALUES (13, [4, 8, 12])")

  df <- dbGetQuery(con, "FROM tbl")

  a <- c(10, 11, 12, 13)
  b <- matrix(c(1, NA, 3, 4, 5, 6, 7, 8, 9, 10, NA, 12), nrow = 4, ncol = 3)

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of DOUBLE can be read", {
  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (a INTEGER, b DOUBLE[3])")
  dbExecute(con, "INSERT INTO tbl VALUES (10, [1, 5, 9])")
  dbExecute(con, "INSERT INTO tbl VALUES (11, [2, 6, 10])")
  dbExecute(con, "INSERT INTO tbl VALUES (12, [3, 7, 11])")
  dbExecute(con, "INSERT INTO tbl VALUES (13, [4, 8, 12])")

  df <- dbGetQuery(con, "FROM tbl")

  a <- c(10, 11, 12, 13)
  b <- matrix(as.double(1:12), nrow = 4, ncol = 3)

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of DOUBLE with NULL can be read", {
  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (a INTEGER, b DOUBLE[3])")
  dbExecute(con, "INSERT INTO tbl VALUES (10, [1, 5, 9])")
  dbExecute(con, "INSERT INTO tbl VALUES (11, [2, 6, NULL])")
  dbExecute(con, "INSERT INTO tbl VALUES (12, [3, 7, 11])")
  dbExecute(con, "INSERT INTO tbl VALUES (13, [4, NULL, 12])")

  df <- dbGetQuery(con, "FROM tbl")

  a <- c(10, 11, 12, 13)
  b <- matrix(as.double(c(1, 2, 3, 4, 5, 6, 7, NA, 9, NA, 11, 12)), nrow = 4, ncol = 3)

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of BOOELAN can be read", {
  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (a INTEGER, b BOOLEAN[3])")
  dbExecute(con, "INSERT INTO tbl VALUES (10, [true, false, true])")
  dbExecute(con, "INSERT INTO tbl VALUES (11, [false, true, true])")
  dbExecute(con, "INSERT INTO tbl VALUES (12, [true, true, false])")
  dbExecute(con, "INSERT INTO tbl VALUES (13, [false, false, false])")

  df <- dbGetQuery(con, "FROM tbl")

  a <- c(10, 11, 12, 13)
  b <- matrix(c(T, F, T, F, F, T, T, F, T, T, F, F) , nrow = 4, ncol = 3)

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of BOOELAN with NULL can be read", {
  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (a INTEGER, b BOOLEAN[3])")
  dbExecute(con, "INSERT INTO tbl VALUES (10, [true, NULL, true])")
  dbExecute(con, "INSERT INTO tbl VALUES (11, [false, true, true])")
  dbExecute(con, "INSERT INTO tbl VALUES (12, [NULL, true, false])")
  dbExecute(con, "INSERT INTO tbl VALUES (13, [false, false, false])")

  df <- dbGetQuery(con, "FROM tbl")

  a <- c(10, 11, 12, 13)
  b <- matrix(c(T, F, NA, F, NA, T, T, F, T, T, F, F) , nrow = 4, ncol = 3)

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of INTEGER in struct column can be read", {
  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (s STRUCT(a INTEGER, b INTEGER[3]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(10, [1, 5, 9]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(11, [2, 6, 10]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(12, [3, 7, 11]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(13, [4, 8, 12]))")

  df <- dbGetQuery(con, "FROM tbl")

  a <- c(10, 11, 12, 13)
  b <- matrix(1:12, nrow = 4, ncol = 3)

  expect_equal(df$s$a, a)
  expect_equal(df$s$b, b)
})


test_that("arrays of DOUBLE in struct column can be read", {
  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (s STRUCT(a INTEGER, b DOUBLE[3]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(10, [1, 5, 9]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(11, [2, 6, 10]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(12, [3, 7, 11]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(13, [4, 8, 12]))")

  df <- dbGetQuery(con, "FROM tbl")

  a <- c(10, 11, 12, 13)
  b <- matrix(as.double(1:12), nrow = 4, ncol = 3)

  expect_equal(df$s$a, a)
  expect_equal(df$s$b, b)
})


test_that("arrays of BOOLEAN in struct column can be read", {
  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (s STRUCT(a INTEGER, b BOOLEAN[3]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(10, [true, false, true]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(11, [false, true, true]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(12, [true, true, false]))")
  dbExecute(con, "INSERT INTO tbl VALUES (row(13, [false, false, false]))")

  df <- dbGetQuery(con, "FROM tbl")

  a <- c(10, 11, 12, 13)
  b <- matrix( c(T, F, T, F, F, T, T, F, T, T, F, F) , nrow = 4, ncol = 3 )

  expect_equal(df$s$a, a)
  expect_equal(df$s$b, b)
})


test_that("array errors with more than one dimention", {
  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (a INTEGER, b INTEGER[3][3])")
  dbExecute(con, "INSERT INTO tbl VALUES (10, [[1,3,4], [4,5,6], [7,8,9]])")
  dbExecute(con, "INSERT INTO tbl VALUES (11, [[1,3,4], [4,5,6], [7,8,9]])")

  expect_snapshot( error = TRUE, {
    dbGetQuery(con, "FROM tbl")
  })
})


test_that("array errors with convert option array = 'none'", {
  con <- dbConnect(duckdb(), array = "none")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (a INTEGER, b INTEGER[3])")
  dbExecute(con, "INSERT INTO tbl VALUES (10, [1, 5, 9])")
  dbExecute(con, "INSERT INTO tbl VALUES (11, [2, 6, 10])")
  dbExecute(con, "INSERT INTO tbl VALUES (12, [3, 7, 11])")
  dbExecute(con, "INSERT INTO tbl VALUES (13, [4, 8, 12])")

  expect_snapshot( error = TRUE, {
    dbGetQuery(con, "FROM tbl")
  })
})


test_that("array errors with default convert option array", {
  con <- dbConnect(duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE))

  dbExecute(con, "CREATE TABLE tbl (a INTEGER, b INTEGER[3])")
  dbExecute(con, "INSERT INTO tbl VALUES (10, [1, 5, 9])")
  dbExecute(con, "INSERT INTO tbl VALUES (11, [2, 6, 10])")
  dbExecute(con, "INSERT INTO tbl VALUES (12, [3, 7, 11])")
  dbExecute(con, "INSERT INTO tbl VALUES (13, [4, 8, 12])")

  expect_snapshot( error = TRUE, {
    dbGetQuery(con, "FROM tbl")
  })
})


test_that("Single array of INTEGER can be written", {
  skip_if_not_installed("dplyr")

  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  a <- matrix(1:12, nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
})


test_that("arrays of INTEGER can be written", {
  skip_if_not_installed("dplyr")

  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  a <- c(10, 11, 12, 13)
  b <- matrix(1:12, nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of INTEGER with NULL can be written", {
  skip_if_not_installed("dplyr")

  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  a <- c(10, 11, 12, 13)
  b <- matrix(c(1, NA, 3, 4, 5, 6, 7, 8, 9, 10, NA, 12), nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of DOUBLE can be written", {
  skip_if_not_installed("dplyr")

  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  a <- c(10, 11, 12, 13)
  b <- matrix(as.double(1:12), nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of DOUBLE with NULL can be written", {
  skip_if_not_installed("dplyr")

  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  a <- c(10, 11, 12, 13)
  b <- matrix(as.double(c(1, 2, 3, 4, 5, 6, 7, NA, 9, NA, 11, 12)), nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of BOOLEAN can be written", {
  skip_if_not_installed("dplyr")

  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  a <- c(10, 11, 12, 13)
  b <- matrix(c(T, F, T, F, F, T, T, F, T, T, F, F) , nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of BOOLEAN with NULL can be written", {
  skip_if_not_installed("dplyr")

  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  a <- c(10, 11, 12, 13)
  b <- matrix(c(T, F, NA, F, NA, T, T, F, T, T, F, F) , nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of STRING can be written", {
  skip_if_not_installed("dplyr")

  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  a <- c(10, 11, 12, 13)
  b <- matrix(c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l") , nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of STRING with NULL can be written", {
  skip_if_not_installed("dplyr")

  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  a <- c(10, 11, 12, 13)
  b <- matrix(c("a", "b", "c", "d", "e", NA, "g", "h", NA, "j", "k", "l") , nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("array errors when writing matrix of complex numbers", {
  skip_if_not_installed("dplyr")

  con <- dbConnect(duckdb(), array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE))

  a <- c(10, 11, 12, 13)
  b <- matrix(1+1i , nrow = 4, ncol = 3)
  df <- dplyr::tibble(a, b)

  expect_snapshot( error = TRUE, {
    dbWriteTable(con, "tbl", df)
  })
})
