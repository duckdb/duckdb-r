# Run an SQL query or statement

**\[experimental\]**

`sql_query()` runs an arbitrary SQL query using
[`DBI::dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html)
and returns a [data.frame](https://rdrr.io/r/base/data.frame.html) with
the query results. `sql_exec()` runs an arbitrary SQL statement using
[`DBI::dbExecute()`](https://dbi.r-dbi.org/reference/dbExecute.html) and
returns the number of affected rows.

These functions are intended as an easy way to interactively run DuckDB
without having to manage connections. By default, data frame objects are
available as views.

Scripts and packages should manage their own connections and prefer the
DBI methods for more control.

## Usage

``` r
sql_query(sql, conn = default_conn())

sql_exec(sql, conn = default_conn())
```

## Arguments

- sql:

  A SQL string

- conn:

  An optional connection, defaults to
  [`default_conn()`](https://r.duckdb.org/reference/default_conn.md)

## Value

A data frame with the query result

## Examples

``` r
# Queries
sql_query("SELECT 42")
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'dbObj' in selecting a method for function 'dbIsValid': error in evaluating the argument 'drv' in selecting a method for function 'dbConnect': {"exception_type":"IO","exception_message":"Input is not a GZIP stream: /proc/self/cgroup"}
#> ℹ Context: rapi_startup

# Statements with side effects
sql_exec("CREATE TABLE test (a INTEGER, b VARCHAR)")
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'dbObj' in selecting a method for function 'dbIsValid': error in evaluating the argument 'drv' in selecting a method for function 'dbConnect': {"exception_type":"IO","exception_message":"Input is not a GZIP stream: /proc/self/cgroup"}
#> ℹ Context: rapi_startup
sql_exec("INSERT INTO test VALUES (1, 'one'), (2, 'two')")
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'dbObj' in selecting a method for function 'dbIsValid': error in evaluating the argument 'drv' in selecting a method for function 'dbConnect': {"exception_type":"IO","exception_message":"Input is not a GZIP stream: /proc/self/cgroup"}
#> ℹ Context: rapi_startup
sql_query("FROM test")
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'dbObj' in selecting a method for function 'dbIsValid': error in evaluating the argument 'drv' in selecting a method for function 'dbConnect': {"exception_type":"IO","exception_message":"Input is not a GZIP stream: /proc/self/cgroup"}
#> ℹ Context: rapi_startup

# Data frames available as views
sql_query("FROM mtcars")
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'dbObj' in selecting a method for function 'dbIsValid': error in evaluating the argument 'drv' in selecting a method for function 'dbConnect': {"exception_type":"IO","exception_message":"Input is not a GZIP stream: /proc/self/cgroup"}
#> ℹ Context: rapi_startup
```
