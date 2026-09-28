test_that("test_all_types() output", {
  skip_on_os("windows")
  skip_if_not(getRversion() >= "4.3")

  con <- local_con(array = "matrix")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    bad <- c(
      # Need to omit timestamp columns, likely due to https://bugs.r-project.org/show_bug.cgi?id=16856
      "timestamp_tz",
      "timestamp_ns",
      "timestamp_array",
      "timestamptz_array",

      "bit",
      '"union"',
      "fixed_nested_int_array",
      "fixed_nested_varchar_array",
      "fixed_struct_array",
      "fixed_array_of_int_list",
      "bignum",
      NULL
    )

    as.list(dbGetQuery(
      con,
      paste0(
        "SELECT * EXCLUDE (",
        paste(bad, collapse = ", "),
        ") REPLACE(replace(varchar, chr(0), '') AS varchar) FROM test_all_types(use_large_enum=true)"
      )
    ))
  })
})

test_that("test_all_types() under bigint = \"integer64\"", {
  skip_on_os("windows")
  skip_if_not(getRversion() >= "4.3")
  skip_if_not_installed("bit64")

  con <- local_con(bigint = "integer64")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    as.list(dbGetQuery(
      con,
      "SELECT bigint, ubigint FROM test_all_types()"
    ))
  })
})

test_that("test_all_types() under array = \"matrix\"", {
  skip_on_os("windows")
  skip_if_not(getRversion() >= "4.3")

  con <- local_con(array = "matrix")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    as.list(dbGetQuery(
      con,
      "SELECT fixed_int_array, fixed_varchar_array,
         struct_of_fixed_array, list_of_fixed_int_array
       FROM test_all_types()"
    ))
  })
})

test_that("test_all_types() under map = \"list_of\"", {
  skip_on_os("windows")
  skip_if_not(getRversion() >= "4.3")
  skip_if_not_installed("vctrs")

  con <- local_con(map = "list_of")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    as.list(dbGetQuery(
      con,
      "SELECT map FROM test_all_types()"
    ))
  })
})

test_that("test_all_types() under geometry = \"wk\"", {
  skip_on_os("windows")
  skip_if_not(getRversion() >= "4.3")
  skip_if_not_installed("wk")

  con <- local_con(geometry = "wk")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    as.list(dbGetQuery(
      con,
      "SELECT geometry FROM test_all_types()"
    ))
  })
})

test_that("test_all_types() under time = \"hms\"", {
  skip_on_os("windows")
  skip_if_not(getRversion() >= "4.3")
  skip_if_not_installed("hms")

  con <- local_con(time = "hms")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    as.list(dbGetQuery(
      con,
      "SELECT time, time_tz, time_ns FROM test_all_types()"
    ))
  })
})

test_that("test_all_types() under blob = \"blob\"", {
  skip_on_os("windows")
  skip_if_not(getRversion() >= "4.3")
  skip_if_not_installed("blob")

  con <- local_con(blob = "blob")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    as.list(dbGetQuery(
      con,
      "SELECT blob FROM test_all_types()"
    ))
  })
})

test_that("test_all_types() under interval = \"Period\"", {
  skip_on_os("windows")
  skip_if_not(getRversion() >= "4.3")
  skip_if_not_installed("lubridate")

  con <- local_con(interval = "Period")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    as.list(dbGetQuery(
      con,
      "SELECT interval FROM test_all_types()"
    ))
  })
})

# The extreme values print in local mean time outside UTC, which depends on the
# time zone database, and `tz_out_convert = "force"` turns them into `NA`,
# so these two read the `NULL` row and an ordinary value.
test_that("test_all_types() under timezone_out = \"Europe/Berlin\"", {
  skip_on_os("windows")
  skip_if_not(getRversion() >= "4.3")

  con <- local_con(timezone_out = "Europe/Berlin")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    as.list(dbGetQuery(
      con,
      "SELECT timestamp, timestamp_s, timestamp_ms, timestamp_tz
       FROM test_all_types() WHERE timestamp IS NULL
       UNION ALL SELECT
         TIMESTAMP '2024-07-01 12:00:00.123456',
         TIMESTAMP_S '2024-07-01 12:00:00',
         TIMESTAMP_MS '2024-07-01 12:00:00.123',
         TIMESTAMPTZ '2024-07-01 12:00:00.123456+00'"
    ))
  })
})

test_that("test_all_types() under tz_out_convert = \"force\"", {
  skip_on_os("windows")
  skip_if_not(getRversion() >= "4.3")

  con <- local_con(timezone_out = "Europe/Berlin", tz_out_convert = "force")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    as.list(dbGetQuery(
      con,
      "SELECT timestamp, timestamp_s, timestamp_ms, timestamp_tz
       FROM test_all_types() WHERE timestamp IS NULL
       UNION ALL SELECT
         TIMESTAMP '2024-07-01 12:00:00.123456',
         TIMESTAMP_S '2024-07-01 12:00:00',
         TIMESTAMP_MS '2024-07-01 12:00:00.123',
         TIMESTAMPTZ '2024-07-01 12:00:00.123456+00'"
    ))
  })
})

# A column carrying a class attribute -- `units`, and anything else built the
# same way -- crosses as the numeric underneath it, so the value is what a
# caller gets back and can re-apply the class to:
# handbook/usage/types/README.md, reported as #590.
test_that("the value of a classed numeric column survives every route in", {
  con <- local_con()

  df <- data.frame(id = 1:3)
  df$area <- structure(c(1.5, 2.5, 3.5), class = "area_unit")

  dbWriteTable(con, "written", df)
  expect_equal(
    dbGetQuery(con, "SELECT area FROM written")$area,
    c(1.5, 2.5, 3.5)
  )

  duckdb_register(con, "registered", df)
  expect_equal(
    dbGetQuery(con, "SELECT area FROM registered")$area,
    c(1.5, 2.5, 3.5)
  )

  bound <- dbGetQuery(
    con,
    "SELECT ? AS area",
    params = list(structure(2.5, class = "area_unit"))
  )
  expect_equal(bound$area, 2.5)
})

test_that("a table whose columns R cannot hold is still found and listed", {
  con <- local_con()

  for (type in c("BIT", "BIGNUM", "UNION(a INTEGER)")) {
    dbExecute(con, paste("CREATE OR REPLACE TABLE t (x", type, ", y INTEGER)"))

    expect_true(dbExistsTable(con, "t"), info = type)
    expect_equal(dbListFields(con, "t"), c("x", "y"), info = type)
  }
})

test_that("a column R cannot hold is refused by name", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()

  res <- dbSendQueryArrow(con, "SELECT '101'::BIT AS x")
  on.exit(dbClearResult(res))

  expect_equal(dbColumnInfo(res)$type, "unknown")
  expect_error(dbGetQuery(con, "SELECT '101'::BIT AS x"), "column `x`: BIT")
})

test_that("a statement returning a column R cannot hold is refused before it runs", {
  con <- local_con()
  dbExecute(
    con,
    "CREATE TABLE t (x BIT, s STRUCT(u UNION(i INTEGER)), y INTEGER)"
  )
  count <- function() dbGetQuery(con, "SELECT count(*) AS n FROM t")$n

  expect_error(
    dbGetQuery(con, "INSERT INTO t (x, y) VALUES ('1', 1) RETURNING x"),
    "column `x`: BIT"
  )
  expect_error(
    dbExecute(con, "INSERT INTO t (x, y) VALUES ('1', 1) RETURNING x"),
    "column `x`: BIT"
  )
  expect_error(
    dbGetQuery(
      con,
      "INSERT INTO t (x, y) VALUES (?, ?) RETURNING x",
      params = list("1", 1L)
    ),
    "column `x`: BIT"
  )
  # So is one nested in a struct
  expect_error(
    dbGetQuery(con, "INSERT INTO t (y) VALUES (1) RETURNING s"),
    "column `s\\$u`: UNION"
  )
  expect_equal(count(), 0)
})

test_that("a statement returning a column R cannot hold runs through Arrow", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x BIT, y INTEGER)")
  count <- function() dbGetQuery(con, "SELECT count(*) AS n FROM t")$n

  res <- dbGetQueryArrow(con, "INSERT INTO t VALUES ('1', 1) RETURNING x")
  expect_equal(nrow(as.data.frame(res)), 1)
  expect_equal(count(), 1)

  res <- dbSendQueryArrow(con, "INSERT INTO t VALUES ('10', 2) RETURNING x")
  expect_equal(dbColumnInfo(res)$type, "unknown")
  expect_equal(nrow(as.data.frame(dbFetchArrow(res))), 1)
  dbClearResult(res)
  expect_equal(count(), 2)
})
