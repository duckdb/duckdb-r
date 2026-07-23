#' DuckDB driver class
#'
#' Implements [DBIDriver-class].
#'
#' @slot database_ref external pointer to the underlying DuckDB database instance.
#' @slot config named list of DuckDB configuration flags applied when the instance was created.
#' @slot dbdir path to the database file, or `":memory:"` for an in-memory database.
#' @slot read_only whether the database was opened read-only.
#' @slot convert_opts internal options controlling how result values are converted to R
#'   (bigint handling, time zone, ...).
#' @slot bigint how 64-bit integers are returned (`"numeric"` or `"integer64"`).
#' @slot allow_extensions `r lifecycle::badge("experimental")` whether this driver
#'   permits loading DuckDB extensions (`INSTALL` / `LOAD`),
#'   resolved once when the driver is created.
#'   See the `allow_extensions` argument of [duckdb()].
#' @aliases duckdb_driver
#' @keywords internal
#' @export
setClass("duckdb_driver", contains = "DBIDriver", slots = list(
  database_ref = "externalptr",
  config = "list",
  dbdir = "character",
  read_only = "logical",
  convert_opts = "list",
  bigint = "character",
  allow_extensions = "logical"
))

#' DuckDB connection class
#'
#' Implements [DBIConnection-class].
#'
#' @slot conn_ref external pointer to the underlying DuckDB connection.
#' @slot driver the [duckdb_driver-class] this connection was opened from.
#' @slot debug whether debug information (such as queries) is printed.
#' @slot convert_opts internal options controlling how result values are converted to R.
#' @slot reserved_words character vector of the engine's reserved SQL keywords, used to quote identifiers.
#' @slot timezone_out (legacy) time zone results are returned in.
#' @slot tz_out_convert (legacy) how timestamps are converted to `timezone_out` (`"with"` or `"force"`).
#' @slot bigint (legacy) how 64-bit integers are returned.
#' @aliases duckdb_connection
#' @keywords internal
#' @export
setClass("duckdb_connection", contains = "DBIConnection", slots = list(
  conn_ref = "externalptr",
  driver = "duckdb_driver",
  debug = "logical",
  convert_opts = "list",
  reserved_words = "character",

  # Legacy
  timezone_out = "character",
  tz_out_convert = "character",
  bigint = "character"
))

duckdb_connection <- function(duckdb_driver, debug, convert_opts) {
  out <- new(
    "duckdb_connection",
    conn_ref = rethrow_rapi_connect(duckdb_driver@database_ref, convert_opts),
    driver = duckdb_driver,
    debug = debug,
    convert_opts = convert_opts,
    timezone_out = convert_opts$timezone_out,
    tz_out_convert = convert_opts$tz_out_convert,
    bigint = convert_opts$bigint
  )
  out@reserved_words <- get_reserved_words(out)
  out
}

duckdb_random_string <- function(x) {
  paste(sample(letters, 10, replace = TRUE), collapse = "")
}
