test_that("create_view creates a view with expected content", {
  con <- dbConnect(duckdb::duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

  df <- data.frame(x = 1:5, y = letters[1:5])
  copy_to(con, df, "original_table", temporary = TRUE)

  data <- tbl(con, "original_table") %>% filter(x > 3)
  create_view(data, "view_test")

  result <- dbReadTable(con, "view_test")
  expect_equal(nrow(result), 2)
  expect_equal(result$x, c(4, 5))

  result <- tbl(con, "view_test") |> dplyr::collect()
  expect_equal(nrow(result), 2)
  expect_equal(result$x, c(4, 5))
})

test_that("create_view replaces an existing view", {
  con <- dbConnect(duckdb::duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

  df <- data.frame(a = 1:2)
  copy_to(con, df, "table1", temporary = TRUE)
  data1 <- tbl(con, "table1")
  create_view(data1, "replace_view")

  df2 <- tibble(a = 10:12)
  copy_to(con, df2, "table2", temporary = TRUE)
  data2 <- tbl(con, "table2")
  create_view(data2, "replace_view")  # Should replace

  result <- dbReadTable(con, "replace_view")
  expect_equal(nrow(result), 3)
  expect_equal(result$a, 10:12)
})

test_that("create_view works with quoted view names", {
  con <- dbConnect(duckdb::duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

  df <- data.frame(id = 1:3)
  copy_to(con, df, "quoted_table", temporary = TRUE)
  data <- tbl(con, "quoted_table")

  create_view(data, "weird-Name With Space")

  result <- dbGetQuery(con, 'SELECT * FROM "weird-Name With Space"')
  expect_equal(nrow(result), 3)
})

