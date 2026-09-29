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
#' so the rows arrive batch by batch and the result is not held twice.
#' `arrow::to_arrow()` materializes the whole result first,
#' through `dbSendQuery(arrow = TRUE)`.
#'
#' The streaming comes with hard limits, listed in the handbook, in
#' [`usage/integrations/`](https://github.com/duckdb/duckdb-r/blob/main/handbook/usage/integrations/README.md).
#' Use `to_arrow_stream()` where a large result goes straight into Arrow
#' and nothing else runs on its connection until the reader has been read
#' to the end.
#' Where that cannot be arranged, use `arrow::to_arrow()`,
#' or run everything else on a second connection.
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
#' # Read the reader to the end before anything else runs on `con`.
#' reader <- to_arrow_stream(dplyr::filter(dplyr::tbl(con, "mtcars"), cyl == 4))
#' as.data.frame(reader$read_table())
#'
#' # Another statement on `con` breaks a reader that has not been read yet.
#' reader <- to_arrow_stream(dplyr::tbl(con, "mtcars"))
#' dbGetQuery(con, "SELECT 1")
#' try(reader$read_table())
#'
#' # A second connection to the same database leaves the reader alone.
#' other <- dbConnect(con@driver)
#' reader <- to_arrow_stream(dplyr::tbl(con, "mtcars"))
#' dbGetQuery(other, "SELECT count(*) FROM mtcars")
#' reader$read_table()$num_rows
#'
#' dbDisconnect(other)
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
