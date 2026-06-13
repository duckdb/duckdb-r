#' @rdname duckdb_result_arrow-class
#' @inheritParams methods::show
#' @usage NULL
show__duckdb_result_arrow <- function(object) {
  message(sprintf(
    "<duckdb_result_arrow %s connection=%s statement='%s'>",
    extptr_str(object@stmt_lst$ref),
    extptr_str(object@connection@conn_ref),
    object@stmt_lst$str
  ))
  invisible(NULL)
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("show", "duckdb_result_arrow", show__duckdb_result_arrow)
