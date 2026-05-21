skip_if_not_installed("nanoarrow")

test_that("dbSendQueryArrow() accepts params= and binds them", {
  con <- local_con()
  dbWriteTable(con, "mt", mtcars)

  res <- dbSendQueryArrow(con, "SELECT * FROM mt WHERE cyl = ?", params = list(6L))
  on.exit(dbClearResult(res), add = TRUE)

  stream <- dbFetchArrow(res)
  df <- as.data.frame(nanoarrow::collect_array_stream(
    stream,
    schema = nanoarrow::infer_nanoarrow_schema(stream)
  ))
  expect_equal(nrow(df), sum(mtcars$cyl == 6))
})

test_that("dbBind() rebinds an arrow result", {
  con <- local_con()
  dbWriteTable(con, "mt", mtcars)

  res <- dbSendQueryArrow(con, "SELECT * FROM mt WHERE cyl = ?")
  on.exit(dbClearResult(res), add = TRUE)

  dbBind(res, list(4L))
  stream <- dbFetchArrow(res)
  df <- as.data.frame(nanoarrow::collect_array_stream(
    stream,
    schema = nanoarrow::infer_nanoarrow_schema(stream)
  ))
  expect_equal(nrow(df), sum(mtcars$cyl == 4))
})

test_that("dbBindArrow() works with a nanoarrow stream", {
  con <- local_con()
  dbWriteTable(con, "mt", mtcars)

  res <- dbSendQueryArrow(con, "SELECT * FROM mt WHERE cyl = ?")
  on.exit(dbClearResult(res), add = TRUE)

  arrow_params <- nanoarrow::as_nanoarrow_array_stream(data.frame(cyl = 8L))
  dbBindArrow(res, arrow_params)

  stream <- dbFetchArrow(res)
  df <- as.data.frame(nanoarrow::collect_array_stream(
    stream,
    schema = nanoarrow::infer_nanoarrow_schema(stream)
  ))
  expect_equal(nrow(df), sum(mtcars$cyl == 8))
})

test_that("dbBind() resets completion state for re-use", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t AS SELECT range a FROM range(10)")

  res <- dbSendQueryArrow(con, "SELECT a FROM t WHERE a >= ?")
  on.exit(dbClearResult(res), add = TRUE)

  dbBind(res, list(5L))
  dbFetchArrow(res)
  expect_true(dbHasCompleted(res))

  dbBind(res, list(0L))
  expect_false(dbHasCompleted(res))
})

test_that("dbBindArrow() rejects multi-row parameter streams", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER)")

  res <- dbSendQueryArrow(con, "INSERT INTO t VALUES (?)")
  on.exit(dbClearResult(res), add = TRUE)

  arrow_params <- nanoarrow::as_nanoarrow_array_stream(data.frame(a = c(1L, 2L)))
  expect_error(dbBindArrow(res, arrow_params), "length one")
})
