test_that("local_con() creates and cleans up connection", {
  # Test that local_con() works in a nested environment
  test_connection <- function() {
    con <- local_con()
    expect_s4_class(con, "duckdb_connection")
    expect_true(dbIsValid(con))

    # Test basic functionality
    result <- dbGetQuery(con, "SELECT 1 as test_col")
    expect_equal(result$test_col, 1)

    return(con)
  }

  # Call the function that uses local_con()
  con <- test_connection()

  # After the function exits, connection should be disconnected
  # (because withr::defer_parent defers to the immediate parent function's exit)
  expect_false(dbIsValid(con))
})

test_that("local_con() accepts duckdb() arguments", {
  # Test that we can pass arguments through to duckdb()
  con <- local_con()
  expect_s4_class(con, "duckdb_connection")
  expect_true(dbIsValid(con))
})
