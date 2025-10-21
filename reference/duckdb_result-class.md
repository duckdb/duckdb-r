# DuckDB Result Set

Methods for accessing result sets for queries on DuckDB connections.
Implements
[DBI::DBIResult](https://dbi.r-dbi.org/reference/DBIResult-class.html).

## Usage

``` r
duckdb_fetch_arrow(res, chunk_size = 1e+06)

duckdb_fetch_record_batch(res, chunk_size = 1e+06)

# S4 method for class 'duckdb_result'
dbBind(res, params, ...)

# S4 method for class 'duckdb_result'
dbClearResult(res, ...)

# S4 method for class 'duckdb_result'
dbColumnInfo(res, ...)

# S4 method for class 'duckdb_result'
dbFetch(res, n = -1, ...)

# S4 method for class 'duckdb_result'
dbGetInfo(dbObj, ...)

# S4 method for class 'duckdb_result'
dbGetRowCount(res, ...)

# S4 method for class 'duckdb_result'
dbGetRowsAffected(res, ...)

# S4 method for class 'duckdb_result'
dbGetStatement(res, ...)

# S4 method for class 'duckdb_result'
dbHasCompleted(res, ...)

# S4 method for class 'duckdb_result'
dbIsValid(dbObj, ...)

# S4 method for class 'duckdb_result'
show(object)
```

## Arguments

- res:

  Query result to be converted to a Record Batch Reader

- chunk_size:

  The chunk size

- params:

  For [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html), a list
  of values, named or unnamed, or a data frame, with one element/column
  per query parameter. For
  [`dbBindArrow()`](https://dbi.r-dbi.org/reference/dbBind.html), values
  as a nanoarrow stream, with one column per query parameter.

- ...:

  Other arguments passed on to methods.

- n:

  maximum number of records to retrieve per fetch. Use `n = -1` or
  `n = Inf` to retrieve all pending records. Some implementations may
  recognize other special values.

- dbObj:

  An object inheriting from class duckdb_result.

- object:

  Any R object
