# Streaming result sets: dbSendQuery(stream = TRUE) pulls chunks lazily from
# a StreamQueryResult inside dbFetch() instead of materializing the whole
# result (plan/streaming-results.md, T5-T10).

test_that("dbSendQuery(stream = TRUE) fetches in chunks without materializing", {
  con <- local_con()
  dbWriteTable(con, "mt", mtcars)

  rs <- dbSendQuery(con, "SELECT * FROM mt", stream = TRUE)
  expect_null(rs@env$resultset)
  # The stream opens eagerly at dbSendQuery() time, without materializing
  expect_false(is.null(rs@env$stream_result))
  expect_false(dbHasCompleted(rs))

  d1 <- dbFetch(rs, n = 10)
  expect_equal(nrow(d1), 10)
  expect_null(rs@env$resultset)
  expect_equal(dbGetRowCount(rs), 10)
  expect_false(dbHasCompleted(rs))

  d2 <- dbFetch(rs, n = 10)
  expect_equal(nrow(d2), 10)
  expect_equal(dbGetRowCount(rs), 20)

  d3 <- dbFetch(rs, n = -1)
  expect_equal(nrow(d3), 12)
  expect_equal(dbGetRowCount(rs), 32)
  expect_true(dbHasCompleted(rs))

  # Fetching past the end returns an empty data frame with the right columns
  d4 <- dbFetch(rs, n = 5)
  expect_equal(nrow(d4), 0)
  expect_equal(names(d4), names(mtcars))
  expect_true(dbHasCompleted(rs))

  expect_identical(rbind(d1, d2, d3), dbGetQuery(con, "SELECT * FROM mt"))

  dbClearResult(rs)
})

test_that("streaming fetch splits chunks at exact row counts", {
  con <- local_con()

  rs <- dbSendQuery(con, "SELECT * FROM range(10000) AS t(i)", stream = TRUE)
  sizes <- c(1, 7, 100, 2048, 3000)
  fetched <- lapply(sizes, function(n) dbFetch(rs, n = n))
  expect_equal(vapply(fetched, nrow, integer(1)), sizes)
  rest <- dbFetch(rs)
  expect_equal(nrow(rest), 10000 - sum(sizes))
  expect_true(dbHasCompleted(rs))

  all <- do.call(rbind, c(fetched, list(rest)))
  expect_identical(all$i, as.numeric(0:9999))

  dbClearResult(rs)
})

test_that("dbFetch(n = 0) on a streaming result returns no rows", {
  con <- local_con()

  rs <- dbSendQuery(con, "SELECT * FROM range(5) AS t(i)", stream = TRUE)
  z <- dbFetch(rs, n = 0)
  expect_equal(nrow(z), 0)
  expect_equal(names(z), "i")
  expect_false(dbHasCompleted(rs))
  expect_equal(nrow(dbFetch(rs)), 5)
  dbClearResult(rs)
})

test_that("streaming a zero-row result completes on first fetch", {
  con <- local_con()

  rs <- dbSendQuery(con, "SELECT 1 AS a WHERE 1 = 0", stream = TRUE)
  z <- dbFetch(rs, n = 10)
  expect_equal(nrow(z), 0)
  expect_equal(names(z), "a")
  expect_true(dbHasCompleted(rs))
  dbClearResult(rs)
})

test_that("streaming results rebind: new params open a fresh stream", {
  con <- local_con()
  dbWriteTable(con, "mt", mtcars)

  rs <- dbSendQuery(con, "SELECT * FROM mt WHERE cyl = ?", stream = TRUE)
  expect_false(dbHasCompleted(rs))
  expect_error(dbFetch(rs), "dbBind")

  dbBind(rs, list(6L))
  p1 <- dbFetch(rs, n = 3)
  expect_equal(nrow(p1), 3)
  expect_false(dbHasCompleted(rs))

  # Re-binding drops the partially fetched stream
  dbBind(rs, list(4L))
  expect_false(dbHasCompleted(rs))
  expect_equal(dbGetRowCount(rs), 0)
  p2 <- dbFetch(rs)
  expect_equal(nrow(p2), 11)
  expect_true(dbHasCompleted(rs))

  dbClearResult(rs)
})

test_that("type errors on streaming results surface at dbFetch()", {
  con <- local_con()

  rs <- dbSendQuery(con, "SELECT ?::INT + 1 AS a", stream = TRUE)
  dbBind(rs, list("asdf"))
  expect_error(dbFetch(rs))
  dbClearResult(rs)
})

test_that("execution errors on streaming queries are raised, not swallowed", {
  con <- local_con()

  # A tiny pipeline completes during the eager open: the error surfaces at
  # dbSendQuery() time and leaves the connection usable
  expect_error(
    dbSendQuery(
      con,
      "SELECT CAST(x AS INT) AS i FROM (VALUES ('1'),('abc')) t(x)",
      stream = TRUE
    ),
    "Could not convert"
  )
  expect_equal(dbGetQuery(con, "SELECT 42 AS x")$x, 42)

  # An error deep in a large scan is beyond what the open buffers:
  # it surfaces on the dbFetch() call that reaches it. The condition text
  # is timing-dependent inside DuckDB: the failing task records the
  # conversion error but also flags the context as interrupted to stop
  # sibling tasks, and the streaming fetch can observe the flag first
  # ("INTERRUPT Error: Interrupted!"). Either way the fetch must error.
  rs <- dbSendQuery(
    con,
    "SELECT CAST(CASE WHEN i < 5000000 THEN '1' ELSE 'abc' END AS INT) AS v
     FROM range(6000000) t(i)",
    stream = TRUE
  )
  expect_equal(nrow(dbFetch(rs, n = 5)), 5)
  expect_error(dbFetch(rs, n = -1))
  dbClearResult(rs)

  expect_equal(dbGetQuery(con, "SELECT 43 AS x")$x, 43)
})

test_that("multi-row binds on a streaming result fall back to materializing", {
  con <- local_con()

  rs <- dbSendQuery(con, "SELECT ?::INT AS a", stream = TRUE)
  dbBind(rs, list(c(1L, 2L, 3L)))
  m <- dbFetch(rs)
  expect_equal(m$a, c(1L, 2L, 3L))
  expect_true(dbHasCompleted(rs))

  # A subsequent single-row bind streams again
  dbBind(rs, list(9L))
  expect_false(dbHasCompleted(rs))
  m2 <- dbFetch(rs)
  expect_equal(m2$a, 9L)
  expect_true(dbHasCompleted(rs))

  dbClearResult(rs)
})

test_that("EXPLAIN stays on the materialized path under stream = TRUE", {
  con <- local_con()

  rs <- dbSendQuery(con, "EXPLAIN SELECT 1", stream = TRUE)
  expect_false(rs@env$stream)
  out <- dbFetch(rs)
  expect_s3_class(out, "duckdb_explain")
  dbClearResult(rs)
})

test_that("stream = TRUE does not affect DML side effects and counts", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE x (a INT)")
  rs <- dbSendQuery(con, "INSERT INTO x VALUES (1), (2)", stream = TRUE)
  expect_false(rs@env$stream)
  expect_equal(dbGetRowsAffected(rs), 2)
  dbClearResult(rs)
  expect_equal(dbGetQuery(con, "SELECT COUNT(*) AS n FROM x")$n, 2)
})

test_that("stream = TRUE is rejected for arrow = TRUE", {
  con <- local_con()

  expect_error(
    dbSendQuery(con, "SELECT 1", arrow = TRUE, stream = TRUE),
    "dbSendQueryArrow"
  )
})

test_that("running another query invalidates a live stream", {
  con <- local_con()

  # Large result: the first fetch cannot buffer everything
  rs <- dbSendQuery(con, "SELECT * FROM range(10000000) AS t(i)", stream = TRUE)
  expect_equal(nrow(dbFetch(rs, n = 5)), 5)

  expect_equal(dbGetQuery(con, "SELECT 42 AS x")$x, 42)

  # Fetching beyond what is buffered from the invalidated stream errors
  expect_error(dbFetch(rs, n = -1), "closed")
  dbClearResult(rs)

  # The connection stays usable
  expect_equal(dbGetQuery(con, "SELECT 43 AS x")$x, 43)
})

test_that("dbClearResult() releases a partially fetched stream", {
  con <- local_con()

  rs <- dbSendQuery(con, "SELECT * FROM range(10000000) AS t(i)", stream = TRUE)
  expect_equal(nrow(dbFetch(rs, n = 5)), 5)
  expect_true(dbClearResult(rs))
  expect_null(rs@env$stream_result)

  # The connection is free for the next query right away
  expect_equal(dbGetQuery(con, "SELECT 42 AS x")$x, 42)
})

test_that("dbConnect(stream = TRUE) sets the connection default", {
  con <- local_con(stream = TRUE)

  rs <- dbSendQuery(con, "SELECT 1 AS a")
  expect_true(rs@env$stream)
  dbClearResult(rs)

  # Per-query override wins
  rs <- dbSendQuery(con, "SELECT 1 AS a", stream = FALSE)
  expect_false(rs@env$stream)
  dbClearResult(rs)

  # dbGetQuery() works on a streaming connection
  expect_equal(dbGetQuery(con, "SELECT 42 AS x")$x, 42)
})

test_that("streaming results convert types identically to materialized results", {
  con <- local_con(array = "matrix")
  dbExecute(con, "CREATE TYPE color AS ENUM ('red', 'green', 'blue')")
  # Core types only: TIMESTAMPTZ arithmetic needs the icu extension and is
  # covered by a separate, skippable test below.
  dbExecute(
    con,
    "CREATE TABLE typed AS
     SELECT
       i::INT AS int_col,
       i::BIGINT * 1000000000 AS bigint_col,
       i / 3.0 AS dbl_col,
       'row ' || i AS str_col,
       (i % 2 = 0) AS lgl_col,
       DATE '2024-01-01' + i::INT AS date_col,
       TIMESTAMP '2024-01-01 12:00:00' + INTERVAL (i) SECOND AS ts_col,
       ('mystery' || i)::BLOB AS blob_col,
       [i, i + 1, i + 2] AS list_col,
       {'a': i, 'b': 'row ' || i} AS struct_col,
       [i, i * 2]::INT[2] AS array_col,
       ['red', 'green', 'blue'][1 + i % 3]::color AS enum_col,
       CASE WHEN i % 5 = 0 THEN NULL ELSE i END AS null_col
     FROM range(5000) t(i)"
  )

  sql <- "SELECT * FROM typed ORDER BY int_col"

  # One streamed fetch of everything is identical to the materialized result
  ref <- dbGetQuery(con, sql)
  rs <- dbSendQuery(con, sql, stream = TRUE)
  expect_identical(dbFetch(rs), ref)
  dbClearResult(rs)

  # The same sequence of partial fetches yields identical frames on both
  # paths. The materialized result executes eagerly at dbSendQuery() time,
  # so its query does not invalidate the stream and the two results coexist
  # on one connection.
  # Struct and array columns are excluded: R-level slicing of the
  # materialized resultset renumbers their inner row names, so the frames
  # cannot be identical even though the values are (covered by the
  # full-fetch comparison above).
  sql_partial <- "SELECT * EXCLUDE (struct_col, array_col) FROM typed ORDER BY int_col"
  rs_m <- dbSendQuery(con, sql_partial)
  rs_s <- dbSendQuery(con, sql_partial, stream = TRUE)
  for (n in c(1, 999, 2500, -1)) {
    expect_identical(dbFetch(rs_s, n = n), dbFetch(rs_m, n = n))
  }
  expect_true(dbHasCompleted(rs_s))
  expect_true(dbHasCompleted(rs_m))
  dbClearResult(rs_s)
  dbClearResult(rs_m)
})

test_that("streaming converts TIMESTAMPTZ identically to materialized results", {
  skip_if_no_icu()

  con <- local_con()
  # The icu extension is downloaded on demand: skip when the download or
  # load fails even though the platform would support it (e.g. offline)
  icu <- tryCatch(
    {
      dbExecute(con, "INSTALL icu; LOAD icu")
      TRUE
    },
    error = function(e) FALSE
  )
  skip_if_not(icu, "icu extension not available")

  sql <- "SELECT TIMESTAMPTZ '2024-01-01 12:00:00+00' + INTERVAL (i) SECOND AS tstz
          FROM range(5000) t(i)"
  ref <- dbGetQuery(con, sql)

  rs <- dbSendQuery(con, sql, stream = TRUE)
  expect_identical(dbFetch(rs), ref)
  dbClearResult(rs)

  rs_m <- dbSendQuery(con, sql)
  rs_s <- dbSendQuery(con, sql, stream = TRUE)
  for (n in c(3, 2500, -1)) {
    expect_identical(dbFetch(rs_s, n = n), dbFetch(rs_m, n = n))
  }
  dbClearResult(rs_s)
  dbClearResult(rs_m)
})

test_that("streaming respects timezone_out and tz_out_convert per fetch", {
  con <- local_con(timezone_out = "America/New_York", tz_out_convert = "force")

  sql <- "SELECT TIMESTAMP '2024-01-01 12:00:00' + INTERVAL (i) HOUR AS ts
          FROM range(100) t(i)"
  ref <- dbGetQuery(con, sql)

  rs <- dbSendQuery(con, sql, stream = TRUE)
  streamed <- rbind(dbFetch(rs, n = 42), dbFetch(rs, n = -1))
  dbClearResult(rs)

  expect_identical(streamed, ref)
})

test_that("streaming works with bigint = \"integer64\"", {
  skip_if_not_installed("bit64")
  con <- local_con(bigint = "integer64")

  sql <- "SELECT i::BIGINT * 1000000000 AS big FROM range(100) t(i)"
  ref <- dbGetQuery(con, sql)

  rs <- dbSendQuery(con, sql, stream = TRUE)
  streamed <- rbind(dbFetch(rs, n = 7), dbFetch(rs, n = -1))
  dbClearResult(rs)

  expect_identical(streamed, ref)
})
