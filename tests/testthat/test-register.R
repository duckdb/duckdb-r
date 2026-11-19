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

test_that("a window query over a registered data frame is planned (#2998)", {
  con <- local_con()
  duckdb_register(
    con,
    "t",
    data.frame(id = 1:3, g = c("a", "b", "a"), px = c(1.5, 2, 3))
  )

  # The window self-join optimizer copies the plan of a view by serializing it;
  # in a -O2 GCC build, R CMD check --use-valgrind reported an uninitialised
  # read in QueryLocation until
  # patch/0127-Avoid-branching-on-the-payload-of-an-unset-optional_idx.patch
  # (https://github.com/duckdb/duckdb-r/issues/2998)
  res <- dbGetQuery(
    con,
    "SELECT id, sum(px) OVER (PARTITION BY g) s FROM t ORDER BY id"
  )
  expect_equal(res, data.frame(id = 1:3, s = c(4.5, 2, 4.5)))

  dbExecute(con, "CREATE TABLE u AS SELECT * FROM t")
  dbExecute(con, "CREATE VIEW v AS SELECT * FROM u")
  res <- dbGetQuery(
    con,
    "SELECT id, sum(px) OVER (PARTITION BY g) s FROM v ORDER BY id"
  )
  expect_equal(res, data.frame(id = 1:3, s = c(4.5, 2, 4.5)))
})

# In each test below, on an -O2 GCC build, R CMD check --use-valgrind reported
# a branch on the payload of an unset optional_idx until
# patch/0127-Avoid-branching-on-the-payload-of-an-unset-optional_idx.patch
# (https://github.com/duckdb/duckdb-r/issues/2998)

test_that("a window query over a filtered table is planned (#2998)", {
  con <- local_con()
  dbExecute(
    con,
    "CREATE TABLE t AS FROM (VALUES (1, 'a', 1.5), (2, 'b', 2), (3, 'a', 3)) v(id, g, px)"
  )

  # A filter on a parameter is pushed into the scan the optimizer copies
  res <- dbGetQuery(
    con,
    "SELECT id, sum(px) OVER (PARTITION BY g) s FROM t WHERE id > ? ORDER BY id",
    params = list(0L)
  )
  expect_equal(res, data.frame(id = 1:3, s = c(4.5, 2, 4.5)))
})

test_that("a CTE referenced twice is inlined (#2998)", {
  con <- local_con()
  dbExecute(
    con,
    "CREATE TABLE t AS FROM (VALUES (1, 1.5), (2, 2), (3, 3)) v(id, px)"
  )

  # Each reference gets a copy of the CTE's plan
  res <- dbGetQuery(
    con,
    "WITH c AS NOT MATERIALIZED (SELECT id, px + 1 AS y FROM t)
     SELECT a.id, a.y + b.y AS y FROM c a JOIN c b USING (id) ORDER BY id"
  )
  expect_equal(res, data.frame(id = 1:3, y = c(5, 6, 8)))
})

test_that("a file database reloads its views, macros and defaults (#2998)", {
  path <- withr::local_tempfile(fileext = ".duckdb")
  local({
    con <- local_con(path)
    dbExecute(con, "CREATE TABLE t (id INTEGER, px DOUBLE DEFAULT 1 + 1)")
    dbExecute(con, "INSERT INTO t (id) VALUES (1), (2)")
    dbExecute(
      con,
      "CREATE VIEW v AS SELECT id, CASE WHEN id > 1 THEN px END AS h FROM t"
    )
    dbExecute(con, "CREATE MACRO m(a, b := 2) AS a + b")
  })

  # Reopening reads the stored expressions back
  con <- local_con(path)
  expect_equal(
    dbGetQuery(con, "SELECT id, h, m(id) AS m FROM v ORDER BY id"),
    data.frame(id = 1:2, h = c(NA, 2), m = c(3, 4))
  )
})

test_that("a file database is checkpointed (#2998)", {
  path <- withr::local_tempfile(fileext = ".duckdb")
  local({
    con <- local_con(path)
    dbExecute(con, "CREATE TABLE t AS SELECT range AS i FROM range(3)")
    dbExecute(con, "CHECKPOINT")
  })

  con <- local_con(path)
  expect_equal(dbGetQuery(con, "SELECT i FROM t ORDER BY i")$i, c(0, 1, 2))
})

test_that("a column changes its type (#2998)", {
  con <- local_con()
  dbExecute(con, "CREATE TABLE t AS SELECT range::INTEGER AS i FROM range(3)")

  # The commit reads back the ALTER with the cast it implies
  dbExecute(con, "ALTER TABLE t ALTER i TYPE VARCHAR")
  expect_equal(
    dbGetQuery(con, "SELECT i FROM t ORDER BY i")$i,
    c("0", "1", "2")
  )
})
