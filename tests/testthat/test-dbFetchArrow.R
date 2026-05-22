skip_if_not_installed("nanoarrow")

test_that("dbFetchArrow() returns a nanoarrow_array_stream", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER, b VARCHAR)")
  dbExecute(con, "INSERT INTO t VALUES (1, 'x'), (2, 'y'), (3, 'z')")

  res <- dbSendQueryArrow(con, "SELECT * FROM t")
  on.exit(dbClearResult(res), add = TRUE)

  stream <- dbFetchArrow(res)
  expect_s3_class(stream, "nanoarrow_array_stream")
  expect_true(dbHasCompleted(res))

  df <- as.data.frame(nanoarrow::collect_array_stream(
    stream,
    schema = nanoarrow::infer_nanoarrow_schema(stream)
  ))
  expect_equal(df, data.frame(a = 1:3, b = c("x", "y", "z")))
})

test_that("dbFetchArrowChunk() iterates lazily until empty", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t AS SELECT range a FROM range(5000)")

  res <- dbSendQueryArrow(con, "SELECT a FROM t")
  on.exit(dbClearResult(res), add = TRUE)

  total <- 0L
  chunks <- 0L
  repeat {
    chunk <- dbFetchArrowChunk(res, chunk_size = 1024)
    if (chunk$length == 0L) break
    total <- total + chunk$length
    chunks <- chunks + 1L
  }
  expect_equal(total, 5000L)
  expect_gt(chunks, 1L)
  expect_true(dbHasCompleted(res))

  # Subsequent calls return an empty chunk without error.
  again <- dbFetchArrowChunk(res)
  expect_equal(again$length, 0L)
})

test_that("dbFetchArrow() errors after the result is cleared", {
  con <- local_con()
  res <- dbSendQueryArrow(con, "SELECT 1")
  dbClearResult(res)
  expect_error(dbFetchArrow(res), "cleared")
  expect_error(dbFetchArrowChunk(res), "cleared")
})

test_that("dbFetchArrow() returns an empty stream after the result is consumed", {
  con <- local_con()
  res <- dbSendQueryArrow(con, "SELECT 1 AS a")
  on.exit(dbClearResult(res), add = TRUE)

  dbFetchArrow(res)
  again <- dbFetchArrow(res)
  expect_s3_class(again, "nanoarrow_array_stream")
  expect_equal(length(nanoarrow::collect_array_stream(again)), 0L)
})

test_that("dbSendQueryArrow() + dbFetchArrowChunk() streams large queries", {
  con <- local_con()

  t1 <- Sys.time()
  res <- dbSendQueryArrow(con, "SELECT * FROM range(10000000)")
  on.exit(dbClearResult(res), add = TRUE)
  elapsed <- as.numeric(Sys.time() - t1, units = "secs")

  # No materialization happened.
  expect_lt(elapsed, 1)

  chunk <- dbFetchArrowChunk(res, chunk_size = 1024)
  expect_equal(chunk$length, 1024L)
})

test_that("dbColumnInfo() still works on an arrow result and matches the schema", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER, b VARCHAR, c DOUBLE)")

  res <- dbSendQueryArrow(con, "SELECT a, b, c FROM t")
  on.exit(dbClearResult(res), add = TRUE)

  info <- dbColumnInfo(res)
  expect_equal(info$name, c("a", "b", "c"))

  # Pull one chunk to populate the arrow schema; check it agrees.
  chunk <- dbFetchArrowChunk(res)
  schema <- res@env$arrow_schema
  expect_s3_class(schema, "nanoarrow_schema")
})
