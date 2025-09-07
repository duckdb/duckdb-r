test_that("read_only flag and shutdown works as expected", {
  skip_if_not(TEST_RE2)

  dbdir <- tempfile()

  # 1st: create a db and write some tables

  callr::r(function(dbdir) {
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir, read_only = FALSE) # FALSE is the default
    print(con)
    res <- DBI::dbWriteTable(con, "iris", iris)
    DBI::dbDisconnect(con)
    duckdb::duckdb_shutdown(con@driver)
  }, args = list(dbdir))


  # 2nd: start two parallel read-only references
  drv <- duckdb(dbdir, read_only = TRUE)
  con <- dbConnect(drv)

  res <- dbReadTable(con, "iris")


  # can have another conn on this drv
  con2 <- dbConnect(drv)
  res <- dbReadTable(con2, "iris")

  # con is still alive
  callr::r(function(dbdir) {
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir, read_only = TRUE)
    res <- DBI::dbReadTable(con, "iris")
    DBI::dbDisconnect(con, shutdown = TRUE)
  }, args = list(dbdir))

  # shut down one of them again
  res <- dbReadTable(con, "iris")

  dbDisconnect(con)
  dbDisconnect(con2, shutdown = TRUE)


  # now we can get write access again
  # TODO shutdown
  callr::r(function(dbdir) {
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir, read_only = FALSE) # FALSE is the default
    res <- DBI::dbWriteTable(con, "iris2", iris)
    DBI::dbDisconnect(con)
  }, args = list(dbdir))

  expect_true(TRUE)
})

test_that("read_only flag does not throw error when rel_sql is called", {
  db_path <- withr::local_tempfile(pattern = "readonly", fileext = ".duckdb")

  con <- local_con(db_path)
  # just need a db to open in read only mode
  dbExecute(con, "create table t1 as select range a from range(2)")
  dbDisconnect(con)

  con <- local_con(db_path, read_only=TRUE)
  rel <- rel_from_df(con, data.frame(a = 1:2, b = 2:3, c = 4:5))
  ans <- data.frame(a = 1L, b = 2L)
  expect_rel2 <- rel_sql(rel, "SELECT a, b FROM _ where c = 4")
  expect_equivalent(expect_rel2, ans)
  dbDisconnect(con)
})

test_that("read_only flag still throws error when table is attempted to be created", {
  db_path <- withr::local_tempfile(pattern = "readonly", fileext = ".duckdb")

  con <- local_con(db_path)
  # just need a db to open in read only mode
  dbExecute(con, "create table t1 as select range a from range(2)")
  dbDisconnect(con)

  con <- local_con(db_path, read_only = TRUE)
  ans <- data.frame(a = 1L, b = 2L)
  expect_error(rel_sql(rel, "SELECT a, b FROM _ where c = 4"))
  dbDisconnect(con)
})
