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

## Slots

- `database_ref`:

  external pointer to the underlying DuckDB database instance.

- `config`:

  named list of DuckDB configuration flags applied when the instance was
  created.

- `dbdir`:

  path to the database file, or `":memory:"` for an in-memory database.

- `read_only`:

  whether the database was opened read-only.

- `convert_opts`:

  internal options controlling how result values are converted to R
  (bigint handling, time zone, ...).

- `bigint`:

  how 64-bit integers are returned (`"numeric"` or `"integer64"`).

- `allow_extensions`:

  **\[experimental\]** whether this driver permits loading DuckDB
  extensions (`INSTALL` / `LOAD`), resolved once when the driver is
  created. See the `allow_extensions` argument of
  [`duckdb()`](https://r.duckdb.org/reference/duckdb.md).
