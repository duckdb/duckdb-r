expect_equal_difftime <- function(a, b) {
  expect_equal(as.numeric(a, units = "secs"), as.numeric(b, units = "secs"))
}

test_that("we can retrieve an interval", {
  con <- local_con()

  res <- dbGetQuery(
    con,
    "SELECT '2021-11-26'::TIMESTAMP-'1984-04-24'::TIMESTAMP i"
  )
  expect_equal_difftime(as.Date("2021-11-26") - as.Date("1984-04-24"), res$i)

  res <- dbGetQuery(
    con,
    "SELECT '2021-11-26 12:01:00'::TIMESTAMP-'2021-11-26 12:00:00'::TIMESTAMP i"
  )
  expect_equal_difftime(
    as.POSIXct("2021-11-26 12:01:00") - as.POSIXct("2021-11-26 12:00:00"),
    res$i
  )

  res <- dbGetQuery(
    con,
    "SELECT '1984-04-24'::TIMESTAMP-'2021-11-26'::TIMESTAMP i"
  )
  expect_equal_difftime(as.Date("1984-04-24") - as.Date("2021-11-26"), res$i)

  res <- dbGetQuery(
    con,
    "SELECT '2021-11-26 12:00:00'::TIMESTAMP - '2021-11-26 12:01:00'::TIMESTAMP i"
  )
  expect_equal_difftime(
    as.POSIXct("2021-11-26 12:00:00") - as.POSIXct("2021-11-26 12:01:00"),
    res$i
  )

  res <- dbGetQuery(con, "SELECT NULL::INTERVAL i")
  expect_true(is.na(res$i))
})

test_that("an integer-backed difftime column keeps its NA, in every unit", {
  con <- local_con()

  for (units in c("secs", "mins", "hours", "days", "weeks")) {
    df <- data.frame(
      i = structure(c(5L, NA), class = "difftime", units = units)
    )
    duckdb_register(con, "df", df, overwrite = TRUE)

    res <- dbGetQuery(con, "SELECT i IS NULL AS n FROM df")
    expect_equal(res$n, c(FALSE, TRUE), info = units)
  }
})

# Reading and writing with interval = "Period" -----------------------------

test_that("`interval = \"difftime\"` is the default, counting a month as 30 days", {
  con <- local_con(interval = "difftime")

  data <- dbGetQuery(con, "SELECT INTERVAL 1 MONTH AS a, NULL::INTERVAL AS b")
  expect_identical(
    data$a,
    structure(2592000, class = "difftime", units = "secs")
  )
  expect_identical(
    data$b,
    structure(NA_real_, class = "difftime", units = "secs")
  )
})

test_that("`interval = \"Period\"` keeps the months, days and microseconds apart", {
  skip_if_not_installed("lubridate")

  con <- local_con(interval = "Period")

  data <- dbGetQuery(
    con,
    "SELECT * FROM (VALUES
       (1, INTERVAL '1 month 2 days 00:00:03.000001'),
       (2, NULL),
       (3, INTERVAL '-1 month 2 days -00:00:01.5'),
       (4, INTERVAL 1 YEAR),
       (5, INTERVAL 30 DAY)
     ) AS t(i, a) ORDER BY i"
  )
  expect_identical(
    data$a,
    lubridate::period(
      months = c(1, NA, -1, 12, 0),
      days = c(2, NA, 2, 0, 30),
      seconds = c(3.000001, NA, -1.5, 0, 0)
    )
  )
})

test_that("`interval = \"Period\"` reads zero rows and nested values as Period", {
  skip_if_not_installed("lubridate")

  con <- local_con(interval = "Period")

  empty <- dbGetQuery(con, "SELECT INTERVAL 1 DAY AS a WHERE false")
  expect_identical(empty$a, lubridate::period())

  data <- dbGetQuery(
    con,
    "SELECT
       [INTERVAL 1 MONTH, NULL] AS l,
       {'p': INTERVAL 2 DAY} AS s,
       MAP {'k': INTERVAL 3 HOUR} AS m"
  )
  expect_identical(data$l[[1]], lubridate::period(months = c(1, NA)))
  expect_identical(data$s$p, lubridate::period(days = 2))
  expect_identical(data$m[[1]]$value, lubridate::period(seconds = 10800))
})

test_that("`interval = \"Period\"` holds for every chunk dbFetch() returns", {
  skip_if_not_installed("lubridate")

  con <- local_con(interval = "Period")

  res <- dbSendQuery(
    con,
    "SELECT to_months(i::INTEGER) AS a FROM range(5) AS r(i) ORDER BY i"
  )
  on.exit(dbClearResult(res))
  expect_identical(dbFetch(res, n = 2)$a, lubridate::period(months = 0:1))
  expect_identical(dbFetch(res)$a, lubridate::period(months = 2:4))
  expect_identical(dbFetch(res)$a, lubridate::period())
})

test_that("`interval = \"Period\"` reaches a relation's columns, fields included", {
  skip_if_not_installed("lubridate")

  con <- local_con(interval = "Period")

  df <- rel_to_altrep(rel_from_sql(
    con,
    "SELECT INTERVAL '1 month 2 days 00:00:03' AS a, {'p': INTERVAL 5 DAY} AS s"
  ))
  expect_identical(
    df$a,
    lubridate::period(months = 1, days = 2, seconds = 3)
  )
  expect_identical(df$s$p, lubridate::period(days = 5))
})

test_that("a Period read under `interval = \"Period\"` adds a month as DuckDB does", {
  skip_if_not_installed("lubridate")

  con <- local_con(interval = "Period")

  data <- dbGetQuery(
    con,
    "SELECT
       INTERVAL 1 MONTH AS p,
       (DATE '2024-01-31' + INTERVAL 1 MONTH)::DATE AS d,
       TIMESTAMP '2024-01-31 12:00:00' + INTERVAL '1 month 1 day 01:00:00.5' AS ts,
       INTERVAL '1 month 1 day 01:00:00.5' AS q"
  )
  expect_identical(lubridate::`%m+%`(as.Date("2024-01-31"), data$p), data$d)
  expect_equal(
    lubridate::`%m+%`(as.POSIXct("2024-01-31 12:00:00", tz = "UTC"), data$q),
    data$ts
  )
})

test_that("`interval = \"Period\"` round-trips INTERVAL through Period", {
  skip_if_not_installed("lubridate")

  con <- local_con(interval = "Period")

  data <- dbGetQuery(
    con,
    "SELECT * FROM (VALUES
       (1, INTERVAL '1 month 2 days 00:00:03.000001'),
       (2, NULL),
       (3, INTERVAL '-14 months -2 days 25:00:00')
     ) AS t(i, a) ORDER BY i"
  )
  dbWriteTable(con, "tbl", data)
  expect_equal(
    dbGetQuery(con, "SELECT a::VARCHAR AS a FROM tbl ORDER BY i")$a,
    c(
      "1 month 2 days 00:00:03.000001",
      NA,
      "-1 year -2 months -2 days 25:00:00"
    )
  )
  expect_identical(dbReadTable(con, "tbl"), data)

  dbAppendTable(con, "tbl", data)
  expect_identical(dbGetQuery(con, "SELECT count(a) AS n FROM tbl")$n, 4)
})

test_that("`interval = \"Period\"` writes a Period column, field or parameter as INTERVAL", {
  skip_if_not_installed("lubridate")

  con <- local_con(interval = "Period")

  p <- lubridate::period(months = 1, days = 2, seconds = 3.000001)
  df <- data.frame(a = p)
  df$s <- data.frame(p = p)
  expect_equal(dbDataType(con, df), c(a = "INTERVAL", s = "INTERVAL"))

  duckdb_register(con, "df", df)
  expect_equal(
    dbGetQuery(con, "DESCRIBE df")$column_type,
    c("INTERVAL", "STRUCT(p INTERVAL)")
  )

  dbCreateTable(con, "tbl", df["a"])
  expect_equal(dbGetQuery(con, "DESCRIBE tbl")$column_type, "INTERVAL")

  bound <- dbGetQuery(
    con,
    "SELECT typeof(?) AS t, ?::VARCHAR AS v",
    params = list(c(p, NA), c(p, NA))
  )
  expect_equal(bound$t, c("INTERVAL", "INTERVAL"))
  expect_equal(bound$v, c("1 month 2 days 00:00:03.000001", NA))
})

test_that("a Period of seconds alone writes DOUBLE under the default `interval`", {
  skip_if_not_installed("lubridate")

  con <- local_con()

  p <- lubridate::seconds(c(2.5, NA))
  dbWriteTable(con, "tbl", data.frame(a = p))
  data <- dbGetQuery(con, "SELECT typeof(a) AS t, a FROM tbl")
  expect_equal(data$t, c("DOUBLE", "DOUBLE"))
  expect_identical(data$a, c(2.5, NA))

  dbWriteTable(con, "empty", data.frame(a = p[0]))
  expect_equal(dbGetQuery(con, "DESCRIBE empty")$column_type, "DOUBLE")

  bound <- dbGetQuery(
    con,
    "SELECT typeof(?) AS t, ? AS a",
    params = list(p[1], p[1])
  )
  expect_equal(bound$t, "DOUBLE")
  expect_identical(bound$a, 2.5)
  expect_equal(dbDataType(con, lubridate::period(months = 1)), "DOUBLE")
})

test_that("a Period with more than seconds is refused under the default `interval`, on every route", {
  skip_if_not_installed("lubridate")

  con <- local_con()

  p <- lubridate::period(months = 1, minutes = 5, seconds = 6.5)
  field <- data.frame(i = 1)
  field$s <- data.frame(p = p)
  cell <- data.frame(i = 1)
  cell$l <- list(c(lubridate::seconds(1), p))

  expect_snapshot(error = TRUE, {
    dbWriteTable(con, "tbl", data.frame(a = c(lubridate::seconds(1), p)))
    duckdb_register(con, "field", field)
    dbWriteTable(con, "cell", cell)
    dbGetQuery(con, "SELECT ? AS a", params = list(p))
  })
  expect_false(dbExistsTable(con, "tbl"))
  expect_false(dbExistsTable(con, "cell"))
})

test_that("a Period in a list writes its seconds alone under `interval = \"Period\"` too", {
  skip_if_not_installed("lubridate")

  con <- local_con(interval = "Period")

  seconds <- data.frame(i = 1)
  seconds$l <- list(lubridate::seconds(c(1, 2.5)))
  dbWriteTable(con, "tbl", seconds)
  expect_equal(
    dbGetQuery(con, "SELECT l::VARCHAR AS l FROM tbl")$l,
    "[1.0, 2.5]"
  )

  more <- data.frame(i = 1)
  more$l <- list(lubridate::period(days = 1))
  map <- data.frame(i = 1)
  map$m <- list(data.frame(key = "a", value = lubridate::period(months = 2)))
  expect_snapshot(error = TRUE, {
    dbAppendTable(con, "tbl", more)
    dbWriteTable(con, "map", map, field.types = c(m = "MAP(VARCHAR, INTERVAL)"))
  })
  expect_false(dbExistsTable(con, "map"))
})

test_that("`interval = \"Period\"` refuses a Period that INTERVAL can't hold, naming its column or parameter", {
  skip_if_not_installed("lubridate")

  con <- local_con(interval = "Period")

  expect_snapshot(error = TRUE, {
    dbWriteTable(
      con,
      "tbl",
      data.frame(a = lubridate::period(seconds = c(1, Inf)))
    )
    dbGetQuery(
      con,
      "SELECT ? AS a",
      params = list(lubridate::period(months = 3e9))
    )
  })
  expect_false(dbExistsTable(con, "tbl"))
})

test_that("`interval = \"Period\"` refuses an array of INTERVAL", {
  skip_if_not_installed("lubridate")

  con <- local_con(interval = "Period", array = "matrix")

  expect_error(
    dbGetQuery(con, "SELECT [INTERVAL 1 DAY]::INTERVAL[1] AS a"),
    "can't be returned to R with `interval = \"Period\"`",
    fixed = TRUE
  )
})

test_that("`interval = \"Period\"` needs the lubridate package", {
  local_mocked_bindings(is_installed = function(pkg) pkg != "lubridate")

  expect_error(
    local_con(interval = "Period"),
    "lubridate package must be installed"
  )
  expect_no_error(local_con(interval = "difftime"))
})

test_that("`interval` rejects unknown values", {
  expect_error(local_con(interval = "wat"), "difftime")
})
