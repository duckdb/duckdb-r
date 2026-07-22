test_that("r_base::min and r_base::max merge partial states under parallel aggregation", {
  drv <- duckdb()
  con <- dbConnect(drv)
  on.exit(dbDisconnect(con, shutdown = TRUE))

  rapi_load_rfuns(drv@database_ref)
  dbExecute(con, "PRAGMA threads=4")

  # Enough rows for many row groups, so several thread-local aggregate
  # states are combined at the end of the aggregation.
  res <- dbGetQuery(
    con,
    'SELECT "r_base::min"(i) AS mn, "r_base::max"(i) AS mx
     FROM (SELECT range::INTEGER AS i FROM range(2000000)) t'
  )
  expect_identical(res$mn, 0L)
  expect_identical(res$mx, 1999999L)

  # Same for grouped aggregation, which combines states in the hash table.
  res <- dbGetQuery(
    con,
    'SELECT g, "r_base::min"(i) AS mn, "r_base::max"(i) AS mx
     FROM (SELECT range::INTEGER AS i, range % 2 AS g FROM range(2000000)) t
     GROUP BY g ORDER BY g'
  )
  expect_identical(res$mn, c(0L, 1L))
  expect_identical(res$mx, c(1999998L, 1999999L))
})

test_that("r_base::min and r_base::max propagate NA poisoning across partial states", {
  drv <- duckdb()
  con <- dbConnect(drv)
  on.exit(dbDisconnect(con, shutdown = TRUE))

  rapi_load_rfuns(drv@database_ref)
  dbExecute(con, "PRAGMA threads=4")

  # One NULL in the middle of the data: with na.rm = FALSE semantics the
  # whole result must be NA, also when the NULL is seen by only one of
  # several thread-local states.
  res <- dbGetQuery(
    con,
    'SELECT "r_base::min"(i) AS mn, "r_base::max"(i) AS mx
     FROM (
       SELECT CASE WHEN range = 1500000 THEN NULL ELSE range::INTEGER END AS i
       FROM range(2000000)
     ) t'
  )
  expect_identical(res$mn, NA_integer_)
  expect_identical(res$mx, NA_integer_)
})
