dbQuoteIdentifier__duckdb_connection <- function(conn, x, ...) {
  if (is(x, "SQL")) {
    return(x)
  }
  if (is(x, "Id")) {
    return(SQL(paste0(dbQuoteIdentifier(conn, x@name), collapse = ".")))
  }

  if (any(is.na(x))) {
    stop("Cannot pass NA to dbQuoteIdentifier()")
  }

  x <- enc2utf8(x)
  needs_escape <- !grepl("^[a-zA-Z_][a-zA-Z0-9_]*$", x) | tolower(x) %in% conn@reserved_words
  x[needs_escape] <- paste0('"', gsub('"', '""', x[needs_escape]), '"')

  SQL(x, names = names(x))
}

#' @rdname duckdb_connection-class
#' @export
setMethod("dbQuoteIdentifier", signature("duckdb_connection"), dbQuoteIdentifier__duckdb_connection)
#' @rdname duckdb_connection-class
#' @usage NULL
setMethod("dbQuoteIdentifier", signature("duckdb_connection", "character"), dbQuoteIdentifier__duckdb_connection)
#' @rdname duckdb_connection-class
#' @usage NULL
setMethod("dbQuoteIdentifier", signature("duckdb_connection", "SQL"), dbQuoteIdentifier__duckdb_connection)
#' @rdname duckdb_connection-class
#' @usage NULL
setMethod("dbQuoteIdentifier", signature("duckdb_connection", "Id"), dbQuoteIdentifier__duckdb_connection)

get_reserved_words <- function(con) {
  dbGetQuery(con, "SELECT keyword_name FROM duckdb_keywords()")[[1]]
}
