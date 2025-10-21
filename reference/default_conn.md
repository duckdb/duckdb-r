# Get the default connection

**\[experimental\]**

`default_conn()` returns a default, built-in connection.

## Usage

``` r
default_conn()
```

## Value

A DuckDB connection object

## Details

Currently, the connection is established with
`duckdb(environment_scan = TRUE)` and
`dbConnect(timezone_out = "", array = "matrix")` so that data frames are
automatically available as tables, timestamps are returned in the local
timezone, and DuckDB's array type is returned as an R matrix. The
details of how the connection is established are subject to change. In
particular, returning the output as a tibble or other object may be
supported in the future.

This connection is intended for interactive use. There is no way for
this or other packages to comprehensively track the state of this
connection, so scripts and packages should manage their own connections.

## Examples

``` r
conn <- default_conn()
sql_query("SELECT 42", conn = conn)
#>   42
#> 1 42
```
