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

test_that("dbQuoteLiteral() keeps sub-second precision (#2646)", {
  # The naive spelling, which `posixct = "timestamp"` is what still reaches
  con <- local_con(posixct = "timestamp")

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

test_that("a TIMESTAMPTZ literal keeps sub-seconds and NA (#2646)", {
  con <- local_con()

  x <- as.POSIXct("2024-01-10 13:03:12", tz = "UTC") + 0.25
  literal <- dbQuoteLiteral(con, x)
  expect_match(as.character(literal), "13:03:12.25+00:00'", fixed = TRUE)
  expect_identical(
    as.numeric(dbGetQuery(con, paste0("SELECT ", literal, " AS a"))$a),
    as.numeric(x)
  )

  expect_equal(
    as.character(dbQuoteLiteral(con, as.POSIXct(NA, tz = "UTC"))),
    "NULL::timestamptz"
  )
})

test_that("dbQuoteLiteral() rounds a `POSIXct` to microseconds on both sides of the epoch", {
  # Before 1970 the whole seconds round down and the fraction counts up from
  # there; a fraction that rounds to a full second carries into the minute.
  x <- .POSIXct(c(-1.25, -0.000001, 59.9999999), tz = "UTC")

  con <- local_con(posixct = "timestamp")
  expect_equal(
    as.character(dbQuoteLiteral(con, x)),
    c(
      "'1969-12-31 23:59:58.75'::timestamp",
      "'1969-12-31 23:59:59.999999'::timestamp",
      "'1970-01-01 00:01:00'::timestamp"
    )
  )

  # The TIMESTAMPTZ spelling shares the rounding and only adds the offset
  con <- local_con()
  expect_equal(
    as.character(dbQuoteLiteral(con, x)),
    c(
      "'1969-12-31 23:59:58.75+00:00'::timestamptz",
      "'1969-12-31 23:59:59.999999+00:00'::timestamptz",
      "'1970-01-01 00:01:00+00:00'::timestamptz"
    )
  )
})
