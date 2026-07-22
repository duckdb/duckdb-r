# Register a data frame as a virtual table

`duckdb_register()` registers a data frame as a virtual table (view) in
a DuckDB connection. No data is copied.

## Usage

``` r
duckdb_register(conn, name, df, overwrite = FALSE, experimental = FALSE)

duckdb_unregister(conn, name)
```

## Arguments

- conn:

  A DuckDB connection, created by
  [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html).

- name:

  The name for the virtual table that is registered or unregistered

- df:

  A `data.frame` with the data for the virtual table

- overwrite:

  Should an existing registration be overwritten?

- experimental:

  Enable experimental optimizations

## Value

These functions are called for their side effect.

## Details

`duckdb_unregister()` unregisters a previously registered data frame.

## Examples

``` r
con <- dbConnect(duckdb())
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpAoSzIE/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.

data <- data.frame(a = 1:3, b = letters[1:3])

duckdb_register(con, "data", data)
dbReadTable(con, "data")
#>   a b
#> 1 1 a
#> 2 2 b
#> 3 3 c

duckdb_unregister(con, "data")

dbDisconnect(con)
```
