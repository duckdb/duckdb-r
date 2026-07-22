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
  home = NULL,
  shared_home = NULL,
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
  array = "none",
  geometry = "blob",
  map = "data.frame"
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

  These dots are for future extensions and must be empty.

- home:

  Root directory for DuckDB's downloaded extensions and stored secrets.
  `NULL` (the default) resolves the location as described in
  [duckdb_storage](https://r.duckdb.org/reference/duckdb_storage.md): an
  existing `~/.duckdb`, else a per-session temporary directory (with an
  offer to create `~/.duckdb` in interactive sessions). Pass a path to
  use it as the root explicitly, creating it if needed. Cannot be
  combined with `shared_home`.

- shared_home:

  Opt in or out of the shared `~/.duckdb` location, overriding the
  automatic resolution. One of:

  - `NULL` (the default) – resolve automatically (see
    [duckdb_storage](https://r.duckdb.org/reference/duckdb_storage.md)).
    This is the safe default.

  - `TRUE` – store extensions and secrets under `~/.duckdb`, **creating
    that directory if it does not exist**. This is a good setting for
    permanent deployments (Posit Connect, Shiny, APIs). Do not use on
    CRAN or on other infrastructure where you don't own `~/.duckdb`.

    The setting is a durable, machine-level side effect that is *not*
    scoped to the current session: the directory persists after R exits,
    is reused by every future R session (and by the DuckDB CLI, Python
    and other clients that share `~/.duckdb`), and any secrets written
    there outlive this process. Applying this setting repeatedly is a
    fast no-op.

  - `FALSE` – use a per-session temporary directory even if `~/.duckdb`
    already exists. Nothing persists beyond the session.

  Cannot be combined with `home`.

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

- geometry:

  How geometry columns should be returned. There are two options:
  `"blob"` and `"wk"`. If `"blob"` is selected, geometry columns are
  returned as a list of raw vectors containing WKB data. If `"wk"` is
  selected, geometry columns are returned as wk `wk_wkb` vectors. Use
  [`wk::wk_handle()`](https://paleolimbot.github.io/wk/reference/wk_handle.html)
  or
  [`sf::st_as_sfc()`](https://r-spatial.github.io/sf/reference/st_as_sfc.html)
  to convert to other geometry formats.

- map:

  How `MAP` columns should be returned. There are two options:
  `"data.frame"` and `"list_of"`. If `"data.frame"` is selected (the
  default), `MAP` columns are returned as a list of data frames with
  `key` and `value` columns. If `"list_of"` is selected, `MAP` columns
  are returned as a
  [`vctrs::list_of()`](https://vctrs.r-lib.org/reference/list_of.html)
  whose `ptype` is a `data.frame(key = <K>, value = <V>)` that records
  the SQL key/value types. This enables MAP columns to round-trip
  through
  [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  /
  [`dbCreateTable()`](https://dbi.r-dbi.org/reference/dbCreateTable.html)
  without specifying `field.types`, and lets scans accept named-list
  cells as MAP entries.

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
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpJbVBMk/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
con <- dbConnect(drv)

dbGetQuery(con, "SELECT 'Hello, world!'")
#>   'Hello, world!'
#> 1   Hello, world!

dbDisconnect(con)
duckdb_shutdown(drv)

# Shorter:
con <- dbConnect(duckdb())
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpJbVBMk/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
dbGetQuery(con, "SELECT 'Hello, world!'")
#>   'Hello, world!'
#> 1   Hello, world!
dbDisconnect(con, shutdown = TRUE)
```
