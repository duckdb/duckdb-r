#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbColumnInfo
#' @usage NULL
dbColumnInfo__duckdb_result_arrow <- function(res, ...) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }
  data.frame(
    name = res@stmt_lst$names,
    type = res@stmt_lst$rtypes,
    stringsAsFactors = FALSE
  )
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("dbColumnInfo", "duckdb_result_arrow", dbColumnInfo__duckdb_result_arrow)
