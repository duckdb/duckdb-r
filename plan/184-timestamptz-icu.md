# #184 — TIMESTAMPTZ + ICU follow-ups

The fix in 50ba3fc makes `TIMESTAMP WITH TIME ZONE` columns pick up the
DuckDB session's `TimeZone` setting. This document records (a) the things
worth exercising from R in a session that allows installing `icu`, (b)
the outcomes when run locally here (where `icu` was downloaded once and
is cached under `inst/extensions/`), and (c) what those outcomes imply
for the current implementation.

The CLI used for cross-checking is `duckdb v1.5.3 (Variegata)`. The CLI
ships `icu` as a built-in extension; the duckdb R package does **not**
statically link `icu`, so reproducing the "without icu" behaviour from R
requires either deleting the cached extension or simply not running
`LOAD icu`.

## TL;DR — does each column have its own timezone?

No. In DuckDB's model:

* `TIMESTAMPTZ` storage is a single int64 of microseconds since the UTC
  epoch. The display timezone is **per session**, applied uniformly to
  every TIMESTAMPTZ column and every row in a query result.
* Two TIMESTAMPTZ columns in the same `SELECT` cannot have different
  timezones. They share whatever `current_setting('TimeZone')` returns
  at execute time.
* The only "per-column" timezone is achieved by `... AT TIME ZONE 'X'`,
  which *demotes* the column to plain `TIMESTAMP` (no tz). That's a
  type change, not a per-column tz attribute.
* `TIMETZ` (`TIME WITH TIME ZONE`) does store a per-row offset, and
  `SET TimeZone` does **not** renormalise it. R loses this information
  today (see B11 below).

So the implementation choice in 50ba3fc — one `tzone` attribute per
result, sourced from `result->client_properties.time_zone` — is faithful
to what DuckDB itself does. There is nothing finer-grained to model.

## Things to try in an R session that can install ICU

```r
library(duckdb)
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL icu")
dbExecute(con, "LOAD icu")
```

The scenarios below are grouped by whether they need ICU. "Without ICU"
means *do not call `LOAD icu`* (numeric offsets parse without it; named
zones don't).

### A. No ICU required (numeric offsets only)

| # | Scenario | What to check |
|---|---|---|
| A1 | `SELECT TIMESTAMPTZ '2024-01-10 13:03:12-08:00'` etc. with `-08:00`, `-05:00`, `+09:00`, `Z` | Each input offset should produce a distinct UTC instant; `tzone` attribute on the column should be `"Etc/UTC"` (default session tz). |
| A2 | `TIMESTAMPTZ '2024-01-10 13:03:12'` (no offset) | Without ICU, naive literal is interpreted as UTC. |
| A3 | `SET TimeZone = 'UTC'` | Trivially works without ICU. |
| A4 | `SET TimeZone = 'America/Los_Angeles'` **without** `LOAD icu` | Should error: `Conversion Error: Unknown TimeZone 'America/Los_Angeles'`. |

### B. ICU required

| # | Scenario | What to check |
|---|---|---|
| B1 | `SET TimeZone = 'America/Los_Angeles'` then `SELECT TIMESTAMPTZ '... -08:00'` | Returned POSIXct has `tzone = "America/Los_Angeles"` and clock matches DuckDB's `::VARCHAR` rendering. |
| B2 | Two `TIMESTAMPTZ` columns with different offsets in one `SELECT` | Both columns share the same `tzone` (= session tz). The differing input offsets show up as different clock times within that shared zone. |
| B3 | `TIMESTAMPTZ '...' AT TIME ZONE 'America/Los_Angeles'` vs `AT TIME ZONE 'Asia/Tokyo'` in one row | Both result columns are plain `TIMESTAMP` (no `tzone` from session). They inherit the connection's `timezone_out`. |
| B4 | Plain `TIMESTAMP` column after `SET TimeZone = '...'` | Unaffected by the session tz. `tzone` is whatever `timezone_out` is at the connection. |
| B5 | Cast `TIMESTAMP '2024-01-10 13:03:12'` to TIMESTAMPTZ with `SET TimeZone = 'America/Los_Angeles'` | DuckDB interprets the naive literal as local LA time, so the stored UTC instant is `2024-01-10 21:03:12 UTC`. |
| B6 | Same query against a `TIMESTAMPTZ` table, called twice with different `SET TimeZone` between calls | Same underlying instant, different `tzone` and different clock display per call. |
| B7 | `rel_to_altrep(rel_from_table(con, "x"))` after `SET TimeZone = 'America/Los_Angeles'` | ALTREP path picks up LA — captured at altrep build time. |
| B8 | `rel_from_table` at tz=LA, `SET TimeZone='Asia/Tokyo'`, then `rel_to_altrep` | Captures tz at `rel_to_altrep`, not `rel_from_table`. Result is Tokyo. |
| B8c | Same as B8 but tz changed *between* `rel_to_altrep` and first data access | Divergence: ALTREP froze tz at altrep-build, regular `dbGetQuery` would have used the newer tz. |
| B9 | `dbWriteTable` a POSIXct vector with `tzone = 'America/Los_Angeles'`, read back | Column is written as `TIMESTAMP` (not `TIMESTAMPTZ`). The R-side tz attribute is lost; you get back UTC. |
| B10 | `dbConnect(timezone_out = 'Pacific/Tahiti', tz_out_convert = 'force')` + `SET TimeZone = 'America/Los_Angeles'` + TIMESTAMPTZ query | The R-side `force` reformatter overrides the session tz. Result has `tzone = 'Pacific/Tahiti'` and the clock is "forced" to that zone. |
| B11 | `SELECT TIMETZ '13:03:12-08:00', TIMETZ '13:03:12-05:00', TIMETZ '13:03:12+09:00'` | DuckDB preserves each per-row offset (`extract(timezone FROM a)` shows them). R returns `difftime(secs)` for all three identical at 46992s — **the per-row offset is silently dropped**. |

## Local results (run with `icu` cached and loaded as noted)

### Part A — no ICU loaded

* **A1** — `Etc/UTC` session, four offset variants returned:
    | input | UTC instant returned |
    | --- | --- |
    | `-08:00` | `2024-01-10 21:03:12 UTC` |
    | `-05:00` | `2024-01-10 18:03:12 UTC` |
    | `+09:00` | `2024-01-10 04:03:12 UTC` |
    | `Z`      | `2024-01-10 13:03:12 UTC` |
    All four columns get `tzone = "Etc/UTC"`. ✅
* **A2** — naive literal cast to TIMESTAMPTZ → `2024-01-10 13:03:12 UTC`. ✅
* **A3** — `SET TimeZone = 'UTC'` works. ✅
* **A4** — without `LOAD icu`, `SET TimeZone = 'America/Los_Angeles'`
  errors as expected (`Conversion Error: Unknown TimeZone ...`). ✅

### Part B — with `LOAD icu`

* **B1** — `tzone = "America/Los_Angeles"`, clock `2024-01-10 13:03:12`
  PST. Matches DB-side `::VARCHAR`. ✅
* **B2** — both columns get `tzone = "America/Los_Angeles"`. Clocks are
  `13:03:12` and `10:03:12` (the two different UTC instants viewed in
  LA). ✅
* **B3** — `DESCRIBE` reports both `AT TIME ZONE` columns as plain
  `TIMESTAMP`. They render as `2024-01-10 13:03:12` (LA-as-local) and
  `2024-01-11 06:03:12` (Tokyo-as-local) but with no `tzone` from the
  session. ✅
* **B4** — plain TIMESTAMP keeps `tzone = "UTC"` (connection default).
  ✅
* **B5** — cast of `TIMESTAMP '2024-01-10 13:03:12'` produces
  `1704920592s = 2024-01-10 13:03:12 PST`, i.e. naive literal
  interpreted as session-local. ✅
* **B6** — switching session tz mid-connection produces independent
  results:
    | session tz | returned clock | returned tzone |
    | --- | --- | --- |
    | `Asia/Tokyo` | `2024-01-11 06:03:12 JST` | `Asia/Tokyo` |
    | `Etc/UTC`    | `2024-01-10 21:03:12 UTC` | `Etc/UTC`    |
    Same underlying instant, different display. ✅
* **B7** — `tzone = "America/Los_Angeles"` on the ALTREP column. ✅
* **B8** — set LA, build rel, switch to Tokyo, then `rel_to_altrep`:
  result has `tzone = "Asia/Tokyo"`. Decoration captures tz at
  `rel_to_altrep`, not at `rel_from_table`. ✅
* **B8c** — set LA, build rel, `rel_to_altrep` (decorate → LA),
  switch to Tokyo, *then* read the data (triggers materialize):
  result keeps `tzone = "America/Los_Angeles"` while a fresh
  `dbGetQuery` at the same moment returns `Asia/Tokyo`. The two paths
  disagree on which session tz to use. Both are internally consistent
  (the clock matches the tzone), but they don't match each other. ⚠️
* **B9** — round-trip POSIXct loses the input `tzone`:
    | step | type | tzone |
    | --- | --- | --- |
    | R input | POSIXct | `America/Los_Angeles` |
    | DuckDB column | `TIMESTAMP` (not `TIMESTAMPTZ`) | n/a |
    | R output | POSIXct | `UTC` |
    `dbWriteTable` never picks `TIMESTAMPTZ` for POSIXct. ⚠️
* **B10** — `tz_out_convert = "force"` overrides the session tz: result
  has `tzone = "Pacific/Tahiti"` even with session = LA. Force path
  short-circuits the new `session_time_zone` plumbing — same as it
  short-circuits `timezone_out` for non-tz `TIMESTAMP`. ✅
* **B11** — `TIMETZ` with three distinct offsets all flatten to
  `difftime(46992 secs)`. `extract(timezone FROM a)` recovers `-28800,
  -18000, +32400` from inside DuckDB but the R column has no place to
  put them. ❌ (pre-existing, not addressed by 50ba3fc).

## Implementation implications

### What the fix gets right

* **TIMESTAMPTZ has no per-row or per-column tz**, so one `tzone`
  attribute sourced from `result->client_properties.time_zone` is the
  correct shape. B1, B2, B6 confirm parity with DuckDB's own rendering.
* **Plain TIMESTAMP** keeps its old `timezone_out` semantics. B3 and B4
  show the `AT TIME ZONE` and naked-TIMESTAMP cases route through the
  unchanged code path.
* **FORCE** mode still works because the R-side `tz_force` reformatter
  runs after the C++ decoration. Whatever `tzone` the C++ side sets is
  immediately replaced by `timezone_out` in R. B10 is consistent with
  the pre-fix behaviour.

### Limitations to keep in mind

1. **ALTREP / dbGetQuery divergence (B8c).** The regular path captures
   tz at `Execute()` (i.e. on `result->client_properties.time_zone`).
   The ALTREP path captures tz at `rapi_rel_to_altrep`, *before*
   materialization. If the user changes `SET TimeZone` between altrep
   construction and first data access, ALTREP renders in the older tz
   while `dbGetQuery` would render in the newer one. Both outputs are
   self-consistent; only their cross-path agreement is lost. Fixing
   would require re-decorating from inside `AltrepVectorWrapper::
   Dataptr()` using `mat_result->client_properties.time_zone`, which
   makes `attr(x, "tzone")` force materialization. Acceptable trade-off
   but not free.
2. **Multiple TIMESTAMPTZ columns share one tz (B2).** This is
   correct, not a limitation, but is worth recording: callers
   sometimes expect "each column has its own tz." It is impossible to
   express that in DuckDB without either (a) using `AT TIME ZONE` per
   column (which yields a plain `TIMESTAMP`) or (b) running multiple
   queries with different `SET TimeZone`.
3. **POSIXct round-trip drops `tzone` (B9).** `dbWriteTable` picks
   `TIMESTAMP`, not `TIMESTAMPTZ`. The input tz is unrecoverable on
   read-back. To make this round-trip lossless the writer would have
   to pick `TIMESTAMPTZ` and the column's UTC instants would still
   come back rendered in the *session* tz, not the input tz —
   information lost either way. This is upstream of #184 (see the
   discussion comments) and out of scope.
4. **TIMETZ silently flattens (B11).** Pre-existing. POSIXct cannot
   carry per-row offsets (scalar `tzone`). A faithful representation
   needs either:
    - a list column of `(time_of_day_seconds, offset_seconds)` pairs;
    - a vctrs/clock-style class with element-wise zones; or
    - a struct return `{ time, offset }`.
    None of these fit the existing `difftime` pipeline. Tracking
    separately from #184.
5. **`session_time_zone = ""` fallback to `timezone_out`.** The current
   code falls back to `timezone_out` only when `session_time_zone` is
   empty. In practice `client_properties.time_zone` defaults to
   `"UTC"`, never `""`, so the fallback is dead code on the regular
   path. The ALTREP path used to be the only caller that could leave
   it empty (when `drel->context` is null); B7/B8 show the field is
   populated in all observed cases.
