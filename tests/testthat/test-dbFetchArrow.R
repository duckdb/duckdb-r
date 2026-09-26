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
    if (chunk$length == 0L) {
      break
    }
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

test_that("the Arrow schema and an empty batch are there before the first fetch", {
  con <- local_con()

  res <- dbSendQueryArrow(
    con,
    "SELECT [i] AS l, INTERVAL 1 DAY AS iv, 'x' AS v FROM range(3) t(i)"
  )
  on.exit(dbClearResult(res), add = TRUE)

  formats <- function(schema) {
    vapply(schema$children, function(child) child$format, character(1))
  }

  schema <- arrow_schema(res)
  expect_named(schema$children, c("l", "iv", "v"))

  # Built from an empty chunk, so it carries the offset a zero-length list or string array still has.
  empty <- nanoarrow::nanoarrow_allocate_array()
  rapi_arrow_empty_array(res@env$query_result, empty)
  expect_no_error(
    nanoarrow::nanoarrow_array_set_schema(empty, schema, validate = TRUE)
  )
  expect_equal(empty$length, 0L)

  chunk <- dbFetchArrowChunk(res)
  expect_equal(chunk$length, 3L)
  expect_equal(
    formats(nanoarrow::infer_nanoarrow_schema(chunk)),
    formats(schema)
  )
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

test_that("a stream that another statement invalidated errors instead of ending (#2772)", {
  con <- local_con()

  res <- dbSendQueryArrow(con, "SELECT i FROM range(30) t(i)")
  stream <- dbFetchArrow(res, chunk_size = 10)
  dbClearResult(res)

  expect_equal(stream$get_next()$length, 10L)
  dbGetQuery(con, "SELECT 42")
  expect_error(stream$get_next(), "invalidated by another statement")
  expect_error(stream$get_next(), "invalidated by another statement")

  # Invalidated before the first read, when not even the schema was read.
  res <- dbSendQueryArrow(con, "SELECT i FROM range(30) t(i)")
  stream <- dbFetchArrow(res, chunk_size = 10)
  dbClearResult(res)

  dbGetQuery(con, "SELECT 42")
  expect_error(stream$get_next(), "invalidated by another statement")
})

test_that("a chunked result that another statement invalidated errors instead of ending (#2772)", {
  con <- local_con()

  res <- dbSendQueryArrow(con, "SELECT i FROM range(30) t(i)")
  on.exit(dbClearResult(res), add = TRUE)

  expect_equal(dbFetchArrowChunk(res, chunk_size = 10)$length, 10L)
  dbGetQuery(con, "SELECT 42")
  expect_error(
    dbFetchArrowChunk(res, chunk_size = 10),
    "invalidated by another statement"
  )
  expect_false(dbHasCompleted(res))
})

test_that("a stream read to the end still ends after another statement (#2772)", {
  con <- local_con()

  res <- dbSendQueryArrow(con, "SELECT i FROM range(30) t(i)")
  stream <- dbFetchArrow(res, chunk_size = 10)
  dbClearResult(res)

  total <- 0L
  while (!is.null(batch <- stream$get_next())) {
    total <- total + batch$length
  }
  expect_equal(total, 30L)

  dbGetQuery(con, "SELECT 42")
  expect_null(stream$get_next())

  res <- dbSendQueryArrow(con, "SELECT i FROM range(30) t(i)")
  on.exit(dbClearResult(res), add = TRUE)
  repeat {
    if (dbFetchArrowChunk(res, chunk_size = 10)$length == 0L) {
      break
    }
  }

  dbGetQuery(con, "SELECT 42")
  expect_equal(dbFetchArrowChunk(res)$length, 0L)
})
