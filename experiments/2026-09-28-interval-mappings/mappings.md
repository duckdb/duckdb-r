``` r
## What each R class that could hold a DuckDB INTERVAL keeps of its three parts,
## months, days and microseconds, and whose arithmetic matches DuckDB's.
library(DBI)

first_line <- function(e) sub("\n.*", "", conditionMessage(e))
con <- dbConnect(duckdb::duckdb(shared_home = FALSE))
dbExecute(con, "SET TimeZone = 'Europe/Berlin'")
#> [1] 0

## DuckDB's own arithmetic -------------------------------------------------------
dbGetQuery(
  con,
  "SELECT
    (DATE '2024-01-31' + INTERVAL 1 MONTH)::DATE AS month_from_jan31,
    (TIMESTAMPTZ '2024-03-30 12:00:00+01' + INTERVAL 1 DAY)::VARCHAR AS day_over_dst,
    (TIMESTAMPTZ '2024-03-30 12:00:00+01' + INTERVAL 24 HOUR)::VARCHAR AS hours_24_over_dst,
    (TIMESTAMP '2024-03-30 12:00:00' + INTERVAL 1 DAY)::VARCHAR AS day_plain"
)
#>   month_from_jan31           day_over_dst      hours_24_over_dst
#> 1       2024-02-29 2024-03-31 12:00:00+02 2024-03-31 13:00:00+02
#>             day_plain
#> 1 2024-03-31 12:00:00

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
#> [1] "1m 0d 0H 0M 0S"  "1m 1d 0H 0M 0S"  "-1d 1H 0M 0S"    "1d 0H 0M 1e-06S"
#> [5] NA
lubridate::`%m+%`(as.Date("2024-01-31"), period[1])
#> [1] "2024-02-29"
t0 <- as.POSIXct("2024-03-30 12:00:00", tz = "Europe/Berlin")
lubridate::`%m+%`(t0, lubridate::period(days = 1))
#> [1] "2024-03-31 12:00:00 CEST"

## The time part across a daylight saving change --------------------------------
## DuckDB adds an INTERVAL's microseconds as elapsed time, lubridate a Period's
## hours, minutes and seconds as clock time.
dbExecute(con_period, "SET TimeZone = 'Europe/Berlin'")
#> [1] 0
dbGetQuery(
  con_period,
  "SELECT
    (TIMESTAMPTZ '2024-03-31 00:30:00+01' + INTERVAL 3 HOUR)::VARCHAR AS from_0030,
    (TIMESTAMPTZ '2024-03-31 01:30:00+01' + INTERVAL 1 HOUR)::VARCHAR AS from_0130"
)
#>                from_0030              from_0130
#> 1 2024-03-31 04:30:00+02 2024-03-31 03:30:00+02
hours <- dbGetQuery(con_period, "SELECT INTERVAL 3 HOUR AS a, INTERVAL 1 HOUR AS b")
lubridate::`%m+%`(as.POSIXct("2024-03-31 00:30:00", tz = "Europe/Berlin"), hours$a)
#> [1] "2024-03-31 03:30:00 CEST"
lubridate::`%m+%`(as.POSIXct("2024-03-31 01:30:00", tz = "Europe/Berlin"), hours$b)
#> [1] NA

## A day or a month from a POSIXct, across the same change ----------------------
## A POSIXct writes a plain TIMESTAMP of its clock in UTC, which a day or a month keeps;
## taken as a TIMESTAMPTZ, a day or a month keeps the clock in the session's TimeZone.
t1 <- as.POSIXct("2024-03-15 12:00:00", tz = "Europe/Berlin")
format(lubridate::`%m+%`(t1, period[1]), usetz = TRUE)
#> [1] "2024-04-15 12:00:00 CEST"
from_r <- "SELECT
    ? + INTERVAL 1 DAY AS day_plain,
    ? + INTERVAL 1 MONTH AS month_plain,
    timezone('UTC', ?) + INTERVAL 1 DAY AS day_tz,
    timezone('UTC', ?) + INTERVAL 1 MONTH AS month_tz"
for (zone in c("Europe/Berlin", "UTC")) {
  dbExecute(con_period, paste0("SET TimeZone = '", zone, "'"))
  sums <- dbGetQuery(con_period, from_r, params = list(t0, t1, t0, t1))
  print(vapply(sums, format, "", tz = "Europe/Berlin", usetz = TRUE))
}
#>                  day_plain                month_plain 
#> "2024-03-31 13:00:00 CEST" "2024-04-15 13:00:00 CEST" 
#>                     day_tz                   month_tz 
#> "2024-03-31 12:00:00 CEST" "2024-04-15 12:00:00 CEST" 
#>                  day_plain                month_plain 
#> "2024-03-31 13:00:00 CEST" "2024-04-15 13:00:00 CEST" 
#>                     day_tz                   month_tz 
#> "2024-03-31 13:00:00 CEST" "2024-04-15 13:00:00 CEST"

## clock's durations -------------------------------------------------------------
tryCatch(clock::duration_months(1) + clock::duration_days(1), error = first_line)
#> [1] "Can't combine `x` <duration<month>> and `y` <duration<day>>."
t0 + 86400
#> [1] "2024-03-31 13:00:00 CEST"
tryCatch(clock::duration_microseconds(3e9), error = first_line)
#> [1] "Can't convert from `n` <double> to <integer> due to loss of precision."
largest <- clock::duration_days(106751991) +
  clock::duration_seconds(14454) +
  clock::duration_microseconds(775807)
largest
#> <duration<microsecond>[1]>
#> [1] 9223372036854775807
largest + clock::duration_microseconds(1)
#> <duration<microsecond>[1]>
#> [1] -9223372036854775808
names(unclass(clock::duration_microseconds(1)))
#> [1] "lower" "upper"

## nanotime's nanoperiod ---------------------------------------------------------
nanotime::plus(
  nanotime::as.nanotime("2024-01-31T12:00:00+00:00"),
  nanotime::as.nanoperiod("1m"),
  tz = "UTC"
)
#> [1] 2024-03-02T12:00:00+00:00
c(nanotime::as.nanoperiod("1m"), NA)
#> [1] 1m0d/00:00:00             1954m2146435072d/00:00:00

## Arrow's interval_month_day_nano, through nanoarrow ----------------------------
tryCatch(
  as.data.frame(dbGetQueryArrow(con, "SELECT INTERVAL 1 MONTH AS a")),
  error = first_line
)
#> [1] "Can't infer R vector type for `a` <interval_month_day_nano>"

## A conversion between Period and clock's durations ---------------------------
tryCatch(clock::as_duration(lubridate::period(days = 1)), error = first_line)
#> [1] "no applicable method for 'as_duration' applied to an object of class \"c('Period', 'Timespan', 'numeric', 'vector')\""
tryCatch(lubridate::as.period(clock::duration_days(1)), error = first_line)
#> [1] "as.period is not defined for class 'clock_duration'as.period is not defined for class 'clock_rcrd'as.period is not defined for class 'vctrs_rcrd'as.period is not defined for class 'vctrs_vctr'"
```

<sup>Created on 2026-09-28 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

<details style="margin-bottom:10px;">

<summary>

Session info
</summary>

``` r
sessioninfo::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────
#>  setting  value
#>  version  R version 4.5.3 (2026-03-11)
#>  os       Ubuntu 24.04.4 LTS
#>  system   x86_64, linux-gnu
#>  ui       X11
#>  language (EN)
#>  collate  C.UTF-8
#>  ctype    C.UTF-8
#>  tz       Etc/UTC
#>  date     2026-09-28
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  bit           4.6.0      2025-03-06 [2] RSPM
#>  bit64         4.8.6      2026-09-01 [2] RSPM
#>  cli           3.6.6      2026-04-09 [2] RSPM
#>  clock         0.7.4      2026-01-13 [2] RSPM (R 4.5.0)
#>  DBI         * 1.3.0      2026-02-25 [2] RSPM
#>  digest        0.6.39     2025-11-19 [2] RSPM
#>  duckdb        1.5.5.9029 2026-09-28 [1] local
#>  evaluate      1.0.5      2025-08-27 [2] RSPM
#>  fastmap       1.2.0      2024-05-15 [2] RSPM
#>  fs            2.1.0      2026-04-18 [2] RSPM
#>  generics      0.1.4      2025-05-09 [2] RSPM
#>  glue          1.8.1      2026-04-17 [2] RSPM
#>  htmltools     0.5.9      2025-12-04 [2] RSPM
#>  knitr         1.52       2026-09-06 [2] RSPM
#>  lattice       0.22-9     2026-02-09 [3] CRAN (R 4.5.3)
#>  lifecycle     1.0.5      2026-01-08 [2] RSPM
#>  lubridate     1.9.5      2026-02-04 [2] RSPM
#>  nanoarrow     0.9.0      2026-08-04 [2] RSPM (R 4.5.0)
#>  nanotime      0.3.15     2026-05-21 [1] RSPM (R 4.5.0)
#>  otel          0.2.0      2025-08-29 [2] RSPM
#>  pillar        1.11.1     2025-09-17 [2] RSPM
#>  Rcpp          1.1.2      2026-07-05 [2] RSPM
#>  RcppCCTZ      0.2.14     2026-01-08 [1] RSPM (R 4.5.0)
#>  reprex        2.1.1      2024-07-06 [2] RSPM
#>  rlang         1.3.0      2026-07-05 [2] RSPM
#>  rmarkdown     2.32       2026-09-01 [2] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [2] RSPM
#>  timechange    0.4.0      2026-01-29 [2] RSPM
#>  tzdb          0.5.0      2025-03-15 [2] RSPM
#>  vctrs         0.7.3      2026-04-11 [2] RSPM
#>  withr         3.0.3      2026-06-19 [2] RSPM
#>  xfun          0.61       2026-09-16 [2] RSPM
#>  yaml          2.3.12     2025-12-10 [2] RSPM
#>  zoo           1.9-1      2026-09-25 [1] RSPM (R 4.5.0)
#> 
#>  [1] <fast-path build library>
#>  [2] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [3] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

</details>
