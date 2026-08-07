# Reprexes for the inbox-zero closes

*What it measures:* what the released package does today when each issue in
the "close with evidence", "close upstream", and "close as stale" groups of
[#2522](https://github.com/duckdb/duckdb-r/issues/2522) is run again —
one reprex per issue, rendered to a transcript that a closing comment can
carry whole.
A verdict of "already fixed" or "belongs upstream" is a claim about
behaviour; these are the runs that back it.

*When and on what:* 2026-08-07, Linux x86_64, R 4.5.3,
**duckdb 1.5.5 from CRAN** — the version a reporter would install,
not this repository's development build —
with dbplyr 2.6.0, arrow 25.0.0, sf 1.1.2, reprex 2.1.1.
Extension-repository probes are HTTP HEAD against `extensions.duckdb.org`
on the same day.
[`render.R`](render.R) renders every `issue-*.R` next to it as `.md`;
it sets `DUCKDB_R_HOME` so that 1.5.5's one-time storage-location note
(see `?duckdb_storage`) does not open every transcript,
which changes where extensions are cached and nothing else.

*What it supports:* the closing comments for the issues below, under
[`operations/triage/`](/handbook/operations/triage/README.md)'s rule that a
close cites its evidence.

## Close with evidence

* [#162](issue-0162-dbi-arrow-api.md) — all seven DBI Arrow generics have
  methods; `dbGetQueryArrow()` returns a `nanoarrow_array_stream`,
  a million rows arrive in chunks, and `dbWriteTableArrow()` takes an
  Arrow table back without a data frame in between.
* [#200](issue-0200-map-append.md) — the issue's reprex runs unchanged:
  `dbAppendTable()` writes the `MAP` column, and a value read out of the
  table can be written straight back in.
* [#590](issue-0590-units-through-arrow.md) — `st_area()`'s units column
  through `write_dataset()` and `to_duckdb()` no longer raises
  `Unknown column type for prepare: INVALID`; the column arrives as
  `DOUBLE`, keeping the value and dropping the unit label.
* [#1581](issue-1581-install-spatial-windows.md) — `spatial` for
  `windows_amd64_mingw` is 404 at v1.4.0 and 200 from v1.4.1 on;
  the same `INSTALL`/`LOAD` on Linux works throughout, so the R side was
  never what failed.
* [#2230](issue-2230-try-cast.md) — `as.numeric()`, `as.integer()`,
  `as.Date()` and `as.POSIXct()` all translate to `TRY_CAST`;
  an unparseable value collects as `NA` where a hand-written `CAST` still
  errors.

## Close upstream

* [#100](issue-0100-out-of-tree-extensions-windows.md) — at v1.5.5 the
  `windows_amd64_mingw` directory serves excel, fts, httpfs, icu, inet,
  json, spatial, sqlite_scanner, tpcds and tpch,
  and 404s for aws, azure, iceberg, motherduck, mysql_scanner and
  postgres_scanner — all of which exist as `windows_amd64`.
  The gap is a toolchain flavour, and it is [#2234](https://github.com/duckdb/duckdb-r/issues/2234)'s.
* [#384](issue-0384-distinct-on.md) — the `ROW_NUMBER()` subquery is
  dbplyr's: the same `distinct(.keep_all = TRUE)` produces it against
  Postgres and MSSQL too, and duckdb-r defines no method that could
  intercept it. The engine has supported `DISTINCT ON` all along, and by
  hand it returns the same rows.
* [#1064](issue-1064-as-posixct-timezone.md) — `as.POSIXct()` in a
  translation casts the string as written and does not take a `tz`
  argument at all, while the same value escaped with `!!` is converted to
  UTC; Postgres, MSSQL and MySQL translate it identically, so the
  inconsistency is dbplyr's, not the dialect's.
* [#1083](issue-1083-duckdb-ui-from-r.md) — the `ui` extension is 404 for
  `windows_amd64_mingw` at v1.2.0 and 200 from v1.2.1 on;
  from R, `INSTALL ui`, `LOAD ui` and `CALL start_ui_server()` all
  succeed, so what a browser then renders is the extension's.
* [#1829](issue-1829-unused-function-warnings.md) — the header the
  warnings name is vendored from duckdb/duckdb and documents the effect in
  its own first lines; a thirteen-line reconstruction of the construct
  (`static` function template, explicit specializations) reproduces the
  warning, and R's default `CXXFLAGS` do not ask for it.
* [#2503](issue-2503-postgres-scanner-windows.md) — `postgres_scanner` is
  404 for `windows_amd64_mingw` and 200 for `windows_amd64` and
  `linux_amd64`, where spatial and httpfs are 200 for all three;
  `INSTALL postgres` on Linux works.

## Close as stale, inviting a fresh report

* [#72](issue-0072-parquet-aggregation-memory.md) — the same aggregation
  shape over 20M Parquet rows under a 256 MB memory limit spills to the
  database's temp directory, peaks at 427 MB resident and finishes in a
  second, four majors after the report.
* [#98](issue-0098-register-generic.md) — still exactly
  `duckdb_register()` and `duckdb_register_arrow()`.
  They are not two names for one operation: the first calls
  `as.data.frame()` on its input, the second copies nothing.
  What arrived instead is the DBI Arrow API, which dispatches on the
  object.
* [#202](issue-0202-interrupt-long-query.md) — a query that would run for
  hours gives up 7.5 seconds in when the session is sent SIGINT, and the
  connection is usable afterwards.
  The MotherDuck `ATTACH` in the report waits inside a closed-source
  extension and is not exercised here.
* [#1065](issue-1065-arrow-fetch-memory.md) — see below; the premise that
  a streaming fetch bounds memory does not survive measurement.
* [#1147](issue-1147-start-ui-twice.md) — see below; it reproduces.
* [#1604](issue-1604-append-under-memory-limit.md) — see below; the
  "temporary directory does not used" half has a named cause.

## What the run changed

Three items came out different from the plan they were written for.

* **[#1147](issue-1147-start-ui-twice.md) is not stale — it reproduces**,
  on Linux, on 1.5.5, with the reporter's exact message:
  `terminate called ... {"exception_type":"Settings",`
  `"exception_message":"Setting \"ui_polling_interval\" not found"}`,
  and the process aborts.
  The trigger is narrower than the report: the first database has to be
  finalised while its UI server is still running *and* a new server has to
  start in the window that follows.
  Keeping the first connection alive, stopping the server before dropping
  it, or waiting two seconds all survive — which is why it looked
  environment-specific.
  It is the `ui` extension's teardown, so it belongs to duckdb/duckdb-ui.
* **[#1604](issue-1604-append-under-memory-limit.md)'s title question has
  an answer**: on 1.5.5 a database opened as
  `dbConnect(duckdb(), dbdir = path)` — the form the report uses — gets a
  temp directory of `<tempdir()>/duckdb/temp`, and the first statement
  that spills dies with
  `IO Error: Failed to create directory ...: No such file or directory`.
  The same work through `dbConnect(duckdb(dbdir = path))` gets DuckDB's
  own `<db>.tmp` and goes through.
  The inserts themselves are fine at 3 GB and at 500 MB.
* **[#1065](issue-1065-arrow-fetch-memory.md) has no streaming escape to
  point at.** Peak resident set for the same 20M-row result:
  879 MB fetched as one Arrow table, 814 MB through the DBI chunk loop,
  1354 MB through `duckdb_fetch_record_batch()`,
  291 MB as ten bounded queries, and 101 MB when the count is left to the
  engine. Fetching costs memory proportional to the result whichever
  fetch API is used; only not fetching the whole thing helps.

[`finding-temp-directory-spill.R`](finding-temp-directory-spill.R) isolates
the defect behind #1604 on its own, in four connections and no data:
the package points `temp_directory` at a path whose parent nothing creates,
DuckDB's directory creation is not recursive, and `dbdir` given to
`dbConnect()` rather than to `duckdb()` never reaches
`resolve_storage_home()`'s temp branch, because `duckdb()` has already put
the in-memory answer into the driver config that `dbConnect()` carries over.
Both hold in this repository's development source as well as in 1.5.5.

## Re-running

```r
setwd("experiments/2026-08-07-inbox-zero-reprexes")
Rscript render.R                       # all of them
Rscript render.R issue-0200-map-append.R   # or one
```

Every transcript names its own duckdb version, so a re-run on a later
release is a new record rather than an edit of this one.
The three memory measurements are machine-specific in absolute terms
(4 cores, 15 GB RAM here); the ordering between strategies is the finding.
