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

# Reading TIME_NS -------------------------------------------------------------

test_that("TIME_NS reads as TIME does, keeping each nanosecond to rounding", {
  con <- local_con()

  data <- dbGetQuery(
    con,
    "SELECT '01:02:03.123456789'::TIME_NS AS a, NULL::TIME_NS AS b,
       '23:59:59.999999999'::TIME_NS AS c, '24:00:00'::TIME_NS AS d"
  )
  expect_s3_class(data$a, "difftime")
  expect_equal(units(data$a), "secs")
  expect_identical(round(as.numeric(data$a) * 1e9), 3723123456789)
  expect_identical(
    data$b,
    structure(NA_real_, class = "difftime", units = "secs")
  )
  expect_identical(round(as.numeric(data$c) * 1e9), 86399999999999)
  expect_identical(as.numeric(data$d), 86400)

  # Every nanosecond at either end of the day comes back by rounding
  ns <- dbGetQuery(
    con,
    "SELECT n, make_timestamp_ns(n)::TIME_NS AS t FROM (
       SELECT i AS n FROM range(100000) AS r(i)
       UNION ALL SELECT 86400000000000 - 1 - i FROM range(100000) AS r(i)
     )"
  )
  expect_identical(round(as.numeric(ns$t) * 1e9), ns$n)
})

test_that("`time = \"hms\"` reads TIME_NS as hms, on every route", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms", array = "matrix")

  data <- dbGetQuery(
    con,
    "SELECT
       '00:00:01.5'::TIME_NS AS a,
       ['00:00:02'::TIME_NS, NULL] AS l,
       {'t': '00:00:03'::TIME_NS} AS s,
       MAP {'k': '00:00:04'::TIME_NS} AS m,
       ['00:00:05'::TIME_NS, NULL]::TIME_NS[2] AS arr"
  )
  expect_identical(data$a, hms::hms(1.5))
  expect_identical(data$l[[1]], hms::hms(c(2, NA)))
  expect_identical(data$s$t, hms::hms(3))
  expect_identical(data$m[[1]]$value, hms::hms(4))
  expect_identical(
    data$arr,
    structure(c(5, NA), dim = 1:2, class = c("hms", "difftime"), units = "secs")
  )

  empty <- dbGetQuery(con, "SELECT '00:00:01'::TIME_NS AS a WHERE false")
  expect_identical(empty$a, hms::hms())

  res <- dbSendQuery(
    con,
    "SELECT make_timestamp_ns(i * 1000000000)::TIME_NS AS a FROM range(3) AS r(i) ORDER BY i"
  )
  on.exit(dbClearResult(res))
  expect_identical(dbFetch(res, n = 2)$a, hms::hms(c(0, 1)))
  expect_identical(dbFetch(res)$a, hms::hms(2))

  df <- rel_to_altrep(rel_from_sql(con, "SELECT '00:00:06'::TIME_NS AS a"))
  expect_identical(df$a, hms::hms(6))
})

test_that("no R class writes TIME_NS, and its text does", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  data <- dbGetQuery(con, "SELECT '01:02:03.123456789'::TIME_NS AS a")
  dbExecute(con, "CREATE TABLE tbl (a TIME_NS)")
  expect_error(dbAppendTable(con, "tbl", data), "TIME -> TIME_NS", fixed = TRUE)

  dbWriteTable(
    con,
    "text",
    data.frame(a = "01:02:03.123456789"),
    field.types = c(a = "TIME_NS")
  )
  expect_equal(
    dbGetQuery(con, "SELECT a::VARCHAR AS a FROM text")$a,
    "01:02:03.123456789"
  )
})

# Writing with time = "hms" ------------------------------------------------

test_that("an hms writes INTERVAL under the default `time`", {
  skip_if_not_installed("hms")

  con <- local_con()

  dbWriteTable(con, "tbl", data.frame(a = hms::hms(3723.45)))
  expect_equal(dbGetQuery(con, "SELECT typeof(a) AS t FROM tbl")$t, "INTERVAL")
  expect_equal(
    dbGetQuery(con, "SELECT typeof(?) AS t", params = list(hms::hms(1)))$t,
    "INTERVAL"
  )
})

test_that("`time = \"hms\"` round-trips TIME through hms", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  data <- dbGetQuery(
    con,
    "SELECT * FROM (VALUES
       (1, TIME '01:02:03.456789'),
       (2, NULL),
       (3, TIME '00:00:00'),
       (4, TIME '24:00:00')
     ) AS t(i, a) ORDER BY i"
  )
  dbWriteTable(con, "tbl", data)
  expect_equal(
    dbGetQuery(con, "SELECT DISTINCT typeof(a) AS t FROM tbl")$t,
    "TIME"
  )
  expect_identical(dbReadTable(con, "tbl"), data)

  dbAppendTable(con, "tbl", data)
  expect_identical(dbGetQuery(con, "SELECT count(a) AS n FROM tbl")$n, 6)
})

test_that("`time = \"hms\"` keeps an hms and a difftime apart, in both directions", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  data <- data.frame(
    a = hms::hms(c(3723, NA)),
    b = as.difftime(c(90000, NA), units = "secs")
  )
  expect_equal(dbDataType(con, data), c(a = "TIME", b = "INTERVAL"))

  dbWriteTable(con, "tbl", data)
  expect_equal(
    dbGetQuery(con, "DESCRIBE tbl")$column_type,
    c("TIME", "INTERVAL")
  )
  expect_identical(dbReadTable(con, "tbl"), data)

  dbCreateTable(con, "tbl2", data)
  expect_equal(
    dbGetQuery(con, "DESCRIBE tbl2")$column_type,
    c("TIME", "INTERVAL")
  )
  dbAppendTable(con, "tbl2", data)
  expect_identical(dbReadTable(con, "tbl2"), data)

  bound <- dbGetQuery(
    con,
    "SELECT typeof(?) AS a, typeof(?) AS b",
    params = unname(as.list(data[1, ]))
  )
  expect_equal(unlist(bound), c(a = "TIME", b = "INTERVAL"))
})

test_that("dbDataType() keeps calling a difftime TIME under the default `time`", {
  skip_if_not_installed("hms")

  con <- local_con()

  expect_equal(
    dbDataType(
      con,
      data.frame(a = hms::hms(1), b = as.difftime(1, units = "secs"))
    ),
    c(a = "TIME", b = "TIME")
  )
})

test_that("`time = \"hms\"` appends an hms to the TIME column dbCreateTable() makes", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  data <- data.frame(a = hms::hms(c(3723, NA)))
  dbCreateTable(con, "tbl", data)
  expect_equal(dbGetQuery(con, "DESCRIBE tbl")$column_type, "TIME")
  dbAppendTable(con, "tbl", data)
  expect_identical(dbReadTable(con, "tbl"), data)
})

test_that("`time = \"hms\"` binds an hms parameter as TIME, and NA as NULL", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  data <- dbGetQuery(
    con,
    "SELECT typeof(?) AS t, ? AS a",
    params = list(hms::hms(c(3723.45, NA)), hms::hms(c(3723.45, NA)))
  )
  expect_equal(data$t, c("TIME", "TIME"))
  expect_identical(data$a, hms::hms(c(3723.45, NA)))

  # A plain difftime still binds as INTERVAL
  expect_equal(
    dbGetQuery(
      con,
      "SELECT typeof(?) AS t",
      params = list(as.difftime(1, units = "secs"))
    )$t,
    "INTERVAL"
  )
})

test_that("`time = \"hms\"` registers an hms column or field as TIME, but not an hms in a list", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  df <- data.frame(a = hms::hms(1:2))
  df$s <- data.frame(t = hms::hms(3:4))
  df$l <- list(hms::hms(5), hms::hms(6))
  duckdb_register(con, "df", df)

  types <- dbGetQuery(con, "DESCRIBE df")$column_type
  expect_equal(types, c("TIME", "STRUCT(t TIME)", "INTERVAL[]"))
})

test_that("`time = \"hms\"` rounds an hms to the microsecond", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  data <- dbGetQuery(
    con,
    "SELECT ?::VARCHAR AS a",
    params = list(hms::hms(c(1.0000004, 86400.0000004)))
  )
  expect_equal(data$a, c("00:00:01", "24:00:00"))
})

test_that("`time = \"hms\"` refuses an hms that TIME can't hold, naming its column or parameter", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  expect_snapshot(error = TRUE, {
    dbWriteTable(con, "tbl", data.frame(a = hms::hms(c(1, -1))))
    dbWriteTable(con, "tbl", data.frame(a = hms::hms(90000)))
    dbWriteTable(con, "tbl", data.frame(a = hms::hms(Inf)))
    dbGetQuery(con, "SELECT ? AS a", params = list(hms::hms(NaN)))
  })

  df <- data.frame(i = 1)
  df$s <- data.frame(t = hms::hms(-5))
  expect_error(duckdb_register(con, "df", df), "`s$t`", fixed = TRUE)

  expect_false(dbExistsTable(con, "tbl"))
})

test_that("`time = \"hms\"` no longer appends an hms to an INTERVAL column", {
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  dbExecute(con, "CREATE TABLE tbl (a INTERVAL)")
  expect_error(
    dbAppendTable(con, "tbl", data.frame(a = hms::hms(1))),
    "TIME -> INTERVAL",
    fixed = TRUE
  )
})

test_that("`time = \"hms\"` appends Arrow's time64 to a TIME column", {
  skip_if_not_installed("hms")
  skip_if_not_installed("nanoarrow")

  con <- local_con(time = "hms")

  stream <- function() {
    nanoarrow::as_nanoarrow_array_stream(data.frame(a = hms::hms(3723)))
  }
  dbCreateTableArrow(con, "tbl", stream())
  dbAppendTableArrow(con, "tbl", stream())
  expect_identical(dbReadTable(con, "tbl")$a, hms::hms(3723))
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

test_that("dbQuoteLiteral() quotes an hms as TIME under `time = \"hms\"`, and as before otherwise", {
  skip_if_not_installed("hms")

  x <- hms::hms(c(3723.5, NA, 86400, 0.000001))

  con <- local_con()
  expect_equal(
    as.character(dbQuoteLiteral(con, x)),
    c(
      "to_microseconds(3723500000)",
      "NULL",
      "to_microseconds(86400000000)",
      "to_microseconds(1)"
    )
  )

  con <- local_con(time = "hms")
  expect_equal(
    as.character(dbQuoteLiteral(con, x)),
    c(
      "'01:02:03.5'::TIME",
      "NULL",
      "'24:00:00'::TIME",
      "'00:00:00.000001'::TIME"
    )
  )
  data <- dbGetQuery(con, paste("SELECT", dbQuoteLiteral(con, x[1]), "AS a"))
  expect_identical(data$a, x[1])
  expect_error(dbQuoteLiteral(con, hms::hms(-1)), "to quote as `TIME`")
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
