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

## Releasing a batch

Each batch that
[`dbFetchArrowChunk()`](https://dbi.r-dbi.org/reference/dbFetchArrowChunk.html)
returns is a `nanoarrow_array` whose buffers live outside R's heap,
allocated by the engine. They are freed by the batch's release callback,
which runs in one of two ways.
[`nanoarrow::nanoarrow_pointer_release()`](https://arrow.apache.org/nanoarrow/latest/r/reference/nanoarrow_pointer_is_valid.html)
runs it at once, whatever else still refers to the batch, and gives the
most control: a loop that converts each batch and releases it holds one
batch at a time, however large the result. Dropping the batch instead
leaves the callback to R's garbage collector, which runs on R's own
allocations and never sees these buffers, so batches accumulate until a
collection happens; [`gc()`](https://rdrr.io/r/base/gc.html) is the
fallback that forces one, and it frees a batch only if nothing refers to
it any more.

Converting a batch with
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) copies
numeric columns, but character columns are converted lazily and keep
their part of the batch alive until they are materialized or dropped,
whichever way the batch itself was released. Releasing a batch never
affects the result it came from; the next
[`dbFetchArrowChunk()`](https://dbi.r-dbi.org/reference/dbFetchArrowChunk.html)
proceeds as before.
