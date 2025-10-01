skip_if_no_R4 <- function() {
  if (R.Version()$major < 4) {
    skip("R 4.0.0 or newer not available for testing")
  }
}

test_that("dbplyr generic scalars translated correctly", {
  skip_if_no_R4()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  translate <- function(...) dbplyr::translate_sql(..., con = con)
  sql <- function(...) dbplyr::sql(...)

  expect_equal(translate(as.character(1)), sql(r"{CAST(1.0 AS TEXT)}"))
  expect_equal(translate(as.character(1L)), sql(r"{CAST(1 AS TEXT)}"))
  expect_equal(translate(as.numeric(1)), sql(r"{CAST(1.0 AS NUMERIC)}"))
  expect_equal(translate(as.double(1.2)), sql(r"{CAST(1.2 AS NUMERIC)}"))
  expect_equal(translate(as.integer(1.2)), sql(r"{CAST(1.2 AS INTEGER)}"))
  expect_equal(translate(as.integer64(1.2)), sql(r"{CAST(1.2 AS BIGINT)}"))
  expect_equal(translate(as.logical("TRUE")), sql(r"{CAST('TRUE' AS BOOLEAN)}"))
  expect_equal(translate(tolower("HELLO")), sql(r"{LOWER('HELLO')}"))
  expect_equal(translate(toupper("hello")), sql(r"{UPPER('hello')}"))
  expect_equal(translate(pmax(1, 2, na.rm = TRUE)), sql(r"{GREATEST(1.0, 2.0)}"))
  expect_equal(translate(pmin(1, 2, na.rm = TRUE)), sql(r"{LEAST(1.0, 2.0)}"))
  expect_equal(translate(as.character("2020-01-01")), sql(r"{CAST('2020-01-01' AS TEXT)}"))
  expect_equal(translate(c("2020-01-01", "2020-13-02")), sql(r"{('2020-01-01', '2020-13-02')}"))
  expect_equal(translate(iris[["sepal_length"]]), sql(r"{iris.sepal_length}"))
  expect_equal(translate(iris[[1]]), sql(r"{iris[1]}"))
  expect_equal(translate(cot(x)), sql(r"{COT(x)}"))
  expect_equal(translate(substr("test", 2, 3)), sql(r"{SUBSTR('test', 2, 2)}"))
})

test_that("duckdb custom scalars translated correctly", {
  skip_if_no_R4()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  translate <- function(...) dbplyr::translate_sql(..., con = con)
  sql <- function(...) dbplyr::sql(...)

  #  expect_equal(translate(as(1,"CHARACTER")), sql(r"{CAST(1.0 AS TEXT}"))        # Not implemented
  expect_equal(translate(as.raw(10)), sql(r"{CAST(10.0 AS VARBINARY)}"))
  expect_equal(translate(13 %% 5), sql(r"{FMOD(13.0, 5.0)}"))
  expect_equal(translate(35.8 %/% 4), sql(r"{FDIV(35.8, 4.0)}"))
  expect_equal(translate(35.8^2.51), sql(r"{POW(35.8, 2.51)}"))
  expect_equal(translate(bitwOr(x, 128L)), sql(r"{(CAST(x AS INTEGER)) | (CAST(128 AS INTEGER))}"))
  expect_equal(translate(bitwAnd(x, 128)), sql(r"{(CAST(x AS INTEGER)) & (CAST(128.0 AS INTEGER))}"))
  expect_equal(translate(bitwXor(x, 128L)), sql(r"{XOR((CAST(x AS INTEGER)), (CAST(128 AS INTEGER)))}"))
  expect_equal(translate(bitwNot(x)), sql(r"{~(CAST(x AS INTEGER))}"))
  expect_equal(translate(bitwShiftL(x, 5L)), sql(r"{(CAST(x AS INTEGER)) << (CAST(5 AS INTEGER))}"))
  expect_equal(translate(bitwShiftR(x, 4L)), sql(r"{(CAST(x AS INTEGER)) >> (CAST(4 AS INTEGER))}"))
  expect_equal(translate(log(x)), sql(r"{LN(x)}"))
  expect_equal(translate(log(x, base = 5)), sql(r"{LOG(x) / LOG(5.0)}"))
  expect_equal(translate(log(x, base = 10)), sql(r"{LOG10(x)}"))
  expect_equal(translate(log(x, base = 2)), sql(r"{LOG2(x)}"))
  expect_equal(translate(log10(x)), sql(r"{LOG10(x)}"))
  expect_equal(translate(log2(x)), sql(r"{LOG2(x)}"))
  expect_equal(translate(is.nan(var1)), sql(r"{(var1 IS NOT NULL AND PRINTF('%f', var1) = 'nan')}"))
  expect_equal(translate(is.infinite(var1)), sql(r"{(var1 IS NOT NULL AND REGEXP_MATCHES(PRINTF('%f', var1), 'inf'))}"))
  expect_equal(translate(is.finite(var1)), sql(r"{(NOT (var1 IS NULL OR REGEXP_MATCHES(PRINTF('%f', var1), 'inf|nan')))}"))
  expect_equal(translate(grepl("pattern", text)), sql(r"{REGEXP_MATCHES("text", 'pattern')}"))
  expect_equal(translate(grepl("pattern", text, ignore.case = TRUE)), sql(r"{REGEXP_MATCHES("text", '(?i)pattern')}"))
  expect_error(translate(grepl("dummy", txt, perl = TRUE)))
  expect_equal(translate(regexpr("pattern", text)), sql(r"{(CASE WHEN REGEXP_MATCHES("text", 'pattern') THEN (LENGTH(LIST_EXTRACT(STRING_SPLIT_REGEX("text", 'pattern'), 0))+1) ELSE -1 END)}"))
  expect_equal(translate(round(x, digits = 1.1)), sql(r"{ROUND_EVEN(x, CAST(ROUND(1.1, 0) AS INTEGER))}"))
  expect_equal(translate(as.Date("2019-01-01")), sql(r"{CAST('2019-01-01' AS DATE)}"))
  expect_equal(translate(as.POSIXct("2019-01-01 01:01:01")), sql(r"{CAST('2019-01-01 01:01:01' AS TIMESTAMP)}"))
})

test_that("pasting translated correctly", {
  skip_if_no_R4()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  translate <- function(...) dbplyr::translate_sql(..., con = con)
  sql <- function(...) dbplyr::sql(...)

  expect_equal(translate(paste("hi", "bye")), sql(r"{CONCAT_WS(' ', 'hi', 'bye')}"))
  expect_equal(translate(paste("hi", "bye", sep = "-")), sql(r"{CONCAT_WS('-', 'hi', 'bye')}"))
  expect_equal(translate(paste0("hi", "bye")), sql(r"{CONCAT_WS('', 'hi', 'bye')}"))

  expect_equal(translate(paste(x, y), window = FALSE), sql(r"{CONCAT_WS(' ', x, y)}"))
  expect_equal(translate(paste0(x, y), window = FALSE), sql(r"{CONCAT_WS('', x, y)}"))

  #   expect_error(translate(paste0(x, collapse = ""), window = FALSE), "`collapse` not supported")
})


# lubridate functions

test_that("custom lubridate functions translated correctly", {
  skip_if_no_R4()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  translate <- function(...) dbplyr::translate_sql(..., con = con)
  sql <- function(...) dbplyr::sql(...)

  expect_equal(translate(yday(x)), sql(r"{EXTRACT(DOY FROM x)}"))
  expect_equal(translate(quarter(x)), sql(r"{EXTRACT(QUARTER FROM x)}"))
  expect_equal(translate(quarter(x, with_year = TRUE)), sql(r"{(EXTRACT(YEAR FROM x) || '.' || EXTRACT(QUARTER FROM x))}"))
  expect_equal(translate(quarter(x, type = "year.quarter")), sql(r"{(EXTRACT(YEAR FROM x) || '.' || EXTRACT(QUARTER FROM x))}"))
  expect_equal(translate(quarter(x, type = "quarter")), sql(r"{EXTRACT(QUARTER FROM x)}"))
  expect_equal(translate(quarter(x, type = TRUE)), sql(r"{(EXTRACT(YEAR FROM x) || '.' || EXTRACT(QUARTER FROM x))}"))
  expect_equal(translate(quarter(x, type = FALSE)), sql(r"{EXTRACT(QUARTER FROM x)}"))
  expect_equal(translate(quarter(x, type = "date_first")), sql(r"{(CAST(DATE_TRUNC('QUARTER', x) AS DATE))}"))
  expect_equal(translate(quarter(x, type = "date_last")), sql(r"{(CAST((DATE_TRUNC('QUARTER', x) + INTERVAL '1 QUARTER' - INTERVAL '1 DAY') AS DATE))}"))
  expect_error(translate(quarter(x, type = "other")))
  expect_error(translate(quarter(x, fiscal_start = 2)))
  expect_equal(translate(month(x, label = FALSE)), sql(r"{EXTRACT(MONTH FROM x)}"))
  expect_equal(translate(month(x, label = TRUE)), sql(r"{STRFTIME(x, '%b')}"))
  expect_equal(translate(month(x, label = TRUE, abbr = FALSE)), sql(r"{STRFTIME(x, '%B')}"))
  expect_equal(translate(qday(x)), sql(r"{DATE_DIFF('DAYS', DATE_TRUNC('QUARTER', CAST((x) AS DATE)), (CAST((x) AS DATE) + INTERVAL '1 DAY'))}"))
  expect_equal(translate(wday(x)), sql(r"{EXTRACT('dow' FROM CAST(x AS DATE) + 0) + 1}"))
  expect_equal(translate(wday(x, week_start = 4)), sql(r"{EXTRACT('dow' FROM CAST(x AS DATE) + 3) + 1}"))
  expect_equal(translate(wday(x, label = TRUE)), sql(r"{STRFTIME(x, '%a')}"))
  expect_equal(translate(wday(x, label = TRUE, abbr = FALSE)), sql(r"{STRFTIME(x, '%A')}"))
  expect_equal(translate(seconds(x)), sql(r"{TO_SECONDS(CAST(x AS BIGINT))}"))
  expect_equal(translate(minutes(x)), sql(r"{TO_MINUTES(CAST(x AS BIGINT))}"))
  expect_equal(translate(hours(x)), sql(r"{TO_HOURS(CAST(x AS BIGINT))}"))
  expect_equal(translate(days(x)), sql(r"{TO_DAYS(CAST(x AS INTEGER))}"))
  expect_equal(translate(weeks(x)), sql(r"{TO_DAYS(7 * CAST(x AS INTEGER))}"))
  expect_equal(translate(months(x)), sql(r"{TO_MONTHS(CAST(x AS INTEGER))}"))
  expect_equal(translate(years(x)), sql(r"{TO_YEARS(CAST(x AS INTEGER))}"))
  expect_equal(translate(floor_date(x, "month")), sql(r"{DATE_TRUNC('month', x)}"))
  expect_equal(translate(floor_date(x, "week")), sql(r"{CAST(x AS DATE) - CAST(EXTRACT('dow' FROM CAST(x AS DATE) + 0) AS INTEGER)}"))
  expect_equal(translate(floor_date(x, "week", week_start = 1)), sql(r"{DATE_TRUNC('week', x)}"))
  expect_equal(translate(floor_date(x, "week", week_start = 4)), sql(r"{CAST(x AS DATE) - CAST(EXTRACT('dow' FROM CAST(x AS DATE) + 3) AS INTEGER)}"))
})

# clock functions
test_that("custom clock functions translated correctly", {
  skip_if_no_R4()
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("clock")
  skip_if_not_installed("rlang")
  skip_if_not_installed("cli")
  con <- local_con()
  translate <- function(...) dbplyr::translate_sql(..., con = con)
  sql <- function(...) dbplyr::sql(...)

  m <- 1
  expect_equal(translate(add_days(x, m)), sql(r"{DATE_ADD(x, INTERVAL (m) day)}"))
  expect_equal(translate(add_days(x, 2L)), sql(r"{DATE_ADD(x, INTERVAL (2) day)}"))

  expect_equal(translate(add_years(x, m)), sql(r"{DATE_ADD(x, INTERVAL (m) year)}"))
  expect_equal(translate(add_years(x, 2L)), sql(r"{DATE_ADD(x, INTERVAL (2) year)}"))

  expect_equal(translate(get_day(x)), sql(r"{DATE_PART('day', x)}"))
  expect_equal(translate(get_month(x)), sql(r"{DATE_PART('month', x)}"))
  expect_equal(translate(get_year(x)), sql(r"{DATE_PART('year', x)}"))

  expect_equal(translate(date_count_between(start = "start",
                                            end = "end",
                                            precision = "day")),
               sql(r"{DATEDIFF('day', start, end)}"))

  test_data <- data.frame(
    person = 1L,
    date_1 = as.Date("2000-01-01"),
    date_2 = as.Date("2000-01-30")
  )
  db_test_data <- dbplyr::copy_inline(con, test_data)

  test_data <- test_data %>%
    dplyr::mutate(date_plus_two_days  = clock::add_days(date_1, 2),
           date_plus_two_years = clock::add_years(date_1, 2),
           date_minus_two_days  = clock::add_days(date_1, -2),
           date_minus_two_years = clock::add_years(date_1, -2),
           day = clock::get_day(date_1),
           month = clock::get_month(date_1),
           year = clock::get_year(date_1),
           diff = clock::date_count_between(date_1, date_2, "day"),
           diff2 = clock::date_count_between(date_2, date_1, "day")
           )
  db_test_data <- db_test_data %>%
    dplyr::mutate(date_plus_two_days  = as.Date(clock::add_days(date_1, 2)),
           date_plus_two_years = as.Date(clock::add_years(date_1, 2)),
           date_minus_two_days  = as.Date(clock::add_days(date_1, -2)),
           date_minus_two_years = as.Date(clock::add_years(date_1, -2)),
           day = clock::get_day(date_1),
           month = clock::get_month(date_1),
           year = clock::get_year(date_1),
           diff = clock::date_count_between(date_1, date_2, "day"),
           diff2 = clock::date_count_between(date_2, date_1, "day")) %>%
    dplyr::collect()

  expect_equal(unclass(test_data), unclass(db_test_data))

  # errors for unsupported arguments
  expect_error(translate(date_count_between(start = "start",
                                            end = "end",
                                            precision = "year")))
  expect_error(translate(date_count_between(start = "start",
                                            end = "end",
                                            precision = "day",
                                            n = 5)))

})

# stringr functions

test_that("custom stringr functions translated correctly", {
  skip_if_no_R4()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  translate <- function(...) dbplyr::translate_sql(..., con = con)
  sql <- function(...) dbplyr::sql(...)

  expect_equal(translate(str_c(x, y)), sql(r"{CONCAT_WS('', x, y)}"))
  #   expect_error(translate(str_c(x, collapse = "")), "`collapse` not supported")
  expect_equal(translate(str_detect(x, y)), sql(r"{REGEXP_MATCHES(x, y)}"))
  expect_equal(translate(str_detect(x, y, negate = TRUE)), sql(r"{(NOT(REGEXP_MATCHES(x, y)))}"))
  expect_equal(translate(str_replace(x, y, z)), sql(r"{REGEXP_REPLACE(x, y, z)}"))
  expect_equal(translate(str_replace_all(x, y, z)), sql(r"{REGEXP_REPLACE(x, y, z, 'g')}"))
  expect_equal(translate(str_squish(x)), sql(r"{TRIM(REGEXP_REPLACE(x, '\s+', ' ', 'g'))}"))
  expect_equal(translate(str_remove(x, y)), sql(r"{REGEXP_REPLACE(x, y, '')}"))
  expect_equal(translate(str_remove_all(x, y)), sql(r"{REGEXP_REPLACE(x, y, '', 'g')}"))
  expect_equal(translate(str_to_sentence(x)), sql(r"{(UPPER(x[0]) || x[1:NULL])}"))
  expect_equal(translate(str_starts(x, y)), sql(r"{REGEXP_MATCHES(x, '^(?:' || y || ')')}"))
  expect_equal(translate(str_ends(x, y)), sql(r"{REGEXP_MATCHES(x, '(?:' || y || ')$')}"))
  expect_equal(translate(str_pad(x, width = 10)), sql(r"{LPAD(x, CAST(GREATEST(10, LENGTH(x)) AS INTEGER), ' ')}"))
  expect_equal(translate(str_pad(x, width = 10, side = "right")), sql(r"{RPAD(x, CAST(GREATEST(10, LENGTH(x)) AS INTEGER), ' ')}"))
  expect_equal(translate(str_pad(x, width = 10, side = "both", pad = "<")), sql(r"{RPAD(REPEAT('<', (10 - LENGTH(x)) / 2) || x, CAST(GREATEST(10, LENGTH(x)) AS INTEGER), '<')}"))
  expect_error(translate(str_pad(x, width = 10, side = "other")))
})

test_that("datetime escaping working as in DBI", {
  skip_if_no_R4()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  escape <- function(...) dbplyr::escape(..., con = con)
  sql <- function(...) dbplyr::sql(...)

  test_date <- as.Date("2020-01-01")
  expect_equal(escape(test_date), sql(r"{'2020-01-01'::date}"))
  expect_equal(escape("2020-01-01"), sql(r"{'2020-01-01'}"))

  test_datetime <- as.POSIXct("2020-01-01 01:23:45 UTC", tz = "UTC")
  expect_equal(escape(test_datetime), sql(r"{'2020-01-01 01:23:45'::timestamp}"))
  expect_equal(escape("2020-01-01 01:23:45 UTC"), sql(r"{'2020-01-01 01:23:45 UTC'}"))

  test_datetime_tz <- as.POSIXct("2020-01-01 18:23:45 UTC", tz = "America/Los_Angeles")
  expect_equal(escape(test_datetime_tz), sql(r"{'2020-01-02 02:23:45'::timestamp}"))
  expect_equal(escape("2020-01-01 18:23:45 PST"), sql(r"{'2020-01-01 18:23:45 PST'}"))
})

test_that("aggregators translated correctly", {
  skip_if_no_R4()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  translate <- function(...) dbplyr::translate_sql(..., con = con)
  sql <- function(...) dbplyr::sql(...)

  expect_equal(translate(sum(x, na.rm = TRUE), window = FALSE), sql(r"{SUM(x)}"))
  expect_equal(translate(sum(x, na.rm = TRUE), window = TRUE), sql(r"{SUM(x) OVER ()}"))

  expect_equal(translate(prod(x, na.rm = TRUE), window = FALSE), sql(r"{PRODUCT(x)}"))
  expect_equal(translate(prod(x, na.rm = TRUE), window = TRUE), sql(r"{PRODUCT(x) OVER ()}"))

  expect_equal(translate(median(x, na.rm = TRUE), window = FALSE), sql(r"{MEDIAN(x)}"))
  expect_equal(translate(median(x, na.rm = TRUE), window = TRUE), sql(r"{MEDIAN(x) OVER ()}"))
  expect_equal(translate(median(x, na.rm = TRUE), window = TRUE, vars_group="z"), sql(r"{MEDIAN(x) OVER (PARTITION BY z)}"))

  expect_equal(translate(sd(x, na.rm = TRUE), window = FALSE), sql(r"{STDDEV(x)}"))
  expect_equal(translate(sd(x, na.rm = TRUE), window = TRUE), sql(r"{STDDEV(x) OVER ()}"))

  expect_equal(translate(var(x, na.rm = TRUE), window = FALSE), sql(r"{VARIANCE(x)}"))
  expect_equal(translate(var(x, na.rm = TRUE), window = TRUE), sql(r"{VARIANCE(x) OVER ()}"))

  expect_equal(translate(all(x, na.rm = TRUE), window = FALSE), sql(r"{BOOL_AND(x)}"))
  expect_equal(translate(all(x, na.rm = TRUE), window = TRUE), sql(r"{BOOL_AND(x) OVER ()}"))

  expect_equal(translate(any(x, na.rm = TRUE), window = FALSE), sql(r"{BOOL_OR(x)}"))
  expect_equal(translate(any(x, na.rm = TRUE), window = TRUE), sql(r"{BOOL_OR(x) OVER ()}"))

  expect_equal(translate(str_flatten(x, ","), window = FALSE), sql(r"{STRING_AGG(x, ',')}"))
  expect_equal(translate(str_flatten(x, ","), window = TRUE), sql(r"{STRING_AGG(x, ',') OVER ()}"))
  expect_equal(translate(str_flatten(x, ","), window = TRUE, vars_group = "y"), sql(r"{STRING_AGG(x, ',') OVER (PARTITION BY y)}"))

  expect_equal(translate(n_distinct(x), window = FALSE), sql(r"{COUNT(DISTINCT row(x))}"))
  expect_equal(translate(n_distinct(x), window = TRUE), sql(r"{COUNT(DISTINCT row(x)) OVER ()}"))
  expect_equal(translate(n_distinct(x), window = TRUE, vars_group = "y"), sql(r"{COUNT(DISTINCT row(x)) OVER (PARTITION BY y)}"))
  expect_equal(translate(n_distinct(x, na.rm = TRUE), window = FALSE), sql(r"{COUNT(DISTINCT x)}"))
  expect_equal(translate(n_distinct(x, na.rm = TRUE), window = TRUE), sql(r"{COUNT(DISTINCT x) OVER ()}"))
  expect_equal(translate(n_distinct(x, na.rm = TRUE), window = TRUE, vars_group = "y"), sql(r"{COUNT(DISTINCT x) OVER (PARTITION BY y)}"))
})

test_that("two variable aggregates are translated correctly", {
  skip_if_no_R4()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  translate <- function(...) dbplyr::translate_sql(..., con = con)
  sql <- function(...) dbplyr::sql(...)

  expect_equal(translate(cor(x, y), window = FALSE), sql(r"{CORR(x, y)}"))
  expect_equal(translate(cor(x, y), window = TRUE), sql(r"{CORR(x, y) OVER ()}"))

  expect_equal(translate(n_distinct(x, y), window = FALSE), sql(r"{COUNT(DISTINCT row(x, y))}"))
  expect_equal(translate(n_distinct(x, y), window = TRUE), sql(r"{COUNT(DISTINCT row(x, y)) OVER ()}"))
  expect_equal(translate(n_distinct(x, y), window = TRUE, vars_group = "y"), sql(r"{COUNT(DISTINCT row(x, y)) OVER (PARTITION BY y)}"))

  expect_equal(translate(n_distinct(x, y, na.rm = TRUE), window = FALSE), sql(r"{COUNT(DISTINCT row(x, y)) FILTER (x IS NOT NULL AND y IS NOT NULL)}"))
  expect_equal(translate(n_distinct(x, y, na.rm = TRUE), window = TRUE), sql(r"{COUNT(DISTINCT row(x, y)) FILTER (x IS NOT NULL AND y IS NOT NULL) OVER ()}"))
  expect_equal(translate(n_distinct(x, y, na.rm = TRUE), window = TRUE, vars_group = "y"), sql(r"{COUNT(DISTINCT row(x, y)) FILTER (x IS NOT NULL AND y IS NOT NULL) OVER (PARTITION BY y)}"))
})

test_that("n_distinct() computations are correct", {
  skip_if_no_R4()
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")
  con <- local_con()
  tbl <- dplyr::tbl
  summarize <- dplyr::summarize
  mutate <- dplyr::mutate
  arrange <- dplyr::arrange
  pull <- dplyr::pull
  n_distinct <- dplyr::n_distinct

  df <- data.frame(x = c(1, 1, 2, 2), y = c(1, 2, 2, 2))
  df_na <- data.frame(x = c(1, 1, 2, NA, NA), y = c(1, 2, NA, 2, NA))

  duckdb_register(con, "df", df)
  duckdb_register(con, "df_na", df_na)

  df_duckdb <- tbl(con, "df")
  df_na_duckdb <- tbl(con, "df_na")

  expect_equal(
    pull(summarize(df_duckdb, n = n_distinct(x, na.rm = TRUE)), n),
    pull(summarize(df, n = n_distinct(x, na.rm = TRUE)), n)
  )
  expect_equal(
    pull(summarize(df_na_duckdb, n = n_distinct(x, na.rm = TRUE)), n),
    pull(summarize(df_na, n = n_distinct(x, na.rm = TRUE)), n)
  )
  expect_equal(
    pull(summarize(df_duckdb, n = n_distinct(x, y, na.rm = TRUE)), n),
    pull(summarize(df, n = n_distinct(x, y, na.rm = TRUE)), n),
  )
  expect_equal(
    pull(summarize(df_na_duckdb, n = n_distinct(x, y, na.rm = TRUE)), n),
    pull(summarize(df_na, n = n_distinct(x, y, na.rm = TRUE)), n),
  )

  # single column is working as usual
  expect_equal(
    pull(summarize(df, n = n_distinct(x)), n),
    pull(summarize(df_duckdb, n = n_distinct(x)), n)
  )

  expect_equal(
    pull(summarize(df_na_duckdb, n = n_distinct(x)), n),
    pull(summarize(df_na, n = n_distinct(x)), n)
  )

  # two columns return correct results
  expect_equal(
    pull(summarize(df_duckdb, n = n_distinct(x, y)), n),
    pull(summarize(df, n = n_distinct(x, y)), n)
  )

  # two columns containing NAs return correct results
  expect_equal(
    pull(summarize(df_na_duckdb, n = n_distinct(x, y)), n),
    pull(summarize(df_na, n = n_distinct(x, y)), n)
  )

  # window functions are working
  expect_equal(
    pull(mutate(df_na_duckdb, n = n_distinct(x, y)), n),
    pull(mutate(df_na, n = n_distinct(x, y)), n)
  )

  expect_equal(
    pull(mutate(df_na_duckdb, n = n_distinct(x, y, na.rm = TRUE)), n),
    pull(mutate(df_na, n = n_distinct(x, y, na.rm = TRUE)), n)
  )

  expect_equal(
    pull(arrange(mutate(df_duckdb, n = n_distinct(x), .by = y), x, y), n),
    pull(arrange(mutate(df, n = n_distinct(x), .by = y), x, y), n),
  )
})


test_that("duckdb round() results equal its R version", {
  skip_if_no_R4()
  skip_if_not_installed("dplyr")
  skip_if_not_installed("dbplyr")

  con <- local_con()
  mutate <- dplyr::mutate
  pull <- dplyr::pull

  df <- data.frame(x = c(-1.5, -0.5, 0.5, 1.5))

  duckdb_register(con, "df", df)
  df_duckdb <- dplyr::tbl(con, "df")

  expect_equal(
    pull(mutate(df_duckdb, r = round(x)), r),
    pull(mutate(df, r = round(x)), r)
  )
})


# Snapshot tests

test_that("snapshots of dbplyr generic scalar translation", {
  skip_on_cran()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  local_edition(3)
  translate <- function(...) dbplyr::translate_sql(..., con = con)

  rlang::local_options(cli.num_colors = 1)

  expect_snapshot({
    translate(as.character(1))
    translate(as.character(1L))
    translate(as.numeric(1))
    translate(as.double(1.2))
    translate(as.integer(1.2))
    translate(as.integer64(1.2))
    translate(as.logical("TRUE"))
    translate(tolower("HELLO"))
    translate(toupper("hello"))
    translate(pmax(1, 2, na.rm = TRUE))
    translate(pmin(1, 2, na.rm = TRUE))
    translate(as.character("2020-01-01"))
    translate(c("2020-01-01", "2020-13-02"))
    translate(iris[["sepal_length"]])
    translate(iris[[1]])
    translate(cot(x))
    translate(substr("test", 2, 3))
  })
})


test_that("snapshots of duckdb custom scalars translations", {
  skip_on_cran()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  local_edition(3)
  translate <- function(...) dbplyr::translate_sql(..., con = con)

  rlang::local_options(cli.num_colors = 1)

  expect_snapshot({
    #  translate(as(1,"CHARACTER"))        # Not implemented
    translate(as.raw(10))
    translate(13 %% 5)
    translate(35.8 %/% 4)
    translate(35.8^2.51)
    translate(bitwOr(x, 128L))
    translate(bitwAnd(x, 128))
    translate(bitwXor(x, 128L))
    translate(bitwNot(x))
    translate(bitwShiftL(x, 5L))
    translate(bitwShiftR(x, 4L))
    translate(log(x))
    translate(log(x, base = 5))
    translate(log(x, base = 10))
    translate(log(x, base = 2))
    translate(log10(x))
    translate(log2(x))
    translate(is.nan(var1))
    translate(is.infinite(var1))
    translate(is.finite(var1))
    translate(grepl("pattern", text))
    translate(grepl("pattern", text, ignore.case = TRUE))
    #  translate(grepl("dummy", txt, perl = TRUE)) # Error tests later
    translate(regexpr("pattern", text))
    translate(round(x, digits = 1.1))
    translate(as.Date("2019-01-01"))
    translate(as.POSIXct("2019-01-01 01:01:01"))
  })
})



test_that("snapshot tests for pasting translate", {
  skip_on_cran()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  local_edition(3)
  translate <- function(...) dbplyr::translate_sql(..., con = con)

  rlang::local_options(cli.num_colors = 1)

  expect_snapshot({
    translate(paste("hi", "bye"))
    translate(paste("hi", "bye", sep = "-"))
    translate(paste0("hi", "bye"))

    translate(paste(x, y), window = FALSE)
    translate(paste0(x, y), window = FALSE)

    #    translate(paste0(x, collapse = ""), window = FALSE)  # Expected error
  })
})


# lubridate functions

test_that("snapshots for custom lubridate functions translated correctly", {
  skip_on_cran()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  local_edition(3)
  translate <- function(...) dbplyr::translate_sql(..., con = con)

  rlang::local_options(cli.num_colors = 1)

  expect_snapshot({
    translate(yday(x))
    translate(quarter(x))
    translate(quarter(x))
    translate(quarter(x, type = "year.quarter"))
    translate(quarter(x, type = "quarter"))
    translate(quarter(x, type = TRUE))
    translate(quarter(x, type = FALSE))
    translate(quarter(x, type = "date_first"))
    translate(quarter(x, type = "date_last"))
    #    translate(quarter(x, type = "other"))       # Not supported - error
    #    translate(quarter(x, fiscal_start = 2))     # Not supported - error
    translate(month(x, label = FALSE))
    translate(month(x, label = TRUE))
    translate(month(x, label = TRUE, abbr = FALSE))
    translate(qday(x))
    translate(wday(x))
    translate(wday(x, week_start = 4))
    translate(wday(x, label = TRUE))
    translate(wday(x, label = TRUE, abbr = FALSE))
    translate(seconds(x))
    translate(minutes(x))
    translate(hours(x))
    translate(days(x))
    translate(weeks(x))
    translate(months(x))
    translate(years(x))
    translate(floor_date(x, "month"))
    translate(floor_date(x, "week"))
    translate(floor_date(x, "week", week_start = 1))
    translate(floor_date(x, "week", week_start = 4))
  })
})

# stringr functions

test_that("snapshots for custom stringr functions translated correctly", {
  skip_on_cran()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  local_edition(3)
  translate <- function(...) dbplyr::translate_sql(..., con = con)

  rlang::local_options(cli.num_colors = 1)

  expect_snapshot({
    translate(str_c(x, y))
    #  translate(str_c(x, collapse = ""))  # Error
    translate(str_detect(x, y))
    translate(str_detect(x, y, negate = TRUE))
    translate(str_replace(x, y, z))
    translate(str_replace_all(x, y, z))
    translate(str_squish(x))
    translate(str_remove(x, y))
    translate(str_remove_all(x, y))
    translate(str_to_sentence(x))
    translate(str_starts(x, y))
    translate(str_ends(x, y))
    translate(str_pad(x, width = 10))
    translate(str_pad(x, width = 10, side = "right"))
    translate(str_pad(x, width = 10, side = "both", pad = "<"))
    #  translate(str_pad(x, width = 10, side = "other")) # Error
  })
})

test_that("snapshots datetime escaping working as in DBI", {
  skip_on_cran()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  local_edition(3)
  escape <- function(...) dbplyr::escape(..., con = con)

  rlang::local_options(cli.num_colors = 1)

  expect_snapshot({
    test_date <- as.Date("2020-01-01")
    escape(test_date)
    escape("2020-01-01")

    test_datetime <- as.POSIXct("2020-01-01 01:23:45 UTC", tz = "UTC")
    escape(test_datetime)
    escape("2020-01-01 01:23:45 UTC")

    test_datetime_tz <- as.POSIXct("2020-01-01 18:23:45 UTC", tz = "America/Los_Angeles")
    escape(test_datetime_tz)
    escape("2020-01-01 18:23:45 PST")
  })
})

test_that("two variable aggregates are translated correctly", {
  skip_on_cran()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  local_edition(3)
  translate <- function(...) dbplyr::translate_sql(..., con = con)

  rlang::local_options(cli.num_colors = 1)

  expect_snapshot({
    translate(cor(x, y), window = FALSE)
    translate(cor(x, y), window = TRUE)
  })
})

test_that("these should give errors", {
  skip_on_cran()
  skip_if_not_installed("dbplyr")
  con <- local_con()
  local_edition(3)
  translate <- function(...) dbplyr::translate_sql(..., con = con)

  rlang::local_options(cli.num_colors = 1)

  expect_snapshot(error = TRUE, {
    translate(grepl("dummy", txt, perl = TRUE)) # Expected error
    #    translate(paste0(x, collapse = ""), window = FALSE) # Skip because of changing rlang_error (sql_paste())
    translate(quarter(x, type = "other")) # Not supported - error
    translate(quarter(x, fiscal_start = 2)) # Not supported - error
    #    translate(str_c(x, collapse = "")) # Skip because of changing rlang_error (sql_paste())
    translate(str_pad(x, width = 10, side = "other")) # Error
  })
})
