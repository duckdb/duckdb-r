#' Local DuckDB connection fixture for testing
#'
#' Creates a DuckDB connection that will be automatically disconnected
#' when the calling function exits. This is a test fixture that follows
#' testthat guidelines for resource management.
#'
#' @param ... Additional arguments passed to [duckdb()]
#'
#' @return A DuckDB connection object
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
#'
#' @export
local_con <- function(...) {
  con <- dbConnect(duckdb(...))
  withr::defer_parent(dbDisconnect(con, shutdown = TRUE))
  con
}