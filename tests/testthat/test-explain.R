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
  expect_true(grepl("Dummy Scan", rs$explain_value))
})

test_that("an unfinished EXPLAIN ANALYZE leaves the next query profiled", {
  # The engine marks its profiler for EXPLAIN ANALYZE when the statement is
  # prepared and when it starts, and clears the mark only at the end of a
  # query that is still profiling; a failure rolls back and stops it first.
  # A mark left over makes the next query run as an EXPLAIN ANALYZE, which
  # writes no profile (patch/0044).
  con <- local_con()
  skip_if_prebuilt_engine(con, "no engine patches in patch/ (#2954)")
  out <- withr::local_tempfile(fileext = ".json")
  DBI::dbExecute(con, "PRAGMA enable_profiling = 'json'")
  DBI::dbExecute(con, paste0("PRAGMA profiling_output = '", out, "'"))

  next_query_profiled <- function() {
    unlink(out)
    DBI::dbGetQuery(con, "SELECT 42")
    file.exists(out)
  }

  expect_true(next_query_profiled())

  # Fails while it runs
  expect_error(
    DBI::dbGetQuery(con, "EXPLAIN ANALYZE SELECT error('boom')"),
    "boom"
  )
  expect_true(next_query_profiled())

  # Fails while it is prepared
  expect_error(
    DBI::dbGetQuery(con, "EXPLAIN ANALYZE FROM nonexistent"),
    "nonexistent"
  )
  expect_true(next_query_profiled())

  # Prepared, never run
  DBI::dbClearResult(DBI::dbSendQuery(con, "EXPLAIN ANALYZE SELECT ?"))
  expect_true(next_query_profiled())
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
