test_that("Data frame scan is off by default", {
  con <- local_con()

  x <- data.frame(a = 1)
  expect_error(dbGetQuery(con, "FROM x"))
})

test_that("Can scan data frames as tables with dbGetQuery()", {
  con <- local_con(drv = duckdb(environment_scan = TRUE))

  x <- data.frame(a = 1)
  expect_equal(dbGetQuery(con, "FROM x"), x)
  expect_error(dbGetQuery(con, "FROM y"))
})

test_that("Can scan data frames as tables with dbSendQuery()", {
  con <- local_con(drv = duckdb(environment_scan = TRUE))

  x <- data.frame(a = 1)
  res <- dbSendQuery(con, "FROM x")
  withr::defer(dbClearResult(res))
  expect_equal(dbFetch(res), x)
})

test_that("Data frame scan fetches from the correct environment", {
  con <- local_con(drv = duckdb(environment_scan = TRUE))

  x <- data.frame(a = 1)

  fun <- function() {
    x <- data.frame(a = 2)
    dbGetQuery(con, "FROM x")
  }

  expect_equal(fun(), data.frame(a = 2))
  expect_equal(dbGetQuery(con, "FROM x"), x)
})

test_that("Function hides data frame", {
  con <- local_con(drv = duckdb(environment_scan = TRUE))

  x <- data.frame(a = 1)

  fun <- function() {
    x <- function() {}
    dbGetQuery(con, "FROM x")
  }

  expect_error(fun())
  expect_equal(dbGetQuery(con, "FROM x"), x)
})

test_that("Database tables take precedence", {
  con <- local_con(drv = duckdb(environment_scan = TRUE))

  dbWriteTable(con, "x", data.frame(a = 2))

  x <- data.frame(a = 1)

  expect_equal(dbGetQuery(con, "FROM x"), data.frame(a = 2))
})

test_that("Data frames scan survives garbage collection", {
  con <- local_con(drv = duckdb(environment_scan = TRUE))

  x <- data.frame(a = 1)
  res <- dbSendQuery(con, "FROM x")
  rm(x)
  gc()
  gc()
  x <- data.frame(a = 2)
  withr::defer(dbClearResult(res))
  expect_equal(dbFetch(res), data.frame(a = 1))
})
