# Connect to a DuckDB database instance

`duckdb()` creates or reuses a database instance.

`duckdb_shutdown()` shuts down a database instance.

Return an
[`adbcdrivermanager::adbc_driver()`](https://arrow.apache.org/adbc/current/r/adbcdrivermanager/reference/adbc_driver_void.html)
for use with Arrow Database Connectivity via the adbcdrivermanager
package.

[`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html) connects
to a database instance.

[`dbDisconnect()`](https://dbi.r-dbi.org/reference/dbDisconnect.html)
closes a DuckDB database connection. The associated DuckDB database
instance is shut down automatically, it is no longer necessary to set
`shutdown = TRUE` or to call `duckdb_shutdown()`.

## Usage

``` r
duckdb(
  dbdir = DBDIR_MEMORY,
  read_only = FALSE,
  bigint = "numeric",
  config = list(),
  ...,
  environment_scan = FALSE
)

duckdb_shutdown(drv)

duckdb_adbc()

# S4 method for class 'duckdb_driver'
dbConnect(
  drv,
  dbdir = DBDIR_MEMORY,
  ...,
  debug = getOption("duckdb.debug", FALSE),
  read_only = FALSE,
  timezone_out = "UTC",
  tz_out_convert = c("with", "force"),
  config = list(),
  bigint = "numeric",
  array = "none"
)

# S4 method for class 'duckdb_connection'
dbDisconnect(conn, ..., shutdown = TRUE)
```

## Arguments

- dbdir:

  Location for database files. Should be a path to an existing directory
  in the file system. With the default (or `""`), all data is kept in
  RAM.

- read_only:

  Set to `TRUE` for read-only operation. For file-based databases, this
  is only applied when the database file is opened for the first time.
  Subsequent connections (via the same `drv` object or a `drv` object
  pointing to the same path) will silently ignore this flag.

- bigint:

  How 64-bit integers should be returned. There are two options:
  `"numeric"` and `"integer64"`. If `"numeric"` is selected, bigint
  integers will be treated as double/numeric. If `"integer64"` is
  selected, bigint integers will be set to bit64 encoding.

- config:

  Named list with DuckDB configuration flags, see
  <https://duckdb.org/docs/configuration/overview#configuration-reference>
  for the possible options. These flags are only applied when the
  database object is instantiated. Subsequent connections will silently
  ignore these flags.

- ...:

  Reserved for future extensions, must be empty.

- environment_scan:

  Set to `TRUE` to treat data frames from the calling environment as
  tables. If a database table with the same name exists, it takes
  precedence. The default of this setting may change in a future
  version.

- drv:

  Object returned by `duckdb()`

- debug:

  Print additional debug information, such as queries.

- timezone_out:

  The time zone returned to R, defaults to `"UTC"`, which is currently
  the only timezone supported by duckdb. If you want to display datetime
  values in the local timezone, set to
  [`Sys.timezone()`](https://rdrr.io/r/base/timezones.html) or `""`.

- tz_out_convert:

  How to convert timestamp columns to the timezone specified in
  `timezone_out`. There are two options: `"with"`, and `"force"`. If
  `"with"` is chosen, the timestamp will be returned as it would appear
  in the specified time zone. If `"force"` is chosen, the timestamp will
  have the same clock time as the timestamp in the database, but with
  the new time zone.

- array:

  How arrays should be returned. There are two options: `"none"` and
  `"matrix"`. If `"none"` is selected, arrays are not returned. Instead
  an error is generated. If `"matrix"` is selected, arrays are returned
  as a column matrix. Each array is one row in the matrix.

- conn:

  A `duckdb_connection` object

- shutdown:

  Unused. The database instance is shut down automatically.

## Value

`duckdb()` returns an object of class
[duckdb_driver](https://r.duckdb.org/reference/duckdb_driver-class.md).

[`dbDisconnect()`](https://dbi.r-dbi.org/reference/dbDisconnect.html)
and `duckdb_shutdown()` are called for their side effect.

An object of class "adbc_driver"

[`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html) returns
an object of class
[duckdb_connection](https://r.duckdb.org/reference/duckdb_connection-class.md).

## Details

The behavior of `with = "force"` at DST transitions depends on how R
handles translation from the underlying time representation to a
human-readable format. If the timestamp is invalid in the target
timezone, the resulting value may be `NA` or an adjusted time.

## Examples

``` r
library(adbcdrivermanager)
with_adbc(db <- adbc_database_init(duckdb_adbc()), {
  as.data.frame(read_adbc(db, "SELECT 1 as one;"))
})
#>   one
#> 1   1
drv <- duckdb()
con <- dbConnect(drv)

dbGetQuery(con, "SELECT 'Hello, world!'")
#>   'Hello, world!'
#> 1   Hello, world!

dbDisconnect(con)
duckdb_shutdown(drv)

# Shorter:
con <- dbConnect(duckdb())
dbGetQuery(con, "SELECT 'Hello, world!'")
#>   'Hello, world!'
#> 1   Hello, world!
dbDisconnect(con, shutdown = TRUE)
```
