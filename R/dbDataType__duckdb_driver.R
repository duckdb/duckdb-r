#' @rdname duckdb_driver-class
#' @usage NULL
dbDataType__duckdb_driver <- function(dbObj, obj, ...) {
  # FIXME: Use RApiTypes::DetectRType()
  if (is.null(obj)) stop("NULL parameter")
  if (is.data.frame(obj)) {
    return(vapply(obj, function(x) dbDataType(dbObj, x), FUN.VALUE = "character"))
  }
  #  else if (int64 && inherits(obj, "integer64")) "BIGINT"
  map_type <- duckdb_map_type_from_list_of(dbObj, obj)
  if (!is.null(map_type)) {
    return(map_type)
  }
  if (inherits(obj, "Date")) {
    "DATE"
  } else if (inherits(obj, "difftime")) {
    "TIME"
  } else if (is.logical(obj)) {
    "BOOLEAN"
  } else if (is.integer(obj)) {
    "INTEGER"
  } else if (is.numeric(obj)) {
    "DOUBLE"
  } else if (inherits(obj, "POSIXt")) {
    "TIMESTAMP"
  } else if (inherits(obj, "blob") || (is.list(obj) && all(vapply(obj, typeof, FUN.VALUE = "character") %in% c("raw", "NULL")))) {
    "BLOB"
  } else {
    "STRING"
  }
}

# Recognise a `vctrs::list_of` whose ptype is a `data.frame(key, value)`
# (the shape produced by `dbConnect(map = "list_of")`) and return its MAP type.
# Returns NULL when `obj` is not such a column.
duckdb_map_type_from_list_of <- function(dbObj, obj) {
  if (!inherits(obj, "vctrs_list_of")) {
    return(NULL)
  }
  ptype <- attr(obj, "ptype")
  if (!is.data.frame(ptype) || !identical(names(ptype), c("key", "value"))) {
    return(NULL)
  }
  k <- dbDataType(dbObj, ptype[["key"]])
  v <- dbDataType(dbObj, ptype[["value"]])
  sprintf("MAP(%s, %s)", k, v)
}

#' @rdname duckdb_driver-class
#' @export
setMethod("dbDataType", "duckdb_driver", dbDataType__duckdb_driver)
