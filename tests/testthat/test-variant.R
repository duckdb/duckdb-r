test_that("DuckDB VARIANT type is correctly decoded into an R list", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE test_v (id INTEGER, v VARIANT)")

  # Insert primitive (null, boolean, number, string)
  dbExecute(con, "INSERT INTO test_v VALUES (1, NULL)")
  dbExecute(con, "INSERT INTO test_v VALUES (2, true::VARIANT)")
  dbExecute(con, "INSERT INTO test_v VALUES (3, 42::VARIANT)")
  dbExecute(con, "INSERT INTO test_v VALUES (4, 'hello'::VARIANT)")

  # Insert object and array via native duckdb cast to variant
  dbExecute(con, "INSERT INTO test_v VALUES (5, {'a': 1, 'b': [2, 3]}::VARIANT)")
  dbExecute(con, "INSERT INTO test_v VALUES (6, [4, 5, 6]::VARIANT)")

  # Fetch the data
  res <- dbGetQuery(con, "SELECT id, v FROM test_v ORDER BY id")

  expect_equal(nrow(res), 6)

  # NULL
  expect_null(res$v[[1]])

  # Boolean
  expect_equal(res$v[[2]], TRUE)

  # Number
  expect_equal(res$v[[3]], 42)

  # String
  expect_equal(res$v[[4]], "hello")

  # Object — struct is returned as a 1-row data frame (consistent with normal struct columns)
  obj <- res$v[[5]]
  expect_s3_class(obj, "data.frame")
  expect_equal(nrow(obj), 1)
  expect_equal(obj$a, 1)
  # 'b' is a list column containing a typed integer vector
  expect_equal(obj$b[[1]], c(2, 3))

  # Array — list is returned as a typed vector (consistent with normal list columns)
  arr <- res$v[[6]]
  expect_equal(arr, c(4, 5, 6))
})

test_that("VARIANT handles empty arrays and objects", {
  con <- local_con()

  # Empty array via list_value()
  res <- dbGetQuery(con, "SELECT list_value()::VARIANT AS empty_arr")
  expect_equal(length(res$empty_arr[[1]]), 0)

  # Empty object via MAP() cast
  res2 <- dbGetQuery(con, "SELECT MAP()::VARIANT AS empty_obj")
  expect_equal(length(res2$empty_obj[[1]]), 0)
})

test_that("VARIANT handles deeply nested structures", {
  con <- local_con()

  res <- dbGetQuery(con, "SELECT {'a': {'b': {'c': [1, 2, 3]}}}::VARIANT AS v")
  v <- res$v[[1]]

  # Nested structs are data frames
  expect_s3_class(v, "data.frame")
  expect_s3_class(v$a, "data.frame")
  expect_s3_class(v$a$b, "data.frame")
  # List child is a typed vector
  expect_equal(v$a$b$c[[1]], c(1, 2, 3))
})

test_that("VARIANT handles timestamps", {
  con <- local_con()

  res <- dbGetQuery(con, "SELECT TIMESTAMP '2024-01-15 12:30:00'::VARIANT AS v")
  v <- res$v[[1]]

  expect_s3_class(v, "POSIXct")
  # Compare epoch seconds directly (UTC-based, no local timezone dependency)
  expect_equal(as.numeric(v), 1705321800)
})

test_that("VARIANT handles dates", {
  con <- local_con()

  res <- dbGetQuery(con, "SELECT DATE '2024-06-15'::VARIANT AS v")
  v <- res$v[[1]]

  expect_s3_class(v, "Date")
  expect_equal(as.character(v), "2024-06-15")
})

test_that("VARIANT handles multiple rows with batched fetch", {
  con <- local_con()

  # Generate enough rows to exercise chunked fetching
  n <- 5000
  dbExecute(con, paste0(
    "CREATE TABLE test_batch AS ",
    "SELECT i AS id, {'val': i, 'label': concat('item_', i)}::VARIANT AS v ",
    "FROM generate_series(1, ", n, ") t(i)"
  ))

  res <- dbGetQuery(con, "SELECT * FROM test_batch ORDER BY id")

  expect_equal(nrow(res), n)

  # Each row's variant is a 1-row data frame (struct)
  expect_s3_class(res$v[[1]], "data.frame")
  expect_equal(res$v[[1]]$val, 1)
  expect_equal(res$v[[1]]$label, "item_1")

  mid <- n %/% 2
  expect_equal(res$v[[mid]]$val, mid)
  expect_equal(res$v[[mid]]$label, paste0("item_", mid))

  expect_equal(res$v[[n]]$val, n)
  expect_equal(res$v[[n]]$label, paste0("item_", n))
})

test_that("VARIANT handles heterogeneous values in an object", {
  con <- local_con()

  # Use a struct with heterogeneous fields cast to variant
  res <- dbGetQuery(con, "SELECT {'num': 1, 'str': 'two', 'flag': true}::VARIANT AS v")
  v <- res$v[[1]]

  expect_s3_class(v, "data.frame")
  expect_equal(v$num, 1)
  expect_equal(v$str, "two")
  expect_equal(v$flag, TRUE)
})

test_that("VARIANT inside a LIST column", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE test_list_v (id INTEGER, vs VARIANT[])")
  dbExecute(con, "INSERT INTO test_list_v VALUES (1, [42::VARIANT, 'hello'::VARIANT])")

  res <- dbGetQuery(con, "SELECT * FROM test_list_v")

  expect_equal(nrow(res), 1)
  vs <- res$vs[[1]]
  expect_equal(length(vs), 2)
  expect_equal(vs[[1]], 42)
  expect_equal(vs[[2]], "hello")
})
