test_that("progress display", {
  # Restore at end
  rlang::local_options(duckdb.progress_display = NULL)

  if (!is_interactive()) {
    options(duckdb.progress_display = NULL)
    expect_null(get_progress_display())
  }

  options(duckdb.progress_display = 5)
  expect_message(
    expect_null(get_progress_display()),
    "expecting either a boolean or function"
  )

  options(duckdb.progress_display = function() {})
  expect_message(
    expect_null(get_progress_display()),
    "has no argument, expecting at least one"
  )

  rlang::local_interactive()

  options(duckdb.progress_display = function(x) {})
  expect_type(get_progress_display(), "closure")

  options(duckdb.progress_display = TRUE)
  expect_identical(get_progress_display(), duckdb_progress_display)

  options(duckdb.progress_display = FALSE)
  expect_null(get_progress_display())

  # Default in interactive setting
  options(duckdb.progress_display = NULL)
  expect_identical(get_progress_display(), duckdb_progress_display)
})

test_that("a handle collected while the display is created does not deadlock", {
  skip_if_not_installed("callr")

  # Pins the callback rule in handbook/architecture/glue/README.md: duckdb
  # builds the progress bar -- and with it this display -- from
  # ClientContext::PendingPreparedStatementInternal(), which holds the client
  # context lock, and building it looks the R callback up. That is arbitrary R
  # code, so R may collect garbage there and run the finalizer of any engine
  # handle it still holds; no such finalizer may re-enter that context.
  #
  # A regression deadlocks rather than failing, so run it in a subprocess with
  # a time limit instead of wedging the whole test run.
  pkg <- get_package_name()

  result <- callr::r(
    function(pkg) {
      ns <- asNamespace(pkg)
      con <- DBI::dbConnect(ns$duckdb())
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

      # Leave a prepared statement unreachable, but not yet collected:
      # the result is deliberately never cleared, and the frame holding it
      # is gone by the time the query below runs.
      leave_garbage <- function() {
        res <- DBI::dbSendQuery(con, "SELECT 1")
        invisible(NULL)
      }
      leave_garbage()

      # Collect it from inside the lookup, where the lock is held.
      if (bindingIsLocked("get_progress_display", ns)) {
        unlockBinding("get_progress_display", ns)
      }
      assign(
        "get_progress_display",
        function() {
          gc()
          NULL
        },
        envir = ns
      )

      DBI::dbGetQuery(con, "SELECT 1 AS a")$a
    },
    args = list(pkg),
    timeout = 60
  )

  expect_equal(result, 1)
})
