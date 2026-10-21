# Timestamp labeling grid

*What it measures:* which zone labels a `TIMESTAMP` and a
`TIMESTAMPTZ` column on the way to R, and when an instant changes,
across local zone × `timezone_out` × `tz_out_convert` ×
session `TimeZone` — 24 combinations, both column types each.

*When and on what:* 2026-08-08, duckdb 1.5.5.9010
(DuckDB 1.5.5, vendored build, icu loaded from the extension store),
Linux.
A binary that links icu statically answers differently:
its session `TimeZone` exists from startup
and defaults to the machine's zone.

*What it supports:*
[`usage/timestamps/`](/handbook/usage/timestamps/README.md).

Run [`grid.R`](grid.R); the recorded run is [`grid.md`](grid.md),
rendered with `reprex::reprex(si = TRUE)`.
The values probed are `TIMESTAMP '2024-01-10 13:03:12'` and
`TIMESTAMPTZ '2024-01-10 13:03:12-08:00'`;
the epochs that appear are
1704891792 (13:03:12 read as UTC),
1704920592 (the offset literal's instant, 21:03:12 UTC),
and their `"force"`-shifted counterparts
1704927792 and 1704956592
(the same wall clocks re-anchored in `Pacific/Tahiti`).

What the grid compresses to:

* No `"with"` cell changes an epoch; every `"force"` cell with a
  non-UTC target does.
* `tstz_label` never equals `timezone_out` under `"with"`:
  it is the session zone (`America/Los_Angeles` rows)
  or the `UTC` fallback (`none` rows).
* `ts_*` columns are identical between the `none` and
  `America/Los_Angeles` session halves:
  plain `TIMESTAMP` never sees the session zone.
* The two local zones produce identical rows except where a label is
  empty: display for `"with"`, the force target for `"force"`,
  both spelled `timezone_out = ""`.
