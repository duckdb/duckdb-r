skip_if_not_installed("arrow")
skip_if_not_installed("dbplyr")
skip_if_not_installed("dplyr")
skip_if_not_installed("nanoarrow")

test_that("to_arrow_stream() returns what arrow::to_arrow() returns", {
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
  con <- local_con()

  lazy <- dplyr::tbl(con, dplyr::sql("SELECT i FROM range(3000000) t(i)"))
  reader <- to_arrow_stream(lazy)
  expect_gt(reader$read_next_batch()$num_rows, 0)
  dbGetQuery(con, "SELECT 1")
  expect_error(reader$read_next_batch(), "invalidated by another statement")
})
