#' Local DuckDB connection fixture for testing
#'
#' Creates a DuckDB connection that will be automatically disconnected
#' when the calling function exits. This is a test fixture that follows
#' testthat guidelines for resource management.
#'
#' @param ... Additional arguments passed to [duckdb()]
#' @param extensions If `FALSE`, point the instance's `extension_directory`
#'   at a dummy path, so no installed extension is found and none can
#'   autoload -- the deterministic way to test "extension absent" behavior
#'   regardless of what a shared extension store contains.
#'   Ignored when `drv` is passed explicitly.
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
local_con <- function(..., drv = duckdb(), extensions = TRUE) {
  if (!extensions) {
    drv <- duckdb(config = list(extension_directory = tempfile("duckdb-dummy-extensions")))
  }
  con <- dbConnect(drv, ...)
  withr::defer_parent(dbDisconnect(con, shutdown = TRUE))
  con
}
