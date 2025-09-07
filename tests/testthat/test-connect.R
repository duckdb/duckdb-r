# Run the first two tests manually

test_that("warning on garbage-collecting unused driver", {
  # Needs to run manually because these warnings can't be caught
  skip_if_not(interactive())

  duckdb()
  expect_null(NULL)
  # Expecting warning: "Database is garbage-collected"
  gc()
})

test_that("warning on garbage-collecting open connection", {
  # Needs to run manually because these warnings can't be caught
  skip_if_not(interactive())

  dbConnect(duckdb())
  expect_null(NULL)
  # Expecting warning: "Connection is garbage-collected", but not "Database ..."
  gc()
})

test_that("no warning after duckdb_shutdown() for unused driver", {
  duckdb_shutdown(duckdb())

  # The warning won't occur here anyway, this is to keep testthat happy
  expect_warning(gc(), NA)
})

test_that("no warning after dbDisconnect() for used driver", {
  con <- dbConnect(duckdb())
  dbDisconnect(con)

  # The warning won't occur here anyway, this is to keep testthat happy
  expect_warning(gc(), NA)
})

test_that("no warning after dbDisconnect() for driver stored in variable", {
  drv <- duckdb()
  con <- dbConnect(drv)
  dbDisconnect(con)

  # The warning won't occur here anyway, this is to keep testthat happy
  expect_warning(gc(), NA)

  rm(drv)
  expect_warning(gc(), NA)
})

test_that("no warning on dbConnect() with other dbdir", {
  con <- dbConnect(duckdb(), tempfile(fileext = ".duckdb"))
  dbDisconnect(con)

  # The warning won't occur here anyway, this is to keep testthat happy
  expect_warning(gc(), NA)
})

test_that("can connect to the same in-memory database via the same driver object", {
  skip_if_not(TEST_RE2)

  drv <- duckdb()

  con1 <- dbConnect(drv)
  on.exit(dbDisconnect(con1), add = TRUE)
  dbWriteTable(con1, "x", data.frame(a = 1:3))

  con2 <- dbConnect(drv)
  on.exit(dbDisconnect(con2), add = TRUE)

  expect_equal(dbReadTable(con2, "x"), data.frame(a = 1:3))

  dbWriteTable(con2, "y", data.frame(b = 1:3))
  expect_equal(dbReadTable(con1, "y"), data.frame(b = 1:3))

  gc()
})

test_that("will connect to different in-memory databases via different driver objects", {
  skip_if_not(TEST_RE2)

  drv1 <- duckdb()
  con1 <- dbConnect(drv1)
  on.exit(dbDisconnect(con1), add = TRUE)
  dbWriteTable(con1, "x", data.frame(a = 1:3))

  drv2 <- duckdb()
  con2 <- dbConnect(drv2)
  on.exit(dbDisconnect(con2), add = TRUE)

  expect_false(dbExistsTable(con2, "x"))

  dbWriteTable(con2, "y", data.frame(b = 1:3))
  expect_false(dbExistsTable(con1, "y"))

  gc()
})

test_that("can connect to the same database file via the same driver object", {
  skip_if_not(TEST_RE2)

  drv <- duckdb(tempfile(fileext = ".duckdb"))

  con1 <- dbConnect(drv)
  on.exit(dbDisconnect(con1), add = TRUE)
  dbWriteTable(con1, "x", data.frame(a = 1:3))

  con2 <- dbConnect(drv)
  on.exit(dbDisconnect(con2), add = TRUE)

  expect_equal(dbReadTable(con2, "x"), data.frame(a = 1:3))

  dbWriteTable(con2, "y", data.frame(b = 1:3))
  expect_equal(dbReadTable(con1, "y"), data.frame(b = 1:3))

  gc()
})

test_that("can connect to the same database file via different driver objects", {
  skip_if_not(TEST_RE2)

  path <- tempfile(fileext = ".duckdb")
  writeLines(character(), path)
  path <- normalizePath(path)
  unlink(path)

  drv1 <- duckdb(path)
  con1 <- dbConnect(drv1)
  on.exit(dbDisconnect(con1), add = TRUE)
  dbWriteTable(con1, "x", data.frame(a = 1:3))

  drv2 <- duckdb(path)
  con2 <- dbConnect(drv2)
  on.exit(dbDisconnect(con2), add = TRUE)

  expect_equal(dbReadTable(con2, "x"), data.frame(a = 1:3))

  dbWriteTable(con2, "y", data.frame(b = 1:3))
  expect_equal(dbReadTable(con1, "y"), data.frame(b = 1:3))

  gc()
})

test_that("read_only only applies to the first driver object for a path", {
  skip_if_not(TEST_RE2)

  path <- tempfile(fileext = ".duckdb")
  writeLines(character(), path)
  path <- normalizePath(path)
  unlink(path)

  drv1 <- duckdb(path)
  con1 <- dbConnect(drv1)
  on.exit(dbDisconnect(con1), add = TRUE)
  dbWriteTable(con1, "y", data.frame(b = 1:3))

  drv2 <- duckdb(path, read_only = TRUE)
  con2 <- dbConnect(drv2)
  on.exit(dbDisconnect(con2), add = TRUE)

  dbWriteTable(con2, "x", data.frame(a = 1:3))
  expect_equal(dbReadTable(con1, "x"), data.frame(a = 1:3))

  gc()
})

test_that("config only applies to the first driver object for a path", {
  skip_if_not(TEST_RE2)

  path <- tempfile(fileext = ".duckdb")
  writeLines(character(), path)
  path <- normalizePath(path)
  unlink(path)

  drv1 <- duckdb(path)
  con1 <- dbConnect(drv1)
  on.exit(dbDisconnect(con1), add = TRUE)
  dbWriteTable(con1, "x", data.frame(a = 1:3))

  drv2 <- duckdb(path, config = list(default_order = "DESC"))
  con2 <- dbConnect(drv2)
  on.exit(dbDisconnect(con2), add = TRUE)
  expect_equal(dbGetQuery(con2, "SELECT * FROM x ORDER BY a"), data.frame(a = 1:3))

  gc()
})

test_that("user agent is set to r", {
  skip_if_not(TEST_RE2)

  drv <- duckdb()
  con <- dbConnect(drv)
  expect_match(dbGetQuery(con, "PRAGMA user_agent")[1, "user_agent"], "duckdb/.*(.*) r-dbi")

  gc()
})
