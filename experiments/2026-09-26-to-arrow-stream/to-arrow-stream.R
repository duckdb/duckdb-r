# A replacement for arrow::to_arrow() on the DBI Arrow interface, and the two
# other constructions it was measured against. Sourced by the other scripts
# here; the README says why the first one is the candidate.

# The candidate. Same contract as arrow::to_arrow() in arrow 25.0.1:
# Arrow objects pass through, anything else must be a dbplyr table on a duckdb
# connection, groups make an arrow_dplyr_query, and otherwise the result is a
# RecordBatchReader. Only exported API is used.
to_arrow_stream <- function(.data) {
  if (inherits(.data, c("arrow_dplyr_query", "ArrowObject"))) {
    return(.data)
  }
  con <- dbplyr::remote_con(.data)
  if (!inherits(con, "duckdb_connection")) {
    stop(
      "to_arrow() currently only supports Arrow tables, Arrow datasets, ",
      "Arrow queries, or dbplyr tbls from duckdb connections",
      call. = FALSE
    )
  }
  groups <- dplyr::groups(.data)

  # DBI's default method sends the query, hands the stream over and clears
  # the DBI result; the stream owns the engine's query result from then on,
  # and arrow owns the stream.
  stream <- DBI::dbGetQueryArrow(con, dbplyr::remote_query(.data))
  out <- arrow::as_record_batch_reader(stream)

  if (length(groups)) {
    out <- dplyr::group_by(out, !!!groups)
  }
  out
}

# The literal swap: to_arrow()'s own body with its two duckdb calls replaced,
# keeping arrow's internal MakeSafeRecordBatchReader(), which moves every read
# onto R's thread.
to_arrow_literal <- function(.data) {
  groups <- dplyr::groups(.data)
  stream <- DBI::dbGetQueryArrow(
    dbplyr::remote_con(.data),
    dbplyr::remote_query(.data)
  )
  reader <- arrow::as_record_batch_reader(stream)
  out <- arrow:::MakeSafeRecordBatchReader(reader)
  if (length(groups)) {
    out <- dplyr::group_by(out, !!!groups)
  }
  out
}

# Reads on R's thread from exported API: arrow's function reader moves every
# call onto R's thread and passes an error on. Each batch is moved into arrow,
# but arrow hands it over as an R object, which keeps it until R collects.
to_arrow_pulled <- function(.data) {
  groups <- dplyr::groups(.data)
  stream <- DBI::dbGetQueryArrow(
    dbplyr::remote_con(.data),
    dbplyr::remote_query(.data)
  )
  out <- arrow::as_record_batch_reader(
    pull_batches(stream),
    schema = arrow::as_schema(stream$get_schema())
  )
  if (length(groups)) {
    out <- dplyr::group_by(out, !!!groups)
  }
  out
}

# Its environment holds the stream and nothing that refers back to the reader,
# so dropping the reader lets the stream go too.
pull_batches <- function(stream) {
  schema <- stream$get_schema()
  function() {
    if (!nanoarrow::nanoarrow_pointer_is_valid(stream)) {
      return(NULL)
    }
    batch <- stream$get_next()
    if (is.null(batch)) {
      stream$release()
      return(NULL)
    }
    array <- nanoarrow::nanoarrow_allocate_array()
    nanoarrow::nanoarrow_pointer_move(batch, array)
    batch_schema <- nanoarrow::nanoarrow_allocate_schema()
    nanoarrow::nanoarrow_pointer_export(schema, batch_schema)
    arrow::RecordBatch$import_from_c(array, batch_schema)
  }
}
