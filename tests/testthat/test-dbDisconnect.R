# `dbDisconnect()` closes the results still open on the connection, so that no
# result keeps the connection's session, and the database instance with it,
# alive past the connection (handbook/architecture/glue/objects/README.md).
# DBI asks for the results to be cleared first, and for a warning otherwise.

# A connection the test closes itself, to see what `dbDisconnect()` says.
# The deferred close is for a test that fails before it gets there.
connect_here <- function(drv = duckdb(), env = parent.frame()) {
  con <- dbConnect(drv)
  withr::defer(
    if (dbIsValid(con)) {
      suppressWarnings(dbDisconnect(con))
    },
    envir = env
  )
  con
}

test_that("dbDisconnect() closes the results still open on the connection", {
  con <- connect_here()
  res <- dbSendQuery(con, "SELECT ? AS a", params = list(1L))
  expect_true(dbIsValid(res))

  expect_warning(dbDisconnect(con), "1 result was still open")

  expect_false(dbIsValid(res))
  closed <- "connection this result was sent on has been closed"
  expect_error(dbFetch(res), closed)
  expect_error(dbBind(res, list(2L)), closed)
  expect_error(dbHasCompleted(res), closed)
  expect_error(dbGetRowCount(res), closed)
  expect_error(dbGetRowsAffected(res), closed)
  expect_error(dbColumnInfo(res), closed)
  expect_error(dbGetStatement(res), closed)

  # Clearing late is the caller catching up, not a mistake.
  expect_no_warning(dbClearResult(res))
  expect_false(dbIsValid(res))
  expect_warning(dbClearResult(res), "cleared already")
})

test_that("dbDisconnect() is silent once every result is cleared", {
  con <- connect_here()
  res <- dbSendQuery(con, "SELECT 1 AS a")
  dbClearResult(res)
  expect_no_warning(dbDisconnect(con))
})

test_that("a statement that fails at send time leaves no result open", {
  con <- connect_here()

  # Fails as it runs, after the result exists; the caller never receives it.
  expect_error(dbGetQuery(con, "SELECT chr(0)"))
  # Fails at the bind that `params` asks for, the same way.
  expect_error(dbGetQuery(con, "SELECT ?::INTEGER", params = list("x")))
  expect_error(dbExecute(con, "SELECT ?::INTEGER", params = list(1, 2)))

  expect_no_warning(dbDisconnect(con))
})

test_that("the warning counts the results still open", {
  con <- connect_here()
  res1 <- dbSendQuery(con, "SELECT 1 AS a")
  res2 <- dbSendQuery(con, "SELECT 2 AS a")
  expect_warning(dbDisconnect(con), "2 results were still open")
  expect_false(dbIsValid(res1))
  expect_false(dbIsValid(res2))
})

test_that("a streaming result closes with its connection", {
  skip_if_not_installed("nanoarrow")

  con <- connect_here()
  res <- dbSendQueryArrow(con, "SELECT * FROM range(100000) t(a)")
  expect_equal(dbFetchArrowChunk(res, chunk_size = 10)$length, 10L)

  expect_warning(dbDisconnect(con), "1 result was still open")

  expect_false(dbIsValid(res))
  closed <- "connection this result was sent on has been closed"
  expect_error(dbFetchArrowChunk(res), closed)
  expect_error(dbFetchArrow(res), closed)
  expect_error(dbHasCompleted(res), closed)
  expect_error(dbBind(res, list()), closed)
  expect_no_warning(dbClearResult(res))
})

test_that("a stream handed over by dbFetchArrow() reports the closed connection instead of reading on", {
  skip_if_not_installed("nanoarrow")

  con <- connect_here()
  res <- dbSendQueryArrow(con, "SELECT * FROM range(100000) t(a)")
  stream <- dbFetchArrow(res, chunk_size = 10)
  expect_equal(stream$get_next()$length, 10L)

  expect_warning(dbDisconnect(con), "1 result was still open")

  closed <- "connection this result was sent on has been closed"
  expect_error(stream$get_next(), closed)
  expect_error(stream$get_next(), closed)
  expect_no_warning(dbClearResult(res))
})

test_that("a record batch reader from the legacy arrow route reports the closed connection", {
  skip_if_not_installed("arrow")

  con <- connect_here()
  res <- dbSendQuery(con, "SELECT * FROM range(100000) t(a)", arrow = TRUE)
  reader <- duckdb_fetch_record_batch(res, chunk_size = 10)
  expect_equal(reader$read_next_batch()$num_rows, 10L)

  expect_warning(dbDisconnect(con), "1 result was still open")

  expect_error(reader$read_next_batch(), "closed")
  expect_no_warning(dbClearResult(res))
})

test_that("no result keeps a file database open past its connection", {
  skip_if_not_installed("callr")

  path <- file.path(withr::local_tempdir(), "db.duckdb")
  pkg <- get_package_name()

  # Opens the file from another process, which is where a lingering instance
  # shows: the lock the engine takes on the file is held per process.
  opens_elsewhere <- function() {
    callr::r(
      function(path, pkg) {
        con <- DBI::dbConnect(asNamespace(pkg)$duckdb(path))
        DBI::dbDisconnect(con)
        TRUE
      },
      args = list(path = path, pkg = pkg),
      timeout = 60
    )
  }

  drv <- duckdb(path)
  con <- connect_here(drv)
  res <- dbSendQuery(
    con,
    "SELECT count(*) AS n FROM duckdb_tables() WHERE table_name = ?",
    params = list("u")
  )
  expect_equal(dbFetch(res)$n, 0)

  expect_warning(dbDisconnect(con), "1 result was still open")

  # The instance went with the connection: the driver holds nothing, and the
  # file is free. Before, the result held the instance, the driver said the
  # same, and another process was refused the file.
  expect_false(dbIsValid(drv))
  expect_true(opens_elsewhere())

  # A new driver on the path opens the one instance there is, which the old
  # result cannot reach: before, it re-executed on an instance of its own,
  # blind to this one.
  con2 <- connect_here(duckdb(path))
  dbExecute(con2, "CREATE TABLE u (x INTEGER)")
  expect_error(
    dbBind(res, list("u")),
    "connection this result was sent on has been closed"
  )
  expect_no_warning(dbClearResult(res))

  expect_no_warning(dbDisconnect(con2))
  expect_true(opens_elsewhere())
})
