test_that("na.rm argument of r_base aggregates is honored in SQL queries", {
  drv <- duckdb()
  con <- dbConnect(drv)
  on.exit(dbDisconnect(con, shutdown = TRUE))

  rapi_load_rfuns(drv@database_ref)

  res <- dbGetQuery(
    con,
    'SELECT
       "r_base::sum"(i, true) AS s_rm, "r_base::sum"(i, false) AS s,
       "r_base::min"(i, true) AS mn_rm, "r_base::min"(i, false) AS mn,
       "r_base::max"(i, true) AS mx_rm, "r_base::max"(i, false) AS mx
     FROM (VALUES (1), (NULL), (3)) t(i)'
  )
  expect_identical(res$s_rm, 4)
  expect_identical(res$s, NA_real_)
  expect_identical(res$mn_rm, 1L)
  expect_identical(res$mn, NA_integer_)
  expect_identical(res$mx_rm, 3L)
  expect_identical(res$mx, NA_integer_)
})

test_that("na.rm argument of r_base aggregates must be a constant", {
  drv <- duckdb()
  con <- dbConnect(drv)
  on.exit(dbDisconnect(con, shutdown = TRUE))

  rapi_load_rfuns(drv@database_ref)

  expect_error(
    dbGetQuery(con, 'SELECT "r_base::sum"(i, i > 1) FROM (VALUES (1)) t(i)'),
    "na.rm"
  )
  expect_error(
    dbGetQuery(con, 'SELECT "r_base::min"(i, NULL) FROM (VALUES (1)) t(i)'),
    "na.rm"
  )
})
