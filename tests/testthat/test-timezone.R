test_that("timezone_out works with default", {
  con <- local_con()

  query <- "SELECT '1970-01-01 12:00:00'::TIMESTAMP AS ts"
  res <- dbGetQuery(con, query)
  expect_equal(res[[1]], as.POSIXct("1970-01-01 12:00:00", tz = "UTC"))
})

test_that("timezone_out works with UTC specified", {
  con <- local_con(timezone_out = "UTC")

  query <- "SELECT '1970-01-01 12:00:00'::TIMESTAMP AS ts"
  res <- dbGetQuery(con, query)
  expect_equal(res[[1]], as.POSIXct("1970-01-01 12:00:00", tz = "UTC"))
})

test_that("timezone_out works with a specified timezone", {
  con <- local_con(timezone_out = "Pacific/Tahiti")

  query <- "SELECT '1970-01-01 12:00:00'::TIMESTAMP AS ts"
  res <- dbGetQuery(con, query)
  expect_equal(res[[1]], as.POSIXct("1970-01-01 02:00:00", tz = "Pacific/Tahiti"))
})

test_that("timezone_out works with '' and converts to local timezime", {
  unlockBinding(".sys.timezone", baseenv())
  withr::local_timezone("Pacific/Tahiti")
  con <- local_con(timezone_out = "")

  query <- "SELECT '1970-01-01 12:00:00'::TIMESTAMP AS ts"
  res <- dbGetQuery(con, query)
  expect_equal(res[[1]], as.POSIXct("1970-01-01 02:00:00", tz = "Pacific/Tahiti"))
})

test_that("timezone_out works with Sys.timezone", {
  unlockBinding(".sys.timezone", baseenv())
  withr::local_timezone("Pacific/Tahiti")
  con <- local_con(timezone_out = Sys.timezone())

  query <- "SELECT '1970-01-01 12:00:00'::TIMESTAMP AS ts"
  res <- dbGetQuery(con, query)
  expect_equal(res[[1]], as.POSIXct("1970-01-01 02:00:00", tz = "Pacific/Tahiti"))
})

test_that("timezone_out works with UTC and tz_out_convert = 'force'", {
  con <- local_con(timezone_out = "UTC", tz_out_convert = "force")

  query <- "SELECT '1970-01-01 12:00:00'::TIMESTAMP AS ts"
  res <- dbGetQuery(con, query)
  expect_equal(res[[1]], as.POSIXct("1970-01-01 12:00:00", tz = "UTC"))
})

test_that("timezone_out works with a specified timezone and tz_out_convert = 'force'", {
  con <- local_con(timezone_out = "Pacific/Tahiti", tz_out_convert = "force")

  query <- "SELECT '1970-01-01 12:00:00'::TIMESTAMP AS ts"
  res <- dbGetQuery(con, query)
  expect_equal(res[[1]], as.POSIXct("1970-01-01 12:00:00", tz = "Pacific/Tahiti"))
})

test_that("timezone_out works with '' and tz_out_convert = 'force': forces local timezime", {
  unlockBinding(".sys.timezone", baseenv())
  withr::local_timezone("Pacific/Tahiti")
  con <- local_con(timezone_out = "", tz_out_convert = "force")

  query <- "SELECT '1970-01-01 12:00:00'::TIMESTAMP AS ts"
  res <- dbGetQuery(con, query)
  expect_equal(res[[1]], as.POSIXct("1970-01-01 12:00:00", tz = "Pacific/Tahiti"))
})

test_that("timezone_out works with a specified local timezone and tz_out_convert = 'force': forces local timezime", {
  unlockBinding(".sys.timezone", baseenv())
  withr::local_timezone("Pacific/Tahiti")
  con <- local_con(timezone_out = Sys.timezone(), tz_out_convert = "force")

  query <- "SELECT '1970-01-01 12:00:00'::TIMESTAMP AS ts"
  res <- dbGetQuery(con, query)
  expect_equal(res[[1]], as.POSIXct("1970-01-01 12:00:00", tz = "Pacific/Tahiti"))
})

test_that("timezone_out gives a warning with invalid timezone, and converts to UTC", {
  expect_warning(con <- local_con(timezone_out = "not_a_timezone"))
  expect_equal(con@timezone_out, "UTC")
})

test_that("timezone_out gives a warning with NULL timezone, and converts to UTC", {
  expect_warning(con <- local_con(timezone_out = NULL))
  expect_equal(con@timezone_out, "UTC")
})

test_that("dbConnect fails when tz_out_convert is misspecified", {
  drv <- duckdb()
  on.exit(duckdb_shutdown(drv))

  expect_error(dbConnect(drv, tz_out_convert = "nope"))
})

test_that("timezone_out and tz_out_convert = force with midnight times (#8547)", {
  con <- local_con(timezone_out = "Etc/GMT+8", tz_out_convert = "force")

  dbExecute(
    con,
    "CREATE TABLE IF NOT EXISTS test( DATE_TIME TIMESTAMP );"
  )

  dbExecute(
    con,
    "INSERT INTO test(DATE_TIME) VALUES ('1975-01-01 00:00:00'),('1975-01-01 15:27:00');"
  )

  res <- dbGetQuery(con, "SELECT * FROM test;")
  expect_equal(res[[1]],
               as.POSIXct(c("1975-01-01 00:00:00", "1975-01-01 15:27:00"),
                          tz = "Etc/GMT+8"))
})

test_that("POSIXct with local time zone", {
  con <- local_con(timezone_out = "")

  df1 <- data.frame(a = structure(1745781814.84963, class = c("POSIXct", "POSIXt")))
  rel <- rel_from_df(con, df1)
  expect_equal(rel_to_altrep(rel), df1)

  # With extra class
  df2 <- data.frame(a = structure(1745781814.84963, class = c("foo", "POSIXct", "POSIXt")))
  rel <- rel_from_df(con, df2, strict = FALSE)
  expect_equal(rel_to_altrep(rel), df1)

  expect_error(rel_from_df(con, df2), "convert")
})

test_that("POSIXct with local time zone and existing but empty attribute", {
  con <- local_con(timezone_out = "")

  df1 <- data.frame(a = structure(1745781814.84963, class = c("POSIXct", "POSIXt"), tzone = ""))
  rel <- rel_from_df(con, df1)
  expect_equal(rel_to_altrep(rel), df1)

  # With extra class
  df2 <- data.frame(a = structure(1745781814.84963, class = c("foo", "POSIXct", "POSIXt"), tzone = ""))
  rel <- rel_from_df(con, df2, strict = FALSE)
  expect_equal(rel_to_altrep(rel), df1)

  expect_error(rel_from_df(con, df2), "convert")
})

test_that("tz_out_convert = force handles invalid timestamps during DST transitions", {
  withr::local_timezone("Europe/London")

  # This test reproduces the issue where invalid timestamps during DST transitions
  # cause all timestamps to lose their time component when tz_out_convert = "force"
  con <- local_con(timezone_out = "Europe/London", tz_out_convert = "force")

  # Test with a single valid timestamp
  query1 <- "VALUES ('2025-03-30 00:59:00'::TIMESTAMP);"
  res1 <- dbGetQuery(con, query1)
  expected1 <- as.POSIXct("2025-03-30 00:59:00", tz = "Europe/London")
  expect_equal(res1[[1]], expected1)

  # Test with mixed valid and invalid timestamps
  # 2025-03-30 01:00:00 does not exist in Europe/London (DST transition)
  query2 <- "VALUES ('2025-03-30 00:59:00'::TIMESTAMP), ('2025-03-30 01:00:00'::TIMESTAMP);"
  res2 <- dbGetQuery(con, query2)

  # The first timestamp should remain valid with full time information
  # The second should be NA (not stripped to date only)
  expected2 <- tz_force_one(timezone = "Europe/London", c(
    as.POSIXct("2025-03-30 00:59:00", format = "%Y-%m-%d %H:%M:%OS", tzone = "UTC"),
    as.POSIXct("2025-03-30 01:00:00", format = "%Y-%m-%d %H:%M:%OS", tzone = "UTC")
  ))
  expect_equal(res2[[1]], expected2)
})
