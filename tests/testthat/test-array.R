local_edition(3)

test_that("arrays of INTEGER can be read", {
  con <- local_con(array = "matrix")

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
  con <- local_con(array = "matrix")

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
  con <- local_con(array = "matrix")

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
  con <- local_con(array = "matrix")

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
  con <- local_con(array = "matrix")

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
  con <- local_con(array = "matrix")

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
  con <- local_con(array = "matrix")

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
  con <- local_con(array = "matrix")

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
  con <- local_con(array = "matrix")

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
  con <- local_con(array = "matrix")

  dbExecute(con, "CREATE TABLE tbl (a INTEGER, b INTEGER[3][3])")
  dbExecute(con, "INSERT INTO tbl VALUES (10, [[1,3,4], [4,5,6], [7,8,9]])")
  dbExecute(con, "INSERT INTO tbl VALUES (11, [[1,3,4], [4,5,6], [7,8,9]])")

  expect_snapshot( error = TRUE, {
    dbGetQuery(con, "FROM tbl")
  })
})


test_that("array errors with convert option array = 'none'", {
  con <- local_con(array = "none")

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
  con <- local_con()

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

  con <- local_con(array = "matrix")

  a <- matrix(1:12, nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
})


test_that("arrays of INTEGER can be written", {
  skip_if_not_installed("dplyr")

  con <- local_con(array = "matrix")

  a <- c(10, 11, 12, 13)
  b <- matrix(1:12, nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of INTEGER with NULL can be written", {
  skip_if_not_installed("dplyr")

  con <- local_con(array = "matrix")

  a <- c(10, 11, 12, 13)
  b <- matrix(c(1, NA, 3, 4, 5, 6, 7, 8, 9, 10, NA, 12), nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of DOUBLE can be written", {
  skip_if_not_installed("dplyr")

  con <- local_con(array = "matrix")

  a <- c(10, 11, 12, 13)
  b <- matrix(as.double(1:12), nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of DOUBLE with NULL can be written", {
  skip_if_not_installed("dplyr")

  con <- local_con(array = "matrix")

  a <- c(10, 11, 12, 13)
  b <- matrix(as.double(c(1, 2, 3, 4, 5, 6, 7, NA, 9, NA, 11, 12)), nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of BOOLEAN can be written", {
  skip_if_not_installed("dplyr")

  con <- local_con(array = "matrix")

  a <- c(10, 11, 12, 13)
  b <- matrix(c(T, F, T, F, F, T, T, F, T, T, F, F) , nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of BOOLEAN with NULL can be written", {
  skip_if_not_installed("dplyr")

  con <- local_con(array = "matrix")

  a <- c(10, 11, 12, 13)
  b <- matrix(c(T, F, NA, F, NA, T, T, F, T, T, F, F) , nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of STRING can be written", {
  skip_if_not_installed("dplyr")

  con <- local_con(array = "matrix")

  a <- c(10, 11, 12, 13)
  b <- matrix(c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l") , nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("arrays of STRING with NULL can be written", {
  skip_if_not_installed("dplyr")

  con <- local_con(array = "matrix")

  a <- c(10, 11, 12, 13)
  b <- matrix(c("a", "b", "c", "d", "e", NA, "g", "h", NA, "j", "k", "l") , nrow = 4, ncol = 3)
  dbWriteTable(con, "tbl", dplyr::tibble(a, b))

  df <- dbGetQuery(con, "FROM tbl")

  expect_equal(df$a, a)
  expect_equal(df$b, b)
})


test_that("array errors when writing matrix of complex numbers", {
  skip_if_not_installed("dplyr")

  con <- local_con(array = "matrix")

  a <- c(10, 11, 12, 13)
  b <- matrix(1+1i , nrow = 4, ncol = 3)
  df <- dplyr::tibble(a, b)

  expect_snapshot( error = TRUE, {
    dbWriteTable(con, "tbl", df)
  })
})

test_that("arrays work correctly with UNION ALL queries", {
  # Regression test for array indexing bug with UNION ALL
  # Previously, UNION ALL queries with arrays would produce incorrect matrix values
  # due to improper column-major indexing when rows were processed individually
  con <- local_con(array = "matrix")

  # Test with INTEGER arrays
  result <- dbGetQuery(con, "
    SELECT 1 AS id, [4, 5, 6]::integer[3] AS matrix
    UNION ALL
    SELECT 2, [7, 8, 9]
  ")

  expected_matrix <- matrix(c(4, 7, 5, 8, 6, 9), nrow = 2, ncol = 3)
  expect_equal(result$matrix, expected_matrix)

  # Test with DOUBLE arrays
  result_double <- dbGetQuery(con, "
    SELECT 1 AS id, [1.1, 2.2, 3.3]::double[3] AS matrix
    UNION ALL
    SELECT 2, [4.4, 5.5, 6.6]
  ")

  expected_matrix_double <- matrix(c(1.1, 4.4, 2.2, 5.5, 3.3, 6.6), nrow = 2, ncol = 3)
  expect_equal(result_double$matrix, expected_matrix_double)

  # Test with three rows to ensure it works with more than two rows
  result_three <- dbGetQuery(con, "
    SELECT 1 AS id, [10, 20, 30]::integer[3] AS matrix
    UNION ALL
    SELECT 2, [40, 50, 60]
    UNION ALL
    SELECT 3, [70, 80, 90]
  ")

  expected_matrix_three <- matrix(c(10, 40, 70, 20, 50, 80, 30, 60, 90), nrow = 3, ncol = 3)
  expect_equal(result_three$matrix, expected_matrix_three)

  # Test with different array sizes
  result_size4 <- dbGetQuery(con, "
    SELECT 1 AS id, [1, 2, 3, 4]::integer[4] AS matrix
    UNION ALL
    SELECT 2, [5, 6, 7, 8]
  ")

  expected_matrix_size4 <- matrix(c(1, 5, 2, 6, 3, 7, 4, 8), nrow = 2, ncol = 4)
  expect_equal(result_size4$matrix, expected_matrix_size4)
})

test_that("arrays work correctly in write/read roundtrip after UNION ALL fix", {
  # Additional test to ensure the fix doesn't break UNION ALL array operations
  con <- local_con(array = "matrix")

  # Test UNION ALL with arrays to ensure our fix works in roundtrip scenarios
  dbExecute(con, "CREATE TABLE test_table AS SELECT 1 as id, [4, 5, 6]::INTEGER[3] as matrix_col
                  UNION ALL
                  SELECT 2 as id, [7, 8, 9]::INTEGER[3] as matrix_col")

  result <- dbReadTable(con, "test_table")

  # The matrix_col should be read as a matrix with correct values
  expected_matrix <- matrix(c(4, 7, 5, 8, 6, 9), nrow = 2, ncol = 3)
  expect_equal(result$matrix_col, expected_matrix)
})
