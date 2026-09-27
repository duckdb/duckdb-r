# Handbook: handbook/usage/integrations/README.md (what the reader streams, and its limits)
#' Stream a dbplyr table on DuckDB into Arrow
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `to_arrow_stream()` is a streaming counterpart of `arrow::to_arrow()`
#' for dbplyr tables on a DuckDB connection.
#' It sends the query with [DBI::dbGetQueryArrow()]
#' and hands the stream to `arrow::as_record_batch_reader()`,
#' so the rows arrive batch by batch.
#' `arrow::to_arrow()` materializes the whole result first,
#' through `dbSendQuery(arrow = TRUE)`.
#'
#' The reader is its connection's open result until it has been read to the end.
#' Another statement on that connection makes the next read an error,
#' and a query on that connection that scans the reader never returns.
#' Ctrl-C does not stop that query, and the R session has to be ended.
#' Tables from `arrow::to_duckdb()` share the one connection that arrow keeps
#' unless `con` is given:
#' for such a table, a later `to_duckdb()` call is such a statement,
#' and `to_duckdb()` on the reader with its default `con` is such a query.
#' Read the reader to the end first, or run the other statement on a separate
#' connection.
#'
#' Unlike `arrow::to_arrow()`, the reader is read on Arrow's threads,
#' not on R's, and Ctrl-C does not interrupt a read.
#'
#' @param .data A dbplyr table on a DuckDB connection, or an Arrow object,
#'   which is returned unchanged.
#' @return An Arrow `RecordBatchReader`,
#'   or an `arrow_dplyr_query` over it if `.data` is grouped.
#' @export
#' @examplesIf simulate_duckdb()$env$examples_enabled() && all(vapply(c("arrow", "dbplyr", "dplyr", "nanoarrow"), requireNamespace, logical(1), quietly = TRUE))
#' con <- dbConnect(duckdb())
#' dbWriteTable(con, "mtcars", mtcars)
#'
#' reader <- to_arrow_stream(dplyr::filter(dplyr::tbl(con, "mtcars"), cyl == 4))
#' as.data.frame(reader$read_table())
#'
#' dbDisconnect(con)
to_arrow_stream <- function(.data) {
  if (inherits(.data, c("arrow_dplyr_query", "ArrowObject"))) {
    return(.data)
  }
  for (pkg in c("arrow", "dbplyr", "dplyr", "nanoarrow")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      abort(sprintf("`to_arrow_stream()` requires the `%s` package.", pkg))
    }
  }

  con <- if (inherits(.data, "tbl_lazy")) dbplyr::remote_con(.data)
  # simulate_duckdb() is an S3 list that carries the class of a connection.
  if (!isS4(con) || !inherits(con, "duckdb_connection")) {
    abort(paste(
      "`to_arrow_stream()` takes a dbplyr table on a DuckDB connection",
      "or an Arrow object."
    ))
  }
  if (!dbIsValid(con)) {
    abort("`to_arrow_stream()` needs the connection of `.data` to be open.")
  }
  groups <- dplyr::groups(.data)

  # dbGetQueryArrow() clears the DBI result as it hands the stream over;
  # the stream owns the engine's query result from then on,
  # and the reader owns the stream.
  stream <- DBI::dbGetQueryArrow(con, dbplyr::remote_query(.data))
  out <- arrow::as_record_batch_reader(stream)

  if (length(groups) > 0) {
    out <- dplyr::group_by(out, !!!groups)
  }
  out
}
