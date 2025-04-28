#' DuckDB driver class
#'
#' Implements [DBIDriver-class].
#'
#' @aliases duckdb_driver
#' @keywords internal
#' @export
setClass("duckdb_driver", contains = "DBIDriver", slots = list(
  database_ref = "externalptr",
  config = "list",
  dbdir = "character",
  read_only = "logical",
  convert_opts = "list",
  bigint = "character"
))

#' DuckDB connection class
#'
#' Implements [DBIConnection-class].
#'
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
