skip_on_cran()

if (rlang::is_installed("dbplyr")) {
  `%>%` <- dplyr::`%>%`
}

test_that("Parquet files can be registered with dplyr::tbl()", {
  skip_if_not(TEST_RE2)

  skip_if_not_installed("dbplyr")

  con <- local_con()

  tab0 <- dplyr::tbl(con, "data/userdata1.parquet")
  expect_true(inherits(tab0, "tbl_duckdb_connection"))
  expect_true(tab0 %>% dplyr::count() %>% dplyr::collect() == 1000)

  tab1 <- dplyr::tbl(con, "read_parquet(['data/userdata1.parquet'])")
  expect_true(inherits(tab1, "tbl_duckdb_connection"))
  expect_true(tab1 %>% dplyr::count() %>% dplyr::collect() == 1000)

  tab2 <- dplyr::tbl(con, "'data/userdata1.parquet'")
  expect_true(inherits(tab2, "tbl_duckdb_connection"))
  expect_true(tab2 %>% dplyr::count() %>% dplyr::collect() == 1000)

  tab3 <- dplyr::tbl(con, "parquet_scan(['data/userdata1.parquet'])")
  expect_true(inherits(tab3, "tbl_duckdb_connection"))
  expect_true(tab3 %>% dplyr::count() %>% dplyr::collect() == 1000)
})

test_that("Parquet files can be registered with tbl_file() and tbl_function()", {
  skip_if_not_installed("dbplyr")

  con <- local_con()

  tab0 <- tbl_file(con, "data/userdata1.parquet")
  expect_true(inherits(tab0, "tbl_duckdb_connection"))
  expect_true(tab0 %>% dplyr::count() %>% dplyr::collect() == 1000)

  tab1 <- tbl_function(con, "read_parquet(['data/userdata1.parquet'])")
  expect_true(inherits(tab1, "tbl_duckdb_connection"))
  expect_true(tab1 %>% dplyr::count() %>% dplyr::collect() == 1000)

  tab2 <- tbl_function(con, "'data/userdata1.parquet'")
  expect_true(inherits(tab2, "tbl_duckdb_connection"))
  expect_true(tab2 %>% dplyr::count() %>% dplyr::collect() == 1000)

  tab3 <- tbl_function(con, "parquet_scan(['data/userdata1.parquet'])")
  expect_true(inherits(tab3, "tbl_duckdb_connection"))
  expect_true(tab3 %>% dplyr::count() %>% dplyr::collect() == 1000)
})


test_that("Object cache can be enabled for parquet files with dplyr::tbl()", {
  skip_if_not_installed("dbplyr")
  # https://github.com/tidyverse/dbplyr/issues/1384
  skip_if(packageVersion("dbplyr") >= "2.4.0")

  DBI::dbExecute(con, "SET enable_object_cache=False;")
  tab1 <- dplyr::tbl(con, "data/userdata1.parquet", cache = TRUE)
  expect_true(
    DBI::dbGetQuery(
      con,
      "SELECT value FROM duckdb_settings() WHERE name='enable_object_cache';"
    ) ==
      "true"
  )

  DBI::dbExecute(con, "SET enable_object_cache=False;")
  tab2 <- dplyr::tbl(con, "'data/userdata1.parquet'", cache = FALSE)
  expect_true(
    DBI::dbGetQuery(
      con,
      "SELECT value FROM duckdb_settings() WHERE name='enable_object_cache';"
    ) ==
      "false"
  )
})

test_that("Object cache can be enabled for parquet files with tbl_file() and tbl_function()", {
  skip_if_not_installed("dbplyr")
  # https://github.com/tidyverse/dbplyr/issues/1384
  skip_if(packageVersion("dbplyr") >= "2.4.0")

  DBI::dbExecute(con, "SET enable_object_cache=False;")
  tab1 <- tbl_file(con, "data/userdata1.parquet", cache = TRUE)
  expect_true(
    DBI::dbGetQuery(
      con,
      "SELECT value FROM duckdb_settings() WHERE name='enable_object_cache';"
    ) ==
      "true"
  )

  DBI::dbExecute(con, "SET enable_object_cache=False;")
  tab2 <- tbl_function(con, "'data/userdata1.parquet'", cache = FALSE)
  expect_true(
    DBI::dbGetQuery(
      con,
      "SELECT value FROM duckdb_settings() WHERE name='enable_object_cache';"
    ) ==
      "false"
  )
})


test_that("CSV files can be registered with dplyr::tbl()", {
  skip_if_not(TEST_RE2)

  skip_if_not_installed("dbplyr")

  path <- file.path(tempdir(), "duckdbtest.csv")
  write.csv(iris, file = path)
  on.exit(unlink(path))

  con <- local_con()

  tab1 <- dplyr::tbl(con, path)
  expect_true(inherits(tab1, "tbl_duckdb_connection"))
  expect_true(tab1 %>% dplyr::count() %>% dplyr::collect() == 150)

  tab2 <- dplyr::tbl(con, paste0("read_csv_auto('", path, "')"))
  expect_true(inherits(tab2, "tbl_duckdb_connection"))
  expect_true(tab2 %>% dplyr::count() %>% dplyr::collect() == 150)
})

test_that("CSV files can be registered with tbl_file() and tbl_function()", {
  skip_if_not_installed("dbplyr")

  path <- file.path(tempdir(), "duckdbtest.csv")
  write.csv(iris, file = path)
  on.exit(unlink(path))

  con <- local_con()

  tab1 <- tbl_file(con, path)
  expect_true(inherits(tab1, "tbl_duckdb_connection"))
  expect_true(tab1 %>% dplyr::count() %>% dplyr::collect() == 150)

  tab2 <- tbl_function(con, paste0("read_csv_auto('", path, "')"))
  expect_true(inherits(tab2, "tbl_duckdb_connection"))
  expect_true(tab2 %>% dplyr::count() %>% dplyr::collect() == 150)
})


test_that("Files use the default connection", {
  skip_if_not_installed("dbplyr")

  path <- file.path(tempdir(), "duckdbtest.csv")
  write.csv(iris, file = path)
  on.exit(unlink(path))

  tab1 <- tbl_file(path = path)
  expect_identical(dbplyr::remote_con(tab1), default_conn())
  expect_true(tab1 %>% dplyr::count() %>% dplyr::collect() == 150)
})


test_that("Other replacement scans or functions can be registered with dplyr::tbl()", {
  skip_if_not(TEST_RE2)

  skip_if_not_installed("dbplyr")

  con <- local_con()

  obj <- dplyr::tbl(con, "duckdb_keywords()")
  expect_true(inherits(obj, "tbl_duckdb_connection"))
  expect_true(
    obj %>%
      dplyr::filter(keyword_name == "all") %>%
      dplyr::count() %>%
      dplyr::collect() ==
      1
  )
})

test_that("Other replacement scans or functions can be registered with tbl_function()", {
  skip_if_not_installed("dbplyr")

  con <- local_con()

  obj <- tbl_function(con, "duckdb_keywords()")
  expect_true(inherits(obj, "tbl_duckdb_connection"))
  expect_true(
    obj %>%
      dplyr::filter(keyword_name == "all") %>%
      dplyr::count() %>%
      dplyr::collect() ==
      1
  )
})


test_that("Strings tagged as SQL will be handled correctly with dplyr::tbl()", {
  skip_if_not_installed("dbplyr")

  con <- local_con()

  rs <- dplyr::tbl(con, dplyr::sql("SELECT 1"))
  expect_true(inherits(rs, "tbl_duckdb_connection"))
  expect_true(rs %>% dplyr::collect() == 1)
})

test_that("tbl_file() errors on erroneous paths and unapplicable wildcard use", {
  skip_if_not_installed("dbplyr")

  con <- local_con()

  expect_error(tbl_file(con, "data/userdata2.parquet"))
  expect_error(tbl_file(con, "data/bogus*.parquet"))
})

test_that("dplyr::tbl() opens an I() schema-qualified table name (#2973)", {
  skip_if_not_installed("dbplyr")

  con <- local_con()
  DBI::dbExecute(con, "CREATE SCHEMA s")
  DBI::dbWriteTable(con, DBI::Id(schema = "s", table = "t"), data.frame(x = 1))

  tab <- dplyr::tbl(con, I("s.t"))
  expect_s3_class(tab, "tbl_duckdb_connection")
  expect_equal(dplyr::collect(tab)$x, 1)
})

test_that("dplyr::tbl() opens a dbplyr::in_schema() table (#2973)", {
  skip_if_not_installed("dbplyr")

  con <- local_con()
  DBI::dbExecute(con, "CREATE SCHEMA s")
  DBI::dbWriteTable(con, DBI::Id(schema = "s", table = "t"), data.frame(x = 1))

  tab <- dplyr::tbl(con, dbplyr::in_schema("s", "t"))
  expect_s3_class(tab, "tbl_duckdb_connection")
  expect_equal(dplyr::collect(tab)$x, 1)
})

test_that("compute() to an I() name points at the table it created (#2973)", {
  skip_if_not_installed("dbplyr")

  con <- local_con()
  DBI::dbExecute(con, "CREATE SCHEMA s")
  DBI::dbWriteTable(con, DBI::Id(schema = "s", table = "t"), data.frame(x = 1))

  tab <- dplyr::compute(
    dplyr::tbl(con, DBI::Id("s", "t")),
    name = I("s.e"),
    temporary = FALSE
  )
  expect_true(DBI::dbExistsTable(con, DBI::Id(schema = "s", table = "e")))
  expect_equal(
    as.character(dbplyr::remote_table(tab)),
    "s.e"
  )
  expect_equal(dplyr::collect(tab)$x, 1)
})

test_that("dplyr::tbl() opens a DBI::Id() table", {
  skip_if_not_installed("dbplyr")

  con <- local_con()
  DBI::dbExecute(con, "CREATE SCHEMA s")
  DBI::dbWriteTable(con, DBI::Id(schema = "s", table = "t"), data.frame(x = 1))

  tab <- dplyr::tbl(con, DBI::Id("s", "t"))
  expect_equal(dplyr::collect(tab)$x, 1)
})

test_that("dplyr::tbl() keeps the FROM fallback for a classed string", {
  skip_if_not_installed("dbplyr")

  con <- local_con()
  csv <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1), csv, row.names = FALSE)

  # The class glue::glue() gives its result, built without the package.
  from <- structure(
    paste0("read_csv('", csv, "')"),
    class = c("glue", "character")
  )
  tab <- dplyr::tbl(con, from)
  expect_equal(dplyr::collect(tab)$x, 1)
})

test_that("dplyr::tbl() opens a plain file path", {
  skip_if_not_installed("dbplyr")

  con <- local_con()
  csv <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1), csv, row.names = FALSE)

  tab <- dplyr::tbl(con, csv)
  expect_equal(dplyr::collect(tab)$x, 1)
})

if (rlang::is_installed("dbplyr")) {
  rm(`%>%`)
}
