# Register an Arrow data source as a virtual table

`duckdb_register_arrow()` registers an Arrow data source as a virtual
table (view) in a DuckDB connection. No data is copied.

## Usage

``` r
duckdb_register_arrow(conn, name, arrow_scannable, use_async = NULL)

duckdb_unregister_arrow(conn, name)

duckdb_list_arrow(conn)
```

## Arguments

- conn:

  A DuckDB connection, created by
  [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html).

- name:

  The name for the virtual table that is registered or unregistered

- arrow_scannable:

  A scannable Arrow-object

- use_async:

  Switched to the asynchronous scanner. (deprecated)

## Value

These functions are called for their side effect.

## Details

`duckdb_unregister_arrow()` unregisters a previously registered data
frame.
