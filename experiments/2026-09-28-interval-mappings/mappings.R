## What each R class that could hold a DuckDB INTERVAL keeps of its three parts,
## months, days and microseconds, and whose arithmetic matches DuckDB's.
library(DBI)

first_line <- function(e) sub("\n.*", "", conditionMessage(e))
con <- dbConnect(duckdb::duckdb(shared_home = FALSE))
dbExecute(con, "SET TimeZone = 'Europe/Berlin'")

## DuckDB's own arithmetic -------------------------------------------------------
dbGetQuery(
  con,
  "SELECT
    (DATE '2024-01-31' + INTERVAL 1 MONTH)::DATE AS month_from_jan31,
    (TIMESTAMPTZ '2024-03-30 12:00:00+01' + INTERVAL 1 DAY)::VARCHAR AS day_over_dst,
    (TIMESTAMPTZ '2024-03-30 12:00:00+01' + INTERVAL 24 HOUR)::VARCHAR AS hours_24_over_dst,
    (TIMESTAMP '2024-03-30 12:00:00' + INTERVAL 1 DAY)::VARCHAR AS day_plain"
)

## lubridate's Period, as `interval = "Period"` reads it ------------------------
con_period <- dbConnect(
  duckdb::duckdb(shared_home = FALSE),
  interval = "Period"
)
period <- dbGetQuery(
  con_period,
  "SELECT * FROM (VALUES
    (1, INTERVAL '1 month'),
    (2, INTERVAL '1 month 1 day'),
    (3, INTERVAL '-1 day 01:00:00'),
    (4, INTERVAL '1 day 00:00:00.000001'),
    (5, NULL)
  ) AS t(i, a) ORDER BY i"
)$a
period
lubridate::`%m+%`(as.Date("2024-01-31"), period[1])
t0 <- as.POSIXct("2024-03-30 12:00:00", tz = "Europe/Berlin")
lubridate::`%m+%`(t0, lubridate::period(days = 1))

## clock's durations -------------------------------------------------------------
tryCatch(clock::duration_months(1) + clock::duration_days(1), error = first_line)
t0 + 86400
tryCatch(clock::duration_microseconds(3e9), error = first_line)
largest <- clock::duration_days(106751991) +
  clock::duration_seconds(14454) +
  clock::duration_microseconds(775807)
largest
largest + clock::duration_microseconds(1)
names(unclass(clock::duration_microseconds(1)))

## nanotime's nanoperiod ---------------------------------------------------------
nanotime::plus(
  nanotime::as.nanotime("2024-01-31T12:00:00+00:00"),
  nanotime::as.nanoperiod("1m"),
  tz = "UTC"
)
c(nanotime::as.nanoperiod("1m"), NA)

## Arrow's interval_month_day_nano, through nanoarrow ----------------------------
tryCatch(
  as.data.frame(dbGetQueryArrow(con, "SELECT INTERVAL 1 MONTH AS a")),
  error = first_line
)

## A conversion between Period and clock's durations ---------------------------
tryCatch(clock::as_duration(lubridate::period(days = 1)), error = first_line)
tryCatch(lubridate::as.period(clock::duration_days(1)), error = first_line)
