test_that("r_base::sum merges partial states under parallel aggregation", {
  drv <- duckdb()
  con <- dbConnect(drv)
  on.exit(dbDisconnect(con, shutdown = TRUE))

  rapi_load_rfuns(drv@database_ref)
  dbExecute(con, "PRAGMA threads=4")

  # Enough rows for many row groups, so several thread-local aggregate
  # states are combined at the end of the aggregation.
  res <- dbGetQuery(
    con,
    'SELECT "r_base::sum"(i) AS s, "r_base::sum"(i::DOUBLE) AS sd, "r_base::sum"(i % 2 = 0) AS sb
     FROM (SELECT range::INTEGER AS i FROM range(2000000)) t'
  )
  expect_identical(res$s, 1999999000000)
  expect_identical(res$sd, 1999999000000)
  expect_identical(res$sb, 1000000L)

  # Same for grouped aggregation, which combines states in the hash table.
  res <- dbGetQuery(
    con,
    'SELECT g, "r_base::sum"(i) AS s
     FROM (SELECT range::INTEGER AS i, range % 2 AS g FROM range(2000000)) t
     GROUP BY g ORDER BY g'
  )
  expect_identical(res$s, c(999999000000, 1000000000000))
})

test_that("r_base::sum propagates NA poisoning across partial states", {
  drv <- duckdb()
  con <- dbConnect(drv)
  on.exit(dbDisconnect(con, shutdown = TRUE))

  rapi_load_rfuns(drv@database_ref)
  dbExecute(con, "PRAGMA threads=4")

  # One NULL in the middle of the data: with na.rm = FALSE semantics the
  # result must be NA, also when the NULL is seen by only one of several
  # thread-local states.
  res <- dbGetQuery(
    con,
    'SELECT "r_base::sum"(i) AS s
     FROM (
       SELECT CASE WHEN range = 1500000 THEN NULL ELSE range::INTEGER END AS i
       FROM range(2000000)
     ) t'
  )
  expect_identical(res$s, NA_real_)
})
