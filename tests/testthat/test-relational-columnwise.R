# Run this file with testthat::test_local(filter = "^relational-columnwise$")
# A lazy data frame over a stored table fetches each column by a query of its own (#2891).

test_that("a table scan fetches only the column that is read", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:10, b = letters[1:10], c = 10:1 / 2))
  # The queries the data frame ran, from the engine's query log
  dbExecute(con, "CALL enable_logging('QueryLog')")
  queries <- function() {
    sql <- dbGetQuery(
      con,
      "SELECT message FROM duckdb_logs WHERE type = 'QueryLog'"
    )$message
    sql[grepl("FROM memory\\.main\\.", sql)]
  }
  calls <- function() length(queries())

  df <- rel_to_altrep(rel_from_table(con, "t"))
  expect_equal(calls(), 0)

  # One query counts the rows, one fetches the column
  expect_equal(df$b, letters[1:10])
  expect_equal(calls(), 2)
  expect_match(queries()[[1]], "count_star()", fixed = TRUE)
  expect_match(queries()[[2]], "^SELECT b AS b FROM memory\\.main\\.t$")
  expect_false(df_is_materialized(df))
  expect_false(rapi_df_has_query_result(df))

  # A converted column runs nothing, another column runs its own query
  expect_equal(df$b, letters[1:10])
  expect_equal(calls(), 2)
  expect_equal(df$c, 10:1 / 2)
  expect_equal(calls(), 3)

  expect_equal(df, dbReadTable(con, "t"))
  expect_equal(calls(), 4)
  # Every column is converted now
  expect_true(df_is_materialized(df))
})

test_that("a projection of column references over a table scan is fetched column-wise", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:10, b = letters[1:10], c = 10:1 / 2))
  # The queries the data frame ran, from the engine's query log
  dbExecute(con, "CALL enable_logging('QueryLog')")
  queries <- function() {
    sql <- dbGetQuery(
      con,
      "SELECT message FROM duckdb_logs WHERE type = 'QueryLog'"
    )$message
    sql[grepl("FROM memory\\.main\\.", sql)]
  }
  calls <- function() length(queries())

  rel <- rel_project(
    rel_from_table(con, "t"),
    list(expr_reference("c"), expr_reference("a", alias = "x"))
  )
  df <- rel_to_altrep(rel)

  expect_equal(df$x, 1:10)
  expect_equal(calls(), 2)
  expect_equal(df$c, 10:1 / 2)
  expect_equal(calls(), 3)
  expect_true(df_is_materialized(df))
  expect_equal(df, data.frame(c = 10:1 / 2, x = 1:10))
})

test_that("nrow() of a table scan fetches no column", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:10, b = letters[1:10]))
  # The queries the data frame ran, from the engine's query log
  dbExecute(con, "CALL enable_logging('QueryLog')")
  queries <- function() {
    sql <- dbGetQuery(
      con,
      "SELECT message FROM duckdb_logs WHERE type = 'QueryLog'"
    )$message
    sql[grepl("FROM memory\\.main\\.", sql)]
  }
  calls <- function() length(queries())

  df <- rel_to_altrep(rel_from_table(con, "t"))
  expect_equal(nrow(df), 10)
  expect_equal(length(df$a), 10)
  expect_equal(calls(), 1)
  expect_false(df_is_materialized(df))
  expect_false(rapi_df_has_query_result(df))

  # The row count is cached, the column is fetched by its own query
  expect_equal(df$a, 1:10)
  expect_equal(calls(), 2)
})

test_that("a relation that is not a plain table scan materializes as a whole", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:10, b = letters[1:10]))

  ordered <- rel_to_altrep(rel_from_sql(con, "FROM t ORDER BY a"))
  expect_equal(nrow(ordered), 10)
  expect_true(df_is_materialized(ordered))

  computed <- rel_to_altrep(rel_project(
    rel_from_table(con, "t"),
    list(expr_reference("a"), expr_constant(1, alias = "one"))
  ))
  expect_equal(computed$a, 1:10)
  expect_true(df_is_materialized(computed))
  expect_true(rapi_df_has_query_result(computed))
})

test_that("the materialization budget applies to each column fetched", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:10, b = letters[1:10], c = 1:10 / 2))
  rel <- rel_from_table(con, "t")

  forbid <- rel_to_altrep(rel, n_cells = 0)
  expect_error(nrow(forbid), "Materialization is disabled")
  expect_error(forbid$a[[1]], "Materialization is disabled")

  expect_error(nrow(rel_to_altrep(rel, n_rows = 9)), "more than 9 rows")
  expect_equal(rel_to_altrep(rel, n_rows = 10)$a, 1:10)

  # Fifteen cells allow one column of ten rows, not two
  cells <- rel_to_altrep(rel, n_cells = 15)
  expect_equal(nrow(cells), 10)
  expect_equal(cells$a, 1:10)
  expect_error(cells$b[[1]], "more than 5 rows")
  # The error is stored and raised again
  expect_error(cells$c[[1]], "more than 5 rows")
  expect_equal(cells$a, 1:10)

  both <- rel_to_altrep(rel, n_rows = 10, n_cells = 30)
  expect_equal(both, dbReadTable(con, "t"))
})

test_that("a table that changes between column fetches fails", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:10, b = letters[1:10]))

  df <- rel_to_altrep(rel_from_table(con, "t"))
  expect_equal(df$a, 1:10)

  dbExecute(con, "INSERT INTO t VALUES (11, 'k')")
  expect_error(df$b[[1]], "table changed")
  expect_error(df$b[[1]], "table changed")
  # The column fetched before the change is still there
  expect_equal(df$a, 1:10)
})

test_that("a column-wise fetch refuses the connection that is running the query", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:3, b = c("x", "y", "z")))
  df <- rel_to_altrep(rel_from_table(con, "t"))

  expect_error(
    duckdb_register(con, "u", df),
    "connection that is running the query"
  )
  expect_false(df_is_materialized(df))

  # A relation of another connection is read column by column under the query
  con_b <- local_con()
  dbWriteTable(con_b, "t", data.frame(a = 1:3, b = c("x", "y", "z")))
  df_b <- rel_to_altrep(rel_from_table(con_b, "t"))
  duckdb_register(con, "v", df_b)
  expect_equal(
    dbGetQuery(con, "FROM v"),
    data.frame(a = 1:3, b = c("x", "y", "z"))
  )
  # Reading every column for the scan converted them all
  expect_true(df_is_materialized(df_b))
})

test_that("a struct column is fetched once for all of its fields", {
  con <- local_con()
  dbExecute(
    con,
    "CREATE TABLE t AS SELECT {'x': range::INTEGER, 'y': range::DOUBLE} AS s, range::INTEGER AS a FROM range(10)"
  )
  # The queries the data frame ran, from the engine's query log
  dbExecute(con, "CALL enable_logging('QueryLog')")
  queries <- function() {
    sql <- dbGetQuery(
      con,
      "SELECT message FROM duckdb_logs WHERE type = 'QueryLog'"
    )$message
    sql[grepl("FROM memory\\.main\\.", sql)]
  }
  calls <- function() length(queries())

  df <- rel_to_altrep(rel_from_table(con, "t"))
  expect_equal(df$s$x, 0:9)
  expect_equal(calls(), 2)
  # The struct column is held until its last field is converted
  expect_true(rapi_df_has_query_result(df))
  expect_equal(df$s$y, as.double(0:9))
  expect_equal(calls(), 2)
  expect_false(rapi_df_has_query_result(df))
  expect_false(df_is_materialized(df))
})

test_that("a column dropped between creation and fetch fails", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:3, b = 4:6, c = 7:9))

  df <- rel_to_altrep(rel_from_table(con, "t"))
  dbExecute(con, "ALTER TABLE t DROP COLUMN a")
  # Not the neighbouring column's data
  expect_error(
    df$b[[1]],
    "table changed.*column `a` \\(INTEGER\\) is now `b` \\(INTEGER\\)"
  )
})

test_that("a column whose type changed between creation and fetch fails", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:3, b = c("1", "2", "3")))

  df <- rel_to_altrep(rel_from_table(con, "t"))
  dbExecute(con, "ALTER TABLE t ALTER b TYPE INTEGER")
  expect_error(df$b[[1]], "column `b` \\(VARCHAR\\) is now `b` \\(INTEGER\\)")
  expect_error(df$b[[1]], "table changed")
})

test_that("a column renamed between creation and fetch fails", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:2, b = 3:4))

  df <- rel_to_altrep(rel_from_table(con, "t"))
  dbExecute(con, "ALTER TABLE t RENAME a TO c")
  expect_error(
    df$b[[1]],
    "table changed.*column `a` \\(INTEGER\\) is now `c` \\(INTEGER\\)"
  )
})

test_that("columns whose names were swapped between creation and fetch fail", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:2, b = c(10L, 20L)))

  df <- rel_to_altrep(rel_from_table(con, "t"))
  dbExecute(con, "ALTER TABLE t RENAME a TO tmp")
  dbExecute(con, "ALTER TABLE t RENAME b TO a")
  dbExecute(con, "ALTER TABLE t RENAME tmp TO b")
  expect_error(
    df$a[[1]],
    "table changed.*column `a` \\(INTEGER\\) is now `b` \\(INTEGER\\)"
  )
})

test_that("an aborted transaction fails a column-wise fetch with a clean message", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:2, b = 3:4))

  fresh <- rel_to_altrep(rel_from_table(con, "t"))
  part <- rel_to_altrep(rel_from_table(con, "t"))
  expect_equal(part$a, 1:2)

  dbBegin(con)
  expect_error(dbExecute(con, "INSERT INTO t VALUES (1)"), "Binder Error")
  for (df in list(fresh, part)) {
    for (i in 1:2) {
      msg <- tryCatch(df$b[[1]], error = conditionMessage)
      expect_match(
        msg,
        "Error evaluating duckdb query: TransactionContext Error: Current transaction is aborted",
        fixed = TRUE
      )
      expect_no_match(msg, "exception_type|table changed")
    }
  }
  dbRollback(con)
})

test_that("a held struct column stays readable after another fetch failed", {
  con <- local_con()
  dbExecute(
    con,
    "CREATE TABLE t AS SELECT {'x': range::INTEGER, 'y': range::DOUBLE} AS s, range::INTEGER AS a FROM range(10)"
  )

  df <- rel_to_altrep(rel_from_table(con, "t"), n_cells = 15)
  expect_equal(df$s$x, 0:9)
  expect_error(df$a[[1]], "more than 5 rows")
  expect_equal(df$s$y, as.double(0:9))
})

test_that("a data frame with every column converted is materialized", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:3, b = c("x", "y", "z")))

  df <- rel_to_altrep(rel_from_table(con, "t"))
  expect_equal(df$a, 1:3)
  expect_false(df_is_materialized(df))
  expect_equal(df$b, c("x", "y", "z"))
  expect_true(df_is_materialized(df))
  expect_false(rapi_df_has_query_result(df))
})

test_that("a relation from a fully converted data frame scans what R holds", {
  con <- local_con()
  skip_if_prebuilt_engine(
    con,
    "one-byte arguments across GCC and clang (#2955)"
  )
  dbWriteTable(con, "t", data.frame(a = 1:3, b = c("x", "y", "z")))

  df <- rel_to_altrep(rel_from_table(con, "t"))
  expect_equal(df$a, 1:3)
  expect_equal(df$b, c("x", "y", "z"))

  # Not the table, which has changed since
  dbExecute(con, "UPDATE t SET a = a * 10")
  rel <- rel_from_altrep_df(df, wrap = TRUE)
  expect_equal(rel_to_altrep(rel)$a, 1:3)
})

test_that("a temporary table is fetched column-wise", {
  con <- local_con()
  dbExecute(
    con,
    "CREATE TEMP TABLE t AS SELECT range::INTEGER AS a, range::INTEGER AS b FROM range(3)"
  )

  df <- rel_to_altrep(rel_from_table(con, "t", schema_name = "main"))
  expect_equal(df$a, 0:2)
  expect_false(df_is_materialized(df))
})

test_that("a converted column keeps its values and runs no query after a later fetch fails", {
  # transformed_vector is never reassigned once converted_payload is published,
  # which the summary methods rely on when they read the payload unguarded
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:10, b = letters[1:10]))
  # The queries the data frame ran, from the engine's query log
  dbExecute(con, "CALL enable_logging('QueryLog')")
  queries <- function() {
    sql <- dbGetQuery(
      con,
      "SELECT message FROM duckdb_logs WHERE type = 'QueryLog'"
    )$message
    sql[grepl("FROM memory\\.main\\.", sql)]
  }
  calls <- function() length(queries())

  # A changed table fails the later fetch
  changed <- rel_to_altrep(rel_from_table(con, "t"))
  # Reading the values converts the column
  a <- changed$a[seq_len(10)]
  expect_equal(a, 1:10)
  dbExecute(con, "INSERT INTO t VALUES (11, 'k')")
  expect_error(changed$b[[1]], "table changed")
  n <- calls()
  expect_identical(changed$a, a)
  expect_equal(calls(), n)

  # An exhausted cell budget fails the later fetch
  budget <- rel_to_altrep(rel_from_table(con, "t"), n_cells = 15)
  # The table has eleven rows now, so fifteen cells leave four after column `a`
  a <- budget$a[seq_len(11)]
  expect_equal(a, 1:11)
  expect_error(budget$b[[1]], "more than 4 rows")
  n <- calls()
  expect_identical(budget$a, a)
  expect_equal(calls(), n)
})

test_that("the materialize callback announces a column-wise data frame once", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:3, b = 4:6, c = 7:9))
  calls <- 0
  rlang::local_options(duckdb.materialize_callback = function(rel) {
    calls <<- calls + 1
  })

  df <- rel_to_altrep(rel_from_table(con, "t"))
  expect_equal(calls, 0)
  expect_equal(nrow(df), 3)
  expect_equal(calls, 1)
  expect_equal(df$a, 1:3)
  expect_equal(df$b, 4:6)
  expect_equal(df$c, 7:9)
  expect_equal(calls, 1)

  # The first read of a column announces the data frame too, without nrow() first
  df2 <- rel_to_altrep(rel_from_table(con, "t"))
  expect_equal(df2$c[[1]], 7)
  expect_equal(df2$a, 1:3)
  expect_equal(calls, 2)
})

test_that("summaries of a column-wise column fetch it once and then read the converted vector", {
  con <- local_con()
  dbWriteTable(
    con,
    "t",
    data.frame(x = c(2.5, NA, 1, 4), n = c(3L, 1L, NA, 2L), s = letters[1:4])
  )
  dbExecute(con, "CALL enable_logging('QueryLog')")
  queries <- function() {
    sql <- dbGetQuery(
      con,
      "SELECT message FROM duckdb_logs WHERE type = 'QueryLog'"
    )$message
    sql[grepl("FROM memory\\.main\\.", sql)]
  }

  df <- rel_to_altrep(rel_from_table(con, "t"))
  # The length needs the row count only
  expect_equal(length(df$x), 4)
  expect_equal(length(queries()), 1)

  expect_equal(mean(df$x, na.rm = TRUE), 2.5)
  expect_equal(length(queries()), 2)
  expect_match(queries()[[2]], "^SELECT x AS x FROM ")
  expect_equal(range(df$x, na.rm = TRUE), c(1, 4))
  expect_true(anyNA(df$x))
  expect_equal(sum(df$x, na.rm = TRUE), 7.5)
  expect_equal(df$x[[3]], 1)
  expect_equal(length(df$x), 4)
  expect_equal(length(queries()), 2)

  expect_equal(range(df$n, na.rm = TRUE), c(1L, 3L))
  expect_true(anyNA(df$n))
  expect_equal(length(queries()), 3)
  expect_false(df_is_materialized(df))
})

test_that("a refused attempt does not use up the announcement", {
  con <- local_con(drv = duckdb(environment_scan = TRUE))
  dbWriteTable(con, "t", data.frame(x = 1:3, y = 4:6))
  calls <- 0
  rlang::local_options(duckdb.materialize_callback = function(rel) {
    calls <<- calls + 1
  })

  # Column-wise, and as a whole
  for (rel in list(rel_from_table(con, "t"), rel_from_sql(con, "FROM t"))) {
    calls <- 0
    df <- rel_to_altrep(rel)
    # Refused before anything executes: the scan's bind runs under a query of the frame's own connection
    expect_error(
      dbGetQuery(con, "FROM df"),
      "connection that is running the query"
    )
    expect_equal(calls, 0)
    expect_equal(sum(df$x), 6)
    expect_equal(calls, 1)
  }
})

test_that("the legacy materialize message prints once per data frame", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:3, b = 4:6))
  rlang::local_options(duckdb.materialize_message = TRUE)

  df <- rel_to_altrep(rel_from_table(con, "t"))
  out <- capture.output({
    nrow(df)
    sum(df$a)
    sum(df$b)
  })
  expect_equal(sum(out == "duckplyr: materializing"), 1)
})
