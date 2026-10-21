test_that("duckdb_register() works", {
  con <- local_con()

  # most basic case
  duckdb_register(con, "my_df1", iris)
  res <- dbReadTable(con, "my_df1")
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris))
  duckdb_unregister(con, "my_df1")

  duckdb_register(con, "my_df2", mtcars)
  res <- dbReadTable(con, "my_df2")
  row.names(res) <- row.names(mtcars)
  expect_true(identical(res, mtcars))
  duckdb_unregister(con, "my_df2")

  duckdb_register(con, "my_df1", mtcars)
  res <- dbReadTable(con, "my_df1")
  row.names(res) <- row.names(mtcars)
  expect_true(identical(res, mtcars))

  # re-registering under same name is an error by default, see issue #967
  expect_error(duckdb_register(con, "my_df1", iris))
  # can force an overwrite
  duckdb_register(con, "my_df1", iris, overwrite = TRUE)
  res <- dbReadTable(con, "my_df1")
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris))

  duckdb_unregister(con, "my_df1")
  duckdb_unregister(con, "my_df2")
  duckdb_unregister(con, "xxx")

  # this needs to be empty now
  expect_true(length(attributes(con@conn_ref)) == 0)
})


test_that("various error cases for duckdb_register()", {
  skip_if_not(TEST_RE2)

  # Closed by hand to test unregistering afterwards, so not a local_con().
  con <- dbConnect(duckdb())

  duckdb_register(con, "my_df1", iris)
  duckdb_unregister(con, "my_df1")
  expect_error(dbReadTable(con, "my_df1"))

  expect_error(duckdb_register(1, "my_df1", iris))
  expect_error(duckdb_register(con, "", iris))
  expect_error(duckdb_unregister(1, "my_df1"))
  expect_error(duckdb_unregister(con, ""))
  dbDisconnect(con, shutdown = TRUE)
  # this is fine
  duckdb_unregister(con, "my_df1")
})


test_that("uppercase data frames are queryable", {
  con <- local_con()

  duckdb_register(con, "My_Mtcars", mtcars)
  dbGetQuery(con, "SELECT * FROM \"My_Mtcars\"")

  res <- dbReadTable(con, "My_Mtcars")
  row.names(res) <- row.names(mtcars)
  expect_true(identical(res, mtcars))
  duckdb_unregister(con, "My_Mtcars")
})

test_that("experimental string handling works", {
  con <- local_con()
  df <- data.frame(a = c(NA, as.character(1:10000)))

  duckdb_register(con, "df", df, experimental = TRUE)

  expect_equal(df, dbGetQuery(con, "SELECT a::STRING a FROM df"))
  expect_equal(df, dbGetQuery(con, "SELECT a FROM df"))
})

test_that("can register list of NULL values", {
  skip_if_not_installed("tibble")

  con <- local_con()
  df <- tibble::tibble(a = 1:2, b = list(NULL))

  expect_silent(duckdb_register(con, "df1", df))
  expect_silent(duckdb_register(con, "df2", df[0, ]))

  expect_equal(dbGetQuery(con, "SELECT * FROM df1"), as.data.frame(df))
})

test_that("a registered data frame binds on a thread other than R's (#2962)", {
  con <- local_con()
  dbExecute(con, "SET threads = 4")
  duckdb_register(con, "v", data.frame(V1 = 1:3))

  # pragma_table_info() rebinds the view in a task, which any thread may run,
  # so the query is repeated for threads other than R's to bind it
  res <- lapply(1:50, function(i) {
    dbGetQuery(con, "SELECT * FROM v JOIN pragma_table_info('v') m ON true")$V1
  })
  expect_equal(res, rep(list(1:3), 50))
})

test_that("a registered relation binds on a thread other than R's (#2962)", {
  con <- local_con()
  con_rel <- local_con()
  dbExecute(con, "SET threads = 4")
  df <- rel_to_altrep(rel_from_df(
    con_rel,
    data.frame(a = 1:3, b = c("x", "y", "z"))
  ))
  duckdb_register(con, "r", df)

  # Its columns are converted when the view is created, on R's thread,
  # and a task that rebinds the view reads them as they are
  res <- lapply(1:50, function(i) {
    sort(
      dbGetQuery(con, "SELECT a FROM r JOIN pragma_table_info('r') m ON true")$a
    )
  })
  expect_equal(res, rep(list(rep(1:3, each = 2)), 50))
})

test_that("a registered relation's list column is refused on a thread other than R's (#2962)", {
  skip_if(getRversion() < "4.3", "ALTREP for lists not supported")

  con <- local_con()
  con_rel <- local_con()
  dbExecute(con, "SET threads = 4")
  df <- rel_to_altrep(rel_from_sql(
    con_rel,
    "SELECT * FROM (VALUES (1, [1, 2]), (2, [3])) t(a, l)"
  ))
  duckdb_register(con, "r", df)
  sql <- "SELECT a FROM r JOIN pragma_table_info('r') m ON true"

  # A list column of rel_to_altrep() is an ALTREP list, which only R reads;
  # the loop ends at the first query whose task binds the view off R's thread
  expect_error(
    for (i in 1:200) {
      dbGetQuery(con, sql)
    },
    "column \"l\" .* off R's thread",
    class = "duckdb_error"
  )

  # With no worker of its own, the engine runs every task on R's thread
  dbExecute(con, "SET threads = 1")
  res <- lapply(1:20, function(i) sort(dbGetQuery(con, sql)$a))
  expect_equal(res, rep(list(c(1L, 1L, 2L, 2L)), 20))
})
