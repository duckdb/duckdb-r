skip_on_cran()
local_edition(3)

test_that("empty statement gives an error", {
  con <- local_con()
  expect_snapshot_error(DBI::dbGetQuery(con, "; ;   ; -- SELECT 1;"))
})

test_that("multiple statements can be used in one call", {
  con <- local_con()
  query <- paste(
    "CREATE TABLE integers(i integer);",
    "insert into integers select * from range(10);",
    "select * from integers;",
    sep = "\n"
  )
  expect_identical(DBI::dbGetQuery(con, query), data.frame(i = 0:9))
  expect_snapshot(DBI::dbGetQuery(
    con,
    paste("DROP TABLE IF EXISTS integers;", query)
  ))
})

test_that("a pragma sees earlier statements in the same call", {
  con <- local_con()
  export_location <- tempfile("duckdb-multi-statement-export-")
  on.exit(unlink(export_location, recursive = TRUE))
  DBI::dbExecute(con, "CREATE TABLE integers AS SELECT 42 AS i")

  query <- sprintf(
    "EXPORT DATABASE '%s'; DROP TABLE integers; PRAGMA import_database('%s')",
    export_location,
    export_location
  )
  DBI::dbExecute(con, query)

  expect_identical(
    DBI::dbGetQuery(con, "SELECT i FROM integers"),
    data.frame(i = 42L)
  )
})

test_that("a LOAD in a pragma's expansion is refused before any of it runs", {
  drv <- duckdb(allow_extensions = FALSE)
  con <- local_con(drv = drv)
  other <- local_con(drv = drv)
  import_location <- withr::local_tempdir()
  writeLines(
    "CREATE TABLE from_import (i INTEGER); LOAD parquet;",
    file.path(import_location, "schema.sql")
  )
  writeLines("", file.path(import_location, "load.sql"))

  query <- sprintf("PRAGMA import_database('%s')", import_location)
  expect_error(DBI::dbExecute(con, query), "disabled")
  expect_false(DBI::dbExistsTable(con, "from_import"))

  # Refused part-way, the expansion's implicit BEGIN stayed open,
  # and work that followed on the connection was never committed.
  DBI::dbExecute(con, "CREATE TABLE user_work AS SELECT 1 AS i")
  expect_true(DBI::dbExistsTable(other, "user_work"))
})

test_that("a failure inside a pragma's expansion rolls back what it began", {
  con <- local_con()
  export_location <- withr::local_tempdir()
  DBI::dbExecute(con, "CREATE TABLE integers (i INTEGER)")
  DBI::dbExecute(con, sprintf("EXPORT DATABASE '%s'", export_location))
  DBI::dbExecute(con, "DROP TABLE integers")
  csv <- list.files(export_location, pattern = "[.]csv$", full.names = TRUE)
  writeLines(c("i", "not_an_integer"), csv)

  query <- sprintf("PRAGMA import_database('%s')", export_location)
  expect_error(DBI::dbExecute(con, query), "not_an_integer")

  # Left open, the aborted transaction failed every later statement.
  expect_identical(DBI::dbListTables(con), character())
})

test_that("a pragma that expands to nothing can end a call", {
  con <- local_con()
  export_location <- withr::local_tempdir()
  DBI::dbExecute(con, sprintf("EXPORT DATABASE '%s'", export_location))
  pragma <- sprintf("PRAGMA import_database('%s')", export_location)

  # The last statement is the call's result, as for any other PRAGMA.
  query <- paste("CREATE TABLE integers (i INTEGER);", pragma)
  expect_identical(
    DBI::dbGetQuery(con, query),
    DBI::dbGetQuery(con, "PRAGMA disable_checkpoint_on_shutdown")
  )
  expect_true(DBI::dbExistsTable(con, "integers"))

  query <- paste("INSERT INTO integers VALUES (1), (2);", pragma)
  expect_identical(DBI::dbExecute(con, query), 0)
  expect_identical(
    DBI::dbGetQuery(con, "SELECT i FROM integers"),
    data.frame(i = 1:2)
  )

  expect_identical(DBI::dbExecute(con, pragma), 0)
})

test_that("statements can be splitted apart correctly", {
  con <- local_con()
  expect_snapshot(DBI::dbGetQuery(
    con,
    a <- paste(
      "--Multistatement testing; testing",
      "/*  test;   ",
      "--test;",
      ";test */",
      "create table temp_test as ",
      "select",
      "'testing_temp;' as temp_col",
      ";",
      "select * from temp_test;",
      sep = "\n"
    )
  ))
})

test_that("export/import database works", {
  skip_if_not(TEST_RE2)

  export_location <- file.path(tempdir(), "duckdb_test_export")
  if (!file.exists(export_location)) {
    dir.create(export_location)
  }

  con <- local_con()
  DBI::dbExecute(con, "CREATE TABLE integers(i integer)")
  DBI::dbExecute(con, "insert into integers select * from range(10)")
  DBI::dbExecute(con, "CREATE TABLE integers2(i INTEGER)")
  DBI::dbExecute(con, "INSERT INTO integers2 VALUES (1), (5), (7), (1928)")
  DBI::dbExecute(con, paste0("EXPORT DATABASE '", export_location, "'"))
  DBI::dbDisconnect(con, shutdown = TRUE)

  con <- local_con()

  DBI::dbExecute(con, paste0("IMPORT DATABASE '", export_location, "'"))
  if (file.exists(export_location)) {
    unlink(export_location, recursive = TRUE)
  }

  expect_identical(
    DBI::dbGetQuery(con, "select * from integers"),
    data.frame(i = 0:9)
  )
  expect_identical(
    DBI::dbGetQuery(con, "select * from integers2"),
    data.frame(i = c(1L, 5L, 7L, 1928L))
  )
})
