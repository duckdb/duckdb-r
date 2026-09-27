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

test_that("a progress callback outlives a collection between the reads of a stream", {
  skip_if_not_installed("nanoarrow")

  calls <- 0L
  rlang::local_options(
    duckdb.progress_display = function(x) calls <<- calls + 1L
  )
  con <- local_con()
  dbExecute(con, "CREATE TABLE t AS SELECT i FROM range(1000000) t(i)")

  # getOption() hands the display a copy of the callback that nothing else
  # refers to, and a streaming result keeps its display until it is read.
  stream <- dbGetQueryArrow(
    con,
    "SELECT i FROM t WHERE i % 2 = 0",
    chunk_size = 10000
  )
  # Collect, and reuse the cells a collected callback would have left behind.
  for (pass in 1:5) {
    invisible(gc())
    garbage <- lapply(1:200000, function(i) list(i))
  }
  calls <- 0L

  rows <- 0
  while (!is.null(batch <- stream$get_next())) {
    rows <- rows + batch$length
  }
  expect_equal(rows, 500000)
  expect_gt(calls, 0L)
})

# Drives duckdb_progress_display() on a clock the test sets.
# The function it returns calls the display with progress `x` at `time`,
# in seconds, and returns what that call printed: "" for nothing.
local_progress_clock <- function(frame = parent.frame()) {
  old_last_time <- the$progress_last_time
  withr::defer(the$progress_last_time <- old_last_time, envir = frame)
  the$progress_last_time <- NULL

  now <- 0
  local_mocked_bindings(progress_now = function() now, .env = frame)

  function(time, x) {
    now <<- time
    out <- utils::capture.output(invisible(duckdb_progress_display(x)))
    paste(out, collapse = "\n")
  }
}

test_that("the progress display paints nothing in a query's first half second", {
  display_at <- local_progress_clock()

  expect_equal(display_at(0, 10), "")
  expect_equal(display_at(0.25, 20), "")
  expect_equal(display_at(0.375, 30), "")
  expect_equal(display_at(0.5, 40), "\rDuckDB progress:  40%")
})
