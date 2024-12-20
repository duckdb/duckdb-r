test_that("Data frame scan is off by default", {
  con <- dbConnect(duckdb())
  withr::defer(dbDisconnect(con))

  x <- data.frame(a = 1)
  expect_error(dbGetQuery(con, "FROM x"))
})

test_that("Can scan data frames as tables with dbGetQuery()", {
  con <- dbConnect(duckdb(environment_scan = TRUE))
  withr::defer(dbDisconnect(con))

  x <- data.frame(a = 1)
  expect_equal(dbGetQuery(con, "FROM x"), x)
  expect_error(dbGetQuery(con, "FROM y"))
})

test_that("Can scan data frames as tables with dbSendQuery()", {
  con <- dbConnect(duckdb(environment_scan = TRUE))
  withr::defer(dbDisconnect(con))

  x <- data.frame(a = 1)
  res <- dbSendQuery(con, "FROM x")
  withr::defer(dbClearResult(res))
  expect_equal(dbFetch(res), x)
})

test_that("Data frame scan fetches from the correct environment", {
  con <- dbConnect(duckdb(environment_scan = TRUE))
  on.exit(dbDisconnect(con))

  x <- data.frame(a = 1)

  fun <- function() {
    x <- data.frame(a = 2)
    dbGetQuery(con, "FROM x")
  }

  expect_equal(fun(), data.frame(a = 2))
  expect_equal(dbGetQuery(con, "FROM x"), x)
})

test_that("Function hides data frame", {
  con <- dbConnect(duckdb(environment_scan = TRUE))
  on.exit(dbDisconnect(con))

  x <- data.frame(a = 1)

  fun <- function() {
    x <- function() {}
    dbGetQuery(con, "FROM x")
  }

  expect_error(fun())
  expect_equal(dbGetQuery(con, "FROM x"), x)
})

test_that("Database tables take precedence", {
  con <- dbConnect(duckdb(environment_scan = TRUE))
  on.exit(dbDisconnect(con))

  dbWriteTable(con, "x", data.frame(a = 2))

  x <- data.frame(a = 1)

  expect_equal(dbGetQuery(con, "FROM x"), data.frame(a = 2))
})

test_that("Data frames scan survives garbage collection", {
  con <- dbConnect(duckdb(environment_scan = TRUE))
  withr::defer(dbDisconnect(con))

  x <- data.frame(a = 1)
  res <- dbSendQuery(con, "FROM x")
  rm(x)
  gc()
  gc()
  x <- data.frame(a = 2)
  withr::defer(dbClearResult(res))
  expect_equal(dbFetch(res), data.frame(a = 1))
})
