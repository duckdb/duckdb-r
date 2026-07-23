# DuckDB driver class

Implements
[DBIDriver](https://dbi.r-dbi.org/reference/DBIDriver-class.html).

## Usage

``` r
# S4 method for class 'duckdb_driver'
dbDataType(dbObj, obj, ...)

# S4 method for class 'duckdb_driver'
dbGetInfo(dbObj, ...)

# S4 method for class 'duckdb_driver'
dbIsValid(dbObj, ...)

# S4 method for class 'duckdb_driver'
show(object)
```

## Arguments

- dbObj:

  An object inheriting from class duckdb_driver.

- ...:

  Other arguments to methods.

- object:

  Any R object

## Details

The driver object additionally carries an experimental
`allow_extensions` slot **\[experimental\]**: whether this driver
permits loading DuckDB extensions (`INSTALL` / `LOAD`), resolved once
when the driver is created. See the `allow_extensions` argument of
[`duckdb()`](https://r.duckdb.org/reference/duckdb.md).
