# `I("schema.table")` names, dbplyr and the strict `dbExistsTable()`

*What it measures:* where `dplyr::tbl(con, I("s.t"))` fails on duckdb 2.0, and whose code passes the `I()` on;
which classes dbplyr hands to DBI methods in `copy_to()` and `compute()`;
how each way of opening a table fares in `dbExistsTable()` and `tbl()` on 2.0, and the table names among them on 1.4.0;
what candidate changes to this package would make of the same;
and what DBI's default, RSQLite, RPostgres and odbc do with an `I()` name.

*When and on what:* 2026-11-17, Linux x86_64, Ubuntu 24.04, R 4.5.3, DBI 1.3.0, dplyr 1.2.1, dbplyr 2.6.0,
RSQLite 3.53.3, RPostgres 1.4.10, odbc 1.7.2.
Each build is rendered by [`scripts/render-reprex.R`](/scripts/render-reprex.R):

* [`v2.0-cyanoptera.md`](v2.0-cyanoptera.md), from [`asis-table-names.R`](asis-table-names.R):
  duckdb 2.0.0.9000 at 73ead8b, the tip of `v2.0-cyanoptera`, without [#3003](https://github.com/duckdb/duckdb-r/pull/3003),
  loaded with `pkgload::load_all()` as a fast-path build linking the release `libduckdb` of DuckDB 2.0.0
  ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
* [`v1.4.0.md`](v1.4.0.md), from [`cran-1-4-0.R`](cran-1-4-0.R): duckdb 1.4.0, the CRAN binary,
  installed into a scratch library of its own from Posit's snapshot of CRAN for 2025-10-15.
  The session info's path to that library was replaced by hand with `<duckdb 1.4.0 library>`; nothing else in the file was edited.

*What it supports:* the sentence on which names `tbl()` probes, in the dbplyr section of [`usage/integrations/`](/handbook/usage/integrations/README.md),
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
so that a string naming a file or a table function can fall back to `sql(paste0("FROM ", from))`, a replacement scan.

* [duckdb/duckdb#3264](https://github.com/duckdb/duckdb/pull/3264), merged 2022-03-29, added the method and its probe
  ("Allow replacement scan if table is not found", then "Use dbExistTable"),
  so that `tbl(con, "'test.parquet'")` and `tbl(con, "read_csv_auto('file.csv')")` reach DuckDB unquoted.
  It wrapped a non-table in `ident_q()`.
* [#91](https://github.com/duckdb/duckdb-r/pull/91), merged 2024-03-03 for [#38](https://github.com/duckdb/duckdb-r/issues/38),
  replaced `ident_q()` with the `FROM` fallback, after dbplyr 2.4.0 had broken the `ident_q()` route.
* [#194](https://github.com/duckdb/duckdb-r/pull/194), the 1.0.0 merge that closed [#189](https://github.com/duckdb/duckdb-r/issues/189),
  widened `dbExistsTable()` from `name = "character"` to `"ANY"`.
  Before it, `tbl(con, I("main.cars"))` failed with "unable to find an inherited method ... `"AsIs"`".
  After it, the `I()` reached `dbQuoteIdentifier()` inside the probe's `tryCatch()`,
  which turned the same `SQL()` error into `FALSE`,
  and the `FROM s.t` fallback happened to be the query the user meant.
  No test pins `tbl(con, I(...))`.

The same probe is why `tbl(con, in_schema("s", "t"))` fails on both 1.4.0 and 2.0, with "Can only have a single name argument":
a `dbplyr_schema` is a list holding the schema and the table, so its `length()` is not one
([tidyverse/dbplyr#1333](https://github.com/tidyverse/dbplyr/issues/1333) reported it in 2023).

## What dbplyr hands to DBI

dbplyr turns `I("s.t")` into a `dbplyr_table_path`, verbatim, in `as_table_path()`.
In the record, `copy_to(con, df, I("s.c"))` reaches duckdb's `dbExistsTable()` with `SQL` only.
In the source of dbplyr 2.6.0, the DBI calls that take a table name pass `DBI::SQL()` of the path,
in `dbplyr_write_table.DBIConnection()`, `db_table_drop_if_exists.DBIConnection()` and the Oracle methods, except:

* `dbplyr_write_table.DBIConnection()` passes `table_path_name()`, the table name without its schema, as a plain string,
  for a `PostgreSQLConnection`, RPostgreSQL's class.
* `local_db_table()`, a test helper, passes its `name` to `dbRemoveTable()` as given.

`sql_query_fields()` and `sql_query_save()` interpolate the path into SQL that goes to `dbGetQuery()` and `dbExecute()`,
and `remote_table()` returns `sql()` of the path.
None of these passes an `I()` on.

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
The release that carried #2893 and #2896 is squashed into 2f82664 on `main` and `v2.0-cyanoptera`, whose NEWS cites #2892, #2893 and #2896.

The descriptions of #2893 and #2896 do not mention `I()` or `AsIs`; #2896's names `dbExistsTable(con, NA)`.
`dbQuoteIdentifier(con, I("s.t"))` fails the same way on 1.4.0; only the swallowing stopped.

## Ways to open a table

`s.t` is a table `t` in schema `s`, and the Parquet and CSV files are written from it.
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
| `glue()` of the CSV path | `TRUE` | works |
| `glue()` of `read_csv('<path>')` | `FALSE` | works, through the `FROM` fallback |
| `fs::path()` of the Parquet path | `TRUE` | works |
| `c(x = "s.t")` | `FALSE` | works, through the `FROM` fallback |
| `factor("s.t")` | "argument is not a character vector" | the same error |
| `"s.t"` with class `"foo"`, or `c("foo", "character")` | `SQL()` error, naming `"foo"` | the same error |
| `tbl_file()` of the CSV path | | works |
| `tbl_function()` of `read_csv('<path>')` | | works |

Among the table names the 1.4.0 script asks about, only `I("s.t")` differs there:
`dbExistsTable()` answers `FALSE`, and `tbl()` works through the fallback.
`SQL("s.t")` fails in `tbl()` on both because dbplyr treats only `I()` and its own `sql()` as verbatim;
a DBI `SQL()` is a character vector to `as_table_path()`, and is quoted.

## Spellings that open `s.t` on this branch

* `tbl(con, Id("s", "t"))`, which `dbExistsTable()` finds.
* `tbl(con, "s.t")` and `tbl(con, ident_q("s.t"))`, through the `FROM` fallback, as `I()` opened it on 1.4.0.
* `tbl(con, sql("SELECT * FROM s.t"))`, which is not probed.

`I()`, `in_schema()` and `SQL()` do not open it.

## Candidate changes

The script applies each change as a patched copy registered for the run, with no change to `R/`.
Rows where every change gives what the branch gives are left out:
`SQL("s.t")` fails under every change, and the rest open the table under every change.

| name | (a) | (a, bare) | (b) | (c) |
|:---|:---|:---|:---|:---|
| `I("s.t")` | works | works | works | works |
| `in_schema("s", "t")` | works | works | works | as today |
| `I()` of the quoted Parquet path | works | works | works | works |
| `glue()` of `read_csv('<path>')` | works | "Can't query fields" | "Can't query fields" | works |
| `factor("s.t")` | dbplyr's "must be a table source" | the same | dbplyr's "unknown specification" | as today |
| `"s.t"` with class `"foo"`, or `c("foo", "character")` | as today | "Can't query fields" | "Can't query fields" | as today |

**(a) `tbl.duckdb_connection()` probes a character `from` unless its class names a table identifier or SQL.**
The condition is `is.character(from) && !inherits(from, c("AsIs", "dbplyr_table_path", "ident", "sql", "SQL"))`.
Those are the classes dbplyr 2.6.0 gives `I()` (`"AsIs"`), a table path (`"dbplyr_table_path"`),
`ident()` and `ident_q()` (both `"ident"`) and its `sql()` (`"sql"`), and DBI gives `SQL()` (`"SQL"`, an S4 class).
`in_schema()`, `in_catalog()` and `Id()` are not character vectors and go to dbplyr unprobed.
`dbQuoteIdentifier()` and `dbExistsTable()` keep #2896's behaviour.

* `compute(x, I("s.e"))` under (a) gives a lazy table whose `remote_table()` is `s.e`, the path dbplyr built, where today it is `FROM s.e`.
* It fixes `in_schema()` as well.
* Classed character vectors are still probed.
  `glue()`, `fs::path()` and a named vector are probed and open the table as they do today, because no listed class is theirs.
  A string with an arbitrary class, `"foo"` alone or before `"character"`, fails with the `SQL()` error today and under (a) alike,
  because duckdb's `dbQuoteIdentifier()` keeps the class.
  A class that dbplyr adds for a table identifier later is probed until it joins the list,
  and a character subclass that inherits one of the listed classes is not probed.
* `factor("s.t")` fails before and after, with a different message.

**(a, bare) probes only a bare string.**
It breaks `tbl(con, glue::glue("read_csv('{csv}')"))`, which opens the table today:
dbplyr quotes the call as one identifier.
`glue()` of a plain path and `fs::path()` still open, because DuckDB resolves a quoted path as a replacement scan.

**(b) A change in dbplyr, or probing what dbplyr would emit.**
dbplyr needs no change: it never passes an `I()` to DBI.
The variant here probes a bare string as given and anything else as `SQL(dbplyr::as_table_path(from, con))`,
as dbplyr's own `db_table_drop_if_exists()` does.

* It costs a call into `as_table_path()`, which dbplyr 2.6.0, the floor, exports.
* The `glue()` of `read_csv()` fails, as under (a, bare), and `SQL("s.t")` fails with `FROM (FROM "s.t")` in the query.
* For a table identifier, it still runs the probe, and the probe's answer does not change the result.

**(c) #3003: duckdb's `dbQuoteIdentifier()` takes a character `I()` as `SQL()`.**

* It is one method, or one branch.
* It gives `I()` a meaning in `dbQuoteIdentifier()`, `dbExistsTable()`, `dbWriteTable()`, `dbRemoveTable()`
  and every other method that quotes a name, which no other backend and not DBI's default gives it.
  Code that works on duckdb would then fail elsewhere, as #189's reporter found for the opposite direction.
* `in_schema()` still fails.

**(d) DBI treats `I()` as `SQL()`.**
DBI already registers `setOldClass("AsIs")`, for `dbDataType()` (`R/data-types.R` in r-dbi/DBI).
An `"AsIs"` object does not extend `"character"` in S4, so a method registered for `name = "character"` never sees it:

* RSQLite, RPostgres and odbc have no `dbExistsTable()` method an `I()` reaches.
  RSQLite raises "unable to find an inherited method", and selecting the method for RPostgres and odbc finds none.
* `dbQuoteIdentifier()` on RSQLite, RPostgres and odbc reaches DBI's default for `x = "ANY"`, which accepts it as character
  and quotes `I("s.t")` as one identifier, `"s.t"`: the opposite of `SQL()`.
* duckdb is the one backend whose methods take any class, which is how #194 let `I()` in.

So the change would reverse DBI's default and add a method for `"AsIs"` beside every `"character"` method that takes a name:
in DBI for `dbQuoteIdentifier()`, and in each backend for `dbExistsTable()`, `dbReadTable()`, `dbWriteTable()`,
`dbAppendTable()`, `dbCreateTable()`, `dbRemoveTable()` and `dbListFields()`.
The DBI specification and DBItest name `I()` nowhere for identifiers; the issues found on DBI concern `dbDataType()`,
where [r-dbi/DBI#514](https://github.com/r-dbi/DBI/issues/514) shows a backend that has to copy the `"AsIs"` method
because dispatch does not reach it.
It takes a DBI release, a DBItest spec and every backend,
and changes what `dbQuoteIdentifier(con, I(x))` returns today on every backend that inherits the default.
The record does not run it.

## Replicating

From this directory, for the branch build, where `DUCKDB_R_SRC` names the checkout by its absolute path:

```sh
DUCKDB_R_USE_SYSTEM_LIB=1 NOT_CRAN=true DUCKDB_R_SRC="$(cd ../.. && pwd)" \
  Rscript ../../scripts/render-reprex.R asis-table-names.R v2.0-cyanoptera
```

It needs dplyr, dbplyr, glue, fs and RSQLite, and RPostgres and odbc installed, though neither connects;
odbc loads only with the system's `libodbc2`.
For 1.4.0, the binary goes into a library of its own, which then comes first:

```sh
Rscript -e 'install.packages("duckdb", lib = "<dir>",
  repos = "https://packagemanager.posit.co/cran/__linux__/noble/2025-10-15")'
R_LIBS="<dir>" Rscript ../../scripts/render-reprex.R cran-1-4-0.R v1.4.0
```
