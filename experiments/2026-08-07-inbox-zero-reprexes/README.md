# Reprexes for the inbox-zero closes

*What it measures:* what the released package does
when each issue in the "close with evidence", "close upstream", and "close as stale" groups of
[#2522](https://github.com/duckdb/duckdb-r/issues/2522) is run again,
one reprex per issue, rendered to a transcript that a closing comment can carry whole.
A verdict of "already fixed" or "belongs upstream" is a claim about behaviour;
these are the runs that back it.
Where a run grew into an experiment of its own,
that experiment owns the finding and this directory links it instead of keeping a second transcript.

*When and on what:* 2026-08-07, Linux x86_64 (4 cores, 15 GB RAM), R 4.5.3,
**duckdb 1.5.5 from CRAN**, the version a reporter would install rather than this repository's development build,
with dbplyr 2.6.0, arrow 25.0.0, sf 1.1.2, reprex 2.1.1,
and, for [#72](issue-0072-parquet-aggregation-memory.md)'s cross-check, the standalone `duckdb` CLI of the same version, v1.5.5.
[#1064](issue-1064-as-posixct-timezone.md) and [#1065](issue-1065-arrow-fetch-memory.md) were rendered again on 2026-09-26
on the same machine shape and duckdb 1.5.5 from CRAN, with arrow 25.0.1 and nanoarrow 0.9.0.
Extension-repository probes are HTTP HEAD against `extensions.duckdb.org` on the first date.
[`render.R`](render.R) renders every `issue-*.R` next to it as `.md`;
it sets `DUCKDB_R_HOME` so that 1.5.5's one-time storage-location note (see `?duckdb_storage`) does not open every transcript,
which changes where extensions are cached and nothing else.

*What it supports:* the closing comments for the issues below,
under [`operations/triage/`](/handbook/operations/triage/README.md)'s rule that a close cites its evidence.
Of them, [#98](https://github.com/duckdb/duckdb-r/issues/98) and [#202](https://github.com/duckdb/duckdb-r/issues/202) stay open.

## Close with evidence

* [#162](issue-0162-dbi-arrow-api.md): all seven DBI Arrow generics have methods;
  `dbGetQueryArrow()` returns a `nanoarrow_array_stream`,
  a million rows arrive in chunks,
  and `dbWriteTableArrow()` takes an Arrow table back without a data frame in between.
* [#200](issue-0200-map-append.md): the issue's reprex runs unchanged.
  `dbAppendTable()` writes the `MAP` column,
  and a value read out of the table can be written straight back in.
* [#590](issue-0590-units-through-arrow.md): `st_area()`'s units column through `write_dataset()` and `to_duckdb()`
  no longer raises `Unknown column type for prepare: INVALID`;
  the column arrives as `DOUBLE`, keeping the value and dropping the unit label.
* [#1581](issue-1581-install-spatial-windows.md): `spatial` for `windows_amd64_mingw` is 404 at v1.4.0 and 200 from v1.4.1 on;
  the same `INSTALL`/`LOAD` on Linux works throughout, so the R side was never what failed.
* [#2230](issue-2230-try-cast.md): `as.numeric()`, `as.integer()`, `as.Date()` and `as.POSIXct()` all translate to `TRY_CAST`;
  an unparseable value collects as `NA` where a hand-written `CAST` still errors.

## Close upstream

* [#100](issue-0100-out-of-tree-extensions-windows.md): at v1.5.5 the `windows_amd64_mingw` directory serves
  excel, fts, httpfs, icu, inet, json, spatial, sqlite_scanner, tpcds and tpch,
  and 404s for aws, azure, iceberg, motherduck, mysql_scanner and postgres_scanner,
  all of which exist as `windows_amd64`.
  The gap is a toolchain flavour, and it is [#2234](https://github.com/duckdb/duckdb-r/issues/2234)'s;
  what a user does about it is [`usage/extensions/`](/handbook/usage/extensions/README.md)'s.
* [#384](https://github.com/duckdb/duckdb-r/issues/384): the `ROW_NUMBER()` subquery is written by dbplyr's `distinct()` method.
  Whether `DISTINCT ON` would be faster is
  [`2026-08-09-distinct-on-cost/`](/experiments/2026-08-09-distinct-on-cost/README.md),
  and whether a caller can have it anyway is
  [`2026-08-09-distinct-on-override/`](/experiments/2026-08-09-distinct-on-override/README.md).
* [#1064](issue-1064-as-posixct-timezone.md): `as.POSIXct()` in a translation casts the string as written and takes no `tz` argument,
  while the same value escaped with `!!` is converted to UTC.
  Postgres, MSSQL and MySQL split the same way, so the convention is dbplyr's;
  on DuckDB both halves are this package's methods, though:
  the translation is `sql_try_cast("TIMESTAMP")` and the escape is `sql_escape_datetime.duckdb_connection()`,
  both in [`R/backend-dbplyr__duckdb_connection.R`](/R/backend-dbplyr__duckdb_connection.R).
  The workaround is [`usage/integrations/`](/handbook/usage/integrations/README.md)'s.
* [#1083](issue-1083-duckdb-ui-from-r.md): the `ui` extension is 404 for `windows_amd64_mingw` at v1.2.0 and 200 from v1.2.1 on;
  from R, `INSTALL ui`, `LOAD ui` and `CALL start_ui_server()` all succeed,
  so what a browser then renders is the extension's.
* [#1829](issue-1829-unused-function-warnings.md): the header the warnings name is vendored from duckdb/duckdb
  and documents the effect in its own first lines;
  a thirteen-line reconstruction of the construct (`static` function template, explicit specializations) reproduces the warning,
  and R's default `CXXFLAGS` do not ask for it.
* [#2503](issue-2503-postgres-scanner-windows.md): `postgres_scanner` is 404 for `windows_amd64_mingw`
  and 200 for `windows_amd64` and `linux_amd64`,
  where spatial and httpfs are 200 for all three;
  `INSTALL postgres` on Linux works.

## Close as stale, inviting a fresh report

* [#72](issue-0072-parquet-aggregation-memory.md): see below;
  at a size and cardinality that make the aggregate real,
  the reported failure comes back, and it comes back in the CLI too.
* [#98](issue-0098-register-generic.md): still exactly `duckdb_register()` and `duckdb_register_arrow()`.
  They are not two names for one operation:
  the first calls `as.data.frame()` on its input, the second copies nothing.
  What arrived instead is the DBI Arrow API, which dispatches on the object.
* [#202](https://github.com/duckdb/duckdb-r/issues/202): not stale.
  Which running work a Ctrl+C stops, in R and in the CLI,
  and why the MotherDuck `ATTACH` in the report behaves differently in the two,
  is [`2026-08-08-interrupt-reach/`](/experiments/2026-08-08-interrupt-reach/README.md).
* [#1065](issue-1065-arrow-fetch-memory.md): see below;
  the Arrow stream bounds memory only when each batch is released.
* [#1147](issue-1147-start-ui-twice.md): see below; it reproduces.
* [#1604](https://github.com/duckdb/duckdb-r/issues/1604):
  the spill failure behind "temporary directory does not used" is
  [`2026-08-temp-storage-spill/`](/experiments/2026-08-temp-storage-spill/README.md),
  which runs the report's own steps and both connection idioms across four builds,
  the last of them the fix, [#2562](https://github.com/duckdb/duckdb-r/pull/2562).

## What the run changed

These came out different from the plan they were written for.

* **[#72](issue-0072-parquet-aggregation-memory.md) is not "the engine four majors on".**
  The first version of this reprex used sequential keys,
  which compress to 35 MB and leave an aggregate small enough to succeed;
  that measured the data, not the engine.
  With 200M rows whose keys are hashed, 1.1 GB on disk and 40M groups,
  a 256 MB limit fails with the error the report quotes
  (`Out of Memory Error: ... 244.1 MiB/244.1 MiB used`),
  having spilled nothing at all,
  and 1 GB succeeds after spilling 1057 MB.
  The reporter's last word was that the same work "works fine in the CLI client, crashes in R"
  ([comment 1964392402](https://github.com/duckdb/duckdb-r/issues/72#issuecomment-1964392402), duckdb 0.10);
  on 1.5.5 that split is gone.
  The standalone client, same version, same statements, same limits,
  fails at 256 MB and succeeds at 1 GB exactly as R does.
  So what to invite a fresh report about is the *floor*, not the client;
  the R-specific remainder stays [#97](https://github.com/duckdb/duckdb-r/issues/97).
* **[#1147](issue-1147-start-ui-twice.md) is not stale: it reproduces**,
  on Linux, on 1.5.5, with the reporter's exact message:
  `terminate called ... {"exception_type":"Settings",`
  `"exception_message":"Setting \"ui_polling_interval\" not found"}`,
  and the process aborts.
  The trigger is narrower than the report:
  the first database has to be finalised while its UI server is still running,
  *and* a new server has to start in the window that follows.
  Keeping the first connection alive, stopping the server before dropping it, or waiting two seconds all survive,
  which is why it looked environment-specific.
  The [closing comment](https://github.com/duckdb/duckdb-r/issues/1147#issuecomment-5231877771) narrows the window to `ui_polling_interval`
  and sends the report to duckdb/duckdb-ui, since what fails is the `ui` extension's teardown.
* **[#1065](issue-1065-arrow-fetch-memory.md)'s streaming escape takes one more line.**
  Peak resident set for the same 20M-row result:
  871 MB fetched as one Arrow table,
  814 MB through the DBI chunk loop when each batch is merely dropped,
  162 MB when each is released with `nanoarrow::nanoarrow_pointer_release()`,
  1659 MB through `duckdb_fetch_record_batch()`,
  298 MB as ten bounded queries,
  and 101 MB when the count is left to the engine.
  Why a dropped batch is held until a collection is
  [`usage/memory/reading/`](/handbook/usage/memory/reading/README.md)'s,
  and `?duckdb_memory` carries the loop.

## Re-running

```r
setwd("experiments/2026-08-07-inbox-zero-reprexes")
Rscript render.R                       # all of them
Rscript render.R issue-0200-map-append.R   # or one
```

Every transcript names its own duckdb version,
so a re-run on a later release is a new record rather than an edit of this one.
The memory measurements are machine-specific in absolute terms;
what the runs establish is the ordering between strategies,
and, for #72, that R and the CLI land on the same side of the limit.
