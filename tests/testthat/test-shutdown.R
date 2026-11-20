test_that("disconnect releases database file", {
  skip_if_not(TEST_RE2)

  db_path <- withr::local_tempfile(fileext = ".duckdb")
  pkg <- get_package_name()

  session_1 <- callr::r_session$new()
  withr::defer(session_1$kill())
  session_2 <- callr::r_session$new()
  withr::defer(session_2$kill())

  session_1$run(
    function(db_path, pkg) {
      .GlobalEnv$con <- DBI::dbConnect(asNamespace(pkg)$duckdb(), db_path)
      DBI::dbWriteTable(con, "test", data.frame(a = 1))
    },
    list(db_path = db_path, pkg = pkg)
  )

  expect_error(session_2$run(
    function(db_path, pkg) {
      .GlobalEnv$con <- DBI::dbConnect(asNamespace(pkg)$duckdb(), db_path)
    },
    list(db_path = db_path, pkg = pkg)
  ))

  session_1$run(function() {
    DBI::dbDisconnect(con, shutdown = TRUE)
  })

  session_2$run(
    function(db_path, pkg) {
      .GlobalEnv$con <- DBI::dbConnect(asNamespace(pkg)$duckdb(), db_path)
      DBI::dbDisconnect(con, shutdown = TRUE)
    },
    list(db_path = db_path, pkg = pkg)
  )
})

test_that("disconnect releases a result parked during an R callback (#2934)", {
  skip_on_cran()

  db_path <- withr::local_tempfile(fileext = ".duckdb")
  pkg <- get_package_name()

  con <- dbConnect(duckdb(db_path, environment_scan = TRUE))
  withr::defer(if (dbIsValid(con)) dbDisconnect(con))
  dbExecute(con, "CREATE TABLE t AS SELECT 42 AS x")

  # An Arrow-mode result holds its client context, and with it the database;
  # holding it needs no arrow package, only fetching from it would.
  holder <- new.env()
  holder$res <- dbSendQuery(con, "SELECT * FROM t", arrow = TRUE)

  # Forced by the environment scan while the binder runs R code:
  # the result's finalizer runs inside that callback, which parks the result.
  delayedAssign("parks_the_result", {
    holder$res <- NULL
    gc()
    NULL
  })
  expect_error(dbSendQuery(con, "SELECT * FROM parks_the_result"))
  expect_null(holder$res)

  # No other package call between the callback and the disconnect
  dbDisconnect(con, shutdown = TRUE)

  # Another process can open the file only once this one has let it go.
  # This process could open it either way: the file lock is per process.
  expect_no_error(callr::r(
    function(db_path, pkg) {
      con <- DBI::dbConnect(asNamespace(pkg)$duckdb(), db_path)
      DBI::dbDisconnect(con)
    },
    list(db_path = db_path, pkg = pkg)
  ))
})
