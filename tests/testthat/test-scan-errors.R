test_that("Data frame scan reports a scan-time error with its message", {
  # A list column is typed at bind from its first cell, so a differently
  # encoded string further down is met only while the scan runs -- inside the
  # engine, and on whichever thread took the task. Raising an R error there
  # calls R off R's thread, and cpp11's unwind travels back through DuckDB,
  # which flattens it to `std::exception`; the message has to travel as an
  # exception instead.
  con <- local_con()

  n <- 1100000L
  cells <- as.list(rep("a", n))
  cells[[n - 10L]] <- iconv("für", "UTF-8", "latin1")
  df <- data.frame(id = seq_len(n))
  df$l <- cells

  duckdb_register(con, "with_list", df)

  # A million rows per task, so the bad cell is in a task of its own
  expect_error(
    dbGetQuery(con, "SELECT count(*) AS n FROM with_list WHERE len(l) > 0"),
    "UTF-8"
  )
})

test_that("Errors raised on R's thread keep their context", {
  # The guard is on the thread, not on the error: an entry point that never
  # leaves R's thread still reports through R, with its context attached.
  con <- local_con()

  expect_error(
    duckdb_register(con, "empty", data.frame()),
    "at least one column"
  )
})
