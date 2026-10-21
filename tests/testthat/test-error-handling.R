test_that("rapi_error functions accept additional parameters", {
  skip_if(getRversion() < "4.2", "Error message formatting differs in R 4.1")
  local_edition(3)
  rlang::local_options(cli.num_colors = 1)

  # Test that our updated function signatures work with default parameters
  expect_snapshot(error = TRUE, {
    rapi_error("test_context", "test message")
  })

  # Test with additional parameters (should not cause different errors about function signature)
  expect_snapshot(error = TRUE, {
    rapi_error("test_context", "test message", "PARSER")
  })
  expect_snapshot(error = TRUE, {
    rapi_error(
      "test_context",
      "test message",
      "PARSER",
      "raw message",
      c(key = "value")
    )
  })
})

test_that("`raw_message` and `extra_info` stay off the message", {
  # The message is for a reader; the rest is data on the condition. `extra_info`
  # especially, which can hold a resolved stack trace or a list of candidate
  # names. https://github.com/duckdb/duckdb-r/issues/2711
  err <- expect_error(rapi_error(
    "test_context",
    "test message",
    "PARSER",
    "raw message",
    c(key = "value")
  ))

  expect_no_match(conditionMessage(err), "raw message", fixed = TRUE)
  expect_no_match(conditionMessage(err), "key: value", fixed = TRUE)
  expect_equal(err$raw_message, "raw message")
  expect_equal(err$extra_info, c(key = "value"))
})

# https://github.com/duckdb/duckdb-r/issues/2711
test_that("engine errors carry DuckDB's classification, not just its wording", {
  con <- local_con()

  err <- expect_error(dbGetQuery(con, "SELECT missing_column"))

  expect_s3_class(err, "duckdb_error")
  expect_equal(err$error_type, "BINDER")
  expect_equal(err$context, "rapi_prepare")
  expect_match(err$raw_message, "missing_column")
  expect_equal(err$extra_info[["error_subtype"]], "COLUMN_NOT_FOUND")
})

test_that("the error type survives execution failures, not only prepare", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE t (x INTEGER PRIMARY KEY)")
  dbExecute(con, "INSERT INTO t VALUES (1)")

  # Rebuilding the error from its message would report both of these as INVALID,
  # which is what a caller telling a constraint violation from an I/O failure
  # needs them not to say.
  err <- expect_error(dbExecute(con, "INSERT INTO t VALUES (1)"))
  expect_equal(err$error_type, "CONSTRAINT")
  expect_equal(err$context, "rapi_execute")

  # A row that only fails once it is produced. The driver materializes at
  # `dbSendQuery()`, so this is where a fetch-time failure surfaces.
  err <- expect_error(dbGetQuery(
    con,
    "SELECT CAST(x AS INTEGER) FROM (VALUES ('1'), ('x')) v(x)"
  ))
  expect_equal(err$error_type, "CONVERSION")
  expect_equal(err$context, "rapi_execute")
})

test_that("bind failures are classified too", {
  con <- local_con()

  res <- dbSendQuery(con, "SELECT $1::int")
  withr::defer(dbClearResult(res))

  err <- expect_error(dbBind(res, list(1L, 2L)))
  expect_s3_class(err, "duckdb_error")
  expect_equal(err$context, "rapi_bind")
})

test_that("the rethrow names the caller and keeps the message readable", {
  skip_if(getRversion() < "4.2", "Error message formatting differs in R 4.1")
  local_edition(3)
  rlang::local_options(cli.num_colors = 1)
  con <- local_con()

  # The call is the user's, not the `rapi_prepare()` that noticed, and the two
  # `extra_info` entries this error carries stay off the message.
  expect_snapshot(error = TRUE, {
    dbGetQuery(con, "SELECT missing_column")
  })
})

test_that("errors raised before the engine keep the plain rethrow", {
  con <- local_con()

  err <- expect_error(dbGetQuery(con, "SELECT 1", n = "many"))
  expect_false(inherits(err, "duckdb_error"))
  expect_null(err$error_type)
})

test_that("the no-rlang fallback carries the same fields", {
  # `rapi_error_base()` is what `rapi_error()` stays bound to when rlang is
  # absent, and is reachable under its own name so this can be checked here.
  err <- expect_error(rapi_error_base(
    "rapi_execute",
    "Constraint Error: Duplicate key",
    "CONSTRAINT",
    "Duplicate key",
    c(position = "7")
  ))

  expect_s3_class(err, "duckdb_error")
  expect_equal(err$error_type, "CONSTRAINT")
  expect_equal(err$context, "rapi_execute")
  expect_equal(err$raw_message, "Duplicate key")
  expect_equal(err$extra_info[["position"]], "7")
})

test_that("a field the engine did not supply is absent, not NULL-valued", {
  err <- expect_error(rapi_error_base("rapi_prepare", "some message"))

  expect_false("error_type" %in% names(err))
  expect_null(err$error_type)
})
