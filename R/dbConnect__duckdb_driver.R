#' Connect to a DuckDB database instance
#'
#' `dbConnect()` connects to a database instance.
#'
#' @param drv Object returned by `duckdb()`
#' @param dbdir Location for database files. Should be a path to an existing
#'   directory in the file system. With the default (or `""`), all
#'   data is kept in RAM.
#' @param ... Reserved for future extensions, must be empty.
#' @param debug Print additional debug information, such as queries.
#' @param read_only Set to `TRUE` for read-only operation.
#'   For file-based databases, this is only applied when the database file is opened for the first time.
#'   Subsequent connections (via the same `drv` object or a `drv` object pointing to the same path)
#'   will silently ignore this flag.
#' @param timezone_out The time zone returned to R, defaults to `"UTC"`, which
#'   is currently the only timezone supported by duckdb.
#'   If you want to display datetime values in the local timezone,
#'   set to [Sys.timezone()] or `""`.
#' @param tz_out_convert How to convert timestamp columns to the timezone specified
#'   in `timezone_out`. There are two options: `"with"`, and `"force"`. If `"with"`
#'   is chosen, the timestamp will be returned as it would appear in the specified time zone.
#'   If `"force"` is chosen, the timestamp will have the same clock
#'   time as the timestamp in the database, but with the new time zone.
#' @param config Named list with DuckDB configuration flags, see
#'   <https://duckdb.org/docs/configuration/overview#configuration-reference> for the possible options.
#'   These flags are only applied when the database object is instantiated.
#'   Subsequent connections will silently ignore these flags.
#' @param bigint How 64-bit integers should be returned. There are two options: `"numeric"` and `"integer64"`.
#'   If `"numeric"` is selected, bigint integers will be treated as double/numeric.
#'   If `"integer64"` is selected, bigint integers will be set to bit64 encoding.
#' @param array How arrays should be returned. There are two options: `"none"` and `"matrix"`.
#'   If `"none"` is selected, arrays are not returned. Instead an error is generated.
#'   If `"matrix"` is selected, arrays are returned as a column matrix. Each array is one row in the matrix.
#'
#' @return `dbConnect()` returns an object of class [duckdb_connection-class].
#'
#' @details
#' The behavior of `with = "force"` at DST transitions depends on how R handles translation from
#' the underlying time representation to a human-readable format.
#' If the timestamp is invalid in the target timezone, the resulting value may be `NA`
#' or an adjusted time.
#'
#' @rdname duckdb
#' @examples
#' drv <- duckdb()
#' con <- dbConnect(drv)
#'
#' dbGetQuery(con, "SELECT 'Hello, world!'")
#'
#' dbDisconnect(con)
#' duckdb_shutdown(drv)
#'
#' # Shorter:
#' con <- dbConnect(duckdb())
#' dbGetQuery(con, "SELECT 'Hello, world!'")
#' dbDisconnect(con, shutdown = TRUE)
#' @usage NULL
dbConnect__duckdb_driver <- function(
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
) {
  check_flag(debug)
  timezone_out <- check_tz(timezone_out)
  tz_out_convert <- match.arg(tz_out_convert)

  if (missing(dbdir)) {
    dbdir <- drv@dbdir
  } else {
    dbdir <- path_normalize(dbdir)
  }

  if (missing(read_only)) {
    read_only <- drv@read_only
  }

  if (missing(bigint)) {
    bigint <- drv@convert_opts$bigint
  }

  convert_opts <- duckdb_convert_opts(
    timezone_out = timezone_out,
    tz_out_convert = tz_out_convert,
    bigint = bigint,
    array = array
  )

  config <- utils::modifyList(drv@config, config)

  # aha, a late comer. let's make a new instance.
  if (dbdir != drv@dbdir || !rethrow_rapi_lock(drv@database_ref)) {
    rethrow_rapi_unlock(drv@database_ref)
    drv <- duckdb(dbdir, read_only, bigint, config)
  }

  conn <- duckdb_connection(drv, debug = debug, convert_opts = convert_opts)
  on.exit(dbDisconnect(conn))

  reg.finalizer(conn@conn_ref, onexit = TRUE, rapi_disconnect)
  on.exit(NULL)

  rs_on_connection_opened(conn)

  conn
}

#' @rdname duckdb
#' @export
setMethod("dbConnect", "duckdb_driver", dbConnect__duckdb_driver)
