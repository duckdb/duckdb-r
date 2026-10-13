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

test_that("Data frame scan reads a packed ALTREP column that bind materialized", {
  # A registered ALTREP data frame's packed columns reach bind unread, so
  # before duckdb/duckdb-r#2582 the scan materialized them itself, on a DuckDB
  # task thread: wrong sums for a numeric field, a killed session for a
  # character one. The scan starts a second task at a million rows, which is
  # what puts two threads on the same column; the subprocess is so that a
  # regression is a failure here rather than a suite that stops.
  pkg <- get_package_name()

  out <- callr::r(
    function(pkg) {
      ns <- asNamespace(pkg)

      con_src <- DBI::dbConnect(ns$duckdb())
      on.exit(DBI::dbDisconnect(con_src, shutdown = TRUE), add = TRUE)

      sql <- paste(
        "SELECT {'a': i, 't': 'row-' || i} AS s",
        "FROM range(2000000) t(i)"
      )
      agg <- "SELECT sum(s.a) AS a, sum(length(s.t)) AS t"
      expected <- DBI::dbGetQuery(con_src, paste0(agg, " FROM (", sql, ")"))

      df <- ns$rel_to_altrep(ns$rel_from_sql(con_src, sql))
      # Runs the relation, and leaves the column transforms undone
      stopifnot(nrow(df) == 2000000)

      con_scan <- DBI::dbConnect(ns$duckdb())
      on.exit(DBI::dbDisconnect(con_scan, shutdown = TRUE), add = TRUE)
      DBI::dbExecute(con_scan, "SET threads=4")
      ns$duckdb_register(con_scan, "packed", df)

      list(
        expected = expected,
        actual = DBI::dbGetQuery(con_scan, paste0(agg, " FROM packed"))
      )
    },
    list(pkg = pkg)
  )

  expect_equal(out$actual, out$expected)
})

test_that("Data frame scan reads list cells of data frames and factors from several tasks", {
  # The scan converts a list cell on a DuckDB task thread, and it detected a
  # data frame cell's or a factor cell's type through cpp11 vectors, which
  # allocate and link themselves into cpp11's one protection list. Two tasks
  # on one list column raced on it, and the session crashed or hung. The
  # subprocess and its timeout are so that a regression is a failure here
  # rather than a suite that stops.
  pkg <- get_package_name()

  out <- callr::r(
    function(pkg) {
      ns <- asNamespace(pkg)

      con <- DBI::dbConnect(ns$duckdb())
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
      DBI::dbExecute(con, "SET threads=4")

      n <- 2000000
      df <- data.frame(id = seq_len(n))
      df$d <- rep(list(data.frame(a = 1:2)), n)
      df$f <- rep(list(factor(c("x", "y"))), n)
      ns$duckdb_register(con, "cells", df)

      DBI::dbGetQuery(
        con,
        "SELECT sum(len(d))::INTEGER AS d, sum(len(f))::INTEGER AS f FROM cells"
      )
    },
    list(pkg = pkg),
    timeout = 120
  )

  expect_equal(out, data.frame(d = 4000000L, f = 4000000L))
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

test_that("the environment scan binds with the connection's options (#2646)", {
  # The replacement scan runs inside the engine, which is handed the
  # database rather than the connection the options live on; without them
  # the same data frame arrives as different types depending on how it was
  # named -- and an `integer64` arrives as the double its bits spell.
  skip_if_not_installed("bit64")
  skip_if_not_installed("vctrs")

  con <- local_con(
    drv = duckdb(environment_scan = TRUE),
    bigint = "integer64",
    map = "list_of"
  )

  types <- function(name) {
    dbGetQuery(con, paste0("DESCRIBE FROM ", name))$column_type
  }
  agrees <- function(df, name) {
    duckdb_register(con, "registered", df)
    withr::defer(duckdb_unregister(con, "registered"))
    expect_equal(types(name), types("registered"))
  }

  big <- bit64::as.integer64("9007199254740993")
  scanned_i64 <- data.frame(a = big)
  agrees(scanned_i64, "scanned_i64")
  expect_equal(dbGetQuery(con, "FROM scanned_i64")$a, big)

  scanned_map <- data.frame(row = 1L)
  scanned_map$m <- list(list(k = 1L))
  agrees(scanned_map, "scanned_map")

  scanned_ts <- data.frame(a = as.POSIXct("2024-01-10 13:03:12", tz = "UTC"))
  agrees(scanned_ts, "scanned_ts")
})

test_that("the environment scan takes an `integer64` as BIGINT whatever `bigint` says", {
  # Registration does since #2819, so a default connection, which reads
  # BIGINT as numeric, has to write it the same way on both paths.
  skip_if_not_installed("bit64")

  con <- local_con(drv = duckdb(environment_scan = TRUE))

  scanned_i64 <- data.frame(a = bit64::as.integer64(c("9007199254740993", NA)))
  res <- dbGetQuery(
    con,
    "SELECT typeof(a) AS t, a::VARCHAR AS v FROM scanned_i64"
  )
  expect_equal(res$t, c("BIGINT", "BIGINT"))
  expect_equal(res$v, c("9007199254740993", NA))
})
