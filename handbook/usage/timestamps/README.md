# Timestamps and time zones

How a timestamp crosses to R:
which zone labels it, when an instant can change,
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
* **Going the other way, in a dbplyr pipeline, the zone is dbplyr's
  to apply — and it applies one only when the value is escaped.**
  `!!` sends the instant as a UTC-naive literal;
  an inline `as.POSIXct("…")` is translated and casts the string as
  written, with no argument that would say otherwise.
  The mechanics and the workaround are
  [`integrations/`](/handbook/usage/integrations/README.md)'s
  ([#1064](https://github.com/duckdb/duckdb-r/issues/1064)).
* **`TIMETZ` flattens.**
  Its per-row offsets have no `POSIXct` home
  and drop to `difftime` seconds;
  the verification record behind this leaf,
  [`plan/history/2026-05-timestamptz-icu.md`](/plan/history/2026-05-timestamptz-icu.md),
  carries that scenario and the rest of the history.

*To deepen: state the writing direction —
what `dbWriteTable()` and `duckdb_register()` pick for a `POSIXct`,
and the round-trip that loses the input zone.*
