# Timestamps and time zones

How a timestamp crosses between R and the engine:
which zone labels it on the way out, which DuckDB type carries it on the
way in, when an instant can change,
and what the session `TimeZone` setting is.
The behaviour is pinned by
[`tests/testthat/test-timezone.R`](/tests/testthat/test-timezone.R)
and measured across all setting combinations in
[`experiments/2026-08-08-timezone-grid/`](/experiments/2026-08-08-timezone-grid/README.md);
the wider type mapping is
[`types/`](/handbook/usage/types/README.md).

* **Every timestamp crosses as an instant plus a label.**
  Values arrive as epoch seconds in a `POSIXct`,
  and on the default `tz_out_convert = "with"` path
  no setting changes an instant — only the `tzone` label varies.
* **Plain `TIMESTAMP` is labeled with `timezone_out`.**
  The naive wall clock is read as UTC;
  the default label is `"UTC"`, set in
  [`R/dbConnect__duckdb_driver.R`](/R/dbConnect__duckdb_driver.R),
  and `""` leaves the label empty, so R renders the local zone.
* **`TIMESTAMPTZ` is labeled with the session `TimeZone`,
  and `timezone_out` is ignored.**
  DuckDB stores microseconds since the UTC epoch
  and renders them per session, not per column or per row,
  so every `TIMESTAMPTZ` column of a result shares one label
  ([#184](https://github.com/duckdb/duckdb-r/issues/184)).
  A DBI result captures the zone at execute time;
  an ALTREP result captures it earlier, when the data frame is built —
  that corner is [`relational/`](/handbook/usage/relational/README.md)'s.
* **The session `TimeZone` is the icu extension's setting.**
  `SET TimeZone` needs icu for any value, `'UTC'` included;
  where icu never loaded, results quietly fall back to a `UTC` label.
  This package autoloads an *installed* icu but downloads nothing
  by itself ([`extensions/`](/handbook/usage/extensions/README.md)),
  and does not link icu statically —
  a binary that does (the DuckDB CLI, a fast-path build against a
  release `libduckdb`) has the setting from startup,
  defaulting to the machine's zone.
* **`tz_out_convert = "force"` is the one instant-changing path.**
  It relabels every datetime column in `timezone_out`,
  preserving the UTC-rendered wall clock;
  the session zone plays no role under it,
  and `""` forces into R's local zone.
* **R's local zone enters only where a label is empty** —
  as the display zone for `"with"`,
  as the target zone for `"force"` —
  both spelled `timezone_out = ""`.
* **A `POSIXct` crosses as `TIMESTAMPTZ`, the instant it names.**
  That is what the R value means, and
  `dbConnect(posixct = "timestamp")` is the way back to the older
  mapping, which sent the UTC rendering into a naive `TIMESTAMP`
  column and dropped the R-side zone
  ([#184](https://github.com/duckdb/duckdb-r/issues/184)).
  The setting reaches `dbWriteTable()`, `dbAppendTable()`,
  `duckdb_register()`, bound parameters, `dbDataType()` and
  `dbQuoteLiteral()` — nested columns included.
* **Two paths stay on `TIMESTAMP` whatever the setting says.**
  A data frame picked up by name under
  `duckdb(environment_scan = TRUE)` scans with the table function's
  own defaults, because the replacement scan has the database and
  not the connection whose options these are.
  `rel_from_df()` declines the setting rather than misses it:
  a relation promises the data frame back unchanged, which a
  `TIMESTAMPTZ` column cannot keep, and what each candidate policy
  costs is measured in
  [`experiments/2026-08-09-rel-from-df-posixct/`](/experiments/2026-08-09-rel-from-df-posixct/README.md).
  A caller who wants the setting there passes `convert_opts` —
  the rest is [`relational/`](/handbook/usage/relational/README.md)'s.
* **A zone survives the round trip only through `TIMESTAMPTZ`,
  and only the session's.**
  Set the session `TimeZone` to the column's zone and the data frame
  comes back identical;
  set it to any other zone and the instant still comes back exact,
  labeled with the session's.
  `posixct = "timestamp"` has no zone to read back at all,
  because the column it writes carries none.
* **In a dbplyr pipeline, `posixct` reaches only the escaped value.**
  `!!` escapes R-side through `dbQuoteLiteral()`, so the literal is
  typed the way the setting says;
  an inline `as.POSIXct("…")` is translated instead
  and casts the string as written, out of the setting's reach.
  The mechanics and the workaround are
  [`integrations/`](/handbook/usage/integrations/README.md)'s
  ([#1064](https://github.com/duckdb/duckdb-r/issues/1064)).
* **`TIMETZ` flattens.**
  Its per-row offsets have no `POSIXct` home
  and drop to `difftime` seconds;
  the verification record behind this leaf,
  [`plan/history/2026-05-timestamptz-icu.md`](/plan/history/2026-05-timestamptz-icu.md),
  carries that scenario and the rest of the history.

*To deepen: extend
[`experiments/2026-08-08-timezone-grid/`](/experiments/2026-08-08-timezone-grid/README.md)
over the writing direction, so the paths `posixct` does reach
are measured across their settings too.*
