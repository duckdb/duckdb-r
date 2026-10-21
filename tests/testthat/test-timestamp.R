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

test_that("a half microsecond rounds to even when written, as when quoted", {
  con <- local_con()

  # 2.5 and 3.5 microseconds are ties; both rules agree on 3.5, and only
  # half to even takes 2.5 to 2.
  s <- c(2.5e-6, 3.5e-6, -2.5e-6, -3.5e-6)
  df <- data.frame(
    i = seq_along(s),
    x = .POSIXct(s, tz = "UTC"),
    d = as.difftime(s, units = "secs")
  )
  dbWriteTable(con, "ties", df)
  written <- dbGetQuery(
    con,
    "SELECT epoch_us(x) AS x, to_microseconds(0) + d AS d FROM ties ORDER BY i"
  )
  expect_identical(written$x, c(2, 4, -2, -4))
  expect_identical(as.numeric(written$d, units = "secs") * 1e6, c(2, 4, -2, -4))

  # A literal quoted from each value finds the row written from it
  for (k in seq_along(s)) {
    for (col in c("x", "d")) {
      lit <- dbQuoteLiteral(con, df[[col]][k])
      n <- dbGetQuery(
        con,
        paste0("SELECT count(*) AS n FROM ties WHERE ", col, " = ", lit)
      )$n
      expect_identical(n, 1, info = paste(col, k))
    }
  }

  # A present-day instant on a tie, where the two rules used to disagree
  x <- .POSIXct(1700000000.0000025, tz = "UTC")
  dbExecute(
    con,
    "CREATE TABLE now AS SELECT ?::TIMESTAMP AS x",
    params = list(x)
  )
  expect_identical(
    dbGetQuery(
      con,
      paste("SELECT count(*) AS n FROM now WHERE x =", dbQuoteLiteral(con, x))
    )$n,
    1
  )
})
