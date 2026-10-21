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
  # Whichever task fails first, the error arrives the same.
  out <- scan_repeated_cells(
    list(l = matrix(1:4, 2)),
    "SELECT count(*) AS n FROM cells WHERE len(l) > 0",
    n = 2100000L
  )

  expect_true("duckdb_error" %in% out$class)
  expect_equal(out$context, "rapi_execute")
  expect_equal(out$error_type, "INVALID_INPUT")
})

test_that("A scan task on R's thread keeps its message", {
  # One thread, so R's thread scans the cell, underneath the engine,
  # whose catch keeps nothing of an R error's unwind but `std::exception`.
  con <- local_con()
  dbExecute(con, "SET threads = 1")

  df <- data.frame(id = 1:3)
  df$l <- rep(list(matrix(1:4, 2)), 3)
  duckdb_register(con, "mats", df)

  expect_snapshot(error = TRUE, {
    dbGetQuery(con, "SELECT count(*) AS n FROM mats WHERE len(l) > 0")
  })
})

test_that("Errors raised on R's thread keep their context", {
  # The guard is on the thread, not on the error
  con <- local_con()

  expect_snapshot(error = TRUE, {
    duckdb_register(con, "empty", data.frame())
  })
})

test_that("An entry point reports the scan's encoding check through R", {
  # The same check the scan meets, met at an entry point instead:
  # the error is raised from R once the C++ call has returned, with its context.
  con <- local_con()
  latin1 <- iconv("f\u00fcr", "UTF-8", "latin1")

  expect_snapshot(error = TRUE, {
    expr_constant(latin1)
  })
  expect_snapshot(error = TRUE, {
    rel_from_table_function(con, "repeat", list(latin1, 3L))
  })
})

test_that("An entry point reports the engine's UTF-8 check through R", {
  # A native string passes the encoding check, and the engine then refuses
  # bytes that are not UTF-8: that refusal is reported like the check.
  con <- local_con()
  bad <- "a\xffb"

  expect_snapshot(error = TRUE, {
    expr_constant(bad)
  })
  expect_snapshot(error = TRUE, {
    dbGetQuery(con, "SELECT ?", params = list(bad))
  })
})

test_that("An error raised while the engine binds a data frame keeps its message", {
  # Bind runs on R's thread but underneath the engine,
  # whose catch keeps nothing of an R error's unwind but `std::exception`:
  # the error has to cross it as an exception of its own.
  con <- local_con()

  expect_snapshot(error = TRUE, {
    duckdb_register(con, "cplx", data.frame(z = 1i))
  })
})
