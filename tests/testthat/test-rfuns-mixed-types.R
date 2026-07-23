test_that("mixed-type overloads of r_base functions work", {
  drv <- duckdb()
  con <- dbConnect(drv)
  on.exit(dbDisconnect(con, shutdown = TRUE))

  rapi_load_rfuns(drv@database_ref)

  # These exercise the (INTEGER, DOUBLE) and (DOUBLE, INTEGER) overloads,
  # whose argument types are verified by BinaryTypeAssert() in builds with
  # assertions enabled.
  res <- dbGetQuery(
    con,
    'SELECT
       "r_base::+"(1::INTEGER, 2.5) AS add_id,
       "r_base::+"(2.5, 1::INTEGER) AS add_di,
       "r_base::<"(1::INTEGER, 2.5) AS lt_id,
       "r_base::>="(2.5, 3::INTEGER) AS ge_di,
       "r_base::=="(TRUE, 1::INTEGER) AS eq_bi'
  )
  expect_identical(res$add_id, 3.5)
  expect_identical(res$add_di, 3.5)
  expect_identical(res$lt_id, TRUE)
  expect_identical(res$ge_di, FALSE)
  expect_identical(res$eq_bi, TRUE)
})
