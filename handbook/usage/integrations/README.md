# Integrations

The routes into DuckDB that do not go through plain `dbGetQuery()`:
dplyr pipelines that dbplyr translates to SQL,
and Arrow, which moves batches across the R boundary without copying them.
What each R type becomes on the other side belongs to
[`types/`](/handbook/usage/types/),
what a connection is and when it goes away to
[`connections/`](/handbook/usage/connections/),
and what a streaming result costs in memory to
[`memory/`](/handbook/usage/memory/).

## The dbplyr backend

dbplyr and dplyr are `Suggests`,
so the backend is wired up at load time rather than declared in `NAMESPACE`:
`.onLoad()` registers S3 methods for dbplyr's `dbplyr_edition()`,
`db_connection_describe()`, `sql_translation()`, `sql_expr_matches()`,
`sql_escape_date()` and `sql_escape_datetime()`,
and for `dplyr::tbl()`.
A session without dplyr installed loads the package normally
and simply never sees them.
The backend declares dbplyr edition 2.

`?backend-duckdb` is the reference page for the backend,
and the file it is generated from,
[`R/backend-dbplyr__duckdb_connection.R`](/R/backend-dbplyr__duckdb_connection.R),
is where the translations themselves live.
`sql_translation.duckdb_connection()` extends dbplyr's `base_scalar`,
`base_agg` and `base_win` translators —
it follows dbplyr's PostgreSQL backend and adds more mapped functions,
among them bit operations,
`is.nan()` / `is.finite()` / `is.infinite()`,
regex-backed stringr verbs, lubridate and clock helpers,
and aggregates such as `median()`, `quantile()` and `n_distinct()`
together with their window forms.
Anything not named there falls through to dbplyr's own defaults.
The coercion functions — `as.numeric()`, `as.Date()`, `as.integer64()`
and the rest — translate to `TRY_CAST()` rather than `CAST()`,
so a value that will not convert yields `NULL` instead of failing
the whole query
([#2230](https://github.com/duckdb/duckdb-r/issues/2230)).

`tbl()` is overridden so that a name which is not an existing table
becomes a replacement scan — `tbl(con, "data.parquet")` is rewritten to
`FROM data.parquet` and handed to DuckDB.
The explicit forms are safer and are what to reach for:
`tbl_file()` takes a path to a Parquet, CSV or JSON file
(and refuses a path containing a single quote,
because it cannot be quoted safely),
and `tbl_function()` takes a table-generating function call
such as `read_csv_auto('...')`.
`tbl_query()` is deprecated in favour of `tbl_function()`.
Passing `cache = TRUE` to any of them runs `PRAGMA enable_object_cache`
on the connection, which speeds up repeated Parquet reads.
`simulate_duckdb()` renders the SQL for a `lazy_frame()`
without opening a connection at all.

## Where translation stops

The backend translates *expressions* and the literal escapes.
It adds no verb-level methods,
so every dplyr verb produces whatever SQL dbplyr generates generically,
however much better DuckDB's own syntax would be:

* `distinct(.keep_all = TRUE)` becomes a `ROW_NUMBER()` subquery,
  not DuckDB's `DISTINCT ON`
  ([#384](https://github.com/duckdb/duckdb-r/issues/384)).
  An attempt at it concluded that the change belongs in dbplyr
  ([tidyverse/dbplyr#1620](https://github.com/tidyverse/dbplyr/pull/1620)),
  and `DISTINCT ON` is DuckDB-specific syntax that dbplyr would have to
  admit as such.
* `copy_to(temporary = TRUE)` writes a real temporary table,
  because `db_copy_to()` is not overridden
  ([#209](https://github.com/duckdb/duckdb-r/issues/209)).
  Registering the data frame instead would copy nothing;
  `duckdb_register()` does exactly that today, outside dplyr.
* `pivot_longer()` on a lazy table expands the way dbplyr expands it,
  which is dramatically slower than DuckDB's `UNPIVOT`
  ([#2029](https://github.com/duckdb/duckdb-r/issues/2029)).
  `UNPIVOT` is reachable through `tbl_function()` or `dplyr::sql()`.

Some translations refuse arguments they cannot honour, with an error:
`grepl()` rejects `perl`, `fixed` and `useBytes`;
`quarter()` requires `fiscal_start = 1`;
`clock::date_count_between()` requires `precision = "day"` and `n = 1`;
`str_pad()` accepts only `"left"`, `"right"` and `"both"`.
The `lubridate` duration helpers (`seconds()`, `minutes()`, … `years()`)
translate to DuckDB's `TO_*` functions and work inside a query,
but the source notes that getting `INTERVAL`-typed data back out
is unreliable pending
[duckdb/duckdb#1920](https://github.com/duckdb/duckdb/issues/1920).

Literals are escaped by dbplyr, not here, and the consequences show up
as recurring reports:

* `as.POSIXct("2025-03-01 18:00:00")` written inside a pipeline
  translates to a cast of that string,
  so the session time zone is never applied;
  `!!as.POSIXct(...)` is escaped R-side and does convert to UTC
  ([#1064](https://github.com/duckdb/duckdb-r/issues/1064)).
  The inconsistency is dbplyr's, and the issue is labelled upstream.
* `Inf` is escaped as the string `'Infinity'`,
  so `mutate(z = Inf)` yields a text column
  ([#1585](https://github.com/duckdb/duckdb-r/issues/1585)).
  `as.numeric(Inf)` does produce a floating-point infinity,
  since the cast target became `DOUBLE` rather than `NUMERIC`;
  bare `Inf` still needs `dplyr::sql("'Infinity'::FLOAT")`.
  A fix needs a hook dbplyr does not have yet.

The `n_distinct()` translation reaches into dbplyr's internals:
it fetches the unexported `glue_sql2()` with `pkg_method()`.
A dbplyr development version that dropped it broke `n_distinct()`
outright ([#1982](https://github.com/duckdb/duckdb-r/issues/1982));
dbplyr restored the function and offers `sql_glue()` from 2.6.0 instead,
so the coupling remains until that migration happens.

## Arrow interchange

Arrow data goes in as a registered virtual table
and comes out as a stream of record batches.

`duckdb_register_arrow()` registers a scannable Arrow object under a name;
nothing is copied, and `duckdb_unregister_arrow()` and `duckdb_list_arrow()`
manage the registrations.
It calls into the arrow package directly, so arrow must be installed.
When DuckDB scans such a table it hands the projection and the filters
back to R as an Arrow scanner specification
([`src/register.cpp`](/src/register.cpp)):
constant comparisons, `IS NULL` / `IS NOT NULL`, and `AND` / `OR`
translate, and `IN` translates up to the `MAX_PUSHDOWN_IN_VALUES` cap
declared there,
expanded into a balanced tree of equality comparisons.
Past that, the conversion raises a not-implemented error
rather than quietly scanning everything —
except inside an optional filter, which only prunes and which DuckDB
re-applies itself, where the pushdown degrades to a `TRUE` predicate.

Results come back through the DBI Arrow API:
`dbSendQueryArrow()`, `dbFetchArrow()`, `dbFetchArrowChunk()`,
`dbBind()` and `dbBindArrow()`.
These return nanoarrow objects backed by DuckDB's own `ArrowArrayStream`,
fetched chunk by chunk — the `chunk_size` argument sets how many rows
at a time — instead of materializing the result first
([#162](https://github.com/duckdb/duckdb-r/issues/162)).
nanoarrow is a `Suggests`, and a missing install is reported with a hint.
Binding several rows at once runs the query once per row
and concatenates the results into a single stream.
The intent behind the API,
including why streaming is opt-in and what was left out,
is in [`plan/PLAN-dbSendQueryArrow.md`](/plan/PLAN-dbSendQueryArrow.md).

The older path predates that API and still works:
`dbSendQuery(arrow = TRUE)` with `duckdb_fetch_arrow()` or
`duckdb_fetch_record_batch()`.
It materializes the whole result up front,
and `dbFetch()` on such a result accepts only `n = -1`.
It is kept for backward compatibility and flagged for eventual deprecation.

`duckdb_adbc()` is a route of its own:
it returns a driver for the adbcdrivermanager package,
so DuckDB can be used through Arrow Database Connectivity
instead of through DBI.

## What Arrow interchange does not cover

Only the read side is native.
The package implements no `dbCreateTableArrow()`, `dbAppendTableArrow()`
or `dbWriteTableArrow()` methods,
so DBI's defaults apply and every chunk becomes a data frame
on its way into a table.
Getting Arrow data in without that detour means registering it
with `duckdb_register_arrow()` and running `CREATE TABLE … AS SELECT`.
On the read side `dbGetQueryArrow()` and `dbReadTableArrow()` need no
method of their own: DBI's defaults are built on `dbSendQueryArrow()`,
so they stream.

`dbFetchArrow()` hands its stream over once —
the result is complete afterwards, and fetching again yields
an empty stream, not the data a second time.
