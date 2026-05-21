#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbFetchArrow
#' @param chunk_size The chunk size in rows used when pulling Arrow batches
#'   from DuckDB.
#' @usage NULL
dbFetchArrow__duckdb_result_arrow <- function(res, ..., chunk_size = 1000000) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }
  if (is.null(res@env$query_result)) {
    if (isTRUE(res@env$completed)) {
      stop("Result has already been consumed")
    }
    stop("Need to call `dbBind()` before `dbFetchArrow()`")
  }
  require_nanoarrow("dbFetchArrow()")

  stream <- nanoarrow::nanoarrow_allocate_array_stream()
  rethrow_rapi_fetch_arrow_stream_into(res@env$query_result, stream, chunk_size)

  res@env$query_result <- NULL
  res@env$completed <- TRUE
  stream
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("dbFetchArrow", "duckdb_result_arrow", dbFetchArrow__duckdb_result_arrow)

#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbFetchArrowChunk
#' @usage NULL
dbFetchArrowChunk__duckdb_result_arrow <- function(res, ..., chunk_size = 1000000) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }
  require_nanoarrow("dbFetchArrowChunk()")

  if (is.null(res@env$query_result)) {
    if (isTRUE(res@env$completed)) {
      return(empty_arrow_chunk(res))
    }
    stop("Need to call `dbBind()` before `dbFetchArrowChunk()`")
  }

  schema <- res@env$arrow_schema
  if (is.null(schema)) {
    schema <- nanoarrow::nanoarrow_allocate_schema()
  }
  array <- nanoarrow::nanoarrow_allocate_array()
  has_chunk <- rethrow_rapi_fetch_arrow_array(res@env$query_result, array, schema, chunk_size)
  res@env$arrow_schema <- schema

  if (!has_chunk) {
    res@env$query_result <- NULL
    res@env$completed <- TRUE
    return(empty_arrow_chunk(res))
  }
  nanoarrow::nanoarrow_pointer_set_protected(array, schema)
  array
}

#' @rdname duckdb_result_arrow-class
#' @export
setMethod("dbFetchArrowChunk", "duckdb_result_arrow", dbFetchArrowChunk__duckdb_result_arrow)

require_nanoarrow <- function(what) {
  if (!requireNamespace("nanoarrow", quietly = TRUE)) {
    stop(
      sprintf(
        "%s requires the `nanoarrow` package. Install it with `install.packages(\"nanoarrow\")`.",
        what
      ),
      call. = FALSE
    )
  }
}

empty_arrow_chunk <- function(res) {
  schema <- res@env$arrow_schema
  if (is.null(schema)) {
    # No chunk has ever been fetched (e.g. dbFetchArrowChunk() on a stream
    # that turned out to be empty after dbBind()). Pull the schema by hand
    # so we can synthesize a conforming 0-length array.
    schema <- nanoarrow::nanoarrow_allocate_schema()
    array <- nanoarrow::nanoarrow_allocate_array()
    rethrow_rapi_fetch_arrow_array(res@env$query_result, array, schema, 1L)
    res@env$arrow_schema <- schema
    res@env$query_result <- NULL
    res@env$completed <- TRUE
  }
  ptype <- nanoarrow::infer_nanoarrow_ptype(schema)
  nanoarrow::as_nanoarrow_array(ptype, schema = schema)
}
