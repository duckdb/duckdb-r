#' Local DuckDB connection fixture for testing
#'
#' Creates a DuckDB connection that will be automatically disconnected when the calling function exits.
#' This is a test fixture that follows testthat guidelines for resource management.
#'
#' @param ... Additional arguments passed to [duckdb()]
#'
#' @return A DuckDB connection object
#' @noRd
#'
#' @examples
#' \dontrun{
#' # In a test
#' test_that("my test", {
#'   con <- local_con()
#'   # Use the connection...
#'   # It will be automatically disconnected when the test exits
#' })
#' }
local_con <- function(..., drv = duckdb()) {
  con <- dbConnect(drv, ...)
  withr::defer_parent(dbDisconnect(con, shutdown = TRUE))
  con
}

#' Run a query off R's thread
#'
#' Runs `sql` on `con` on a thread of its own, while R's thread only waits for it,
#' so the query binds, and runs, off R's thread every time (#2962).
#' Test-only: the engine otherwise binds a task on whichever thread takes it.
#'
#' @param con A DuckDB connection
#' @param sql A query
#'
#' @return The error message, or `NA` when the query succeeded
#' @noRd
query_off_r_thread <- function(con, sql) {
  rethrow_rapi_query_off_r_thread(con@conn_ref, sql)
}
