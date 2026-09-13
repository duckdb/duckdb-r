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
  # Only a display the engine still calls can show that the callback survived,
  # and an engine that reports no progress while a streaming result is read
  # never calls it. Ask this one, before anything is collected, on the second
  # read: the first starts the query and reports even where no later read does.
  rows <- 0
  batch <- stream$get_next()
  if (!is.null(batch)) {
    rows <- rows + batch$length
  }
  calls <- 0L
  batch <- stream$get_next()
  reports_while_streaming <- calls > 0L
  if (!is.null(batch)) {
    rows <- rows + batch$length
  }

  # Collect, and reuse the cells a collected callback would have left behind.
  for (pass in 1:5) {
    invisible(gc())
    garbage <- lapply(1:200000, function(i) list(i))
  }
  calls <- 0L

  while (!is.null(batch <- stream$get_next())) {
    rows <- rows + batch$length
  }
  expect_equal(rows, 500000)
  skip_if_not(
    reports_while_streaming,
    "the engine reports no progress after a stream's first read"
  )
  expect_gt(calls, 0L)
})

# Drives duckdb_progress_display() on a clock the test sets.
# The function it returns calls the display with progress `x` at `time`,
# in seconds, and returns what that call printed: "" for nothing.
local_progress_clock <- function(.local_envir = parent.frame()) {
  old_last_time <- the$progress_last_time
  old_painted <- the$progress_painted
  withr::defer(
    {
      the$progress_last_time <- old_last_time
      the$progress_painted <- old_painted
    },
    envir = .local_envir
  )
  the$progress_last_time <- NULL
  the$progress_painted <- NULL

  now <- 0
  local_mocked_bindings(progress_now = function() now, .env = .local_envir)

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

test_that("the progress display paints at most one line per half second", {
  display_at <- local_progress_clock()

  # A call every 1/64 second; the engine makes them denser still (#2748).
  times <- seq(0, 3, by = 1 / 64)
  out <- mapply(display_at, times, seq_along(times) / length(times) * 99)
  expect_equal(times[out != ""], seq(0.5, 3, by = 0.5))
})

test_that("completion clears a painted line, however soon after it comes", {
  display_at <- local_progress_clock()

  expect_equal(display_at(0, 10), "")
  expect_equal(display_at(0.5, 50), "\rDuckDB progress:  50%")
  expect_equal(display_at(0.625, 100), "\r                     \r")
  # The engine can report 100% before it finishes the display with 100%.
  expect_equal(display_at(0.75, 100), "")
})

test_that("a query done in its first half second leaves the next its own", {
  display_at <- local_progress_clock()

  expect_equal(display_at(0, 10), "")
  expect_equal(display_at(0.25, 100), "")

  expect_equal(display_at(10, 10), "")
  expect_equal(display_at(10.25, 20), "")
  expect_equal(display_at(10.5, 30), "\rDuckDB progress:  30%")
})

test_that("the next query clears the line of a query that never completed", {
  display_at <- local_progress_clock()
  rlang::local_options(duckdb.progress_display = TRUE)

  expect_equal(display_at(0, 10), "")
  expect_equal(display_at(0.5, 50), "\rDuckDB progress:  50%")
  # The query fails here, and the engine never finishes its display.

  # The engine builds the next query's display, which clears the line.
  out <- utils::capture.output(display <- get_progress_display())
  expect_equal(out, "\r                     \r")
  expect_identical(display, duckdb_progress_display)

  # That query starts its own half second, and completes without painting.
  expect_equal(display_at(10, 10), "")
  expect_equal(display_at(10.25, 100), "")
})
