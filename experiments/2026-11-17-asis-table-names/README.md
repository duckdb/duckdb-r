# `I("schema.table")` names, dbplyr and the strict `dbExistsTable()`

*What it measures:* where `dplyr::tbl(con, I("s.t"))` fails on duckdb 2.0, and whose code passes the `I()` on;
which classes dbplyr hands to DBI methods in `copy_to()` and `compute()`;
how nine ways of naming a table fare in `dbExistsTable()` and `tbl()`, on 2.0 and on 1.4.0;
what three changes to this package would make of the same nine;
and what DBI's default, RSQLite, RPostgres and odbc do with an `I()` name.

*When and on what:* 2026-11-17, Linux x86_64, Ubuntu 24.04, R 4.5.3, DBI 1.3.0, dplyr 1.2.1, dbplyr 2.6.0, RSQLite 3.53.3,
RPostgres 1.4.10, odbc 1.7.2.
Two builds, each rendered by [`scripts/render-reprex.R`](/scripts/render-reprex.R):

* [`v2.0-cyanoptera.md`](v2.0-cyanoptera.md), from [`asis-table-names.R`](asis-table-names.R):
  duckdb 2.0.0.9000 at afffa45 of `v2.0-cyanoptera`, without [#3003](https://github.com/duckdb/duckdb-r/pull/3003),
  loaded with `pkgload::load_all()` as a fast-path build linking the release `libduckdb` of DuckDB 2.0.0
  ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
* [`v1.4.0.md`](v1.4.0.md), from [`cran-1-4-0.R`](cran-1-4-0.R): duckdb 1.4.0, the CRAN binary.

*What it supports:* the `I()` entry in the dbplyr section of [`usage/integrations/`](/handbook/usage/integrations/README.md),
and [#2973](https://github.com/duckdb/duckdb-r/issues/2973).

## The stack

The rlang backtrace of `dplyr::tbl(con, I("s.t"))`, without the frames of the harness that catches it:

```
 9. ├─dplyr::tbl(con, I("s.t"))
10. └─duckdb:::tbl.duckdb_connection(con, I("s.t"))
11.   ├─DBI::dbExistsTable(src, from) at R/backend-dbplyr__duckdb_connection.R:687:3
12.   └─DBI::dbExistsTable(src, from)
13.     ├─DBI::dbQuoteIdentifier(conn, name) at R/dbExistsTable__duckdb_connection_ANY.R:13:3
14.     └─duckdb::dbQuoteIdentifier(conn, name)
15.       └─DBI::SQL(x, names = names(x)) at R/dbQuoteIdentifier__duckdb_connection.R:18:3
16.         └─methods::new("SQL", x)
```

* dplyr owns the generic, `tbl()`, and nothing else.
* No dbplyr frame is on the stack.
  The `I()` never reaches dbplyr: duckdb's own S3 method, `tbl.duckdb_connection()`, probes it first.
* duckdb's method calls `DBI::dbExistsTable()`, whose duckdb method calls `DBI::dbQuoteIdentifier()`.
  Both are DBI generics dispatching to duckdb's methods, registered for `x` and `name` of any class.
* duckdb's `dbQuoteIdentifier()` escapes by subassignment, which keeps the `"AsIs"` class,
  and `DBI::SQL()` then refuses an object of that class in `new()`.
  The error is that accident, not a check that names the problem.

## Root cause

The `I()` reaches a strict DBI method through this package's own `tbl()` method, not through dbplyr.
That method asks `dbExistsTable(src, from)` about every `from` that is not `sql()`,
so that a bare string naming a file or a table function can fall back to `sql(paste0("FROM ", from))`, a replacement scan.

* [duckdb/duckdb#3264](https://github.com/duckdb/duckdb/pull/3264), merged 2022-03-29, added the method and its probe
  ("Allow replacement scan if table is not found", then "Use dbExistTable"),
  so that `tbl(con, "'test.parquet'")` and `tbl(con, "read_csv_auto('file.csv')")` reach DuckDB unquoted.
  It wrapped a non-table in `ident_q()`.
* [#91](https://github.com/duckdb/duckdb-r/pull/91), merged 2024-03-03 for [#38](https://github.com/duckdb/duckdb-r/issues/38),
  replaced `ident_q()` with the `FROM` fallback, after dbplyr 2.4.0 had broken the `ident_q()` route.
* [#194](https://github.com/duckdb/duckdb-r/pull/194), the 1.0.0 merge that closed [#189](https://github.com/duckdb/duckdb-r/issues/189),
  widened `dbExistsTable()` from `name = "character"` to `"ANY"`.
  Before it, `tbl(con, I("main.cars"))` failed with "unable to find an inherited method ... `"AsIs"`".
  After it, the `I()` reached `dbQuoteIdentifier()` inside the probe's `tryCatch()`, which turned the same `SQL()` error into `FALSE`,
  and the `FROM s.t` fallback happened to be the query the user meant.
  No test pins `tbl(con, I(...))`.

The same probe is why `tbl(con, in_schema("s", "t"))` fails on both 1.4.0 and 2.0, with "Can only have a single name argument":
a `dbplyr_schema` is a list of length two
([tidyverse/dbplyr#1333](https://github.com/tidyverse/dbplyr/issues/1333) reported it in 2023).

## What dbplyr hands to DBI

dbplyr turns `I("s.t")` into a `dbplyr_table_path`, verbatim, in `as_table_path()`,
and every DBI call it makes with a table passes `DBI::SQL()` of that path.
In the record, `copy_to(con, df, I("s.c"))` reaches duckdb's `dbExistsTable()` and `dbListFields()` with `SQL` only.
The source of dbplyr 2.6.0 agrees:
`dbplyr_write_table.DBIConnection()`, `db_table_drop_if_exists.DBIConnection()` and the Oracle methods wrap the path in `DBI::SQL()`,
and `sql_query_fields()` and `sql_query_save()` interpolate it into SQL that goes to `dbGetQuery()` and `dbExecute()`.
The one exception is `local_db_table()`, a test helper, which passes its `name` to `dbRemoveTable()` as given.
`remote_table()` returns `sql()` of the path.

The path comes back to duckdb's probe only through dplyr's `tbl()`: `compute(x, I("s.d"))` calls it with the `dbplyr_table_path`.
That is a character vector, so it quotes, as one identifier `"s.d"`, misses,
and the lazy table reads `FROM s.d` rather than the path dbplyr built.

## Why `dbExistsTable()` is strict

[#2896](https://github.com/duckdb/duckdb-r/pull/2896), merged 2026-10-14, moved `dbQuoteIdentifier()` out of the `tryCatch()`
("Quoted outside the probe", now in [`R/dbExistsTable__duckdb_connection_ANY.R`](/R/dbExistsTable__duckdb_connection_ANY.R)).
It switched on the DBItest specs that `TEST_RE2` had skipped everywhere,
and DBItest's `exists_table_error` failed: `dbExistsTable(con, NA)` answered `FALSE`.
The DBI specification asks for an error
"if `name` cannot be processed with `dbQuoteIdentifier()` or if this results in a non-scalar"
([`dbExistsTable()`](https://dbi.r-dbi.org/reference/dbExistsTable.html), Failure modes).
[#2893](https://github.com/duckdb/duckdb-r/pull/2893), merged the same day, narrowed the same `tryCatch()` further,
so that a transaction that has already failed raises rather than answers `FALSE`
([`2026-10-14-exists-table-transaction/`](/experiments/2026-10-14-exists-table-transaction/README.md)).
The release that carried both is squashed into 2f82664 on `main` and `v2.0-cyanoptera`, whose NEWS cites #2892, #2893 and #2896.

Neither change was aimed at `I()`.
`dbQuoteIdentifier(con, I("s.t"))` fails the same way on 1.4.0; only the swallowing stopped.

## Nine names

`s.t` is a table `t` in schema `s`; the last two rows name a Parquet file written from it.
On this branch:

| name | `dbExistsTable()` | `tbl()` |
|:---|:---|:---|
| `I("s.t")` | `SQL()` error | `SQL()` error |
| `SQL("s.t")` | `TRUE` | "Can't query fields", `FROM "s.t"` |
| `in_schema("s", "t")` | "Can only have a single name argument" | the same error |
| `Id("s", "t")` | `TRUE` | works |
| `ident_q("s.t")` | `FALSE` | works, through the `FROM` fallback |
| `"s.t"` | `FALSE` | works, through the `FROM` fallback |
| `sql("SELECT * FROM s.t")` | `FALSE` | works, unprobed |
| a Parquet path | `TRUE` | works |
| `I()` of the quoted Parquet path | `SQL()` error | `SQL()` error |

Of the seven table names the 1.4.0 script asks about, only `I("s.t")` differs there: `dbExistsTable()` answers `FALSE`, and `tbl()` works through the fallback.
`SQL("s.t")` fails in `tbl()` on both because dbplyr treats only `I()` and its own `sql()` as verbatim;
a DBI `SQL()` is a character vector to `as_table_path()`, and is quoted.

## Workarounds

On 2.0.0, without a change here:

* `tbl(con, Id("s", "t"))`, which DBI and dbplyr both understand, and which `dbExistsTable()` finds.
* `tbl(con, "s.t")`, which works only through the fallback, as `I()` did on 1.4.0.
* `tbl(con, sql("SELECT * FROM s.t"))`, which skips the probe.

`in_schema()` and `SQL()` do not work.

## Options

The script applies (a), (b) and (c) to the same nine names, as a patched copy registered for the run, with no change to `R/`.

| name | (a) `tbl()` | (b) `tbl()` | (c) `dbExistsTable()` | (c) `tbl()` |
|:---|:---|:---|:---|:---|
| `I("s.t")` | works | works | `TRUE` | works |
| `SQL("s.t")` | as today | `FROM (FROM "s.t")` | `TRUE` | as today |
| `in_schema("s", "t")` | works | works | as today | as today |
| `I()` of the quoted Parquet path | works | works | `TRUE` | works |

The other five names work under all three, as they do today.

**(a) `tbl.duckdb_connection()` probes only a bare string.**
The fallback exists for one form, a bare string naming a file or a table function,
so every other `from`, `I()`, `in_schema()`, `in_catalog()`, `Id()`, `ident_q()` and a table path among them,
goes to `NextMethod()` and dbplyr unprobed.
`dbQuoteIdentifier()` and `dbExistsTable()` stay as strict as DBI asks.

* Cost: one condition, `rlang::is_bare_character(from)` in place of `!inherits(from, "sql")`.
* Risk: a caller who relied on the fallback for a classed string, such as `ident_q("'x.parquet'")`, would get dbplyr's reading instead.
  `I("'x.parquet'")` keeps working, because dbplyr emits it verbatim.
  `compute()` with an `I()` name should then keep dbplyr's table path rather than `FROM s.d`; the record does not measure that.
* It also fixes `in_schema()`, which has failed since the probe was added.

**(b) A change in dbplyr, or probing what dbplyr would emit.**
dbplyr needs no change: it never passes an `I()` to DBI.
The variant here keeps the probe for everything but `sql()`, and asks about `SQL(dbplyr::as_table_path(from, con))`,
as dbplyr's own `db_table_drop_if_exists()` does.

* Cost: one more call into dbplyr, `as_table_path()`, which 2.6.0, the floor, exports.
* Risk: it runs a probe whose answer no longer changes anything for a table identifier,
  and it ties the probe to dbplyr's notion of a table path.
  `SQL("s.t")` fails with a worse query.

**(c) #3003: duckdb's `dbQuoteIdentifier()` takes a character `I()` as `SQL()`.**

* Cost: one method, or one branch.
* Risk: it gives `I()` a meaning in `dbQuoteIdentifier()`, `dbExistsTable()`, `dbWriteTable()`, `dbRemoveTable()` and every other method that quotes a name,
  which no other backend and not DBI's default gives it (below).
  Code that works on duckdb would then fail elsewhere, as #189's reporter found for the opposite direction.
* `in_schema()` still fails.

**(d) DBI treats `I()` as `SQL()`.**
DBI already registers `setOldClass("AsIs")`, for `dbDataType()` (`R/data-types.R` in r-dbi/DBI).
An `"AsIs"` object does not extend `"character"` in S4, so a method registered for `name = "character"` never sees it:

* RSQLite, RPostgres and odbc have no `dbExistsTable()` method an `I()` reaches.
  RSQLite raises "unable to find an inherited method", and selecting the method for RPostgres and odbc finds none.
* `dbQuoteIdentifier()` on all three reaches DBI's default for `x = "ANY"`, which accepts it as character
  and quotes `I("s.t")` as one identifier, `"s.t"`: the opposite of `SQL()`.
* duckdb is the one backend whose methods take any class, which is how #194 let `I()` in.

So the change would be a reversal of DBI's default, plus a method for `"AsIs"` beside every `"character"` method that takes a name,
in DBI for `dbQuoteIdentifier()`, and in each backend for `dbExistsTable()`, `dbReadTable()`,
`dbWriteTable()`, `dbAppendTable()`, `dbCreateTable()`, `dbRemoveTable()` and `dbListFields()`.
The DBI specification and DBItest name `I()` nowhere for identifiers; the issues found on DBI concern `dbDataType()`,
where [r-dbi/DBI#514](https://github.com/r-dbi/DBI/issues/514) shows a backend that has to copy the `"AsIs"` method because dispatch does not reach it.

* Cost: a DBI release, a DBItest spec, and every backend.
* Risk: it changes what `dbQuoteIdentifier(con, I(x))` returns today on every backend that inherits the default.

**Recommendation: (a).**
It removes the only path that hands an `I()` to DBI, fixes `in_schema()` as well,
keeps the strictness #2896 added for DBI's specification, and costs one condition.
#3003 can then be closed, or reduced to a clear error for an `"AsIs"` name in place of the `SQL()` accident.

## Replicating

From this directory, with `DUCKDB_R_SRC` naming a checkout of the branch by its absolute path:
`DUCKDB_R_USE_SYSTEM_LIB=1 NOT_CRAN=true DUCKDB_R_SRC="$(cd ../.. && pwd)" Rscript ../../scripts/render-reprex.R asis-table-names.R v2.0-cyanoptera`.
For 1.4.0, with the CRAN binary first in the library path, `Rscript ../../scripts/render-reprex.R cran-1-4-0.R v1.4.0`.
Both need dplyr and dbplyr; the first also needs RSQLite, and RPostgres and odbc installed, though neither connects.
