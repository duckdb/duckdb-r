# How a `POSIXct` and a `difftime` round to the microsecond

*What it measures:* which way a `POSIXct` or a `difftime` that falls exactly halfway between two microseconds rounds
on the write routes (`dbWriteTable()`, `duckdb_register()`, `dbAppendTable()` and a parameter), in `dbQuoteLiteral()`,
and in the engine's own conversions from a `DOUBLE`.
Also how often present-day instants are such a tie, and what the difference costs a query.

*When and on what:* 2026-09-28, Linux x86_64, R 4.5.3, DBI 1.3.0.
duckdb 1.5.5.9900 is the code of `main` at 3a1699a,
as a fast-path build linking the release `libduckdb` of DuckDB 1.5.6, the version vendored there
([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
The write routes round in the glue and `dbQuoteLiteral()` in R, which the release library does not change,
and the engine's conversions are the release's own.
[`microsecond-rounding.R`](microsecond-rounding.R) is rendered to [`microsecond-rounding.md`](microsecond-rounding.md)
by [`scripts/render-reprex.R`](/scripts/render-reprex.R).

*What it supports:* the microsecond rounding limitation in [`usage/types/`](/handbook/usage/types/README.md).

## Findings

From [`microsecond-rounding.md`](microsecond-rounding.md):

* **The write routes round half away from zero, and `dbQuoteLiteral()` rounds half to even.**
  2.5, 3.5, -2.5 and -3.5 microseconds write as 3, 4, -3 and -4 through all three write routes and as a parameter,
  for a `POSIXct` and a `difftime` alike.
  `dbQuoteLiteral()` quotes them as 2, 4, -2 and -4.
  The write converts with C's `round()` in `RTimestampType::Convert()` and the `RInterval*Type::Convert()` family
  in [`src/types.cpp`](/src/types.cpp),
  and `dbQuoteLiteral()` with R's `round()`, in [`R/dbQuoteLiteral__duckdb_connection.R`](/R/dbQuoteLiteral__duckdb_connection.R).
* **The engine rounds half to even, as `dbQuoteLiteral()` does.**
  `CAST(v AS BIGINT)` and `to_timestamp()` of a `DOUBLE` take the same four ties to 2, 4, -2 and -4.
  Only the SQL function `round()` rounds half away from zero.
  So the write routes are the odd one out:
  over 100,000 present-day instants, `dbQuoteLiteral()` and `to_timestamp()` of the same double agree on every one,
  and the write differs from both on the same 12.7%.
* **Ties are common, not a corner case.**
  Near 1.7e9 seconds, the epoch seconds times 1e6 is a double spaced 0.25 apart,
  so 25.2% of uniformly drawn present-day instants land exactly on a half microsecond.
  Half of those have an even microsecond below them, where the two rules disagree, by one microsecond and never more.
* **A quoted literal misses the row it was quoted from.**
  For an instant where the rules disagree, `WHERE x = ` the quoted literal counts no rows of the table written from it,
  and `WHERE x = ?` with the same `POSIXct` as a parameter counts one.

## Replicating

From this directory, with the build under test first in the library path,
`Rscript ../../scripts/render-reprex.R microsecond-rounding.R microsecond-rounding`.
It needs no network and does not wait, and its seed makes the shares repeat.
