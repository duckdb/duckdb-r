# Limits found in review and left in place

*What it measures:* limits of running statements and of writing R values
that reviews of the stack of pull requests named below found and did not fix.
For statements: an `INSTALL` or `LOAD` in a multi-statement string under `allow_extensions = FALSE`,
a `PRAGMA` whose expansion fails while a streaming result is open,
and one character parameter used both inside `typeof()` and in a cast.
For types: `NaN` and infinities in a `Date`, `difftime` or `POSIXct` stored as double, a `POSIXct` stored as integer,
`dbDataType()` of a data frame column, and when an `ARRAY` column is refused under `array = "none"`.

*When and on what:* 2026-09-27, Linux x86_64 with 4 cores, R 4.5.3, DBI 1.3.0, callr 3.8.0.
duckdb 1.5.5.9028 is a55c0f14cd, the top of the stack of pull requests this record was written on,
a fast-path build linking the release `libduckdb` of DuckDB 1.5.5 ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
What is measured is the glue's code and engine code the release shares with the vendored engine.
[`statements.R`](statements.R) and [`types.R`](types.R) are rendered to [`statements.md`](statements.md) and [`types.md`](types.md)
by [`scripts/render-reprex.R`](/scripts/render-reprex.R),
and the session info names the scratch library that held the build as `<fast-path build library>`.

*What it supports:* the multi-statement and parameter entries in [`usage/statements/`](/handbook/usage/statements/README.md),
and the limitations in [`usage/types/`](/handbook/usage/types/README.md).

## Statements

From [`statements.md`](statements.md):

* **An `INSTALL` or `LOAD` stops the whole string.**
  Under `allow_extensions = FALSE`, `CREATE TABLE l1 (i INTEGER); LOAD parquet` is refused and leaves no `l1`,
  where a string whose second statement fails for another reason keeps its first.
  `rapi_prepare()` in [`src/statement.cpp`](/src/statement.cpp) checks every parsed statement before it runs the first.
* **A `PRAGMA`'s expansion is left half done while a stream is open.**
  An export of two tables, the second table's CSV made unparseable, is imported with `PRAGMA import_database`.
  On its own the import fails and leaves no table.
  With a `dbSendQueryArrow()` result open on the connection it fails the same way,
  and leaves both tables created, the first one loaded, and no transaction for `dbRollback()` to end.
  The engine wraps an expansion of several statements in a transaction only when it finds none active
  (`GetTransactionHandling()` in [`statement_preprocessor.cpp`](/src/duckdb/src/planner/statement_preprocessor.cpp)),
  and the transaction an open stream holds is one.
* **One character parameter inside `typeof()` and in a cast invalidates the database.**
  `SELECT typeof($1), $1::VARCHAR` with `params = list("ok")` raises `INTERNAL Error: Invalid PhysicalType for GetTypeIdSize`.
  The next statement on the connection, a new connection to the driver, and a new driver on the same file
  then fail with `FATAL Error: Failed: database has been invalidated`, until `duckdb_shutdown()` releases the instance;
  the file's committed rows are there after it.
  An integer, a double, a logical or a `Date` in the same query answers, and so does a character value bound to two parameters.
  The error is the engine's:
  [`2026-09-27-arrow-types/`](/experiments/2026-09-27-arrow-types/README.md) raised it with `PREPARE` and `EXECUTE` alone.

## Types

From [`types.md`](types.md):

* **`NaN`, `Inf` and `-Inf` write as far-off negative values, not as `NULL` or infinity.**
  In a `Date`, a `difftime` and a `POSIXct` stored as double, all three write as `DATE` 5877642-06-23 (BC),
  `INTERVAL` -106751991 days -04:00:54.775808,
  and the `TIMESTAMP` at the smallest 64-bit microsecond count, which no cast to `VARCHAR` accepts.
  Only `NA` writes `NULL`: `RDoubleType::IsNull()` in [`src/types.cpp`](/src/types.cpp) tests `ISNA()`,
  and every other value is converted to an integer, which for a value that is not finite is undefined in C++.
  What x86_64 does with it is what is recorded here.
* **A `POSIXct` stored as integer writes `INTEGER`.**
  The column reads back as `integer`, `dbDataType()` says `INTEGER` too, and so does `typeof()` of it bound as a parameter.
  `RApiTypes::DetectRType()` in [`src/types.cpp`](/src/types.cpp) takes a `POSIXct` as a timestamp only when it is a double,
  and [`R/dbDataType__duckdb_driver.R`](/R/dbDataType__duckdb_driver.R) tests `is.integer()` before it tests for `POSIXt`.
* **`dbDataType()` does not describe a data frame column.**
  For a data frame nesting one of two fields it fails with "values must be length 1",
  and so do `sqlCreateTable()` and `dbCreateTable()`, where `dbWriteTable()` writes the column as a `STRUCT`.
  Nesting one field, it gives that field's type, so `dbCreateTable()` creates an `INTEGER` column that `dbAppendTable()` then cannot fill.
  `dbDataType()` of a data frame is a `vapply()` over its columns that expects one type from each.
* **An `ARRAY` column under `array = "none"` is refused after the statement ran.**
  `INSERT ... RETURNING` of an `INTEGER[2]` fails with the `array = "matrix"` hint, and the row is inserted.
  One returning a `BIT` is refused before it runs, and inserts nothing.
  The check before running (`CheckResultTypeForR()` in [`src/statement.cpp`](/src/statement.cpp)) looks at an array's element type only,
  and the refusal comes when the result is converted (`duckdb_r_allocate()` in [`src/transform.cpp`](/src/transform.cpp)).

## Replicating

From this directory, with the build under test first in the library path,
`Rscript ../../scripts/render-reprex.R statements.R statements`, and likewise for `types.R`.
Neither needs a network, and neither waits.
