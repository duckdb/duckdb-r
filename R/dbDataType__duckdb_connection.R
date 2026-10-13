#' @rdname duckdb_connection-class
#' @inheritParams DBI::dbDataType
#' @usage NULL
dbDataType__duckdb_connection <- function(dbObj, obj, ...) {
  # Column by column here, as the driver does, so that each column meets the check below
  if (is.data.frame(obj)) {
    return(vapply(
      obj,
      function(x) dbDataType(dbObj, x),
      FUN.VALUE = "character"
    ))
  }
  # The key and value types of a `list_of` map are asked of the connection too, so that they see its options
  map_type <- duckdb_map_type_from_list_of(dbObj, obj)
  if (!is.null(map_type)) {
    return(map_type)
  }
  # Under `time = "hms"`, an hms writes TIME and any other difftime INTERVAL,
  # so the connection answers the difftime the driver would call TIME
  # (handbook/usage/types/README.md).
  if (
    identical(dbObj@convert_opts$time, "hms") &&
      inherits(obj, "difftime") &&
      !inherits(obj, "hms")
  ) {
    return("INTERVAL")
  }
  # Under `interval = "Period"`, a lubridate Period writes INTERVAL.
  if (
    identical(dbObj@convert_opts$interval, "Period") &&
      inherits(obj, "Period")
  ) {
    return("INTERVAL")
  }
  dbDataType(dbObj@driver, obj, ...)
}

#' @rdname duckdb_connection-class
#' @export
setMethod("dbDataType", "duckdb_connection", dbDataType__duckdb_connection)
