#' @rdname duckdb_result_arrow-class
#' @inheritParams DBI::dbFetchArrow
#' @param chunk_size The chunk size in rows used when pulling Arrow batches
#'   from DuckDB.
#' @usage NULL
dbFetchArrow__duckdb_result_arrow <- function(res, ..., chunk_size = 1000000) {
  if (!res@env$open) {
    stop("result has already been cleared")
  }
  require_nanoarrow("dbFetchArrow()")

  if (is.null(res@env$query_result)) {
    if (isTRUE(res@env$completed)) {
      return(empty_arrow_stream(res))
    }
    stop("Need to call `dbBind()` before `dbFetchArrow()`")
  }

  pending <- res@env$pending_query_results
  if (is.null(pending) || length(pending) == 0L) {
    # Single execution: hand the streaming wrapper over to nanoarrow directly.
    stream <- nanoarrow::nanoarrow_allocate_array_stream()
    rethrow_rapi_fetch_arrow_stream_into(res@env$query_result, stream, chunk_size)
    res@env$query_result <- NULL
    res@env$completed <- TRUE
    return(stream)
  }

  # Multi-execution: drain every per-row query result into chunks and emit a
  # single basic_array_stream so callers see one unified stream.
  arrays <- list()
  repeat {
    chunk <- dbFetchArrowChunk(res, chunk_size = chunk_size)
    if (chunk$length == 0L) break
    arrays[[length(arrays) + 1L]] <- chunk
  }
  if (length(arrays) == 0L) {
    return(empty_arrow_stream(res))
  }
  schema <- res@env$arrow_schema
  if (is.null(schema)) {
    schema <- nanoarrow::infer_nanoarrow_schema(arrays[[1L]])
  }
  nanoarrow::basic_array_stream(arrays, schema = schema, validate = FALSE)
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

  repeat {
    schema <- res@env$arrow_schema
    if (is.null(schema)) {
      schema <- nanoarrow::nanoarrow_allocate_schema()
    }
    array <- nanoarrow::nanoarrow_allocate_array()
    has_chunk <- rethrow_rapi_fetch_arrow_array(res@env$query_result, array, schema, chunk_size)
    res@env$arrow_schema <- schema

    if (has_chunk) {
      nanoarrow::nanoarrow_array_set_schema(array, schema, validate = FALSE)
      return(array)
    }

    # Current result drained: advance to next pending bind result, if any.
    pending <- res@env$pending_query_results
    if (length(pending) > 0L) {
      res@env$query_result <- pending[[1L]]
      res@env$pending_query_results <- pending[-1L]
      next
    }
    res@env$query_result <- NULL
    res@env$completed <- TRUE
    return(empty_arrow_chunk(res))
  }
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
    # No chunk has ever been fetched (e.g. dbBindArrow() with a zero-length
    # stream). Fall back to an empty no-column array; downstream code that
    # only inspects `chunk$length` is unaffected.
    return(nanoarrow::as_nanoarrow_array(data.frame()))
  }
  ptype <- nanoarrow::infer_nanoarrow_ptype(schema)
  nanoarrow::as_nanoarrow_array(ptype, schema = schema)
}

empty_arrow_stream <- function(res) {
  chunk <- empty_arrow_chunk(res)
  nanoarrow::basic_array_stream(
    list(),
    schema = nanoarrow::infer_nanoarrow_schema(chunk),
    validate = FALSE
  )
}
