# Which R class can hold a DuckDB INTERVAL

*What it measures:* for each R class that could hold a DuckDB `INTERVAL`, which of its three parts
(months, days and microseconds) it keeps, and whether its arithmetic matches DuckDB's
for a month from January 31, and for a day and for hours across a daylight saving change.
The classes are lubridate's `Period`, as `interval = "Period"` reads it, clock's durations,
nanotime's `nanoperiod`, and what nanoarrow makes of the engine's Arrow export,
and the record also looks for a conversion between `Period` and clock's durations.

*When and on what:* 2026-09-28, Linux x86_64, R 4.5.3, DBI 1.3.0,
lubridate 1.9.5, clock 0.7.4, nanotime 0.3.15, nanoarrow 0.9.0.
duckdb 1.5.5.9029 with the commit that adds `interval = "Period"`,
a fast-path build linking the release `libduckdb` of DuckDB 1.5.5 ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)),
whose time zone support is built in.
[`mappings.R`](mappings.R) is rendered to [`mappings.md`](mappings.md)
by [`scripts/render-reprex.R`](/scripts/render-reprex.R),
and the session info names the scratch library that held the build as `<fast-path build library>`.

*What it supports:* the `INTERVAL` entry in [`usage/types/`](/handbook/usage/types/README.md),
and the decision there that `INTERVAL` has no clock mapping.

## Findings

From [`mappings.md`](mappings.md):

* **DuckDB adds a month from January 31 as February 29, and a day across a daylight saving change as a calendar day.**
  In `Europe/Berlin`, `TIMESTAMPTZ '2024-03-30 12:00:00+01'` plus `INTERVAL 1 DAY` is 12:00 the next day, 23 hours later,
  and plus `INTERVAL 24 HOUR` is 13:00; a plain `TIMESTAMP` plus a day is 24 hours later.
* **A `Period` keeps all three parts, and lubridate's `%m+%` adds its months and days as DuckDB does.**
  `INTERVAL '-1 day 01:00:00'` reads as `-1d 1H 0M 0S`, a microsecond stays in the seconds, and `NULL` reads as `NA`.
  January 31 `%m+%` a month is February 29, and a day added to the Berlin timestamp above is 12:00 the next day.
* **Its hours, minutes and seconds lubridate adds as clock time, where DuckDB adds elapsed time.**
  In Berlin on 2024-03-31, three hours from 00:30 are 04:30 in DuckDB and 03:30 through `%m+%`,
  and one hour from 01:30 is 03:30 in DuckDB and `NA` through `%m+%`, which lands in the hour the clocks skip.
* **A clock duration can't hold a month and a day at once.**
  `duration_months(1) + duration_days(1)` is refused, since one duration has one precision,
  and a calendrical one, months, does not combine with a chronological one, days or finer.
  A day as 86400 seconds takes the Berlin timestamp to 13:00, not to DuckDB's 12:00.
* **clock's constructors take 32-bit counts, and its arithmetic wraps past 64 bits.**
  `duration_microseconds(3e9)` is refused, so the largest 64-bit count of microseconds builds only from days, seconds and microseconds,
  and adding one more microsecond to it gives the smallest, without an error.
  A duration's fields, `lower` and `upper`, are clock's own and undocumented.
* **nanotime's `nanoperiod` holds the parts, but not DuckDB's arithmetic.**
  January 31 plus a month is March 2, and `NA` combined with a period prints as `1954m2146435072d/00:00:00`.
* **nanoarrow does not convert `interval_month_day_nano`,** the type the engine exports an `INTERVAL` as.
* **Neither package converts between `Period` and its own durations.**
  `clock::as_duration()` has no method for a `Period`, and `lubridate::as.period()` none for a clock duration.
