test_that("fractional seconds can be roundtripped", {
  skip_if_not(TEST_RE2)

  con <- local_con()

  df <- data.frame(
    a = as.POSIXct(
      1.234567 + (1:100) * 1e-6,
      origin = structure(0, class = c("POSIXct", "POSIXt")),
      tz = "UTC"
    )
  )
  dbWriteTable(con, "df", df)
  df_out <- dbReadTable(con, "df")
  expect_equal(df_out, df)
})

test_that("fractional seconds can be extracted from TIME columns", {
  con <- local_con()

  data <- dbGetQuery(
    con,
    "SELECT TIME '01:02:03.45' AS a, INTERVAL '01:02:03.45' AS b"
  )
  expect_equal(
    data$a,
    structure(3723.45, class = "difftime", units = "secs")
  )
  expect_equal(
    data$b,
    structure(3723.45, class = "difftime", units = "secs")
  )
})

test_that("TIME WITH TIME ZONE columns are returned as difftime (#1807)", {
  con <- local_con()

  data <- dbGetQuery(
    con,
    "SELECT
       TIMETZ '01:02:03.45+05:00' AS a,
       TIMETZ '01:02:03.45-05:00' AS b,
       TIMETZ '01:02:03.45+00:00' AS c,
       CAST(NULL AS TIMETZ) AS d"
  )
  expected <- structure(3723.45, class = "difftime", units = "secs")
  expect_equal(data$a, expected)
  expect_equal(data$b, expected)
  expect_equal(data$c, expected)
  expect_equal(data$d, structure(NA_real_, class = "difftime", units = "secs"))
})

# Reading with time = "hms" ------------------------------------------------

test_that("`time = \"difftime\"` is the default", {
  con <- local_con(time = "difftime")

  data <- dbGetQuery(
    con,
    "SELECT TIME '01:02:03.45' AS a, TIMETZ '01:02:03.45+05:00' AS b"
  )
  expected <- structure(3723.45, class = "difftime", units = "secs")
  expect_identical(data$a, expected)
  expect_identical(data$b, expected)
})

test_that("`time = \"hms\"` reads TIME and TIMETZ as hms, and leaves INTERVAL alone", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  data <- dbGetQuery(
    con,
    "SELECT
       TIME '01:02:03.45' AS a,
       TIMETZ '01:02:03.45+05:00' AS b,
       CAST(NULL AS TIME) AS c,
       CAST(NULL AS TIMETZ) AS d,
       INTERVAL '01:02:03.45' AS e"
  )
  expect_identical(data$a, hms::hms(3723.45))
  expect_identical(data$b, hms::hms(3723.45))
  expect_identical(data$c, hms::hms(NA_real_))
  expect_identical(data$d, hms::hms(NA_real_))
  expect_identical(
    data$e,
    structure(3723.45, class = "difftime", units = "secs")
  )
})

test_that("`time = \"hms\"` reads zero rows and nested values as hms", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  empty <- dbGetQuery(con, "SELECT TIME '01:02:03' AS a WHERE false")
  expect_identical(empty$a, hms::hms())

  data <- dbGetQuery(
    con,
    "SELECT [TIME '00:00:01', NULL] AS l, {'t': TIME '00:00:02'} AS s"
  )
  expect_identical(data$l[[1]], hms::hms(c(1, NA)))
  expect_identical(data$s$t, hms::hms(2))
})

test_that("`time = \"hms\"` holds for every chunk dbFetch() returns", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  res <- dbSendQuery(
    con,
    "SELECT TIME '00:00:00' + to_seconds(i) AS a FROM range(5) AS r(i) ORDER BY i"
  )
  on.exit(dbClearResult(res))
  expect_identical(dbFetch(res, n = 2)$a, hms::hms(0:1 + 0))
  expect_identical(dbFetch(res, n = 2)$a, hms::hms(2:3 + 0))
  expect_identical(dbFetch(res)$a, hms::hms(4))
  expect_identical(dbFetch(res)$a, hms::hms())
})

test_that("`time = \"hms\"` reaches a relation's columns", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  df <- rel_to_altrep(rel_from_sql(con, "SELECT TIME '01:02:03' AS a"))
  expect_identical(df$a, hms::hms(3723))
})

test_that("an hms read under `time = \"hms\"` writes back as INTERVAL", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  data <- dbGetQuery(con, "SELECT TIME '01:02:03.45' AS a")
  dbWriteTable(con, "tbl", data)
  expect_equal(dbGetQuery(con, "SELECT typeof(a) AS t FROM tbl")$t, "INTERVAL")
  expect_identical(
    dbReadTable(con, "tbl")$a,
    structure(3723.45, class = "difftime", units = "secs")
  )
})

test_that("`time = \"hms\"` needs the hms package", {
  local_mocked_bindings(is_installed = function(pkg) pkg != "hms")

  expect_error(local_con(time = "hms"), "hms package must be installed")
  expect_no_error(local_con(time = "difftime"))
})

test_that("`time` rejects unknown values", {
  expect_error(local_con(time = "wat"), "difftime")
})

test_that("dbQuoteLiteral() keeps sub-second precision (#2646)", {
  con <- local_con()

  x <- as.POSIXct("2024-01-10 13:03:12", tz = "UTC") + 0.25
  literal <- dbQuoteLiteral(con, x)
  expect_match(as.character(literal), "13:03:12.25'")
  # Compared exactly: `expect_equal()`'s tolerance would accept the value
  # truncated to whole seconds, which is the bug.
  expect_identical(
    as.numeric(dbGetQuery(con, paste0("SELECT ", literal, " AS a"))$a),
    as.numeric(x)
  )

  # Whole seconds keep the shorter spelling, and NA is still NULL
  expect_match(
    as.character(dbQuoteLiteral(
      con,
      as.POSIXct("2024-01-10 13:03:12", tz = "UTC")
    )),
    "'2024-01-10 13:03:12'::timestamp",
    fixed = TRUE
  )
  expect_equal(
    as.character(dbQuoteLiteral(con, as.POSIXct(NA, tz = "UTC"))),
    "NULL::timestamp"
  )
})

test_that("dbQuoteLiteral() rounds a `POSIXct` to microseconds on both sides of the epoch", {
  con <- local_con()

  # Before 1970 the whole seconds round down and the fraction counts up from
  # there; a fraction that rounds to a full second carries into the minute.
  x <- .POSIXct(c(-1.25, -0.000001, 59.9999999), tz = "UTC")
  expect_equal(
    as.character(dbQuoteLiteral(con, x)),
    c(
      "'1969-12-31 23:59:58.75'::timestamp",
      "'1969-12-31 23:59:59.999999'::timestamp",
      "'1970-01-01 00:01:00'::timestamp"
    )
  )
})
