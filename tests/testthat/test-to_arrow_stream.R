skip_if_not_installed("arrow")
skip_if_not_installed("dbplyr")
skip_if_not_installed("dplyr")
skip_if_not_installed("nanoarrow")

test_that("to_arrow_stream() returns what arrow::to_arrow() returns", {
  # arrow::to_arrow() calls the mainline package by name.
  skip_on_flavor()
  con <- local_con()
  dbWriteTable(con, "t", data.frame(g = c("a", "b", "a"), x = 1:3))

  lazy <- dplyr::filter(dplyr::tbl(con, "t"), x > 1)
  reader <- to_arrow_stream(lazy)
  expect_s3_class(reader, "RecordBatchReader")
  expect_equal(
    as.data.frame(reader$read_table()),
    as.data.frame(arrow::to_arrow(lazy)$read_table())
  )

  grouped <- dplyr::group_by(dplyr::tbl(con, "t"), g)
  query <- to_arrow_stream(grouped)
  expect_s3_class(query, "arrow_dplyr_query")
  expect_equal(
    dplyr::collect(query),
    dplyr::collect(arrow::to_arrow(grouped))
  )
})

test_that("to_arrow_stream() passes Arrow objects through and refuses other input", {
  table <- arrow::arrow_table(x = 1:3)
  expect_identical(to_arrow_stream(table), table)
  expect_error(to_arrow_stream(data.frame(x = 1)), "DuckDB connection")
})

test_that("to_arrow_stream() refuses a simulated or a closed connection", {
  simulated <- dbplyr::lazy_frame(x = 1, con = simulate_duckdb())
  expect_error(to_arrow_stream(simulated), "DuckDB connection")

  con <- dbConnect(duckdb())
  dbWriteTable(con, "t", data.frame(x = 1:3))
  lazy <- dplyr::tbl(con, "t")
  dbDisconnect(con, shutdown = TRUE)
  expect_error(to_arrow_stream(lazy), "to be open")
})

test_that("a statement on its connection invalidates a reader not read to the end", {
  skip_if_arrow_result_not_streamed()
  con <- local_con()

  lazy <- dplyr::tbl(con, dplyr::sql("SELECT i FROM range(3000000) t(i)"))
  reader <- to_arrow_stream(lazy)
  expect_gt(reader$read_next_batch()$num_rows, 0)
  dbGetQuery(con, "SELECT 1")
  expect_error(reader$read_next_batch(), "invalidated by another statement")
})

test_that("the reader's documented limits hold", {
  con <- local_con()
  dbWriteTable(con, "t", data.frame(i = seq_len(3e6)))
  dbWriteTable(con, "u", data.frame(j = 1:3))
  lazy <- dplyr::tbl(con, "t")

  # dbplyr asks for the columns of a new lazy table.
  reader <- to_arrow_stream(lazy)
  dplyr::tbl(con, "u")
  if (arrow_result_streams()) {
    expect_error(reader$read_next_batch(), "invalidated by another statement")
  }

  # A second connection to the same database leaves the reader alone.
  other <- dbConnect(con@driver)
  withr::defer(dbDisconnect(other))
  reader <- to_arrow_stream(lazy)
  expect_equal(nrow(dplyr::collect(dplyr::tbl(other, "u"))), 3)
  expect_equal(reader$read_table()$num_rows, 3e6)

  # The reader is read once.
  expect_equal(reader$read_table()$num_rows, 0)
})
