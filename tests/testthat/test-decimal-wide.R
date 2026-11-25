# A DECIMAL wider than 38 digits stores its digits as a BIGNUM instead of a
# fixed-size integer, and the engine binds one by default:
# the sum of two DECIMAL(38, 2) is a DECIMAL(39, 2).
# It reads as `numeric`, as the narrower widths do (handbook/usage/types/README.md).

wide_decimal_types <- c(
  "DECIMAL(39, 2)",
  "DECIMAL(76, 10)",
  "DECIMAL(255, 0)",
  "DECIMAL(300, 150)"
)

test_that("a wide DECIMAL reads as numeric", {
  con <- local_con()

  for (type in wide_decimal_types) {
    res <- dbGetQuery(
      con,
      sprintf(
        "SELECT x::%s AS x FROM (VALUES ('2'), (NULL), ('-12345'), ('0')) t(x)",
        type
      )
    )
    expect_identical(res$x, c(2, NA, -12345, 0), label = type)
  }

  res <- dbGetQuery(
    con,
    "SELECT '1.5'::DECIMAL(39, 2) AS a, '-12345.25'::DECIMAL(76, 10) AS b, '0.125'::DECIMAL(300, 150) AS c"
  )
  expect_identical(res, data.frame(a = 1.5, b = -12345.25, c = 0.125))

  # the result of arithmetic that no longer fits 38 digits
  res <- dbGetQuery(
    con,
    "SELECT 999999999999999999999999999999999999.99::DECIMAL(38, 2) + 1::DECIMAL(38, 2) AS x"
  )
  expect_identical(res$x, 1e36)
  expect_identical(
    dbGetQuery(
      con,
      "SELECT typeof(1::DECIMAL(38, 2) + 1::DECIMAL(38, 2)) AS t"
    )$t,
    "DECIMAL(39,2)"
  )
})

test_that("a wide DECIMAL reads as the nearest double", {
  con <- local_con()

  res <- dbGetQuery(
    con,
    "SELECT
      '1267650600228229401496703205376'::DECIMAL(50, 0) AS exact,
      '9007199254740993'::DECIMAL(50, 0) AS tie_down,
      '9007199254740995'::DECIMAL(50, 0) AS tie_up,
      '9007199254740993.0000000000000000000000000000000000000001'::DECIMAL(60, 40) AS above_tie,
      '0.1'::DECIMAL(50, 40) AS tenth,
      '-0.1'::DECIMAL(300, 150) AS negative_tenth"
  )
  expect_identical(res$exact, 2^100)
  expect_identical(res$tie_down, 2^53)
  expect_identical(res$tie_up, 2^53 + 4)
  expect_identical(res$above_tie, 2^53 + 2)
  expect_identical(res$tenth, 0.1)
  expect_identical(res$negative_tenth, -0.1)

  # past the range of a double
  res <- dbGetQuery(
    con,
    "SELECT ('1' || repeat('0', 399))::DECIMAL(400, 0) AS big, ('-1' || repeat('0', 399))::DECIMAL(400, 0) AS small"
  )
  expect_identical(res$big, Inf)
  expect_identical(res$small, -Inf)
})

test_that("a wide DECIMAL reads inside nested types and across chunks", {
  con <- local_con()

  res <- dbGetQuery(
    con,
    "SELECT [1.5::DECIMAL(50, 2), NULL, 2.25] AS l, {'a': 1.5::DECIMAL(50, 2), 'b': NULL::DECIMAL(50, 2)} AS s"
  )
  expect_identical(res$l[[1]], c(1.5, NA, 2.25))
  expect_identical(res$s$a, 1.5)
  expect_identical(res$s$b, NA_real_)

  res <- dbGetQuery(
    con,
    "SELECT CASE WHEN i % 7 = 0 THEN NULL ELSE i END::DECIMAL(50, 2) / 4 AS x FROM range(5000) t(i)"
  )
  expected <- (0:4999) / 4
  expected[(0:4999) %% 7 == 0] <- NA
  expect_identical(res$x, expected)
})

test_that("R values write into a wide DECIMAL", {
  con <- local_con()

  # a parameter
  res <- dbGetQuery(
    con,
    "SELECT typeof(?::DECIMAL(50, 2)) AS t, ?::DECIMAL(50, 2) AS x",
    params = list(1.5, -1.25)
  )
  expect_identical(res$t, "DECIMAL(50,2)")
  expect_identical(res$x, -1.25)

  # text is exact both ways
  digits <- "123456789012345678901234567890123456789012345678.25"
  res <- dbGetQuery(
    con,
    "SELECT ?::DECIMAL(50, 2)::VARCHAR AS x",
    params = list(digits)
  )
  expect_identical(res$x, digits)

  dbWriteTable(
    con,
    "wide",
    data.frame(a = c(1.25, NA, -3), b = c(digits, NA, "-0.5")),
    field.types = c(a = "DECIMAL(50, 2)", b = "DECIMAL(300, 150)")
  )
  dbAppendTable(con, "wide", data.frame(a = 7.5, b = "2"))
  res <- dbGetQuery(
    con,
    "SELECT a, b, a::VARCHAR AS a_text, typeof(a) AS a_type, typeof(b) AS b_type FROM wide"
  )
  expect_identical(res$a, c(1.25, NA, -3, 7.5))
  expect_identical(res$b, c(as.numeric(digits), NA, -0.5, 2))
  expect_identical(res$a_text, c("1.25", NA, "-3.00", "7.50"))
  expect_identical(unique(res$a_type), "DECIMAL(50,2)")
  expect_identical(unique(res$b_type), "DECIMAL(300,150)")
  expect_identical(
    dbGetQuery(
      con,
      "SELECT b::VARCHAR LIKE ? AS ok FROM wide LIMIT 1",
      params = list(paste0(digits, "%"))
    )$ok,
    TRUE
  )
})

test_that("a wide DECIMAL goes through Arrow as decimal256", {
  skip_if_not_installed("arrow", "13.0.0")
  con <- local_con()
  # decimal256 is part of Arrow format version 1.1
  dbExecute(con, "SET arrow_output_version = '1.1'")

  tbl <- duckdb_fetch_arrow(dbSendQuery(
    con,
    "SELECT x::DECIMAL(50, 2) AS x FROM (VALUES ('1.5'), (NULL), ('-12345.25')) t(x)",
    arrow = TRUE
  ))
  expect_true(tbl$schema$x$type == arrow::decimal256(50, 2))
  expect_identical(as.data.frame(tbl)$x, c(1.5, NA, -12345.25))

  # 76 digits is what decimal256 holds
  tbl <- duckdb_fetch_arrow(dbSendQuery(
    con,
    "SELECT repeat('9', 76)::DECIMAL(76, 0) AS x",
    arrow = TRUE
  ))
  expect_true(tbl$schema$x$type == arrow::decimal256(76, 0))
  expect_identical(tbl$x$cast(arrow::utf8())$as_vector(), strrep("9", 76))

  expect_error(
    duckdb_fetch_arrow(dbSendQuery(
      con,
      "SELECT 1.5::DECIMAL(77, 2) AS x",
      arrow = TRUE
    )),
    "at most 76 digits"
  )

  # and back
  tbl <- arrow::arrow_table(
    x = arrow::Array$create(c(
      "1.5",
      NA,
      strrep("9", 48)
    ))$cast(arrow::decimal256(50, 2))
  )
  duckdb_register_arrow(con, "wide_arrow", tbl)
  res <- dbGetQuery(
    con,
    "SELECT x, x::VARCHAR AS text, typeof(x) AS type FROM wide_arrow"
  )
  expect_identical(res$type, rep("DECIMAL(50,2)", 3))
  expect_identical(res$text, c("1.50", NA, paste0(strrep("9", 48), ".00")))
  expect_identical(res$x, c(1.5, NA, 1e48))
})
