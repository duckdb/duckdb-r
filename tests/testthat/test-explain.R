skip_on_cran()
local_edition(3)

# The Windows skip must live inside each `test_that()` block, not at the top of
# the file. testthat only restores a snapshot when the skip is recorded for a
# named test; a file-level skip aborts before any test starts, so the file's
# snapshots count as unused and `_snaps/explain.md` gets deleted.

test_that("EXPLAIN gives reasonable output", {
  skip_on_os("windows")
  con <- local_con()
  expect_snapshot({
    DBI::dbGetQuery(con, "EXPLAIN SELECT 1;")
  })
})

test_that("EXPLAIN shows logical, optimized and physical plan", {
  skip_on_os("windows")
  con <- local_con()
  expect_snapshot({
    DBI::dbExecute(con, "PRAGMA explain_output='all';")
    DBI::dbGetQuery(con, "EXPLAIN SELECT 1;")
  })
})

test_that("EXPLAIN ANALYZE outputs query tree", {
  skip_on_os("windows")
  con <- local_con()
  rs <- DBI::dbGetQuery(con, "EXPLAIN ANALYZE SELECT 1;")
  expect_true(is(rs, c("duckdb_explain")))
  expect_true(grepl("Total Time", rs$explain_value))
  expect_true(grepl("DUMMY_SCAN", rs$explain_value))
})

test_that("zero length input is smoothly skipped", {
  skip_on_os("windows")
  con <- local_con()
  expect_snapshot({
    rs <- DBI::dbGetQuery(con, "SELECT 1;")
    rs[FALSE, ]
  })
})

test_that("wrong type of input forwards handling to the next method", {
  skip_on_os("windows")
  con <- local_con()
  expect_snapshot({
    rs <- DBI::dbGetQuery(con, "SELECT 1;")
    class(rs) <- c("duckdb_explain", class(rs))
    rs
  })
})
