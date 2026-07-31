# DuckDB Arrow Result Set

Streaming Arrow result for queries on DuckDB connections. Implements
[DBIResultArrow-class](https://dbi.r-dbi.org/reference/DBIResultArrow-class.html).

## Usage

``` r
# S4 method for class 'duckdb_result_arrow'
dbBind(res, params, ...)

# S4 method for class 'duckdb_result_arrow'
dbBindArrow(res, params, ...)

# S4 method for class 'duckdb_result_arrow'
dbClearResult(res, ...)

# S4 method for class 'duckdb_result_arrow'
dbColumnInfo(res, ...)

# S4 method for class 'duckdb_result_arrow'
dbFetchArrow(res, ..., chunk_size = 1e+06)

# S4 method for class 'duckdb_result_arrow'
dbFetchArrowChunk(res, ..., chunk_size = 1e+06)

# S4 method for class 'duckdb_result_arrow'
dbGetRowCount(res, ...)

# S4 method for class 'duckdb_result_arrow'
dbGetRowsAffected(res, ...)

# S4 method for class 'duckdb_result_arrow'
dbGetStatement(res, ...)

# S4 method for class 'duckdb_result_arrow'
dbHasCompleted(res, ...)

# S4 method for class 'duckdb_result_arrow'
dbIsValid(dbObj, ...)

# S4 method for class 'duckdb_result_arrow'
show(object)
```

## Arguments

- res:

  An object inheriting from
  [DBI::DBIResult](https://dbi.r-dbi.org/reference/DBIResult-class.html).

- params:

  For [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html), a list
  of values, named or unnamed, or a data frame, with one element/column
  per query parameter. For
  [`dbBindArrow()`](https://dbi.r-dbi.org/reference/dbBind.html), values
  as a nanoarrow stream, with one column per query parameter.

- ...:

  Other arguments passed on to methods.

- chunk_size:

  The chunk size in rows used when pulling Arrow batches from DuckDB.

- dbObj:

  An object inheriting from
  [DBIObject](https://dbi.r-dbi.org/reference/DBIObject-class.html),
  i.e.
  [DBIDriver](https://dbi.r-dbi.org/reference/DBIDriver-class.html),
  [DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html),
  or a [DBIResult](https://dbi.r-dbi.org/reference/DBIResult-class.html)

- object:

  Any R object

## Slots

- `connection`:

  the
  [duckdb_connection](https://r.duckdb.org/reference/duckdb_connection-class.md)
  the query was executed on.

- `stmt_lst`:

  internal list describing the prepared statement.

- `env`:

  environment holding the result's mutable fetch state.
