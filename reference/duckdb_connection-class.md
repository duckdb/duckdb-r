# DuckDB connection class

Implements
[DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html).

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

  For [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html), a list
  of values, named or unnamed, or a data frame, with one element/column
  per query parameter. For
  [`dbBindArrow()`](https://dbi.r-dbi.org/reference/dbBind.html), values
  as a nanoarrow stream, with one column per query parameter.

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
