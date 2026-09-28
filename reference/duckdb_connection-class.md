# DuckDB connection class

Implements
[DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html).

## Usage

``` r
# S4 method for class 'duckdb_connection'
dbAppendTable(conn, name, value, ..., row.names = NULL)

# S4 method for class 'duckdb_connection'
dbBegin(conn, ...)

# S4 method for class 'duckdb_connection'
dbCommit(conn, ...)

# S4 method for class 'duckdb_connection'
dbDataType(dbObj, obj, ...)

# S4 method for class 'duckdb_connection,ANY'
dbExistsTable(conn, name, ...)

# S4 method for class 'duckdb_connection'
dbGetInfo(dbObj, ...)

# S4 method for class 'duckdb_connection'
dbIsValid(dbObj, ...)

# S4 method for class 'duckdb_connection,Id'
dbListFields(conn, name, ...)

# S4 method for class 'duckdb_connection,character'
dbListFields(conn, name, ...)

# S4 method for class 'duckdb_connection'
dbListTables(conn, ...)

# S4 method for class 'duckdb_connection,ANY'
dbQuoteIdentifier(conn, x, ...)

# S4 method for class 'duckdb_connection'
dbQuoteLiteral(conn, x, ...)

# S4 method for class 'duckdb_connection,character'
dbRemoveTable(conn, name, ..., fail_if_missing = TRUE)

# S4 method for class 'duckdb_connection'
dbRollback(conn, ...)

# S4 method for class 'duckdb_connection,character'
dbSendQueryArrow(conn, statement, params = NULL, ...)

# S4 method for class 'duckdb_connection,character'
dbSendQuery(conn, statement, params = NULL, ..., arrow = FALSE)

# S4 method for class 'duckdb_connection,character,data.frame'
dbWriteTable(
  conn,
  name,
  value,
  ...,
  row.names = FALSE,
  overwrite = FALSE,
  append = FALSE,
  field.types = NULL,
  temporary = FALSE
)

# S4 method for class 'duckdb_connection'
show(object)
```

## Arguments

- conn:

  A duckdb_connection object as returned by
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

- name:

  The table name, passed on to
  [`dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html).
  Options are:

  - a character string with the unquoted DBMS table name, e.g.
    `"table_name"`,

  - a call to [`Id()`](https://dbi.r-dbi.org/reference/Id.html) with
    components to the fully qualified table name, e.g.
    `Id(schema = "my_schema", table = "table_name")`

  - a call to [`SQL()`](https://dbi.r-dbi.org/reference/SQL.html) with
    the quoted and fully qualified table name given verbatim, e.g.
    `SQL('"my_schema"."table_name"')`

- value:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) (or coercible
  to data.frame).

- ...:

  Other parameters passed on to methods.

- row.names:

  Whether the row.names of the data.frame should be preserved

- dbObj:

  An object inheriting from class duckdb_connection.

- obj:

  An R object whose SQL type we want to determine.

- statement:

  a character string containing SQL.

- params:

  For `dbBind()`, a list of values, named or unnamed, or a data frame,
  with one element/column per query parameter. For `dbBindArrow()`,
  values as a nanoarrow stream, with one column per query parameter.

- arrow:

  Whether the query should be returned as an Arrow Table

- overwrite:

  If a table with the given name already exists, should it be
  overwritten?

- append:

  If a table with the given name already exists, just try to append the
  passed data to it

- field.types:

  Override the auto-generated SQL types

- temporary:

  Should the created table be temporary?

- object:

  Any R object

## Slots

- `conn_ref`:

  external pointer to the underlying DuckDB connection.

- `driver`:

  the
  [duckdb_driver](https://r.duckdb.org/reference/duckdb_driver-class.md)
  this connection was opened from.

- `debug`:

  whether debug information (such as queries) is printed.

- `convert_opts`:

  internal options controlling how result values are converted to R.

- `reserved_words`:

  character vector of the engine's reserved SQL keywords, used to quote
  identifiers.

- `timezone_out`:

  **\[deprecated\]** time zone results are returned in; superseded by
  `convert_opts`, from which it is copied at construction, and no longer
  read internally.

- `tz_out_convert`:

  **\[deprecated\]** how timestamps are converted to `timezone_out`
  (`"with"` or `"force"`); superseded by `convert_opts`.

- `bigint`:

  **\[deprecated\]** how 64-bit integers are returned; superseded by
  `convert_opts`.

## Multiple statements

A `statement` can hold several SQL statements separated by semicolons,
in [`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html),
[`dbSendQueryArrow()`](https://dbi.r-dbi.org/reference/dbSendQueryArrow.html),
and the helpers built on them, such as
[`dbExecute()`](https://dbi.r-dbi.org/reference/dbExecute.html) and
[`dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html). They
run in order, and each is prepared only after those before it have run,
so it sees their effects: a `PRAGMA` that generates SQL, such as
`create_fts_index`, finds a table created earlier in the same string.
Every statement but the last runs when the query is sent, `params` bind
to the last statement only, and only the last statement's result is
returned.

The whole string is parsed before anything runs, so a syntax error in
any statement means that none of them run. Any other error stops at the
statement that raised it, and the statements before it keep their
effect, because the string does not run in a transaction of its own. For
all or nothing, run the call inside
[`dbWithTransaction()`](https://dbi.r-dbi.org/reference/dbWithTransaction.html),
or call [`dbBegin()`](https://dbi.r-dbi.org/reference/transactions.html)
before it and
[`dbRollback()`](https://dbi.r-dbi.org/reference/transactions.html) if
it fails. To know which statements have run when one fails, send one
statement per call.
