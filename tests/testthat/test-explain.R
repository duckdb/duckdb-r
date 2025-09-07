skip_on_cran()
skip_on_os(c("windows"))
local_edition(3)

test_that("EXPLAIN gives reasonable output", {
  con <- local_con()
  expect_snapshot({
    DBI::dbGetQuery(con, "EXPLAIN SELECT 1;")
  })
})

test_that("EXPLAIN shows logical, optimized and physical plan", {
  con <- local_con()
  expect_snapshot({
    DBI::dbExecute(con, "PRAGMA explain_output='all';")
    DBI::dbGetQuery(con, "EXPLAIN SELECT 1;")
  })
})

test_that("EXPLAIN ANALYZE outputs query tree", {
  con <- local_con()
  rs <- DBI::dbGetQuery(con, "EXPLAIN ANALYZE SELECT 1;")
  expect_true(is(rs, c("duckdb_explain")))
  expect_true(grepl("Total Time", rs$explain_value))
  expect_true(grepl("DUMMY_SCAN", rs$explain_value))
})

test_that("zero length input is smoothly skipped", {
  con <- local_con()
  expect_snapshot({
    rs <- DBI::dbGetQuery(con, "SELECT 1;")
    rs[FALSE, ]
  })
})

test_that("wrong type of input forwards handling to the next method", {
  con <- local_con()
  expect_snapshot({
    rs <- DBI::dbGetQuery(con, "SELECT 1;")
    class(rs) <- c("duckdb_explain", class(rs))
    rs
  })
})
