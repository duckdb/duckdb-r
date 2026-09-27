# Handbook: handbook/architecture/glue/threading/README.md

test_that("Data frame scan reports a scan-time error with its message", {
  # Registration converts character columns to UTF-8, not the strings in a
  # list column's cells, so a differently encoded one is met only by the scan.
  con <- local_con()

  df <- data.frame(id = 1:3)
  df$l <- list("a", iconv("f\u00fcr", "UTF-8", "latin1"), "b")
  duckdb_register(con, "with_list", df)

  expect_snapshot(error = TRUE, {
    dbGetQuery(con, "SELECT count(*) AS n FROM with_list WHERE len(l) > 0")
  })
})

test_that("A scan task off R's thread reports its error without calling R", {
  # `SexpToValue()` has no case for a matrix, so every cell of this list
  # column fails, and so does a task a worker thread took.
  # Reporting that through R killed the session.
  # Which task fails first decides the message, so this checks where the
  # error arrived rather than its text.
  out <- scan_repeated_cells(
    list(l = matrix(1:4, 2)),
    "SELECT count(*) AS n FROM cells WHERE len(l) > 0",
    n = 2100000L
  )

  expect_true("duckdb_error" %in% out$class)
  expect_equal(out$context, "rapi_execute")
})

test_that("Errors raised on R's thread keep their context", {
  # The guard is on the thread, not on the error
  con <- local_con()

  expect_snapshot(error = TRUE, {
    duckdb_register(con, "empty", data.frame())
  })
})

test_that("An entry point reports the scan's encoding check through R", {
  # The check throws for the scan's sake; outside the scan it must still
  # arrive as a classed error, not as the engine's JSON
  con <- local_con()
  latin1 <- iconv("f\u00fcr", "UTF-8", "latin1")

  expect_snapshot(error = TRUE, {
    expr_constant(latin1)
  })
  expect_snapshot(error = TRUE, {
    rel_from_table_function(con, "repeat", list(latin1, 3L))
  })
})
